extends Control

enum TouchControlsMode {
	AUTO,
	ON,
	OFF,
}

const HOLD_BUTTON_ACTIONS := {
	"MoveLeftButton": "move_left",
	"MoveRightButton": "move_right",
	"CrouchButton": "down",
	"GuardButton": "guard",
}

const TAP_BUTTON_ACTIONS := {
	"PunchButton": "attack",
	"KickButton": "kick",
	"JumpButton": "jump",
	"SpecialButton": "special",
	"PauseButton": "pause",
}

@export var touch_controls_mode: TouchControlsMode = TouchControlsMode.ON
@export var button_opacity := 0.72
@export var pressed_opacity := 0.96
@export var disabled_opacity := 0.25
@export var base_button_size := Vector2(88.0, 88.0)
@export var safe_margin := Vector2(28.0, 24.0)
@export var show_rotate_hint := true

var _held_actions: Array[String] = []
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
	for action_name in _held_actions:
		Input.action_release(action_name)
	_held_actions.clear()
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
	_apply_touch_visibility()


func hide_touch_controls() -> void:
	release_all_touch_inputs()
	visible = false


func set_touch_controls_mode(mode: TouchControlsMode) -> void:
	touch_controls_mode = mode
	_apply_touch_visibility()


func set_special_cooldown(remaining: float, total: float) -> void:
	_special_cooldown_remaining = maxf(remaining, 0.0)
	_special_cooldown_total = maxf(total, 0.0)
	_update_special_button_state()


func _connect_touch_buttons() -> void:
	for button_name in HOLD_BUTTON_ACTIONS:
		var button := get_node_or_null("LeftControls/%s" % button_name) as Button
		if button == null:
			button = get_node_or_null("RightControls/%s" % button_name) as Button
		if button == null:
			continue
		var action_name := HOLD_BUTTON_ACTIONS[button_name] as String
		_prepare_button(button)
		button.button_down.connect(_on_hold_button_down.bind(button, action_name))
		button.button_up.connect(_on_hold_button_up.bind(button, action_name))
		button.mouse_exited.connect(_on_hold_button_up.bind(button, action_name))

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
		button.button_down.connect(_on_tap_button_down.bind(button, action_name))


func _prepare_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate.a = button_opacity
	button.custom_minimum_size = base_button_size


func _on_hold_button_down(button: Button, action_name: String) -> void:
	if not visible:
		return
	_pressed_buttons[button] = true
	if not _held_actions.has(action_name):
		_held_actions.append(action_name)
		Input.action_press(action_name)
	button.modulate.a = pressed_opacity


func _on_hold_button_up(button: Button, action_name: String) -> void:
	if not _pressed_buttons.has(button):
		return
	_pressed_buttons.erase(button)
	if _held_actions.has(action_name):
		_held_actions.erase(action_name)
		Input.action_release(action_name)
	button.modulate.a = button_opacity


func _on_tap_button_down(button: Button, action_name: String) -> void:
	if not visible or button.disabled:
		return
	button.modulate.a = pressed_opacity
	await _tap_action(action_name)
	if is_instance_valid(button):
		button.modulate.a = button_opacity


func _tap_action(action_name: String) -> void:
	Input.action_press(action_name)
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
	var is_portrait := viewport_size.y > viewport_size.x
	if left_controls != null:
		left_controls.position = Vector2.ZERO
		left_controls.size = viewport_size
	if right_controls != null:
		right_controls.position = Vector2.ZERO
		right_controls.size = viewport_size
	var scale_factor: float = clampf(viewport_size.y / 720.0, 0.72, 1.18)
	var button_size := base_button_size * scale_factor
	var gap := 16.0 * scale_factor
	var margin := Vector2(maxf(safe_margin.x, 24.0), maxf(safe_margin.y, 20.0))
	var left_origin := Vector2(margin.x, viewport_size.y - margin.y - button_size.y * 2.25 - gap)
	var right_origin := Vector2(viewport_size.x - margin.x - button_size.x * 3.0 - gap * 2.0, viewport_size.y - margin.y - button_size.y * 2.05 - gap)
	left_origin.x = clampf(left_origin.x, margin.x, maxf(margin.x, viewport_size.x - margin.x - button_size.x * 2.0 - gap))
	left_origin.y = clampf(left_origin.y, margin.y + 80.0, maxf(margin.y + 80.0, viewport_size.y - margin.y - button_size.y * 2.0 - gap))
	right_origin.x = clampf(right_origin.x, margin.x, maxf(margin.x, viewport_size.x - margin.x - button_size.x * 3.0 - gap * 2.0))
	right_origin.y = clampf(right_origin.y, margin.y + 80.0, maxf(margin.y + 80.0, viewport_size.y - margin.y - button_size.y * 2.0 - gap))

	_position_button($LeftControls/MoveLeftButton, left_origin + Vector2(0.0, button_size.y * 0.5 + gap * 0.5), button_size)
	_position_button($LeftControls/MoveRightButton, left_origin + Vector2(button_size.x + gap, button_size.y * 0.5 + gap * 0.5), button_size)
	_position_button($LeftControls/CrouchButton, left_origin + Vector2((button_size.x + gap) * 0.5, button_size.y + gap), button_size)
	_position_button($RightControls/JumpButton, left_origin + Vector2((button_size.x + gap) * 0.5, 0.0), button_size)

	_position_button($RightControls/GuardButton, right_origin + Vector2(0.0, button_size.y * 0.55), button_size)
	_position_button($RightControls/PunchButton, right_origin + Vector2(button_size.x + gap, 0.0), button_size)
	_position_button($RightControls/KickButton, right_origin + Vector2((button_size.x + gap) * 2.0, button_size.y * 0.55), button_size)
	_position_button($RightControls/SpecialButton, right_origin + Vector2(button_size.x + gap, button_size.y + gap), button_size * 1.06)
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
	special_cooldown_label.visible = cooling_down
	if cooling_down:
		special_cooldown_label.text = "%0.1f" % _special_cooldown_remaining


func _set_all_button_pressed_visuals(is_pressed: bool) -> void:
	for button in find_children("*", "Button", true, false):
		if button is Button:
			button.modulate.a = pressed_opacity if is_pressed else button_opacity
	_update_special_button_state()
