extends Control

const BATTLE_SCENE := "res://scenes/Battle.tscn"
const PAGES: Array[Dictionary] = [
	{"speaker": "", "text": "夜の街に、黒い羽根の紋章を掲げた一団が現れた。"},
	{"speaker": "", "text": "ブラックスパロウは、仲間たちの大切な人を連れ去った。"},
	{"speaker": "アッキー", "text": "必ず見つけ出して、みんなを連れ戻す。"},
	{"speaker": "ごう", "text": "ブラックスパロウの拠点へ向かうぞ。"},
	{"speaker": "せいや", "text": "待っている人たちを、必ず助けよう。"},
]

var page_index := 0
var speaker_label: Label
var story_label: Label
var progress_label: Label
var next_button: Button
var is_transitioning := false


func _ready() -> void:
	_build_ui()
	_show_page()
	print("[GameFlow] OPENING ready pages=%d" % PAGES.size())


func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return
	var advance_requested := event.is_action_pressed("ui_accept")
	if event is InputEventScreenTouch:
		advance_requested = advance_requested or (event as InputEventScreenTouch).pressed
	if advance_requested:
		advance()
		get_viewport().set_input_as_handled()


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
	var page := PAGES[page_index]
	speaker_label.text = String(page["speaker"])
	speaker_label.visible = not speaker_label.text.is_empty()
	story_label.text = String(page["text"])
	progress_label.text = "%d / %d" % [page_index + 1, PAGES.size()]
	next_button.text = "次へ" if page_index < PAGES.size() - 1 else "ゲームを始める"


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("10121d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.02, 0.035, 0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var layout := VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 40.0
	layout.offset_top = 32.0
	layout.offset_right = -40.0
	layout.offset_bottom = -28.0
	layout.add_theme_constant_override("separation", 12)
	add_child(layout)

	var heading := Label.new()
	heading.text = "OPENING"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 28)
	layout.add_child(heading)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)

	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 210.0
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(panel)

	var text_box := VBoxContainer.new()
	text_box.add_theme_constant_override("separation", 12)
	panel.add_child(text_box)

	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 24)
	text_box.add_child(speaker_label)

	story_label = Label.new()
	story_label.custom_minimum_size.y = 112.0
	story_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	story_label.add_theme_font_size_override("font_size", 25)
	text_box.add_child(story_label)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	layout.add_child(footer)

	progress_label = Label.new()
	progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(progress_label)

	var skip_button := Button.new()
	skip_button.text = "スキップ"
	skip_button.custom_minimum_size = Vector2(150.0, 58.0)
	skip_button.pressed.connect(skip)
	footer.add_child(skip_button)

	next_button = Button.new()
	next_button.custom_minimum_size = Vector2(270.0, 58.0)
	next_button.pressed.connect(advance)
	footer.add_child(next_button)
