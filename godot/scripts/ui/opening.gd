extends Control

const BATTLE_SCENE := "res://scenes/Battle.tscn"
const PORTRAIT_PATHS := [
	"res://assets/characters/player01/selection_portrait.png",
	"res://assets/characters/player02/selection_portrait.png",
	"res://assets/characters/player03/selection_portrait.png",
]
const SPEAKER_INDEX := {"アッキー": 0, "ごう": 1, "せいや": 2}
const PAGES: Array[Dictionary] = [
	{"speaker":"アッキー", "text":"来てくれたか。二人とも、話がある。"},
	{"speaker":"ごう", "text":"……俺もだ。"},
	{"speaker":"アッキー", "text":"どうした？"},
	{"speaker":"ごう", "text":"弟がさらわれた。"},
	{"speaker":"アッキー", "text":"何だって……？"},
	{"speaker":"せいや", "text":"待て。俺も同じだ。"},
	{"speaker":"ごう", "text":"同じ？"},
	{"speaker":"せいや", "text":"妹がさらわれた。突然、連絡が取れなくなった。"},
	{"speaker":"アッキー", "text":"……俺の恋人もだ。"},
	{"speaker":"せいや", "text":"三人同時か……。偶然じゃないな。"},
	{"speaker":"アッキー", "text":"ああ。調べて分かったことが一つある。"},
	{"speaker":"アッキー", "text":"ブラックスパロウだ。", "mark":true},
	{"speaker":"ごう", "text":"ブラックスパロウ……。"},
	{"speaker":"せいや", "text":"やっぱり奴らか。"},
	{"speaker":"ごう", "text":"だったら、すぐアジトへ乗り込もうぜ。"},
	{"speaker":"せいや", "text":"待て。肝心のアジトがどこにあるのか分からない。"},
	{"speaker":"ごう", "text":"じゃあ、どうする？"},
	{"speaker":"アッキー", "text":"まず街だ。"},
	{"speaker":"アッキー", "text":"ブラックスパロウの奴を見つけて、アジトの情報を探る。"},
	{"speaker":"せいや", "text":"そこから奴らを追うってことか。"},
	{"speaker":"アッキー", "text":"ああ。"},
	{"speaker":"ごう", "text":"決まりだな。"},
	{"speaker":"アッキー", "text":"ブラックスパロウを壊す。"},
	{"speaker":"アッキー", "text":"そして――全員、必ず連れ戻す。"},
	{"speaker":"ごう", "text":"ああ！"},
	{"speaker":"せいや", "text":"行こう。"},
]

var page_index := 0
var safe_content: Control
var speaker_label: Label
var story_label: Label
var progress_label: Label
var next_button: Button
var skip_button: Button
var mark_label: Label
var character_portraits: Array[TextureRect] = []
var is_transitioning := false


func _ready() -> void:
	_build_backdrop()
	_build_ui()
	_update_safe_content_rect()
	get_viewport().size_changed.connect(_update_safe_content_rect)
	_show_page()
	print("[GameFlow] OPENING ready pages=%d" % PAGES.size())


func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return
	var advance_requested := event.is_action_pressed("ui_accept")
	if event is InputEventScreenTouch:
		advance_requested = advance_requested or (event as InputEventScreenTouch).pressed
	if advance_requested:
		get_viewport().set_input_as_handled()
		advance()


func advance() -> void:
	if is_transitioning:
		return
	page_index += 1
	if page_index >= PAGES.size():
		_enter_battle()
	else:
		_show_page()


func skip() -> void:
	_enter_battle()


func _enter_battle() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	print("[GameFlow] OPENING -> FIGHTER_SELECT")
	var error := get_tree().change_scene_to_file(BATTLE_SCENE)
	if error != OK:
		is_transitioning = false
		push_error("[GameFlow] Could not open %s (error %d)." % [BATTLE_SCENE, error])


func _show_page() -> void:
	var page: Dictionary = PAGES[page_index]
	speaker_label.text = String(page["speaker"])
	story_label.text = String(page["text"])
	progress_label.text = "%02d / %02d" % [page_index + 1, PAGES.size()]
	next_button.text = "次へ" if page_index < PAGES.size() - 1 else "ゲームを始める"
	mark_label.visible = bool(page.get("mark", false))
	var active_portrait := int(SPEAKER_INDEX.get(speaker_label.text, -1))
	for index in range(character_portraits.size()):
		character_portraits[index].modulate = Color.WHITE if active_portrait == index else Color(0.50, 0.56, 0.70, 1.0)


func _build_backdrop() -> void:
	var background := ColorRect.new()
	background.color = Color("17213a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var horizon := ColorRect.new()
	horizon.color = Color("252c43")
	horizon.anchor_right = 1.0
	horizon.anchor_bottom = 1.0
	horizon.anchor_top = 0.43
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(horizon)

	var moon := Panel.new()
	var moon_style := StyleBoxFlat.new()
	moon_style.bg_color = Color(0.95, 0.77, 0.48, 0.78)
	moon_style.set_corner_radius_all(32)
	moon.add_theme_stylebox_override("panel", moon_style)
	moon.anchor_left = 0.78
	moon.anchor_top = 0.12
	moon.anchor_right = 0.82
	moon.anchor_bottom = 0.19
	moon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(moon)

	var skyline := Control.new()
	skyline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	skyline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(skyline)
	var buildings := [
		[0.00, 0.55, 0.09, 1.00], [0.08, 0.47, 0.17, 1.00],
		[0.15, 0.60, 0.24, 1.00], [0.22, 0.50, 0.32, 1.00],
		[0.30, 0.62, 0.40, 1.00], [0.39, 0.48, 0.49, 1.00],
		[0.47, 0.58, 0.57, 1.00], [0.55, 0.43, 0.65, 1.00],
		[0.63, 0.61, 0.74, 1.00], [0.72, 0.50, 0.82, 1.00],
		[0.80, 0.56, 0.90, 1.00], [0.88, 0.45, 1.00, 1.00],
	]
	for data in buildings:
		var building := ColorRect.new()
		building.color = Color("101522")
		building.anchor_left = data[0]
		building.anchor_top = data[1]
		building.anchor_right = data[2]
		building.anchor_bottom = data[3]
		building.mouse_filter = Control.MOUSE_FILTER_IGNORE
		skyline.add_child(building)


func _build_ui() -> void:
	safe_content = Control.new()
	safe_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(safe_content)

	var heading := Label.new()
	heading.text = "OPENING"
	heading.set_anchors_preset(Control.PRESET_TOP_WIDE)
	heading.anchor_bottom = 0.10
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 26)
	heading.add_theme_color_override("font_color", Color("f2d08a"))
	safe_content.add_child(heading)

	for index in range(PORTRAIT_PATHS.size()):
		var portrait := TextureRect.new()
		portrait.texture = load(PORTRAIT_PATHS[index]) as Texture2D
		portrait.anchor_left = 0.15 + index * 0.26
		portrait.anchor_top = 0.105
		portrait.anchor_right = 0.35 + index * 0.26
		portrait.anchor_bottom = 0.61
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		safe_content.add_child(portrait)
		character_portraits.append(portrait)

	mark_label = Label.new()
	mark_label.text = "BLACK SPARROW"
	mark_label.anchor_left = 0.30
	mark_label.anchor_right = 0.70
	mark_label.anchor_top = 0.34
	mark_label.anchor_bottom = 0.46
	mark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark_label.add_theme_font_size_override("font_size", 38)
	mark_label.add_theme_color_override("font_color", Color("e75858"))
	mark_label.add_theme_color_override("font_outline_color", Color("100914"))
	mark_label.add_theme_constant_override("outline_size", 5)
	mark_label.visible = false
	safe_content.add_child(mark_label)

	var dialogue_panel := PanelContainer.new()
	dialogue_panel.anchor_left = 0.035
	dialogue_panel.anchor_top = 0.635
	dialogue_panel.anchor_right = 0.965
	dialogue_panel.anchor_bottom = 0.985
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.045, 0.075, 0.96)
	panel_style.border_color = Color("bc9451")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	safe_content.add_child(dialogue_panel)

	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 18)
	margins.add_theme_constant_override("margin_top", 10)
	margins.add_theme_constant_override("margin_right", 18)
	margins.add_theme_constant_override("margin_bottom", 10)
	dialogue_panel.add_child(margins)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	margins.add_child(content)

	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 23)
	speaker_label.add_theme_color_override("font_color", Color("f2d08a"))
	content.add_child(speaker_label)

	story_label = Label.new()
	story_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	story_label.add_theme_font_size_override("font_size", 24)
	content.add_child(story_label)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	content.add_child(footer)

	progress_label = Label.new()
	progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_label.add_theme_color_override("font_color", Color("c5cad6"))
	footer.add_child(progress_label)

	skip_button = Button.new()
	skip_button.text = "スキップ"
	skip_button.custom_minimum_size = Vector2(145, 48)
	skip_button.pressed.connect(skip)
	footer.add_child(skip_button)

	next_button = Button.new()
	next_button.custom_minimum_size = Vector2(250, 48)
	next_button.pressed.connect(advance)
	footer.add_child(next_button)


func _update_safe_content_rect() -> void:
	if safe_content == null:
		return
	var viewport_size := get_viewport_rect().size
	# Keep all text and touch controls clear of camera cutouts and rounded edges.
	var horizontal_margin := maxf(72.0, viewport_size.x * 0.075)
	var top_margin := maxf(80.0, viewport_size.y * 0.12)
	var bottom_margin := maxf(46.0, viewport_size.y * 0.07)
	safe_content.offset_left = horizontal_margin
	safe_content.offset_top = top_margin
	safe_content.offset_right = -horizontal_margin
	safe_content.offset_bottom = -bottom_margin
