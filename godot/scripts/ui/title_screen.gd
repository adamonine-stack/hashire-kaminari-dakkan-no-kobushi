extends Control

const BATTLE_SCENE := "res://scenes/Battle.tscn"

signal new_game_requested
signal scene_transition_started(scene_path: String)
signal scene_transition_finished(scene_path: String)

var is_scene_transitioning := false
var title_menu: VBoxContainer
var how_to_play_panel: PanelContainer
var options_panel: PanelContainer
var game_start_button: Button
var continue_button: Button
var how_to_play_button: Button
var options_button: Button
var exit_button: Button
var how_to_back_button: Button
var options_back_button: Button
var bgm_button: Button
var se_button: Button
var shake_button: Button
var hitstop_button: Button
var fullscreen_button: Button
var transition_overlay: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	_build_title_layout()
	_play_bgm("title")
	game_start_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if is_scene_transitioning:
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		if how_to_play_panel.visible:
			_hide_how_to_play()
			get_viewport().set_input_as_handled()
		elif options_panel.visible:
			_hide_options()
			get_viewport().set_input_as_handled()


func start_new_game() -> void:
	if is_scene_transitioning:
		return
	_play_ui_se("confirm")
	is_scene_transitioning = true
	new_game_requested.emit()
	scene_transition_started.emit(BATTLE_SCENE)
	print("[DEV041][GameFlow] TITLE -> SORTIE_ORDER")
	await _fade_out(0.25)
	get_tree().paused = false
	get_tree().change_scene_to_file(BATTLE_SCENE)


func _show_how_to_play() -> void:
	if is_scene_transitioning:
		return
	_play_ui_se("confirm")
	title_menu.visible = false
	options_panel.visible = false
	how_to_play_panel.visible = true
	how_to_back_button.grab_focus()


func _hide_how_to_play() -> void:
	_play_ui_se("cancel")
	how_to_play_panel.visible = false
	title_menu.visible = true
	how_to_play_button.grab_focus()


func _show_options() -> void:
	if is_scene_transitioning:
		return
	_play_ui_se("confirm")
	title_menu.visible = false
	how_to_play_panel.visible = false
	options_panel.visible = true
	_refresh_options_text()
	options_back_button.grab_focus()


func _hide_options() -> void:
	_play_ui_se("cancel")
	options_panel.visible = false
	title_menu.visible = true
	options_button.grab_focus()


func _exit_game() -> void:
	if is_scene_transitioning:
		return
	_play_ui_se("confirm")
	get_tree().quit()


func _build_title_layout() -> void:
	var background := ColorRect.new()
	background.color = Color(0.035, 0.045, 0.065, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var haze := ColorRect.new()
	haze.color = Color(0.18, 0.12, 0.04, 0.12)
	haze.set_anchors_preset(Control.PRESET_FULL_RECT)
	haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(haze)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 32.0
	center.offset_top = 24.0
	center.offset_right = -32.0
	center.offset_bottom = -24.0
	add_child(center)

	title_menu = VBoxContainer.new()
	title_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	title_menu.add_theme_constant_override("separation", 14)
	center.add_child(title_menu)

	var title_label := Label.new()
	title_label.text = "走れ雷 奪還の拳"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_menu.add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.text = "Hashire Ikazuchi: Dakkan no Ken"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 18)
	title_menu.add_child(subtitle_label)

	game_start_button = _make_menu_button("GAME START")
	game_start_button.pressed.connect(start_new_game)
	title_menu.add_child(game_start_button)

	continue_button = _make_menu_button("CONTINUE")
	continue_button.disabled = not _has_continue_data()
	continue_button.tooltip_text = "Save data is not available yet." if continue_button.disabled else ""
	continue_button.pressed.connect(start_new_game)
	title_menu.add_child(continue_button)

	how_to_play_button = _make_menu_button("HOW TO PLAY")
	how_to_play_button.pressed.connect(_show_how_to_play)
	title_menu.add_child(how_to_play_button)

	options_button = _make_menu_button("OPTIONS")
	options_button.pressed.connect(_show_options)
	title_menu.add_child(options_button)

	exit_button = _make_menu_button("QUIT")
	exit_button.pressed.connect(_exit_game)
	title_menu.add_child(exit_button)

	_build_how_to_play_panel(center)
	_build_options_panel(center)
	_build_transition_overlay()


func _build_how_to_play_panel(parent: Node) -> void:
	how_to_play_panel = PanelContainer.new()
	how_to_play_panel.visible = false
	how_to_play_panel.custom_minimum_size = Vector2(680.0, 470.0)
	parent.add_child(how_to_play_panel)

	var box := _make_panel_box(how_to_play_panel)
	var title_label := _make_label("HOW TO PLAY", 30)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)

	var body_label := _make_label(_input_help_text(), 17)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body_label)

	how_to_back_button = _make_menu_button("BACK")
	how_to_back_button.pressed.connect(_hide_how_to_play)
	box.add_child(how_to_back_button)


func _build_options_panel(parent: Node) -> void:
	options_panel = PanelContainer.new()
	options_panel.visible = false
	options_panel.custom_minimum_size = Vector2(620.0, 430.0)
	parent.add_child(options_panel)

	var box := _make_panel_box(options_panel)
	var title_label := _make_label("OPTIONS", 30)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)

	bgm_button = _make_menu_button("")
	bgm_button.pressed.connect(_cycle_bgm_volume)
	box.add_child(bgm_button)

	se_button = _make_menu_button("")
	se_button.pressed.connect(_cycle_se_volume)
	box.add_child(se_button)

	shake_button = _make_menu_button("")
	shake_button.pressed.connect(_cycle_screen_shake)
	box.add_child(shake_button)

	hitstop_button = _make_menu_button("")
	hitstop_button.pressed.connect(_cycle_hitstop)
	box.add_child(hitstop_button)

	fullscreen_button = _make_menu_button("")
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	box.add_child(fullscreen_button)

	options_back_button = _make_menu_button("BACK")
	options_back_button.pressed.connect(_hide_options)
	box.add_child(options_back_button)
	_refresh_options_text()


func _build_transition_overlay() -> void:
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color(0, 0, 0, 0)
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(transition_overlay)


func _cycle_bgm_volume() -> void:
	var settings := _settings()
	if settings == null:
		return
	var next := _next_volume(float(settings.get("bgm_volume")))
	settings.call("set_bgm_volume", next)
	_play_ui_se("cursor")
	_refresh_options_text()


func _cycle_se_volume() -> void:
	var settings := _settings()
	if settings == null:
		return
	var next := _next_volume(float(settings.get("se_volume")))
	settings.call("set_se_volume", next)
	_play_ui_se("cursor")
	_refresh_options_text()


func _cycle_screen_shake() -> void:
	var settings := _settings()
	if settings != null and settings.has_method("cycle_screen_shake_mode"):
		settings.call("cycle_screen_shake_mode")
	_play_ui_se("cursor")
	_refresh_options_text()


func _cycle_hitstop() -> void:
	var settings := _settings()
	if settings != null and settings.has_method("cycle_hitstop_mode"):
		settings.call("cycle_hitstop_mode")
	_play_ui_se("cursor")
	_refresh_options_text()


func _toggle_fullscreen() -> void:
	var settings := _settings()
	if settings != null and settings.has_method("toggle_fullscreen"):
		settings.call("toggle_fullscreen")
	_play_ui_se("cursor")
	_refresh_options_text()


func _refresh_options_text() -> void:
	var settings := _settings()
	if settings == null:
		return
	bgm_button.text = "BGM  %d%%" % int(round(float(settings.get("bgm_volume")) * 100.0))
	se_button.text = "SE   %d%%" % int(round(float(settings.get("se_volume")) * 100.0))
	shake_button.text = "SCREEN SHAKE  %s" % String(settings.get("screen_shake_mode"))
	hitstop_button.text = "HITSTOP  %s" % String(settings.get("hitstop_mode"))
	fullscreen_button.text = "FULLSCREEN  %s" % ("ON" if bool(settings.get("fullscreen_enabled")) else "OFF")


func _next_volume(value: float) -> float:
	var steps := [1.0, 0.75, 0.50, 0.25, 0.0]
	for step in steps:
		if value > step + 0.01:
			return step
	return 1.0


func _input_help_text() -> String:
	return "\n".join([
		"Move: %s / %s" % [_action_text("move_left"), _action_text("move_right")],
		"Jump: %s" % _action_text("jump"),
		"Crouch: %s" % _action_text("crouch"),
		"Punch: %s" % _action_text("attack"),
		"Kick: %s" % _action_text("kick"),
		"Guard: %s" % _action_text("guard"),
		"Special: %s" % _action_text("special"),
		"Throw: %s" % _action_text("throw_attack"),
		"Pause: %s" % _action_text("pause"),
		"",
		"Set the sortie order, defeat all 8 enemies, and clear the run.",
		"Defeated fighters cannot be selected again in the same run.",
	])


func _action_text(action_name: String) -> String:
	if not InputMap.has_action(action_name):
		return action_name
	var names: Array[String] = []
	for event in InputMap.action_get_events(action_name):
		var text := event.as_text()
		if text.length() > 0:
			names.append(text)
		if names.size() >= 2:
			break
	return " / ".join(names) if not names.is_empty() else action_name


func _fade_out(duration: float) -> void:
	if transition_overlay == null:
		return
	var tween := create_tween()
	tween.tween_property(transition_overlay, "color", Color(0, 0, 0, 1), duration)
	await tween.finished


func _make_panel_box(panel: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	return box


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _make_menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300.0, 48.0)
	button.focus_mode = Control.FOCUS_ALL
	button.focus_entered.connect(_play_ui_se.bind("cursor"))
	return button


func _has_continue_data() -> bool:
	return FileAccess.file_exists("user://save.cfg")


func _settings() -> Node:
	return get_node_or_null("/root/SettingsManager")


func _audio() -> Node:
	return get_node_or_null("/root/AudioManager")


func _play_bgm(bgm_id: String) -> void:
	var audio := _audio()
	if audio != null and audio.has_method("play_bgm"):
		audio.call("play_bgm", bgm_id)


func _play_ui_se(se_id: String) -> void:
	var audio := _audio()
	if audio != null and audio.has_method("play_ui_se"):
		audio.call("play_ui_se", se_id)
