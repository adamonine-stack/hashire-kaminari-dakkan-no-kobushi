extends Control

const CAST_SCALE := preload("res://scripts/ui/ending_cast_scale.gd")
const SNAPSHOT_META := &"stage8_ending_snapshot"
const HERO_IDS := ["player_01_akky", "player_02_gou", "player_03_seiya"]
const HERO_NAMES := ["アッキー", "ゴウ", "セイヤ"]
const HERO_ART_IDS := ["ally_balance", "ally_power", "ally_speed"]
const ENDING_HERO := preload("res://scripts/ui/ending_hero.gd")
const CHECKPOINT := preload("res://scripts/ui/stage8_ending_checkpoint.gd")
const CREDITS_CHECKPOINT := preload("res://scripts/ui/ending_credits_checkpoint.gd")
const SCRIPT_PATH := "res://data/story/stage8_dialogue.txt"
const ENDING_VERSION := "STAGE8_TRUE_ENDING_V1"

var route := ""
var pages: Array[Dictionary] = []
var page_index := 0
var actors: Dictionary = {}
var badges: Dictionary = {}
var safe_content: Control
var backdrop: TextureRect
var speaker_label: Label
var story_label: Label
var next_button: Button
var heading: Label
var end_card: Label
var veil: ColorRect
var input_locked := false
var finished := false
var terminal_card := false
var credits_roll: Label
var credits_started := false
var credits_complete := false
var returning_to_title := false
var credits_timing_scale := 1.0 # QA may shorten the roll without changing gameplay timing.
var last_input_msec := -1000
var visible_elapsed := 0.0
var script_events: Array[String] = []
var stage8_snapshot: Array = []

static func route_for(living: Array) -> String:
	var mask := 0
	for i in range(3):
		if living.has(HERO_IDS[i]): mask |= 1 << i
	return {1:"A", 2:"B", 4:"C", 3:"D", 5:"E", 6:"F", 7:"G"}.get(mask, "")

static func dialogue_for(selected_route: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var active := false
	for raw in FileAccess.get_file_as_string(SCRIPT_PATH).split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("["):
			active = line == "[%s]" % selected_route
		elif active and line.contains("|"):
			var parts := line.split("|", true, 1)
			result.append({"speaker":parts[0], "text":parts[1]})
	return result

func _ready() -> void:
	get_tree().paused = false
	get_tree().root.set_meta(&"st_action_continue_run", false)
	stage8_snapshot = get_tree().root.get_meta(SNAPSHOT_META, [])
	if stage8_snapshot.is_empty():
		stage8_snapshot = CHECKPOINT.load_snapshot()
		get_tree().root.set_meta(SNAPSHOT_META, stage8_snapshot)
	var living: Array = []
	for data in stage8_snapshot:
		if not bool(data.get("is_defeated", false)) and int(data.get("current_health", 0)) > 0:
			living.append(String(data.get("character_id", "")))
	route = route_for(living)
	if route.is_empty():
		get_tree().change_scene_to_file("res://scenes/Title.tscn")
		return
	pages = dialogue_for(route)
	_build(living)
	_layout()
	get_viewport().size_changed.connect(_layout)
	# Route G still owns its final-boss music and deliberate silence cue.
	if route == "G": _audio("play_bgm", "final_boss")
	else: get_node("/root/AudioManager").play_ending_theme("final_boss")
	_show_page()
	print("[%s] ENDING route=%s mio=%s ren=%s" % [ENDING_VERSION, route, living.has(HERO_IDS[0]), living.has(HERO_IDS[1])])

func _process(delta: float) -> void:
	if not input_locked and not terminal_card and not finished:
		visible_elapsed += delta
		story_label.visible_characters = mini(story_label.get_total_character_count(), int(visible_elapsed * 38.0))

func _input(event: InputEvent) -> void:
	if not credits_started or returning_to_title: return
	var tapped := false
	if event is InputEventScreenTouch:
		tapped = (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		tapped = mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	if tapped or (event.is_action_pressed("ui_accept") and not event.is_echo()):
		get_viewport().set_input_as_handled()
		_return_from_credits()


func _return_from_credits() -> void:
	if returning_to_title: return
	returning_to_title = true
	await get_node("/root/AudioManager").fade_out()
	get_tree().change_scene_to_file("res://scenes/Title.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		advance()
		get_viewport().set_input_as_handled()

func advance() -> void:
	if input_locked or finished or Time.get_ticks_msec() - last_input_msec < 180: return
	last_input_msec = Time.get_ticks_msec()
	if terminal_card:
		_begin_normal_credits()
		return
	if story_label.visible_characters >= 0 and story_label.visible_characters < story_label.get_total_character_count():
		visible_elapsed = 1000.0
		story_label.visible_characters = -1
		return
	page_index += 1
	_show_page()

func _auto_begin_normal_credits() -> void:
	await get_tree().create_timer(3.0).timeout
	if terminal_card and not finished: _begin_normal_credits()


func _begin_normal_credits() -> void:
	if finished: return
	finished = true
	_record_completion()
	_roll_normal_credits()


func _roll_normal_credits() -> void:
	# Persist the already-determined ending BEFORE unloading scene textures.
	# The checkpoint survives a browser reload until the player taps to exit.
	var ending_type := CREDITS_CHECKPOINT.BAD if route == "C" else CREDITS_CHECKPOINT.NORMAL
	if CREDITS_CHECKPOINT.save_pending(ending_type) != OK:
		push_error("Cannot save ending credits checkpoint")
		# Preserve the Stage8 checkpoint if the new one could not be written.
		finished = false
		return
	credits_started = true
	print("[%s] CREDITS_START route=%s" % [ENDING_VERSION, route])
	get_tree().change_scene_to_file(CREDITS_CHECKPOINT.SCENE)


func _show_page() -> void:
	if page_index >= pages.size(): return
	var page := pages[page_index]
	if page.speaker == "@":
		_execute_event(String(page.text))
		return
	visible_elapsed = 0.0
	story_label.visible_characters = 0
	speaker_label.text = String(page.speaker)
	story_label.text = String(page.text)
	for actor_name in actors:
		actors[actor_name].modulate = Color.WHITE if actor_name == page.speaker else Color(0.60, 0.66, 0.77)
		badges[actor_name].modulate = Color("f8da99") if actor_name == page.speaker else Color("a1adbe")
	next_button.text = "次へ  [決定 / タップ]"

func _execute_event(event_name: String) -> void:
	input_locked = true
	next_button.disabled = true
	script_events.append(event_name)
	match event_name:
		"bad_pause":
			await get_tree().create_timer(1.2).timeout
		"true_pause":
			# Deliberately no fade: the audience stays in the rescue chamber.
			await get_tree().create_timer(3.0).timeout
		"exchange_glance":
			for actor_name in ["ミオ", "レン"]:
				actors[actor_name].modulate = Color.WHITE
			var glance := create_tween().set_parallel(true)
			glance.tween_property(actors["ミオ"], "rotation", -0.035, 0.3)
			glance.tween_property(actors["レン"], "rotation", 0.035, 0.3)
			await glance.finished
			await get_tree().create_timer(0.7).timeout
			actors["ミオ"].rotation = 0.0
			actors["レン"].rotation = 0.0
		"stop_bgm":
			_audio("stop_bgm")
			heading.text = "BLACK SPARROW"
		"battle_stance":
			backdrop.texture = load("res://assets/backgrounds/stage_08_hideout_boss_room.webp")
			heading.text = "基地最深部"
			actors["ミオ"].visible = false
			actors["レン"].visible = false
			badges["ミオ"].visible = false
			badges["レン"].visible = false
			actors["セイヤ"].position.x = 990
			actors["セイヤ"].visual_root.scale.x = -1.0
			actors["セイヤ"].character_visual_controller.play_animation(&"guard", true)
			await get_tree().create_timer(0.8).timeout
		"heroes_stance":
			for actor_name in ["アッキー", "ゴウ"]:
				actors[actor_name].character_visual_controller.play_animation(&"guard", true)
			await get_tree().create_timer(0.5).timeout
		"normal_end", "bad_end":
			# Keep the main theme playing through the end card until return.
			var fade := create_tween()
			fade.tween_property(veil, "color:a", 1.0, 0.8)
			await fade.finished
			end_card.text = "BAD END" if event_name == "bad_end" else "TO BE CONTINUED…"
			end_card.show()
			terminal_card = true
			print("[%s] END_CARD route=%s card=%s" % [ENDING_VERSION, route, end_card.text])
			_record_completion()
			next_button.text = "エンドロールへ"
			next_button.z_index = 12
			input_locked = false
			next_button.disabled = false
			_auto_begin_normal_credits()
			return
		"true_battle":
			finished = true
			end_card.text = "TRUE FINAL BATTLE\nBLACK SPARROW\nTRUE BOSS\nSEIYA"
			end_card.show()
			veil.color = Color(0.02, 0.0, 0.04, 0.72)
			await get_tree().create_timer(2.8).timeout
			get_tree().change_scene_to_file("res://scenes/TrueBattle.tscn")
			return
	input_locked = false
	next_button.disabled = false
	page_index += 1
	_show_page()

func _audio(method: String, argument: String = "") -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio == null: return
	if argument.is_empty(): audio.call(method)
	else: audio.call(method, argument)

func _record_completion() -> void:
	# Do not clear the Stage8 snapshot here: a crash before the credits
	# checkpoint is installed must still be able to resume the dialogue.
	var cfg := ConfigFile.new()
	if FileAccess.file_exists("user://story_progress.cfg"): cfg.load("user://story_progress.cfg")
	cfg.set_value("story", "normal_ending_unlocked", true)
	cfg.set_value("story", "last_stage8_route", route)
	cfg.save("user://story_progress.cfg")

func _build(living: Array) -> void:
	var letterbox := ColorRect.new()
	letterbox.color = Color("05070c")
	letterbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	letterbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(letterbox)
	safe_content = Control.new()
	safe_content.size = Vector2(1280, 720)
	add_child(safe_content)
	backdrop = TextureRect.new()
	backdrop.texture = load("res://assets/backgrounds/stage8_detention.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.size = Vector2(1280, 720)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_content.add_child(backdrop)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.015, 0.035, 0.22)
	shade.size = Vector2(1280, 720)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_content.add_child(shade)
	heading = _label("ブラックスパロウ基地・収容区画", Vector2(45, 24), Vector2(1190, 50), 26)
	heading.add_theme_color_override("font_color", Color("f8da99"))
	var slots := {"アッキー":210.0, "ミオ":380.0, "ゴウ":580.0, "レン":750.0, "セイヤ":1030.0}
	if route == "C": slots["セイヤ"] = 640.0
	for i in range(3):
		if not living.has(HERO_IDS[i]): continue
		var actor := ENDING_HERO.new()
		actor.name = "EndingHero%d" % i
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		safe_content.add_child(actor)
		actor.setup(HERO_ART_IDS[i])
		actor.position = Vector2(slots[HERO_NAMES[i]], 478)
		actor.character_visual_controller.play_animation(&"idle_prebattle", true)
		actor.animated_character_sprite.stop()
		actors[HERO_NAMES[i]] = actor
	for data in [["ミオ", HERO_IDS[0], "mio.png", CAST_SCALE.MIO_HEIGHT_RATIO], ["レン", HERO_IDS[1], "ren.png", CAST_SCALE.REN_HEIGHT_RATIO]]:
		if not living.has(data[1]): continue
		var texture: Texture2D = load("res://assets/characters/rescued/%s" % data[2])
		var sprite := Sprite2D.new()
		sprite.texture = texture
		# Compare with the rescued character's own hero in single-hero routes.
		var hero_name: String = "アッキー" if data[0] == "ミオ" else "ゴウ"
		# Gou's authored height difference remains; use Akky when both survive.
		var reference_actor: Node2D = actors.get("アッキー", actors[hero_name])
		CAST_SCALE.fit_rescued(sprite, CAST_SCALE.hero_height(reference_actor), float(data[3]))
		sprite.position = Vector2(slots[data[0]], 478)
		safe_content.add_child(sprite)
		actors[data[0]] = sprite
	for actor_name in actors:
		var badge := _label(actor_name, Vector2(slots[actor_name] - 70, 483), Vector2(140, 30), 20)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badges[actor_name] = badge
	var panel := Panel.new()
	panel.position = Vector2(35, 524)
	panel.size = Vector2(1210, 174)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.024, 0.045, 0.96)
	style.border_color = Color("b79657")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	safe_content.add_child(panel)
	speaker_label = _label("", Vector2(62, 536), Vector2(1020, 35), 26)
	speaker_label.add_theme_color_override("font_color", Color("f8da99"))
	story_label = _label("", Vector2(62, 579), Vector2(1150, 70), 30)
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_button = Button.new()
	next_button.position = Vector2(958, 650)
	next_button.size = Vector2(285, 45)
	next_button.focus_mode = Control.FOCUS_NONE
	next_button.add_theme_font_size_override("font_size", 20)
	next_button.pressed.connect(advance)
	safe_content.add_child(next_button)
	veil = ColorRect.new()
	veil.size = Vector2(1280, 720)
	veil.color = Color(0, 0, 0, 0)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.z_index = 10
	safe_content.add_child(veil)
	end_card = _label("", Vector2(80, 190), Vector2(1120, 300), 48)
	end_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_card.z_index = 11
	end_card.hide()

func _label(value: String, pos: Vector2, extent: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.position = pos
	label.size = extent
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color("080c18"))
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_content.add_child(label)
	return label

func _layout() -> void:
	var viewport_size := get_viewport_rect().size
	var factor := minf(viewport_size.x / 1280.0, viewport_size.y / 720.0)
	safe_content.scale = Vector2(factor, factor)
	safe_content.position = (viewport_size - Vector2(1280, 720) * factor) * 0.5
