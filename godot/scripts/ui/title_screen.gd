extends Control

const BATTLE_SCENE := "res://scenes/Battle.tscn"
const RUN_SAVE_PATH := "user://save.cfg"
const CONTINUE_REQUEST_META := &"st_action_continue_run"
const TITLE_MAIN := "走れイカズチ"
const TITLE_SUBTITLE := "奪還の拳"
const TITLE_ENGLISH := "HASHIRE IKAZUCHI"
const HERO_PORTRAITS := [
	"res://assets/characters/player01/selection_portrait.png",
	"res://assets/characters/player02/selection_portrait.png",
	"res://assets/characters/player03/selection_portrait.png",
]
const THREAT_PORTRAIT := "res://assets/characters/enemy08/portrait.png"

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
var orientation_overlay: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	_build_title_layout()
	if not get_viewport().size_changed.is_connected(_refresh_orientation_overlay):
		get_viewport().size_changed.connect(_refresh_orientation_overlay)
	_refresh_orientation_overlay()
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
	if _is_portrait_viewport():
		_refresh_orientation_overlay()
		return
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUN_SAVE_PATH))
	get_tree().root.set_meta(CONTINUE_REQUEST_META, false)
	await _enter_battle_scene(false)


func continue_game() -> void:
	if is_scene_transitioning or not _has_continue_data():
		return
	if _is_portrait_viewport():
		_refresh_orientation_overlay()
		return
	get_tree().root.set_meta(CONTINUE_REQUEST_META, true)
	await _enter_battle_scene(true)


func _enter_battle_scene(is_continue: bool) -> void:
	_play_ui_se("confirm")
	is_scene_transitioning = true
	if not is_continue:
		new_game_requested.emit()
	scene_transition_started.emit(BATTLE_SCENE)
	print("[DEV041][GameFlow] TITLE -> %s" % ("CONTINUE" if is_continue else "FIGHTER_SELECT"))
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
	_build_story_background()

	var readability_scrim := ColorRect.new()
	readability_scrim.color = Color(0.015, 0.02, 0.035, 0.36)
	readability_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	readability_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(readability_scrim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 32.0
	center.offset_top = 22.0
	center.offset_right = -32.0
	center.offset_bottom = -22.0
	add_child(center)

	var title_plate := PanelContainer.new()
	title_plate.custom_minimum_size = Vector2(470.0, 0.0)
	var plate_style := StyleBoxFlat.new()
	plate_style.bg_color = Color(0.02, 0.025, 0.045, 0.78)
	plate_style.border_color = Color(0.92, 0.63, 0.12, 0.62)
	plate_style.border_width_left = 2
	plate_style.border_width_top = 2
	plate_style.border_width_right = 2
	plate_style.border_width_bottom = 2
	plate_style.corner_radius_top_left = 14
	plate_style.corner_radius_top_right = 14
	plate_style.corner_radius_bottom_left = 14
	plate_style.corner_radius_bottom_right = 14
	plate_style.content_margin_left = 34.0
	plate_style.content_margin_top = 24.0
	plate_style.content_margin_right = 34.0
	plate_style.content_margin_bottom = 26.0
	title_plate.add_theme_stylebox_override("panel", plate_style)
	center.add_child(title_plate)

	title_menu = VBoxContainer.new()
	title_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	title_menu.add_theme_constant_override("separation", 10)
	title_plate.add_child(title_menu)

	var eyebrow := Label.new()
	eyebrow.text = TITLE_ENGLISH
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_color_override("font_color", Color(1.0, 0.76, 0.28, 0.92))
	title_menu.add_child(eyebrow)

	var title_label := Label.new()
	title_label.text = TITLE_MAIN
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 58)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.76, 1.0))
	title_label.add_theme_color_override("font_outline_color", Color(0.08, 0.055, 0.025, 0.96))
	title_label.add_theme_constant_override("outline_size", 9)
	title_menu.add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.text = TITLE_SUBTITLE
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 31)
	subtitle_label.add_theme_color_override("font_color", Color(1.0, 0.70, 0.18, 1.0))
	subtitle_label.add_theme_color_override("font_outline_color", Color(0.08, 0.045, 0.02, 0.95))
	subtitle_label.add_theme_constant_override("outline_size", 6)
	title_menu.add_child(subtitle_label)

	var divider := HSeparator.new()
	divider.custom_minimum_size = Vector2(320.0, 8.0)
	title_menu.add_child(divider)

	game_start_button = _make_menu_button("スタート")
	game_start_button.pressed.connect(start_new_game)
	_style_title_button(game_start_button, true)
	title_menu.add_child(game_start_button)

	continue_button = _make_menu_button("CONTINUE")
	continue_button.disabled = not _has_continue_data()
	continue_button.tooltip_text = "Save data is not available yet." if continue_button.disabled else ""
	continue_button.pressed.connect(continue_game)
	_style_title_button(continue_button, false)
	title_menu.add_child(continue_button)

	how_to_play_button = _make_menu_button("HOW TO PLAY")
	how_to_play_button.pressed.connect(_show_how_to_play)
	_style_title_button(how_to_play_button, false)
	title_menu.add_child(how_to_play_button)

	options_button = _make_menu_button("OPTIONS")
	options_button.pressed.connect(_show_options)
	_style_title_button(options_button, false)
	title_menu.add_child(options_button)

	exit_button = _make_menu_button("QUIT")
	exit_button.pressed.connect(_exit_game)
	_style_title_button(exit_button, false)
	title_menu.add_child(exit_button)

	var flow_hint := Label.new()
	flow_hint.text = "START  →  CHARACTER SELECT  →  BATTLE"
	flow_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flow_hint.add_theme_font_size_override("font_size", 12)
	flow_hint.add_theme_color_override("font_color", Color(0.82, 0.84, 0.9, 0.68))
	title_menu.add_child(flow_hint)

	_build_how_to_play_panel(center)
	_build_options_panel(center)
	_build_orientation_overlay()
	_build_transition_overlay()


func _build_story_background() -> void:
	var base := ColorRect.new()
	base.color = Color(0.018, 0.026, 0.05, 1.0)
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)

	var upper_haze := ColorRect.new()
	upper_haze.color = Color(0.08, 0.13, 0.22, 0.58)
	upper_haze.anchor_right = 1.0
	upper_haze.anchor_bottom = 0.52
	upper_haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(upper_haze)

	var horizon := ColorRect.new()
	horizon.color = Color(0.42, 0.14, 0.04, 0.34)
	horizon.anchor_top = 0.62
	horizon.anchor_right = 1.0
	horizon.anchor_bottom = 1.0
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(horizon)

	_build_city_silhouette()

	# A single lightning slash visually ties the title "Ikazuchi" to the rescue story.
	var lightning := Polygon2D.new()
	lightning.polygon = PackedVector2Array([
		Vector2(676.0, -20.0),
		Vector2(610.0, 214.0),
		Vector2(664.0, 197.0),
		Vector2(604.0, 382.0),
		Vector2(732.0, 158.0),
		Vector2(674.0, 176.0),
		Vector2(728.0, -20.0),
	])
	lightning.color = Color(1.0, 0.78, 0.22, 0.46)
	add_child(lightning)

	# The three playable heroes occupy the foreground; the stage-8 threat is kept
	# in shadow so the title hints at the campaign without revealing later beats.
	_add_story_portrait(HERO_PORTRAITS[1], -0.03, 0.25, 0.27, 1.05, Color(0.42, 0.49, 0.63, 0.58))
	_add_story_portrait(HERO_PORTRAITS[2], 0.17, 0.27, 0.46, 1.05, Color(0.48, 0.54, 0.68, 0.62))
	_add_story_portrait(HERO_PORTRAITS[0], 0.02, 0.15, 0.38, 1.05, Color(0.78, 0.82, 0.92, 0.76))
	_add_story_portrait(THREAT_PORTRAIT, 0.71, 0.08, 1.04, 1.02, Color(0.52, 0.18, 0.16, 0.52))

	var vignette_left := ColorRect.new()
	vignette_left.color = Color(0.0, 0.0, 0.0, 0.26)
	vignette_left.anchor_right = 0.18
	vignette_left.anchor_bottom = 1.0
	vignette_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette_left)

	var vignette_right := ColorRect.new()
	vignette_right.color = Color(0.0, 0.0, 0.0, 0.32)
	vignette_right.anchor_left = 0.82
	vignette_right.anchor_right = 1.0
	vignette_right.anchor_bottom = 1.0
	vignette_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette_right)


func _build_city_silhouette() -> void:
	var skyline := Control.new()
	skyline.set_anchors_preset(Control.PRESET_FULL_RECT)
	skyline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(skyline)

	var building_data := [
		[0.00, 0.54, 0.08, 1.00],
		[0.07, 0.47, 0.15, 1.00],
		[0.14, 0.60, 0.23, 1.00],
		[0.22, 0.50, 0.30, 1.00],
		[0.29, 0.64, 0.39, 1.00],
		[0.38, 0.46, 0.47, 1.00],
		[0.46, 0.58, 0.55, 1.00],
		[0.54, 0.42, 0.63, 1.00],
		[0.62, 0.61, 0.72, 1.00],
		[0.71, 0.49, 0.80, 1.00],
		[0.79, 0.57, 0.89, 1.00],
		[0.88, 0.44, 1.00, 1.00],
	]
	for data in building_data:
		var building := ColorRect.new()
		building.color = Color(0.015, 0.02, 0.032, 0.86)
		building.anchor_left = data[0]
		building.anchor_top = data[1]
		building.anchor_right = data[2]
		building.anchor_bottom = data[3]
		building.mouse_filter = Control.MOUSE_FILTER_IGNORE
		skyline.add_child(building)


func _add_story_portrait(path: String, left: float, top: float, right: float, bottom: float, tint: Color) -> void:
	var texture := load(path) as Texture2D
	if texture == null:
		return
	var portrait := TextureRect.new()
	portrait.texture = texture
	portrait.anchor_left = left
	portrait.anchor_top = top
	portrait.anchor_right = right
	portrait.anchor_bottom = bottom
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.modulate = tint
	add_child(portrait)


func _style_title_button(button: Button, primary: bool) -> void:
	button.custom_minimum_size = Vector2(320.0, 58.0 if primary else 44.0)
	button.add_theme_font_size_override("font_size", 22 if primary else 16)
	button.add_theme_color_override("font_color", Color(0.08, 0.06, 0.025, 1.0) if primary else Color(0.93, 0.94, 0.98, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.04, 0.03, 0.015, 1.0) if primary else Color(1.0, 0.82, 0.36, 1.0))
	button.add_theme_stylebox_override(
		"normal",
		_title_button_box(
			Color(0.96, 0.67, 0.14, 0.96) if primary else Color(0.035, 0.045, 0.075, 0.86),
			Color(1.0, 0.88, 0.48, 0.98) if primary else Color(0.46, 0.50, 0.62, 0.72)
		)
	)
	button.add_theme_stylebox_override(
		"hover",
		_title_button_box(
			Color(1.0, 0.79, 0.26, 1.0) if primary else Color(0.09, 0.075, 0.055, 0.96),
			Color(1.0, 0.94, 0.68, 1.0) if primary else Color(1.0, 0.72, 0.24, 0.92)
		)
	)
	button.add_theme_stylebox_override(
		"focus",
		_title_button_box(Color(0.99, 0.75, 0.22, 1.0), Color(1.0, 0.96, 0.78, 1.0))
	)


func _title_button_box(background: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.border_width_left = 2
	box.border_width_top = 2
	box.border_width_right = 2
	box.border_width_bottom = 2
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	box.corner_radius_bottom_left = 8
	box.corner_radius_bottom_right = 8
	box.content_margin_left = 14.0
	box.content_margin_top = 8.0
	box.content_margin_right = 14.0
	box.content_margin_bottom = 8.0
	return box


func _build_orientation_overlay() -> void:
	orientation_overlay = PanelContainer.new()
	orientation_overlay.visible = false
	orientation_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	orientation_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(orientation_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	orientation_overlay.add_child(center)

	var label := Label.new()
	label.text = "Rotate device to landscape"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	center.add_child(label)


func _refresh_orientation_overlay() -> void:
	if orientation_overlay == null:
		return
	var is_portrait := _is_portrait_viewport()
	orientation_overlay.visible = is_portrait
	if title_menu != null:
		title_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_portrait else Control.MOUSE_FILTER_PASS


func _is_portrait_viewport() -> bool:
	var viewport_size := get_viewport_rect().size
	return viewport_size.y > viewport_size.x


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
		"Start with all 3 fighters. Choose one fighter before each stage.",
		"The 2 fighters who sit out recover 20% of their maximum HP.",
		"The fighter who battles does not recover after winning.",
		"Stage 8: Leon Crow. Stage 9: secret boss.",
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
