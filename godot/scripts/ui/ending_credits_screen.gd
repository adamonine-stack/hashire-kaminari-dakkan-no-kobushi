extends Control

# Intentionally keeps ZERO background plates, animation atlases or cast textures
# alive while rolling: safe even when a mobile browser reloads at the checkpoint.
const CHECKPOINT := preload("res://scripts/ui/ending_credits_checkpoint.gd")
const CREDITS := preload("res://scripts/ui/ending_credits.gd")
const TITLE_SCENE := "res://scenes/Title.tscn"

var credits_started := false
var credits_complete := false
var returning_to_title := false
var ending_route := ""
var timing_scale := 1.0 # QA-only override.
var background: ColorRect
var header: Label
var roll: Label
var hint: Label
var tween: Tween

func _ready() -> void:
	get_tree().paused = false
	get_tree().root.set_meta(&"st_action_continue_run", false)
	ending_route = CHECKPOINT.load_route()
	if ending_route.is_empty():
		# A corrupt or stale save must never strand the player on an empty screen.
		get_tree().change_scene_to_file(TITLE_SCENE)
		return
	# The shortened speed is available only to Godot test runs, never a
	# release Web player.
	if OS.has_feature("debug") and get_tree().root.has_meta(&"ending_credits_qa_scale"):
		timing_scale = float(get_tree().root.get_meta(&"ending_credits_qa_scale"))
		get_tree().root.remove_meta(&"ending_credits_qa_scale")
	_build()
	credits_started = true
	var audio := get_node("/root/AudioManager")
	# CONTINUE can arrive from Title, whose theme loops. Switch that loop
	# to non-looping credits playback, even when the audio ID is unchanged.
	if not audio.is_music_playing(audio.THEME_ID) or audio.theme_repeat:
		audio.play_ending_theme("true_ending" if ending_route == CHECKPOINT.TRUE else "final_boss")
	print("[ENDING_CREDITS] started route=%s" % ending_route)
	_play_roll()

func _build() -> void:
	background = ColorRect.new()
	background.color = Color("05070c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var scaler := Control.new()
	scaler.name = "CreditsContent"
	scaler.size = Vector2(1280, 720)
	add_child(scaler)
	var viewport_size := get_viewport_rect().size
	var factor := minf(viewport_size.x / 1280.0, viewport_size.y / 720.0)
	scaler.scale = Vector2.ONE * factor
	scaler.position = (viewport_size - Vector2(1280, 720) * factor) * 0.5
	get_viewport().size_changed.connect(func():
		var view := get_viewport_rect().size
		var scale_value := minf(view.x / 1280.0, view.y / 720.0)
		scaler.scale = Vector2.ONE * scale_value
		scaler.position = (view - Vector2(1280, 720) * scale_value) * 0.5
	)
	header = Label.new()
	header.text = _ending_title()
	header.position = Vector2(160, 45)
	header.size = Vector2(960, 75)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 32)
	header.add_theme_color_override("font_color", Color("f8da99"))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scaler.add_child(header)
	roll = CREDITS.make_roll(scaler)
	hint = Label.new()
	hint.text = "画面をタップするとタイトルへ戻ります"
	hint.position = Vector2(160, 649)
	hint.size = Vector2(960, 52)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color("adb8ca"))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scaler.add_child(hint)

func _ending_title() -> String:
	if ending_route == CHECKPOINT.TRUE: return "TRUE ENDING"
	if ending_route == CHECKPOINT.BAD: return "BAD END"
	return "TO BE CONTINUED…"

func _play_roll() -> void:
	tween = create_tween()
	tween.tween_property(roll, "position:y", CREDITS.offscreen_y(roll), CREDITS.NORMAL_SCROLL_SECONDS * timing_scale)
	await tween.finished
	if returning_to_title or not is_inside_tree(): return
	roll.hide()
	credits_complete = true
	header.position.y = 280
	header.add_theme_font_size_override("font_size", 52)
	hint.position.y = 390
	print("[ENDING_CREDITS] complete route=%s" % ending_route)

func _input(event: InputEvent) -> void:
	if not credits_started or returning_to_title: return
	var tapped := false
	if event is InputEventScreenTouch:
		tapped = (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		tapped = mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed
	if tapped or (event.is_action_pressed("ui_accept") and not event.is_echo()):
		get_viewport().set_input_as_handled()
		_return_to_title()

func _return_to_title() -> void:
	if returning_to_title: return
	returning_to_title = true
	# Clear only on explicit user exit, NEVER during cinematic/credits setup.
	CHECKPOINT.clear()
	await get_node("/root/AudioManager").fade_out()
	get_tree().change_scene_to_file(TITLE_SCENE)
