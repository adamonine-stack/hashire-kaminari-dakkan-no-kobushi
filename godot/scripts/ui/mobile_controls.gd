extends Control

enum TouchControlsMode {
	AUTO,
	ON,
	OFF,
}

const DIRECTION_BUTTONS := {
	"UpLeftButton": {
		"text": "↖",
		"hold": ["move_left"],
		"tap": ["jump"],
	},
	"UpButton": {
		"text": "↑",
		"hold": [],
		"tap": ["jump"],
	},
	"UpRightButton": {
		"text": "↗",
		"hold": ["move_right"],
		"tap": ["jump"],
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


func _exit_tree() -> void:
	release_all_touch_inputs()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		release_all_touch_inputs()


func release_all_touch_inputs() -> void:
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
	if not visible:
		return
	_pressed_buttons[button] = true
	for action_name in data.get("hold", []):
		_press_virtual_action(String(action_name))
	for action_name in data.get("tap", []):
		Input.action_press(String(action_name))
		_release_tap_action_deferred(String(action_name))
	button.modulate.a = pressed_opacity


func _on_direction_button_up(button: Button, data: Dictionary) -> void:
	if not _pressed_buttons.has(button):
		return
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


func _tap_action(action_name: String) -> void:
	Input.action_press(action_name)
	await _release_tap_action_deferred(action_name)


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
	var scale_factor: float = clampf(viewport_size.y / 720.0, 0.56, 0.92)
	var button_size := base_button_size * scale_factor
	var gap := maxf(10.0, 16.0 * scale_factor)
	var margin := Vector2(maxf(safe_margin.x * scale_factor, 18.0), maxf(safe_margin.y * scale_factor, 16.0))
	var bottom_margin := margin.y + (8.0 if not is_portrait else 0.0)
	var dpad_button_size := button_size * 0.78
	var action_button_size := button_size * 0.86
	var left_top_y := viewport_size.y - bottom_margin - dpad_button_size.y * 3.0 - gap * 2.0
	var right_top_y := viewport_size.y - bottom_margin - button_size.y * 2.0 - gap
	var left_origin := Vector2(margin.x, left_top_y)
	var right_origin := Vector2(viewport_size.x - margin.x - action_button_size.x * 3.0 - gap * 2.0, right_top_y)
	left_origin.x = clampf(left_origin.x, margin.x, maxf(margin.x, viewport_size.x - margin.x - dpad_button_size.x * 3.0 - gap * 2.0))
	left_origin.y = clampf(left_origin.y, margin.y, maxf(margin.y, viewport_size.y - bottom_margin - dpad_button_size.y * 3.0 - gap * 2.0))
	right_origin.x = clampf(right_origin.x, margin.x, maxf(margin.x, viewport_size.x - margin.x - action_button_size.x * 3.0 - gap * 2.0))
	right_origin.y = clampf(right_origin.y, margin.y, maxf(margin.y, viewport_size.y - bottom_margin - button_size.y * 2.0 - gap))

	_position_button($LeftControls/UpLeftButton, left_origin, dpad_button_size)
	_position_button($LeftControls/UpButton, left_origin + Vector2(dpad_button_size.x + gap, 0.0), dpad_button_size)
	_position_button($LeftControls/UpRightButton, left_origin + Vector2((dpad_button_size.x + gap) * 2.0, 0.0), dpad_button_size)
	_position_button($LeftControls/MoveLeftButton, left_origin + Vector2(0.0, dpad_button_size.y + gap), dpad_button_size)
	_position_button($LeftControls/NeutralButton, left_origin + Vector2(dpad_button_size.x + gap, dpad_button_size.y + gap), dpad_button_size)
	_position_button($LeftControls/MoveRightButton, left_origin + Vector2((dpad_button_size.x + gap) * 2.0, dpad_button_size.y + gap), dpad_button_size)
	_position_button($LeftControls/DownLeftButton, left_origin + Vector2(0.0, (dpad_button_size.y + gap) * 2.0), dpad_button_size)
	_position_button($LeftControls/CrouchButton, left_origin + Vector2(dpad_button_size.x + gap, (dpad_button_size.y + gap) * 2.0), dpad_button_size)
	_position_button($LeftControls/DownRightButton, left_origin + Vector2((dpad_button_size.x + gap) * 2.0, (dpad_button_size.y + gap) * 2.0), dpad_button_size)

	_position_button($RightControls/ThrowButton, right_origin + Vector2(0.0, button_size.y * 0.55), action_button_size)
	_position_button($RightControls/PunchButton, right_origin + Vector2(action_button_size.x + gap, 0.0), action_button_size)
	_position_button($RightControls/KickButton, right_origin + Vector2((action_button_size.x + gap) * 2.0, button_size.y * 0.55), action_button_size)
	_position_button($RightControls/GuardButton, right_origin + Vector2(0.0, button_size.y + gap), action_button_size)
	_position_button($RightControls/SpecialButton, right_origin + Vector2(action_button_size.x + gap, button_size.y + gap), action_button_size * 1.06)
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
