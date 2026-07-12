extends Control

const BATTLE_SCENE := "res://scenes/Battle.tscn"

signal new_game_requested
signal scene_transition_started(scene_path: String)
signal scene_transition_finished(scene_path: String)

var is_scene_transitioning := false
var title_menu: VBoxContainer
var how_to_play_panel: PanelContainer
var game_start_button: Button
var how_to_play_button: Button
var exit_button: Button
var how_to_back_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	_build_title_layout()
	game_start_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if is_scene_transitioning:
		get_viewport().set_input_as_handled()
		return
	if how_to_play_panel.visible and event.is_action_pressed("ui_cancel"):
		_hide_how_to_play()
		get_viewport().set_input_as_handled()


func start_new_game() -> void:
	if is_scene_transitioning:
		return
	is_scene_transitioning = true
	new_game_requested.emit()
	scene_transition_started.emit(BATTLE_SCENE)
	print("[DEV041][GameFlow] TITLE -> SORTIE_ORDER")
	get_tree().paused = false
	get_tree().change_scene_to_file(BATTLE_SCENE)


func _show_how_to_play() -> void:
	if is_scene_transitioning:
		return
	title_menu.visible = false
	how_to_play_panel.visible = true
	how_to_back_button.grab_focus()


func _hide_how_to_play() -> void:
	how_to_play_panel.visible = false
	title_menu.visible = true
	game_start_button.grab_focus()


func _exit_game() -> void:
	if is_scene_transitioning:
		return
	get_tree().quit()


func _build_title_layout() -> void:
	var background := ColorRect.new()
	background.color = Color(0.035, 0.045, 0.065, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 32.0
	center.offset_top = 24.0
	center.offset_right = -32.0
	center.offset_bottom = -24.0
	add_child(center)

	title_menu = VBoxContainer.new()
	title_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	title_menu.add_theme_constant_override("separation", 16)
	center.add_child(title_menu)

	var title_label := Label.new()
	title_label.text = "ST_action"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 52)
	title_menu.add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.text = "Hashire Ikazuchi: Dakkan no Ken"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 18)
	title_menu.add_child(subtitle_label)

	game_start_button = _make_menu_button("GAME START")
	game_start_button.pressed.connect(start_new_game)
	title_menu.add_child(game_start_button)

	how_to_play_button = _make_menu_button("HOW TO PLAY")
	how_to_play_button.pressed.connect(_show_how_to_play)
	title_menu.add_child(how_to_play_button)

	exit_button = _make_menu_button("EXIT")
	exit_button.pressed.connect(_exit_game)
	title_menu.add_child(exit_button)

	_build_how_to_play_panel(center)


func _build_how_to_play_panel(parent: Node) -> void:
	how_to_play_panel = PanelContainer.new()
	how_to_play_panel.visible = false
	how_to_play_panel.custom_minimum_size = Vector2(620.0, 420.0)
	parent.add_child(how_to_play_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	how_to_play_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title_label := Label.new()
	title_label.text = "HOW TO PLAY"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 30)
	box.add_child(title_label)

	var body_label := Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.text = "\n".join([
		"Move: Arrow Keys / A D",
		"Jump: Up / W / Space",
		"Crouch: Down / S",
		"Punch: J / Z",
		"Kick: K",
		"Guard: L / Shift / Pad L1",
		"Throw: E / Pad L2",
		"Pause: Esc / Pad Start",
		"",
		"Set the sortie order, defeat all 8 enemies, and clear the run.",
	])
	box.add_child(body_label)

	how_to_back_button = _make_menu_button("BACK")
	how_to_back_button.pressed.connect(_hide_how_to_play)
	box.add_child(how_to_back_button)


func _make_menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(280.0, 48.0)
	button.focus_mode = Control.FOCUS_ALL
	return button
