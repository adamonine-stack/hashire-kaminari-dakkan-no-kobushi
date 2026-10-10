extends Control

enum TouchControlsMode {
	AUTO,
	ON,
	OFF,
}

const DIRECTION_BUTTONS := {
	"UpLeftButton": {
		"text": "↖",
		"hold": ["move_left", "jump"],
		"tap": [],
	},
	"UpButton": {
		"text": "↑",
		"hold": ["jump"],
		"tap": [],
	},
	"UpRightButton": {
		"text": "↗",
		"hold": ["move_right", "jump"],
		"tap": [],
	},
	"MoveLeftButton": {
		"text": "←",
		"hold": ["move_left"],
		"tap": [],
	},
	"NeutralButton": {
		"text": "•",
		"hold": [],
		"tap": [],
	},
	"MoveRightButton": {
		"text": "→",
		"hold": ["move_right"],
		"tap": [],
	},
	"DownLeftButton": {
		"text": "↙",
		"hold": ["move_left", "down"],
		"tap": [],
	},
	"CrouchButton": {
		"text": "↓",
		"hold": ["down"],
		"tap": [],
	},
	"DownRightButton": {
		"text": "↘",
		"hold": ["move_right", "down"],
		"tap": [],
	},
}

const TAP_BUTTON_ACTIONS := {
	"PunchButton": "attack",
	"KickButton": "kick",
	"ThrowButton": "throw_attack",
	"SpecialButton": "special_attack",
	"PauseButton": "pause",
}

const HOLD_BUTTON_ACTIONS := {
	"GuardButton": "guard",
}

@export var touch_controls_mode: TouchControlsMode = TouchControlsMode.ON
@export var button_opacity := 0.72
@export var pressed_opacity := 0.96
@export var disabled_opacity := 0.25
@export var base_button_size := Vector2(88.0, 88.0)
@export var safe_margin := Vector2(28.0, 24.0)
@export var show_rotate_hint := true

var _held_action_counts: Dictionary = {}
var _pressed_buttons: Dictionary = {}
var _touch_buttons_by_index: Dictionary = {}
var _direct_touch_active := false
var _tap_queues: Dictionary = {}
var _tap_running: Dictionary = {}
var _tap_generation := 0
var _special_cooldown_remaining := 0.0
var _special_cooldown_total := 0.0
var _combat_buttons_paused := false

@onready var left_controls := $LeftControls as Control
@onready var right_controls := $RightControls as Control
@onready var pause_button := $PauseButton as Button
@onready var special_button := $RightControls/SpecialButton as Button
@onready var special_cooldown_label := $RightControls/SpecialButton/SpecialCooldownLabel as Label
@onready var rotate_hint := $RotateHint as Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modulate.a = 1.0
	_ensure_runtime_buttons()
	_connect_touch_buttons()
	_apply_touch_visibility()
	_layout_controls()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	visibility_changed.connect(_on_visibility_changed)


func _process(delta: float) -> void:
	_update_special_cooldown(delta)


# Use each touch identifier independently instead of relying on emulated mouse
# clicks, which cannot reliably hold a D-pad key while tapping attack buttons.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if not _direct_touch_active:
			_direct_touch_active = true
			for button in find_children("*", "Button", true, false):
				button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_set_touch_button(touch.index, _button_at_touch_position(touch.position))
		else:
			_set_touch_button(touch.index, null)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _direct_touch_active:
		var drag := event as InputEventScreenDrag
		if _touch_buttons_by_index.has(drag.index):
			_set_touch_button(drag.index, _button_at_touch_position(drag.position))
			get_viewport().set_input_as_handled()


func _button_at_touch_position(screen_position: Vector2) -> Button:
	for item in find_children("*", "Button", true, false):
		var button := item as Button
		if button != null and button.is_visible_in_tree() and not button.disabled and button.get_global_rect().has_point(screen_position):
			return button
	return null


func _set_touch_button(index: int, next_button: Button) -> void:
	var current: Button = _touch_buttons_by_index.get(index) as Button
	if current == next_button:
		return
	if current != null and is_instance_valid(current):
		current.button_up.emit()
	_touch_buttons_by_index.erase(index)
	if next_button != null:
		_touch_buttons_by_index[index] = next_button
		next_button.button_down.emit()


func _exit_tree() -> void:
	release_all_touch_inputs()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		release_all_touch_inputs()


func release_all_touch_inputs() -> void:
	# Invalidate async tap pulses so an old timer cannot release a fresh input.
	_tap_generation += 1
	_tap_queues.clear()
	_tap_running.clear()
	_touch_buttons_by_index.clear()
	# Tap actions can still be waiting for their deferred physics/frame release.
	for action_name in TAP_BUTTON_ACTIONS.values():
		Input.action_release(String(action_name))
	Input.action_release("jump")
	for action_name in _held_action_counts.keys():
		Input.action_release(action_name)
	_held_action_counts.clear()
	_pressed_buttons.clear()
	_set_all_button_pressed_visuals(false)


func set_paused_input_mode(is_paused: bool) -> void:
	_combat_buttons_paused = is_paused
	release_all_touch_inputs()
	for button in find_children("*", "Button", true, false):
		if button is Button and button != pause_button:
			button.disabled = is_paused
			button.modulate.a = disabled_opacity if is_paused else button_opacity
	if pause_button != null:
		pause_button.disabled = false
		pause_button.modulate.a = button_opacity
	_update_special_button_state()


func show_touch_controls() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	modulate.a = 1.0
	_apply_touch_visibility()
	_layout_controls()


func hide_touch_controls() -> void:
	release_all_touch_inputs()
	visible = false


func refresh_layout() -> void:
	_layout_controls()


func set_input_enabled(is_enabled: bool) -> void:
	set_paused_input_mode(not is_enabled)


func set_touch_controls_mode(mode: TouchControlsMode) -> void:
	touch_controls_mode = mode
	_apply_touch_visibility()


func set_special_cooldown(remaining: float, total: float) -> void:
	_special_cooldown_remaining = maxf(remaining, 0.0)
	_special_cooldown_total = maxf(total, 0.0)
	_update_special_button_state()


func _connect_touch_buttons() -> void:
	for button_name in DIRECTION_BUTTONS:
		var button := get_node_or_null("LeftControls/%s" % button_name) as Button
		if button == null:
			continue
		var data: Dictionary = DIRECTION_BUTTONS[button_name]
		_prepare_button(button)
		button.text = String(data.get("text", ""))
		button.button_down.connect(_on_direction_button_down.bind(button, data))
		button.button_up.connect(_on_direction_button_up.bind(button, data))

	for button_name in TAP_BUTTON_ACTIONS:
		var button := get_node_or_null("LeftControls/%s" % button_name) as Button
		if button == null:
			button = get_node_or_null("RightControls/%s" % button_name) as Button
		if button == null and button_name == "PauseButton":
			button = pause_button
		if button == null:
			continue
		var action_name := TAP_BUTTON_ACTIONS[button_name] as String
		_prepare_button(button)
		match button_name:
			"PunchButton":
				button.text = "P"
			"KickButton":
				button.text = "K"
			"ThrowButton":
				button.text = "T"
			"SpecialButton":
				button.text = "S"
			"PauseButton":
				button.text = "II"
		button.button_down.connect(_on_tap_button_down.bind(button, action_name))

	for button_name in HOLD_BUTTON_ACTIONS:
		var button := get_node_or_null("LeftControls/%s" % button_name) as Button
		if button == null:
			button = get_node_or_null("RightControls/%s" % button_name) as Button
		if button == null:
			continue
		var action_name := HOLD_BUTTON_ACTIONS[button_name] as String
		_prepare_button(button)
		if button_name == "GuardButton":
			button.text = "G"
		button.visible = true
		button.disabled = false
		button.button_down.connect(_on_hold_button_down.bind(button, action_name))
		button.button_up.connect(_on_hold_button_up.bind(button, action_name))
	var legacy_jump_button := get_node_or_null("RightControls/JumpButton") as Button
	if legacy_jump_button != null:
		legacy_jump_button.visible = false
		legacy_jump_button.disabled = true


func _prepare_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate.a = button_opacity
	button.custom_minimum_size = base_button_size
	_apply_touch_button_style(button)


func _apply_touch_button_style(button: Button) -> void:
	var accent := _touch_button_accent(button.name)
	button.add_theme_font_size_override("font_size", 28 if button.name != "PauseButton" else 20)
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.88))
	button.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.92, 0.62, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.56, 0.58, 0.63, 0.86))
	button.add_theme_stylebox_override("normal", _touch_button_box(Color(0.035, 0.045, 0.065, 0.94), accent, 5))
	button.add_theme_stylebox_override("hover", _touch_button_box(Color(0.075, 0.078, 0.085, 0.98), accent.lightened(0.18), 5))
	button.add_theme_stylebox_override("pressed", _touch_button_box(Color(0.018, 0.022, 0.03, 0.99), accent.lightened(0.26), 2))
	button.add_theme_stylebox_override("disabled", _touch_button_box(Color(0.025, 0.028, 0.036, 0.82), Color(0.25, 0.27, 0.31, 0.76), 3))


func _touch_button_accent(button_name: StringName) -> Color:
	match String(button_name):
		"PunchButton":
			return Color(0.92, 0.24, 0.12, 1.0)
		"KickButton":
			return Color(0.96, 0.52, 0.10, 1.0)
		"ThrowButton":
			return Color(0.70, 0.30, 0.88, 1.0)
		"SpecialButton":
			return Color(1.0, 0.72, 0.12, 1.0)
		"GuardButton":
			return Color(0.18, 0.58, 0.92, 1.0)
		"PauseButton":
			return Color(0.62, 0.66, 0.74, 1.0)
		_:
			return Color(0.48, 0.54, 0.66, 1.0)


func _touch_button_box(background: Color, border: Color, bottom_depth: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.border_width_left = 3
	box.border_width_top = 3
	box.border_width_right = 3
	box.border_width_bottom = bottom_depth
	box.corner_radius_top_left = 12
	box.corner_radius_top_right = 12
	box.corner_radius_bottom_left = 12
	box.corner_radius_bottom_right = 12
	box.content_margin_left = 8.0
	box.content_margin_top = 8.0
	box.content_margin_right = 8.0
	box.content_margin_bottom = 10.0
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.68)
	box.shadow_size = 5
	box.shadow_offset = Vector2(0.0, 4.0 if bottom_depth >= 4 else 2.0)
	return box


func _ensure_runtime_buttons() -> void:
	if left_controls != null:
		for button_name in DIRECTION_BUTTONS:
			if left_controls.get_node_or_null(button_name) != null:
				continue
			var button := Button.new()
			button.name = button_name
			left_controls.add_child(button)
	if right_controls != null and right_controls.get_node_or_null("ThrowButton") == null:
		var throw_button := Button.new()
		throw_button.name = "ThrowButton"
		throw_button.text = "T"
		right_controls.add_child(throw_button)


func _press_virtual_action(action_name: String) -> void:
	var count := int(_held_action_counts.get(action_name, 0))
	_held_action_counts[action_name] = count + 1
	if count == 0:
		Input.action_press(action_name)


func _release_virtual_action(action_name: String) -> void:
	var count := int(_held_action_counts.get(action_name, 0))
	if count <= 1:
		_held_action_counts.erase(action_name)
		Input.action_release(action_name)
	else:
		_held_action_counts[action_name] = count - 1


func _on_direction_button_down(button: Button, data: Dictionary) -> void:
	if not visible or button.disabled:
		return
	_pressed_buttons[button] = int(_pressed_buttons.get(button, 0)) + 1
	for action_name in data.get("hold", []):
		_press_virtual_action(String(action_name))
	for action_name in data.get("tap", []):
		Input.action_press(String(action_name))
		_release_tap_action_deferred(String(action_name))
	button.modulate.a = pressed_opacity


func _on_direction_button_up(button: Button, data: Dictionary) -> void:
	if not _pressed_buttons.has(button):
		return
	var count := int(_pressed_buttons.get(button, 0))
	if count > 1:
		_pressed_buttons[button] = count - 1
	else:
		_pressed_buttons.erase(button)
	for action_name in data.get("hold", []):
		_release_virtual_action(String(action_name))
	button.modulate.a = button_opacity


func _on_tap_button_down(button: Button, action_name: String) -> void:
	if not visible or button.disabled:
		return
	button.modulate.a = pressed_opacity
	await _tap_action(action_name)
	if is_instance_valid(button):
		button.modulate.a = button_opacity


func _on_hold_button_down(button: Button, action_name: String) -> void:
	if not visible or button.disabled:
		return
	_press_virtual_action(action_name)
	button.modulate.a = pressed_opacity


func _on_hold_button_up(button: Button, action_name: String) -> void:
	_release_virtual_action(action_name)
	if is_instance_valid(button):
		button.modulate.a = button_opacity


# Every button_down is one separate action, even when two taps happen
# before the previous pulse has been released by the physics loop.
func _tap_action(action_name: String) -> void:
	_tap_queues[action_name] = int(_tap_queues.get(action_name, 0)) + 1
	if bool(_tap_running.get(action_name, false)):
		return
	_tap_running[action_name] = true
	var generation := _tap_generation
	while generation == _tap_generation and int(_tap_queues.get(action_name, 0)) > 0:
		_tap_queues[action_name] = int(_tap_queues[action_name]) - 1
		Input.action_press(action_name)
		await get_tree().physics_frame
		if generation != _tap_generation or not is_inside_tree():
			return
		await get_tree().process_frame
		if generation != _tap_generation or not is_inside_tree():
			return
		Input.action_release(action_name)
		# A full physics sample in the released state is required for the
		# combat command buffer to recognize the next press as a new tap.
		await get_tree().physics_frame
		if generation != _tap_generation or not is_inside_tree():
			return
		await get_tree().process_frame
		if generation != _tap_generation or not is_inside_tree():
			return
	_tap_queues.erase(action_name)
	_tap_running.erase(action_name)


func _release_tap_action_deferred(action_name: String) -> void:
	await get_tree().physics_frame
	await get_tree().process_frame
	Input.action_release(action_name)


func _on_viewport_size_changed() -> void:
	release_all_touch_inputs()
	_layout_controls()


func _on_visibility_changed() -> void:
	if not visible:
		release_all_touch_inputs()


func _apply_touch_visibility() -> void:
	match touch_controls_mode:
		TouchControlsMode.ON:
			visible = true
		TouchControlsMode.OFF:
			visible = false
		_:
			visible = _should_show_for_current_device()
	if not visible:
		release_all_touch_inputs()


func _should_show_for_current_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web") or DisplayServer.is_touchscreen_available()


func _layout_controls() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	var is_portrait := viewport_size.y > viewport_size.x
	if left_controls != null:
		left_controls.anchor_left = 0.0
		left_controls.anchor_top = 0.0
		left_controls.anchor_right = 0.0
		left_controls.anchor_bottom = 0.0
		left_controls.position = Vector2.ZERO
		left_controls.size = viewport_size
	if right_controls != null:
		right_controls.anchor_left = 0.0
		right_controls.anchor_top = 0.0
		right_controls.anchor_right = 0.0
		right_controls.anchor_bottom = 0.0
		right_controls.position = Vector2.ZERO
		right_controls.size = viewport_size
	var is_compact_landscape := viewport_size.x > viewport_size.y and viewport_size.y <= 430.0
	var scale_factor: float = clampf(viewport_size.y / 720.0, 0.50, 0.92)
	if is_compact_landscape:
		scale_factor = clampf(viewport_size.y / 720.0, 0.48, 0.62)
	var button_size := base_button_size * scale_factor
	var gap := maxf(10.0, 16.0 * scale_factor)
	var margin := Vector2(maxf(safe_margin.x * scale_factor, 18.0), maxf(safe_margin.y * scale_factor, 16.0))
	var bottom_margin := margin.y + (8.0 if not is_portrait else 0.0)
	var dpad_button_size := button_size * 0.78
	var action_button_size := button_size * 0.86
	var left_group_size := Vector2(dpad_button_size.x * 3.0 + gap * 2.0, dpad_button_size.y * 3.0 + gap * 2.0)
	var right_group_size := Vector2(action_button_size.x * 3.0 + gap * 2.0, action_button_size.y * 2.0 + gap)
	var left_top_y := viewport_size.y - bottom_margin - left_group_size.y
	var right_top_y := viewport_size.y - bottom_margin - right_group_size.y
	var left_origin := Vector2(margin.x, left_top_y)
	var right_origin := Vector2(viewport_size.x - margin.x - right_group_size.x, right_top_y)
	left_origin.x = clampf(left_origin.x, margin.x, maxf(margin.x, viewport_size.x - margin.x - left_group_size.x))
	left_origin.y = clampf(left_origin.y, margin.y, maxf(margin.y, viewport_size.y - bottom_margin - left_group_size.y))
	right_origin.x = clampf(right_origin.x, margin.x, maxf(margin.x, viewport_size.x - margin.x - right_group_size.x))
	right_origin.y = clampf(right_origin.y, margin.y, maxf(margin.y, viewport_size.y - bottom_margin - right_group_size.y))

	_position_button($LeftControls/UpLeftButton, left_origin, dpad_button_size)
	_position_button($LeftControls/UpButton, left_origin + Vector2(dpad_button_size.x + gap, 0.0), dpad_button_size)
	_position_button($LeftControls/UpRightButton, left_origin + Vector2((dpad_button_size.x + gap) * 2.0, 0.0), dpad_button_size)
	_position_button($LeftControls/MoveLeftButton, left_origin + Vector2(0.0, dpad_button_size.y + gap), dpad_button_size)
	_position_button($LeftControls/NeutralButton, left_origin + Vector2(dpad_button_size.x + gap, dpad_button_size.y + gap), dpad_button_size)
	_position_button($LeftControls/MoveRightButton, left_origin + Vector2((dpad_button_size.x + gap) * 2.0, dpad_button_size.y + gap), dpad_button_size)
	_position_button($LeftControls/DownLeftButton, left_origin + Vector2(0.0, (dpad_button_size.y + gap) * 2.0), dpad_button_size)
	_position_button($LeftControls/CrouchButton, left_origin + Vector2(dpad_button_size.x + gap, (dpad_button_size.y + gap) * 2.0), dpad_button_size)
	_position_button($LeftControls/DownRightButton, left_origin + Vector2((dpad_button_size.x + gap) * 2.0, (dpad_button_size.y + gap) * 2.0), dpad_button_size)

	_position_button($RightControls/ThrowButton, right_origin, action_button_size)
	_position_button($RightControls/PunchButton, right_origin + Vector2(action_button_size.x + gap, 0.0), action_button_size)
	_position_button($RightControls/KickButton, right_origin + Vector2((action_button_size.x + gap) * 2.0, 0.0), action_button_size)
	_position_button($RightControls/GuardButton, right_origin + Vector2(0.0, action_button_size.y + gap), action_button_size)
	_position_button($RightControls/SpecialButton, right_origin + Vector2(action_button_size.x + gap, action_button_size.y + gap), action_button_size)
	_position_button(pause_button, Vector2(viewport_size.x - margin.x - button_size.x * 0.78, margin.y), button_size * 0.78)

	if rotate_hint != null:
		rotate_hint.visible = show_rotate_hint and is_portrait and visible


func _position_button(button: Control, position: Vector2, size: Vector2) -> void:
	if button == null:
		return
	button.custom_minimum_size = size
	button.position = position
	button.size = size


func _update_special_cooldown(delta: float) -> void:
	if _special_cooldown_remaining <= 0.0:
		return
	_special_cooldown_remaining = maxf(_special_cooldown_remaining - delta, 0.0)
	_update_special_button_state()


func _update_special_button_state() -> void:
	if special_button == null or special_cooldown_label == null:
		return
	var cooling_down := _special_cooldown_remaining > 0.0
	special_button.disabled = cooling_down or _combat_buttons_paused
	special_button.modulate.a = disabled_opacity if special_button.disabled else button_opacity
	special_cooldown_label.visible = false
	special_cooldown_label.text = ""


func _set_all_button_pressed_visuals(is_pressed: bool) -> void:
	for button in find_children("*", "Button", true, false):
		if button is Button:
			button.modulate.a = pressed_opacity if is_pressed else button_opacity
	_update_special_button_state()
