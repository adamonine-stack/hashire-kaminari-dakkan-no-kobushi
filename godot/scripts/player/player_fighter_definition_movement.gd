extends "res://scripts/player/player_knockdown_movement.gd"

var fighter_definition: Resource
var base_max_hp := 100
var base_move_speed := 300.0
var base_jump_power := 500.0
var base_punch_damage := 5
var base_kick_damage := 8
var base_throw_damage := 15
var base_punch_knockback_x := 180.0
var base_punch_knockback_y := 160.0
var base_kick_knockback_x := 280.0
var base_kick_knockback_y := 260.0
var base_attack_cooldown_time := 0.35
var base_kick_cooldown_time := 0.5
var base_guard_damage_rate := 0.25
var base_second_hit_damage_scale := 0.90
var base_third_hit_damage_scale := 0.80
var ai_profile: Resource
var ai_decision_timer := 0.0
var ai_action_recovery_timer := 0.0
var ai_movement_timer := 0.0
var ai_movement_direction := 0.0
var last_ai_action: StringName = &""
var repeated_action_count := 0


func _ready() -> void:
	_capture_base_stats()
	super._ready()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_profile_ai(delta)


func apply_fighter_definition(definition: Resource) -> void:
	fighter_definition = definition
	if fighter_definition == null:
		_restore_base_stats()
		return

	max_hp = int(round(fighter_definition.max_health))
	move_speed = fighter_definition.move_speed
	jump_power = fighter_definition.jump_force
	punch_damage = maxi(1, int(round(float(base_punch_damage) * fighter_definition.punch_damage_scale)))
	kick_damage = maxi(1, int(round(float(base_kick_damage) * fighter_definition.kick_damage_scale)))
	throw_damage = maxi(1, int(round(float(base_throw_damage) * fighter_definition.throw_damage_scale)))
	punch_knockback_x = base_punch_knockback_x * fighter_definition.knockback_scale
	punch_knockback_y = base_punch_knockback_y * fighter_definition.knockback_scale
	kick_knockback_x = base_kick_knockback_x * fighter_definition.knockback_scale
	kick_knockback_y = base_kick_knockback_y * fighter_definition.knockback_scale
	attack_cooldown_time = base_attack_cooldown_time / maxf(fighter_definition.attack_speed_scale, 0.1)
	kick_cooldown_time = base_kick_cooldown_time / maxf(fighter_definition.attack_speed_scale, 0.1)
	guard_damage_rate = base_guard_damage_rate * fighter_definition.guard_damage_scale
	second_hit_damage_scale = base_second_hit_damage_scale * fighter_definition.combo_damage_scale
	third_hit_damage_scale = base_third_hit_damage_scale * fighter_definition.combo_damage_scale
	dev026_second_hit_damage_scale = second_hit_damage_scale
	dev026_third_hit_damage_scale = third_hit_damage_scale
	current_hp = clampi(current_hp, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)
	apply_ai_profile(fighter_definition.ai_profile)
	apply_temporary_color(fighter_definition.temporary_color)


func apply_ai_profile(profile: Resource) -> void:
	ai_profile = profile
	clear_ai_action_state()
	if ai_profile == null:
		return

	ai_throw_probability = _profile_float(&"throw_weight", ai_throw_probability)
	ai_throw_cooldown = _profile_float(&"throw_cooldown", ai_throw_cooldown)
	ai_throw_check_interval = _profile_float(&"decision_interval_min", ai_throw_check_interval)
	ai_guard_chance = _profile_float(&"guard_weight", ai_guard_chance)
	ai_guard_check_interval = _profile_float(&"decision_interval_min", ai_guard_check_interval)
	ai_guard_min_time = _profile_float(&"guard_duration_min", ai_guard_min_time)
	ai_guard_max_time = _profile_float(&"guard_duration_max", ai_guard_max_time)
	throw_escape_probability = _profile_float(&"throw_escape_probability", throw_escape_probability)
	dev026_ai_combo_continue_probability = _profile_float(&"second_hit_probability", dev026_ai_combo_continue_probability)
	dev026_ai_third_hit_probability = _profile_float(&"third_hit_probability", dev026_ai_third_hit_probability)


func apply_temporary_color(color: Color) -> void:
	if visual_root == null:
		return
	visual_root.modulate = color


func clear_ai_action_state() -> void:
	ai_decision_timer = 0.0
	ai_action_recovery_timer = 0.0
	ai_movement_timer = 0.0
	ai_movement_direction = 0.0
	last_ai_action = &""
	repeated_action_count = 0


func set_health(value: int) -> void:
	current_hp = clampi(value, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)


func get_ai_debug_lines() -> Array[String]:
	var lines: Array[String] = []
	if ai_profile == null:
		return lines

	var distance := 0.0
	var opponent := _get_opponent()
	if opponent is Node2D:
		distance = absf(global_position.x - opponent.global_position.x)

	lines.append("AI ACTION: %s" % _debug_ai_action_text())
	lines.append("AI TARGET DISTANCE: %.0f" % distance)
	lines.append("AI DECISION TIMER: %.2f" % ai_decision_timer)
	lines.append("PUNCH WEIGHT: %.2f" % _profile_float(&"punch_weight", 0.0))
	lines.append("KICK WEIGHT: %.2f" % _profile_float(&"kick_weight", 0.0))
	lines.append("THROW WEIGHT: %.2f" % _profile_float(&"throw_weight", 0.0))
	lines.append("GUARD WEIGHT: %.2f" % _profile_float(&"guard_weight", 0.0))
	lines.append("MOVE WEIGHT: %.2f" % _profile_float(&"movement_weight", 0.0))
	lines.append("COMBO 2ND: %d%%" % int(round(_profile_float(&"second_hit_probability", 0.0) * 100.0)))
	lines.append("COMBO 3RD: %d%%" % int(round(_profile_float(&"third_hit_probability", 0.0) * 100.0)))
	lines.append("THROW ESCAPE: %d%%" % int(round(_profile_float(&"throw_escape_probability", 0.0) * 100.0)))
	return lines


func _capture_base_stats() -> void:
	base_max_hp = max_hp
	base_move_speed = move_speed
	base_jump_power = jump_power
	base_punch_damage = punch_damage
	base_kick_damage = kick_damage
	base_throw_damage = throw_damage
	base_punch_knockback_x = punch_knockback_x
	base_punch_knockback_y = punch_knockback_y
	base_kick_knockback_x = kick_knockback_x
	base_kick_knockback_y = kick_knockback_y
	base_attack_cooldown_time = attack_cooldown_time
	base_kick_cooldown_time = kick_cooldown_time
	base_guard_damage_rate = guard_damage_rate
	base_second_hit_damage_scale = second_hit_damage_scale
	base_third_hit_damage_scale = third_hit_damage_scale


func _restore_base_stats() -> void:
	max_hp = base_max_hp
	move_speed = base_move_speed
	jump_power = base_jump_power
	punch_damage = base_punch_damage
	kick_damage = base_kick_damage
	throw_damage = base_throw_damage
	punch_knockback_x = base_punch_knockback_x
	punch_knockback_y = base_punch_knockback_y
	kick_knockback_x = base_kick_knockback_x
	kick_knockback_y = base_kick_knockback_y
	attack_cooldown_time = base_attack_cooldown_time
	kick_cooldown_time = base_kick_cooldown_time
	guard_damage_rate = base_guard_damage_rate
	second_hit_damage_scale = base_second_hit_damage_scale
	third_hit_damage_scale = base_third_hit_damage_scale
	dev026_second_hit_damage_scale = base_second_hit_damage_scale
	dev026_third_hit_damage_scale = base_third_hit_damage_scale
	apply_temporary_color(Color.WHITE)
	clear_ai_action_state()


func _update_profile_ai(delta: float) -> void:
	if ai_profile == null or name != "Enemy" or input_enabled:
		return
	if not is_round_active or current_hp <= 0:
		clear_ai_action_state()
		return

	_update_profile_ai_movement(delta)

	ai_action_recovery_timer = maxf(ai_action_recovery_timer - delta, 0.0)
	ai_decision_timer = maxf(ai_decision_timer - delta, 0.0)
	if ai_action_recovery_timer > 0.0 or ai_decision_timer > 0.0:
		return
	if not _can_choose_profile_ai_action():
		return

	var action := choose_ai_action()
	ai_decision_timer = randf_range(
		_profile_float(&"decision_interval_min", 0.35),
		_profile_float(&"decision_interval_max", 0.75)
	)
	if action == &"":
		return

	_register_ai_action(action)
	match action:
		&"punch":
			_dev_start_attack()
			_start_ai_recovery()
		&"kick":
			_dev_start_kick()
			_start_ai_recovery()
		&"throw":
			if can_choose_throw():
				_start_throw()
				ai_throw_cooldown_timer = ai_throw_cooldown
				_start_ai_recovery()
		&"guard":
			if can_choose_guard():
				is_guarding = true
				is_crouch_guarding = false
				guard_type = "stand"
				ai_guard_timer = randf_range(ai_guard_min_time, ai_guard_max_time)
				_start_ai_recovery()
		&"movement":
			_start_ai_movement()


func choose_ai_action() -> StringName:
	var weights := get_distance_based_weights()
	return select_weighted_action(weights)


func get_distance_based_weights() -> Dictionary:
	var weights := {
		&"punch": _profile_float(&"punch_weight", 0.0),
		&"kick": _profile_float(&"kick_weight", 0.0),
		&"throw": _profile_float(&"throw_weight", 0.0),
		&"guard": _profile_float(&"guard_weight", 0.0),
		&"movement": _profile_float(&"movement_weight", 0.0),
	}

	var opponent := _get_opponent()
	if not (opponent is Node2D):
		return {&"movement": 1.0}

	var distance := absf(global_position.x - opponent.global_position.x)
	var preferred_min := _profile_float(&"preferred_distance_min", 45.0)
	var preferred_max := _profile_float(&"preferred_distance_max", 110.0)
	if distance > preferred_max:
		weights[&"punch"] = 0.0
		weights[&"kick"] = 0.0
		weights[&"throw"] = 0.0
		weights[&"movement"] = maxf(float(weights[&"movement"]), 0.65)
	elif distance < preferred_min:
		weights[&"movement"] = maxf(float(weights[&"movement"]), 0.35)

	if not can_choose_throw():
		weights[&"throw"] = 0.0
	if not can_choose_guard():
		weights[&"guard"] = 0.0

	if repeated_action_count >= 2 and weights.has(last_ai_action):
		weights[last_ai_action] = float(weights[last_ai_action]) * 0.25
	return weights


func select_weighted_action(action_weights: Dictionary) -> StringName:
	var total_weight := 0.0
	for action in action_weights:
		total_weight += maxf(float(action_weights[action]), 0.0)
	if total_weight <= 0.0:
		return &"movement"

	var roll := randf() * total_weight
	for action in action_weights:
		roll -= maxf(float(action_weights[action]), 0.0)
		if roll <= 0.0:
			return StringName(action)
	return &"movement"


func can_choose_throw() -> bool:
	return _can_choose_profile_ai_action() and _get_throw_target() != null and ai_throw_cooldown_timer <= 0.0


func can_choose_guard() -> bool:
	return _can_start_guard_or_crouch() and not is_guarding and not is_crouch_guarding


func update_enemy_target(_target: Node) -> void:
	clear_ai_action_state()


func _can_choose_profile_ai_action() -> bool:
	if not is_on_floor() or is_hit or is_guard_hit or is_guarding or is_crouching or is_crouch_guarding:
		return false
	if current_attack_type != "" or attack_active_timer > 0.0 or kick_active_timer > 0.0:
		return false
	if _is_throw_busy():
		return false
	if has_method("_is_knockdown_busy") and _is_knockdown_busy():
		return false
	return true


func _start_ai_movement() -> void:
	var opponent := _get_opponent()
	if not (opponent is Node2D):
		return
	var distance := absf(global_position.x - opponent.global_position.x)
	var preferred_min := _profile_float(&"preferred_distance_min", 45.0)
	var preferred_max := _profile_float(&"preferred_distance_max", 110.0)
	var toward := signf(opponent.global_position.x - global_position.x)
	if toward == 0.0:
		toward = -facing_direction

	if distance > preferred_max:
		ai_movement_direction = toward
	elif distance < preferred_min:
		ai_movement_direction = -toward
	else:
		ai_movement_direction = -toward if randf() < 0.4 else toward
	ai_movement_timer = randf_range(0.15, 0.40)
	_start_ai_recovery()


func _update_profile_ai_movement(delta: float) -> void:
	if ai_movement_timer <= 0.0:
		return
	if is_hit or is_guard_hit or _is_throw_busy() or current_attack_type != "":
		ai_movement_timer = 0.0
		return
	ai_movement_timer = maxf(ai_movement_timer - delta, 0.0)
	if ai_movement_direction == 0.0:
		return

	position.x += ai_movement_direction * move_speed * 0.45 * delta
	facing_direction = signf(ai_movement_direction)
	visual_root.scale.x = facing_direction
	_clamp_to_screen()


func _start_ai_recovery() -> void:
	ai_action_recovery_timer = randf_range(
		_profile_float(&"action_recovery_min", 0.15),
		_profile_float(&"action_recovery_max", 0.45)
	)


func _register_ai_action(action: StringName) -> void:
	if action == last_ai_action:
		repeated_action_count += 1
	else:
		last_ai_action = action
		repeated_action_count = 1


func _profile_float(property_name: StringName, fallback: float) -> float:
	if ai_profile == null:
		return fallback
	var value = ai_profile.get(String(property_name))
	if value == null:
		return fallback
	return float(value)


func _debug_ai_action_text() -> String:
	if ai_movement_timer > 0.0:
		return "MOVEMENT"
	if is_guarding:
		return "GUARD"
	if current_attack_type != "":
		return String(current_attack_type).to_upper()
	if _is_throw_busy():
		return "THROW"
	if last_ai_action != &"":
		return String(last_ai_action).to_upper()
	return "WAIT"
