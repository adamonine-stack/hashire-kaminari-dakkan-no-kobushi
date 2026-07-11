extends "res://scripts/player/player_movement.gd"

const PlayerAttackDataScript := preload("res://scripts/data/player_attack_data.gd")

signal attack_started(attack_id)
signal attack_became_active(attack_id)
signal attack_hit(attack_id, target)
signal attack_finished(attack_id)
signal combo_advanced(attack_id, combo_index)
signal combo_finished
signal hitstop_started(duration)
signal hitstop_finished

enum AttackPhase {
	NONE,
	STARTUP,
	ACTIVE,
	RECOVERY,
}

@export var dev026_combo_input_buffer_time := 0.20
@export var dev026_combo_continue_window := 0.25
@export var dev026_combo_reset_time := 0.80
@export var dev026_max_combo_hits: int = 3
@export var dev026_minimum_combo_damage := 1.0
@export var dev026_combo_hitstun_time := 0.30
@export_range(0.0, 1.0, 0.05) var dev026_second_hit_damage_scale := 0.90
@export_range(0.0, 1.0, 0.05) var dev026_third_hit_damage_scale := 0.80
@export_range(0.0, 1.0, 0.05) var dev026_first_combo_knockback_scale := 0.50
@export_range(0.0, 1.0, 0.05) var dev026_second_combo_knockback_scale := 0.65
@export_range(0.0, 1.0, 0.05) var dev026_ai_combo_continue_probability := 0.45
@export_range(0.0, 1.0, 0.05) var dev026_ai_third_hit_probability := 0.25
@export var show_attack_hitboxes := false

var dev_combo_window_open := false
var dev_buffered_attack: StringName = &""
var dev_attack_buffer_timer := 0.0
var dev_last_attack_type: StringName = &""
var dev_combo_target: Node
var dev_current_attack_connected := false
var dev_combo_step := 0
var dev_starting_combo_attack := false
var attack_data_sequence: Array[Resource] = []
var attack_data_by_id: Dictionary = {}
var current_attack_data: Resource
var current_attack_id := ""
var attack_phase := AttackPhase.NONE
var attack_phase_timer := 0.0
var attack_forward_timer := 0.0
var attack_forward_speed := 0.0
var attack_startup_time_actual := 0.0
var attack_active_time_actual := 0.0
var attack_recovery_time_actual := 0.0


func _physics_process(delta: float) -> void:
	if _update_hit_stop(delta):
		return

	var direction := Input.get_axis("move_left", "move_right") if input_enabled else 0.0
	var is_kicking := kick_active_timer > 0.0

	_update_invincibility(delta)
	_update_hit_reaction(delta)
	_update_guard_hit(delta)
	_update_throw_state(delta)
	_update_combo_timer(delta)
	_update_cancel_window(delta)
	_update_attack_buffer(delta)
	_update_ai_throw(delta)

	if input_enabled and not is_hit and not is_guard_hit and not _is_throw_busy():
		_update_defensive_state()
	elif _uses_ai_guard():
		_update_ai_guard(delta)

	if current_attack_type != "" or is_kicking or is_crouching or is_crouch_guarding or is_hit or _is_throw_busy():
		direction = 0.0

	if direction != 0.0 and not is_hit and not _is_throw_busy():
		facing_direction = signf(direction)
		visual_root.scale.x = facing_direction

	if not is_hit and not _is_throw_busy():
		velocity.x = direction * get_current_move_speed()

	if is_on_floor():
		if input_enabled and current_attack_type == "" and Input.is_action_just_pressed("jump") and not is_crouching and not is_kicking and not is_guarding and not is_crouch_guarding and not is_hit and not is_guard_hit and not _is_throw_busy():
			velocity.y = -jump_power
		elif not is_hit:
			velocity.y = 0.0
	else:
		velocity.y += gravity * delta

	if input_enabled and _is_throw_input_pressed() and _can_start_throw():
		_start_throw()
	var did_cancel_attack := try_continue_combo()
	if input_enabled and not did_cancel_attack and current_attack_type == "" and not is_kicking and not is_guarding and not is_crouching and not is_crouch_guarding and not is_hit and not is_guard_hit and not _is_throw_busy() and not _is_throw_input_held() and Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0.0:
		request_punch_attack()
	if input_enabled and not did_cancel_attack and current_attack_type == "" and not is_guarding and not is_crouching and not is_crouch_guarding and not is_hit and not is_guard_hit and not _is_throw_busy() and not _is_throw_input_held() and Input.is_action_just_pressed("kick") and kick_cooldown_timer <= 0.0 and attack_active_timer <= 0.0:
		request_kick_attack()

	if not is_hit and not is_guard_hit and not _is_throw_busy():
		_update_attack(delta)
		_update_kick(delta)
	_update_visual_state()
	move_and_slide()

	if is_guard_hit and is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)

	var viewport_width := get_viewport_rect().size.x
	position.x = clampf(position.x, screen_margin, viewport_width - screen_margin)


func _dev_start_attack() -> void:
	request_punch_attack()


func _dev_start_kick() -> void:
	request_kick_attack()


func _start_throw() -> void:
	interrupt_combo()
	super._start_throw()


func receive_throw(attacker: Node, damage: int, hit_position: Vector2, throw_direction: float, throw_velocity: Vector2) -> void:
	interrupt_combo()
	super.receive_throw(attacker, damage, hit_position, throw_direction, throw_velocity)


func enter_throw_escape_recovery(escaped_target: Node) -> void:
	interrupt_combo()
	super.enter_throw_escape_recovery(escaped_target)


func apply_attack_sequence(sequence: Array) -> void:
	attack_data_sequence.clear()
	attack_data_by_id.clear()
	for attack_data in sequence:
		if attack_data == null:
			continue
		var attack_id := String(attack_data.attack_id)
		if attack_id.is_empty():
			continue
		attack_data_sequence.append(attack_data)
		attack_data_by_id[attack_id] = attack_data
	dev026_max_combo_hits = maxi(1, attack_data_sequence.size())
	reset_attack_state()


func request_punch_attack() -> void:
	var attack_id := get_next_attack_id("punch")
	if attack_id.is_empty():
		attack_id = _ensure_fallback_attack_data("punch")
	start_attack(attack_id)


func request_kick_attack() -> void:
	var attack_id := get_next_attack_id("kick")
	if attack_id.is_empty():
		attack_id = _ensure_fallback_attack_data("kick")
	start_attack(attack_id)


func start_attack(attack_id: String) -> void:
	var attack_data := _get_attack_data(attack_id)
	if attack_data == null:
		return

	if not dev_starting_combo_attack:
		dev_combo_step = 1
		dev_last_attack_type = &""
	else:
		dev_combo_step = mini(combo_count + 1, dev026_max_combo_hits)

	reset_attack_state(false)
	current_attack_data = attack_data
	current_attack_id = attack_id
	current_attack_type = _attack_type_to_state_name(String(attack_data.attack_type))
	dev_current_attack_connected = false
	attack_startup_time_actual = float(attack_data.startup_time) * _get_attack_startup_multiplier(current_attack_type)
	attack_active_time_actual = float(attack_data.active_time)
	attack_recovery_time_actual = float(attack_data.recovery_time) * _get_attack_recovery_multiplier(current_attack_type)
	attack_phase = AttackPhase.STARTUP
	attack_phase_timer = attack_startup_time_actual
	attack_active_timer = 0.0
	kick_active_timer = 0.0
	attack_cooldown_timer = attack_startup_time_actual + attack_active_time_actual + attack_recovery_time_actual
	kick_cooldown_timer = attack_cooldown_timer if current_attack_type == "Kick" else 0.0
	if current_attack_type == "Punch":
		kick_cooldown_timer = 0.0
	clear_attack_hit_targets()
	apply_attack_hitbox_data(attack_data)
	disable_attack_hitbox()
	_setup_attack_forward_movement(attack_data)
	_play_attack_animation(_attack_animation_name(attack_data))
	attack_started.emit(attack_id)
	print("[DEV036] Attack started: %s" % attack_id)


func enter_attack_startup() -> void:
	if current_attack_data == null:
		return
	attack_phase = AttackPhase.STARTUP
	attack_phase_timer = attack_startup_time_actual
	disable_attack_hitbox()


func enter_attack_active() -> void:
	if current_attack_data == null:
		return
	attack_phase = AttackPhase.ACTIVE
	attack_phase_timer = attack_active_time_actual
	enable_attack_hitbox()
	attack_became_active.emit(current_attack_id)
	print("[DEV036] Attack active: %s" % current_attack_id)


func enter_attack_recovery() -> void:
	if current_attack_data == null:
		return
	disable_attack_hitbox()
	attack_phase = AttackPhase.RECOVERY
	attack_phase_timer = attack_recovery_time_actual


func finish_attack() -> void:
	var finished_attack_id := current_attack_id
	var missed := not dev_current_attack_connected
	var whiff_chain_allowed := can_chain_on_whiff()
	disable_attack_hitbox()
	clear_attack_movement()
	if combo_count > 0 and not dev_current_attack_connected:
		reset_combo()
	current_attack_type = ""
	current_attack_data = null
	current_attack_id = ""
	attack_phase = AttackPhase.NONE
	attack_phase_timer = 0.0
	attack_active_timer = 0.0
	kick_active_timer = 0.0
	attack_cooldown_timer = 0.0
	kick_cooldown_timer = 0.0
	clear_attack_buffer()
	close_combo_window()
	if combo_count >= dev026_max_combo_hits:
		reset_combo()
	if not finished_attack_id.is_empty():
		attack_finished.emit(finished_attack_id)
		print("[DEV036] Attack finished: %s" % finished_attack_id)
	if missed:
		print("[DEV036] Attack missed")
		if not whiff_chain_allowed:
			print("[DEV036] Combo chain blocked on whiff")
	if combo_count == 0:
		combo_finished.emit()


func enable_attack_hitbox() -> void:
	if current_attack_type == "Kick":
		_set_kick_hitbox_active(true)
	else:
		_set_punch_hitbox_active(true)


func disable_attack_hitbox() -> void:
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)


func apply_attack_hitbox_data(data: Resource) -> void:
	if data == null:
		return
	var target_area := kick_area if String(data.attack_type).to_lower() == "kick" else punch_area
	var target_shape := kick_shape if String(data.attack_type).to_lower() == "kick" else punch_shape
	target_area.position = Vector2(float(data.hitbox_offset.x) * facing_direction, float(data.hitbox_offset.y))
	if target_shape != null:
		if target_shape.shape == null or not (target_shape.shape is RectangleShape2D):
			target_shape.shape = RectangleShape2D.new()
		else:
			target_shape.shape = target_shape.shape.duplicate()
		target_shape.shape.size = data.hitbox_size


func register_attack_hit(target: Node) -> void:
	if current_attack_id.is_empty():
		return
	attack_hit.emit(current_attack_id, target)
	print("[DEV036] Attack hit: %s" % _target_debug_name(target))


func clear_attack_hit_targets() -> void:
	punch_hit_targets.clear()
	kick_hit_targets.clear()


func queue_next_attack(input_type: String) -> void:
	buffer_attack(StringName(input_type.capitalize()))


func consume_buffered_attack() -> StringName:
	var buffered := dev_buffered_attack
	clear_attack_buffer()
	return buffered


func get_next_attack_id(input_type: String) -> String:
	var normalized_type := input_type.to_lower()
	if current_attack_data != null and not current_attack_id.is_empty():
		for next_id in current_attack_data.next_attack_ids:
			var attack_data := _get_attack_data(String(next_id))
			if attack_data != null and String(attack_data.attack_type).to_lower() == normalized_type:
				return String(attack_data.attack_id)
		return ""

	for attack_data in attack_data_sequence:
		if attack_data != null and String(attack_data.attack_type).to_lower() == normalized_type:
			return String(attack_data.attack_id)
	return ""


func can_chain_to_attack(attack_id: String) -> bool:
	if current_attack_data == null:
		return false
	return current_attack_data.next_attack_ids.has(attack_id)


func can_chain_on_whiff() -> bool:
	return current_attack_data != null and bool(current_attack_data.can_cancel_on_whiff)


func apply_attack_forward_movement(delta: float) -> void:
	if attack_forward_timer <= 0.0:
		return
	var step := minf(delta, attack_forward_timer)
	position.x += attack_forward_speed * step
	attack_forward_timer = maxf(attack_forward_timer - delta, 0.0)


func clear_attack_movement() -> void:
	attack_forward_timer = 0.0
	attack_forward_speed = 0.0


func apply_hitstop(duration: float, target: Node) -> void:
	start_hit_stop_seconds(duration)
	hitstop_started.emit(duration)
	if target != null and target.has_method("start_hit_stop_seconds"):
		target.start_hit_stop_seconds(duration)


func cancel_current_attack() -> void:
	reset_attack_state()


func reset_attack_state(clear_combo_state := true) -> void:
	disable_attack_hitbox()
	clear_attack_hit_targets()
	clear_attack_movement()
	current_attack_data = null
	current_attack_id = ""
	attack_phase = AttackPhase.NONE
	attack_phase_timer = 0.0
	attack_startup_time_actual = 0.0
	attack_active_time_actual = 0.0
	attack_recovery_time_actual = 0.0
	attack_active_timer = 0.0
	kick_active_timer = 0.0
	attack_cooldown_timer = 0.0
	kick_cooldown_timer = 0.0
	current_attack_type = ""
	if clear_combo_state:
		clear_attack_buffer()
		close_combo_window()


func receive_attack(attack_data: Dictionary, attack_direction: float, hit_position: Vector2, attacker: Node) -> bool:
	if _can_guard_attack(attack_data, attacker):
		_receive_guarded_attack(attack_data, attack_direction, hit_position, attacker)
		return false

	interrupt_combo()
	reset_attack_state()
	_cancel_current_action()
	_enter_hit_state()
	if int(attack_data.get("combo_hit_index", 1)) < dev026_max_combo_hits:
		hit_reaction_timer = maxf(hit_reaction_timer, dev026_combo_hitstun_time)
	apply_damage(attack_data["damage"])
	if attacker != null and attacker.has_method("register_combo_hit"):
		attacker.register_combo_hit(self)
		if current_hp == 0 and attacker.has_method("_finish_combo_after_ko"):
			attacker._finish_combo_after_ko()
	_apply_knockback(attack_data, attack_direction)
	_start_invincibility()
	_start_hit_stop(attack_data["hit_stop_frames"])
	_spawn_hit_effect(hit_position, attack_data["effect_size"])
	_play_hit_se(attack_data["se_type"])
	if attacker != null and attacker.has_method("start_hit_stop"):
		attacker.start_hit_stop(attack_data["hit_stop_frames"])
	screen_shake_requested.emit(attack_data["screen_shake"])
	return true


func _apply_attack_to_target(target: Node, attack_data: Dictionary) -> void:
	if not target.has_method("receive_attack"):
		return

	var scaled_attack_data := _build_combo_scaled_attack_data(attack_data, target)
	var did_hit: bool = bool(target.receive_attack(scaled_attack_data, facing_direction, _get_hit_position(target), self))
	if did_hit:
		register_attack_hit(target)


func _receive_guarded_attack(attack_data: Dictionary, attack_direction: float, hit_position: Vector2, attacker: Node) -> void:
	reset_attack_state(false)
	attack_active_timer = 0.0
	kick_active_timer = 0.0
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)
	if attacker != null and attacker.has_method("reset_combo"):
		attacker.reset_combo()
	if attacker != null and attacker.has_method("_clear_cancel_window"):
		attacker._clear_cancel_window()
	if attacker != null and attacker.has_method("clear_attack_buffer"):
		attacker.clear_attack_buffer()
	_enter_guard_hit_state()
	apply_damage(_get_guard_damage(int(attack_data.get("base_damage", attack_data["damage"]))))
	_apply_guard_knockback(attack_data, attack_direction)
	_start_hit_stop_seconds(guard_hit_stop_time)
	_spawn_guard_effect(hit_position)
	_play_guard_se()
	if attacker != null and attacker.has_method("start_hit_stop"):
		attacker.start_hit_stop_seconds(guard_hit_stop_time)


func _update_attack(delta: float) -> void:
	if current_attack_type != "Punch":
		return
	_update_current_attack(delta)


func _update_kick(delta: float) -> void:
	if current_attack_type != "Kick":
		return
	_update_current_attack(delta)


func _update_current_attack(delta: float) -> void:
	if current_attack_data == null:
		return

	apply_attack_forward_movement(delta)
	attack_cooldown_timer = maxf(attack_cooldown_timer - delta, 0.0)
	if current_attack_type == "Kick":
		kick_cooldown_timer = attack_cooldown_timer

	attack_phase_timer = maxf(attack_phase_timer - delta, 0.0)
	match attack_phase:
		AttackPhase.STARTUP:
			if attack_phase_timer == 0.0:
				enter_attack_active()
		AttackPhase.ACTIVE:
			if attack_phase_timer == 0.0:
				enter_attack_recovery()
		AttackPhase.RECOVERY:
			if attack_phase_timer == 0.0:
				finish_attack()


func register_combo_hit(target: Node) -> void:
	if target == null or not is_instance_valid(target):
		reset_combo()
		return

	if combo_timer <= 0.0 or dev_combo_target == null or not is_instance_valid(dev_combo_target):
		combo_count = 0
		dev_combo_target = target
	elif dev_combo_target != target:
		reset_combo()
		dev_combo_target = target

	combo_count = mini(combo_count + 1, dev026_max_combo_hits)
	dev_current_attack_connected = true
	dev_last_attack_type = StringName(current_attack_type)
	dev_combo_step = combo_count
	combo_timer = dev026_combo_reset_time
	combo_changed.emit(combo_count, self)
	combo_advanced.emit(current_attack_id, combo_count)
	if combo_log_enabled and combo_count >= 2:
		print("Combo: %s %d HIT" % [_get_combo_log_name(), combo_count])

	if combo_count < dev026_max_combo_hits and current_hp > 0:
		open_combo_window()
	else:
		close_combo_window()
		clear_attack_buffer()


func reset_combo() -> void:
	if combo_count == 0 and combo_timer == 0.0 and not dev_combo_window_open and dev_buffered_attack == &"":
		return

	combo_count = 0
	combo_timer = 0.0
	dev_combo_window_open = false
	dev_buffered_attack = &""
	dev_attack_buffer_timer = 0.0
	dev_last_attack_type = &""
	dev_combo_target = null
	dev_current_attack_connected = false
	dev_combo_step = 0
	_clear_cancel_window()
	combo_changed.emit(combo_count, self)


func _update_combo_timer(delta: float) -> void:
	if combo_count == 0:
		return

	combo_timer = maxf(combo_timer - delta, 0.0)
	if combo_timer == 0.0:
		reset_combo()


func buffer_attack(attack_type: StringName) -> void:
	if attack_type != &"Punch" and attack_type != &"Kick":
		return
	dev_buffered_attack = attack_type
	dev_attack_buffer_timer = dev026_combo_input_buffer_time


func clear_attack_buffer() -> void:
	dev_buffered_attack = &""
	dev_attack_buffer_timer = 0.0


func open_combo_window() -> void:
	if current_attack_type == "" or current_attack_data == null or not bool(current_attack_data.can_cancel_on_hit):
		return
	can_cancel = true
	dev_combo_window_open = true
	cancel_window_timer = maxf(float(current_attack_data.combo_input_end) - float(current_attack_data.combo_input_start), dev026_combo_continue_window)
	_maybe_buffer_ai_combo()


func close_combo_window() -> void:
	dev_combo_window_open = false
	can_cancel = false
	cancel_window_timer = 0.0


func _open_cancel_window() -> void:
	open_combo_window()


func _update_cancel_window(delta: float) -> void:
	if not can_cancel and not dev_combo_window_open:
		return
	cancel_window_timer = maxf(cancel_window_timer - delta, 0.0)
	if cancel_window_timer == 0.0:
		close_combo_window()


func _update_attack_buffer(delta: float) -> void:
	if dev_attack_buffer_timer > 0.0:
		dev_attack_buffer_timer = maxf(dev_attack_buffer_timer - delta, 0.0)
		if dev_attack_buffer_timer == 0.0:
			clear_attack_buffer()

	if not input_enabled or current_attack_type == "" or _is_throw_input_held():
		return
	if Input.is_action_just_pressed("attack"):
		buffer_attack(&"Punch")
	elif Input.is_action_just_pressed("kick"):
		buffer_attack(&"Kick")


func _try_cancel_attack_from_input() -> bool:
	return try_continue_combo()


func _can_cancel_attack() -> bool:
	return is_round_active and dev_combo_window_open and can_cancel and cancel_window_timer > 0.0 and current_attack_type != "" and current_hp > 0 and (dev_current_attack_connected or can_chain_on_whiff()) and combo_count < dev026_max_combo_hits and is_on_floor() and not is_hit and not is_guard_hit and not is_guarding and not is_crouching and not is_crouch_guarding and not _is_throw_busy()


func can_chain_attack(current_attack: StringName, next_attack: StringName) -> bool:
	if current_attack_data == null:
		return false
	return not get_next_attack_id(String(next_attack).to_lower()).is_empty()


func try_continue_combo() -> bool:
	if not _can_cancel_attack():
		return false
	if dev_buffered_attack == &"":
		return false
	if not can_chain_attack(StringName(current_attack_type), dev_buffered_attack):
		clear_attack_buffer()
		return false

	var next_attack := dev_buffered_attack
	var next_attack_id := get_next_attack_id(String(next_attack).to_lower())
	if next_attack_id.is_empty():
		clear_attack_buffer()
		return false
	clear_attack_buffer()
	start_combo_attack(StringName(next_attack_id))
	return true


func start_combo_attack(next_attack_type: StringName) -> void:
	var previous_attack_id := current_attack_id
	reset_attack_state(false)
	close_combo_window()
	dev_current_attack_connected = false
	dev_starting_combo_attack = true
	dev_combo_step = mini(combo_count + 1, dev026_max_combo_hits)
	print("Cancel: %s -> %s" % [previous_attack_id, next_attack_type])
	start_attack(String(next_attack_type))
	print("[DEV036] Combo advanced: %s" % String(next_attack_type))
	dev_starting_combo_attack = false


func _cancel_into_attack(next_attack_type: String) -> void:
	start_combo_attack(StringName(next_attack_type))


func _clear_cancel_window() -> void:
	can_cancel = false
	cancel_window_timer = 0.0
	dev_combo_window_open = false


func _build_combo_scaled_attack_data(attack_data: Dictionary, target: Node) -> Dictionary:
	var scaled_attack_data := attack_data.duplicate()
	var hit_index := _get_next_combo_hit_index(target)
	var knockback_scale := _get_combo_knockback_scale_for_hit(hit_index)
	scaled_attack_data["base_damage"] = attack_data["damage"]
	scaled_attack_data["knockback_x"] = float(attack_data["knockback_x"]) * knockback_scale
	scaled_attack_data["knockback_y"] = float(attack_data["knockback_y"]) * knockback_scale
	scaled_attack_data["combo_hit_index"] = hit_index
	scaled_attack_data["damage_scale"] = 1.0
	return scaled_attack_data


func _get_next_combo_hit_index(target: Node) -> int:
	if combo_timer <= 0.0 or dev_combo_target == null or not is_instance_valid(dev_combo_target) or dev_combo_target != target:
		return 1
	return mini(combo_count + 1, dev026_max_combo_hits)


func get_combo_damage_scale() -> float:
	return _get_combo_damage_scale_for_hit(maxi(combo_count, 1))


func _get_combo_damage_scale_for_hit(hit_index: int) -> float:
	match hit_index:
		1:
			return 1.0
		2:
			return dev026_second_hit_damage_scale
		_:
			return dev026_third_hit_damage_scale


func get_combo_knockback_scale() -> float:
	return _get_combo_knockback_scale_for_hit(maxi(combo_count, 1))


func _get_combo_knockback_scale_for_hit(hit_index: int) -> float:
	if hit_index <= 1:
		return dev026_first_combo_knockback_scale
	if hit_index == 2 and dev026_max_combo_hits > 2:
		return dev026_second_combo_knockback_scale
	return 1.0


func interrupt_combo() -> void:
	reset_attack_state(false)
	clear_attack_buffer()
	close_combo_window()
	reset_combo()


func _finish_combo_after_ko() -> void:
	clear_attack_buffer()
	close_combo_window()


func _maybe_buffer_ai_combo() -> void:
	if name != "Enemy" or input_enabled:
		return
	if not dev_combo_window_open or dev_buffered_attack != &"" or combo_count >= dev026_max_combo_hits:
		return
	if not dev_current_attack_connected or current_attack_type == "":
		return

	var continue_probability := dev026_ai_combo_continue_probability if combo_count <= 1 else dev026_ai_third_hit_probability
	if randf() > continue_probability:
		return

	var next_attack := _choose_ai_combo_attack()
	if next_attack != &"":
		buffer_attack(next_attack)


func _choose_ai_combo_attack() -> StringName:
	match StringName(current_attack_type):
		&"Punch":
			if not get_next_attack_id("kick").is_empty() and randf() < 0.5:
				return &"Kick"
			return &"Punch" if not get_next_attack_id("punch").is_empty() else &""
		&"Kick":
			return &"Punch" if not get_next_attack_id("punch").is_empty() else &""
		_:
			return &""


func _play_attack_animation(animation_name: StringName) -> void:
	if animation_player == null:
		return
	if animation_player.has_animation(String(animation_name)):
		animation_player.play(String(animation_name))
	elif animation_player.has_animation("Punch") and current_attack_type == "Punch":
		animation_player.play("Punch")
	elif animation_player.has_animation("Kick") and current_attack_type == "Kick":
		animation_player.play("Kick")


func _get_attack_animation_name(attack_type: StringName) -> StringName:
	if attack_type == &"Punch":
		return &"punch_2" if dev_combo_step == 2 else &"punch_1"
	if dev_combo_step >= dev026_max_combo_hits:
		return &"combo_finisher"
	return &"kick_1"


func _get_punch_attack_data() -> Dictionary:
	return _get_attack_data_dictionary("Punch")


func _get_kick_attack_data() -> Dictionary:
	return _get_attack_data_dictionary("Kick")


func _get_attack_data_dictionary(fallback_attack_type: String) -> Dictionary:
	var attack_data := current_attack_data
	var attack_type := current_attack_type if current_attack_type != "" else fallback_attack_type
	if attack_data == null:
		if fallback_attack_type == "Kick":
			return super._get_kick_attack_data()
		return super._get_punch_attack_data()

	var base_damage := kick_damage if attack_type == "Kick" else punch_damage
	var final_knockback := calculate_attack_knockback(Vector2(absf(float(attack_data.knockback.x)), absf(float(attack_data.knockback.y))))
	return {
		"damage": maxi(1, int(round(float(base_damage) * float(attack_data.base_damage)))),
		"attack_height": "low" if attack_type == "Kick" else "middle",
		"knockback_x": final_knockback.x,
		"knockback_y": final_knockback.y,
		"hit_stop_frames": maxi(1, int(round(float(attack_data.hitstop_time) * 60.0))),
		"effect_size": 1.5 if attack_type == "Kick" else 1.0,
		"screen_shake": 4.0 if attack_type == "Kick" else 2.0,
		"se_type": "strong" if attack_type == "Kick" else "weak",
		"attack_id": current_attack_id,
	}


func _get_attack_data(attack_id: String) -> Resource:
	if attack_data_by_id.has(attack_id):
		return attack_data_by_id[attack_id]
	return null


func _ensure_fallback_attack_data(attack_type: String) -> String:
	var normalized_type := attack_type.to_lower()
	var fallback_id := "fallback_%s" % normalized_type
	if attack_data_by_id.has(fallback_id):
		return fallback_id

	var fallback_data: Resource = PlayerAttackDataScript.new()
	fallback_data.attack_id = fallback_id
	fallback_data.display_name = "%s Attack" % normalized_type.capitalize()
	fallback_data.attack_type = normalized_type
	fallback_data.base_damage = 1.0
	fallback_data.startup_time = 0.0
	fallback_data.active_time = kick_active_time if normalized_type == "kick" else attack_active_time
	fallback_data.recovery_time = kick_cooldown_time if normalized_type == "kick" else attack_cooldown_time
	fallback_data.combo_input_start = 0.05
	fallback_data.combo_input_end = dev026_combo_continue_window
	fallback_data.hitbox_size = Vector2(60.0, 32.0) if normalized_type == "kick" else Vector2(48.0, 40.0)
	fallback_data.hitbox_offset = Vector2(kick_offset, -44.0) if normalized_type == "kick" else Vector2(attack_offset, -64.0)
	fallback_data.forward_move_distance = 0.0
	fallback_data.forward_move_duration = 0.0
	fallback_data.knockback = Vector2(kick_knockback_x, -kick_knockback_y) if normalized_type == "kick" else Vector2(punch_knockback_x, -punch_knockback_y)
	fallback_data.hitstop_time = 0.08 if normalized_type == "kick" else 0.05
	fallback_data.hitstun_time = 0.28 if normalized_type == "kick" else 0.18
	fallback_data.next_attack_ids = []
	fallback_data.animation_name = "Kick" if normalized_type == "kick" else "Punch"
	attack_data_by_id[fallback_id] = fallback_data
	return fallback_id


func _attack_type_to_state_name(attack_type: String) -> String:
	return "Kick" if attack_type.to_lower() == "kick" else "Punch"


func _get_attack_startup_multiplier(attack_type: String) -> float:
	return kick_startup_multiplier if attack_type == "Kick" else punch_startup_multiplier


func _get_attack_recovery_multiplier(attack_type: String) -> float:
	return kick_recovery_multiplier if attack_type == "Kick" else punch_recovery_multiplier


func _attack_animation_name(attack_data: Resource) -> StringName:
	if attack_data != null and not String(attack_data.animation_name).is_empty():
		return StringName(attack_data.animation_name)
	return _get_attack_animation_name(StringName(current_attack_type))


func _setup_attack_forward_movement(attack_data: Resource) -> void:
	clear_attack_movement()
	if attack_data == null:
		return
	var duration := float(attack_data.forward_move_duration)
	if duration <= 0.0:
		return
	attack_forward_timer = duration
	attack_forward_speed = (float(attack_data.forward_move_distance) / duration) * facing_direction


func _target_debug_name(target: Node) -> String:
	if target == null:
		return "Unknown"
	if target.name == "Enemy":
		return "Enemy1"
	return String(target.name)


func _update_visual_state() -> void:
	super._update_visual_state()
	if not debug_state_label_enabled:
		return
	if combo_count == 0 and not dev_combo_window_open and dev_buffered_attack == &"":
		return

	var buffered_text := "NONE" if dev_buffered_attack == &"" else String(dev_buffered_attack).to_upper()
	var window_text := "OPEN" if dev_combo_window_open else "CLOSED"
	state_label.text += "\nATTACK ID: %s\nATTACK PHASE: %s\nCOMBO HITS: %d\nCOMBO STEP: %d\nBUFFERED ATTACK: %s\nCOMBO WINDOW: %s\nATTACK CONNECTED: %s\nDAMAGE SCALE: %.2f" % [
		"NONE" if current_attack_id.is_empty() else current_attack_id,
		AttackPhase.keys()[attack_phase],
		combo_count,
		dev_combo_step,
		buffered_text,
		window_text,
		str(dev_current_attack_connected).to_upper(),
		get_combo_damage_scale(),
	]
