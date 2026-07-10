extends "res://scripts/player/player_movement.gd"

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

var dev_combo_window_open := false
var dev_buffered_attack: StringName = &""
var dev_attack_buffer_timer := 0.0
var dev_last_attack_type: StringName = &""
var dev_combo_target: Node
var dev_current_attack_connected := false
var dev_combo_step := 0
var dev_starting_combo_attack := false


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

	if is_kicking or is_crouching or is_crouch_guarding or is_hit or _is_throw_busy():
		direction = 0.0

	if direction != 0.0 and not is_hit and not _is_throw_busy():
		facing_direction = signf(direction)
		visual_root.scale.x = facing_direction

	if not is_hit and not _is_throw_busy():
		velocity.x = direction * move_speed

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
		_dev_start_attack()
	if input_enabled and not did_cancel_attack and current_attack_type == "" and not is_guarding and not is_crouching and not is_crouch_guarding and not is_hit and not is_guard_hit and not _is_throw_busy() and not _is_throw_input_held() and Input.is_action_just_pressed("kick") and kick_cooldown_timer <= 0.0 and attack_active_timer <= 0.0:
		_dev_start_kick()

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
	if not dev_starting_combo_attack:
		dev_combo_step = 1
		dev_last_attack_type = &""
	current_attack_type = "Punch"
	dev_current_attack_connected = false
	attack_active_timer = attack_active_time
	attack_cooldown_timer = attack_cooldown_time
	punch_hit_targets.clear()
	punch_area.position.x = facing_direction * attack_offset
	_play_attack_animation(_get_attack_animation_name(&"Punch"))
	_set_punch_hitbox_active(true)


func _dev_start_kick() -> void:
	print("Kick Start")
	if not dev_starting_combo_attack:
		dev_combo_step = 1
		dev_last_attack_type = &""
	current_attack_type = "Kick"
	dev_current_attack_connected = false
	kick_active_timer = kick_active_time
	kick_cooldown_timer = kick_cooldown_time
	velocity.x = 0.0
	kick_hit_targets.clear()
	kick_area.position.x = facing_direction * kick_offset
	_play_attack_animation(_get_attack_animation_name(&"Kick"))
	_set_kick_hitbox_active(true)


func _start_throw() -> void:
	interrupt_combo()
	super._start_throw()


func receive_throw(attacker: Node, damage: int, hit_position: Vector2, throw_direction: float, throw_velocity: Vector2) -> void:
	interrupt_combo()
	super.receive_throw(attacker, damage, hit_position, throw_direction, throw_velocity)


func enter_throw_escape_recovery(escaped_target: Node) -> void:
	interrupt_combo()
	super.enter_throw_escape_recovery(escaped_target)


func receive_attack(attack_data: Dictionary, attack_direction: float, hit_position: Vector2, attacker: Node) -> bool:
	if _can_guard_attack(attack_data, attacker):
		_receive_guarded_attack(attack_data, attack_direction, hit_position, attacker)
		return false

	interrupt_combo()
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
	target.receive_attack(scaled_attack_data, facing_direction, _get_hit_position(target), self)


func _receive_guarded_attack(attack_data: Dictionary, attack_direction: float, hit_position: Vector2, attacker: Node) -> void:
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
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer = maxf(attack_cooldown_timer - delta, 0.0)
		if attack_cooldown_timer == 0.0 and current_attack_type == "Punch":
			if combo_count > 0 and not dev_current_attack_connected:
				reset_combo()
			current_attack_type = ""
			clear_attack_buffer()
			close_combo_window()
			if combo_count >= dev026_max_combo_hits:
				reset_combo()

	if attack_active_timer <= 0.0:
		_set_punch_hitbox_active(false)
		return

	attack_active_timer = maxf(attack_active_timer - delta, 0.0)
	if attack_active_timer == 0.0:
		_set_punch_hitbox_active(false)


func _update_kick(delta: float) -> void:
	if kick_cooldown_timer > 0.0:
		kick_cooldown_timer = maxf(kick_cooldown_timer - delta, 0.0)
		if kick_cooldown_timer == 0.0 and current_attack_type == "Kick":
			if combo_count > 0 and not dev_current_attack_connected:
				reset_combo()
			current_attack_type = ""
			clear_attack_buffer()
			close_combo_window()
			if combo_count >= dev026_max_combo_hits:
				reset_combo()

	if kick_active_timer <= 0.0:
		_set_kick_hitbox_active(false)
		return

	kick_active_timer = maxf(kick_active_timer - delta, 0.0)
	if kick_active_timer == 0.0:
		_set_kick_hitbox_active(false)
		print("Kick End")


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
	if current_attack_type == "":
		return
	can_cancel = true
	dev_combo_window_open = true
	cancel_window_timer = dev026_combo_continue_window
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
	return is_round_active and dev_combo_window_open and can_cancel and cancel_window_timer > 0.0 and current_attack_type != "" and current_hp > 0 and dev_current_attack_connected and combo_count < dev026_max_combo_hits and is_on_floor() and not is_hit and not is_guard_hit and not is_guarding and not is_crouching and not is_crouch_guarding and not _is_throw_busy()


func can_chain_attack(current_attack: StringName, next_attack: StringName) -> bool:
	match current_attack:
		&"Punch":
			return next_attack == &"Punch" or next_attack == &"Kick"
		&"Kick":
			return next_attack == &"Punch"
		_:
			return false


func try_continue_combo() -> bool:
	if not _can_cancel_attack():
		return false
	if dev_buffered_attack == &"":
		return false
	if not can_chain_attack(StringName(current_attack_type), dev_buffered_attack):
		clear_attack_buffer()
		return false

	var next_attack := dev_buffered_attack
	clear_attack_buffer()
	start_combo_attack(next_attack)
	return true


func start_combo_attack(next_attack_type: StringName) -> void:
	var previous_attack_type := current_attack_type
	attack_active_timer = 0.0
	kick_active_timer = 0.0
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)
	punch_hit_targets.clear()
	kick_hit_targets.clear()
	close_combo_window()
	dev_current_attack_connected = false
	dev_starting_combo_attack = true
	dev_combo_step = mini(combo_count + 1, dev026_max_combo_hits)
	print("Cancel: %s -> %s" % [previous_attack_type, next_attack_type])
	if next_attack_type == &"Kick":
		_dev_start_kick()
	else:
		_dev_start_attack()
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
	var damage_scale := _get_combo_damage_scale_for_hit(hit_index)
	var knockback_scale := _get_combo_knockback_scale_for_hit(hit_index)
	scaled_attack_data["base_damage"] = attack_data["damage"]
	scaled_attack_data["damage"] = maxi(int(round(float(attack_data["damage"]) * damage_scale)), int(dev026_minimum_combo_damage))
	scaled_attack_data["knockback_x"] = float(attack_data["knockback_x"]) * knockback_scale
	scaled_attack_data["knockback_y"] = float(attack_data["knockback_y"]) * knockback_scale
	scaled_attack_data["combo_hit_index"] = hit_index
	scaled_attack_data["damage_scale"] = damage_scale
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
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)
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
			return &"Kick" if randf() < 0.5 else &"Punch"
		&"Kick":
			return &"Punch"
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


func _update_visual_state() -> void:
	super._update_visual_state()
	if not debug_state_label_enabled:
		return
	if combo_count == 0 and not dev_combo_window_open and dev_buffered_attack == &"":
		return

	var buffered_text := "NONE" if dev_buffered_attack == &"" else String(dev_buffered_attack).to_upper()
	var window_text := "OPEN" if dev_combo_window_open else "CLOSED"
	state_label.text += "\nCOMBO HITS: %d\nCOMBO STEP: %d\nBUFFERED ATTACK: %s\nCOMBO WINDOW: %s\nATTACK CONNECTED: %s\nDAMAGE SCALE: %.2f" % [
		combo_count,
		dev_combo_step,
		buffered_text,
		window_text,
		str(dev_current_attack_connected).to_upper(),
		get_combo_damage_scale(),
	]
