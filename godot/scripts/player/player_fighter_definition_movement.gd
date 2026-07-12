extends "res://scripts/player/player_knockdown_movement.gd"

signal ai_state_changed(previous_state, new_state)
signal ai_action_started(action_name)
signal ai_action_finished(action_name)
signal enemy_attack_requested(attack_type)
signal enemy_guard_requested
signal enemy_retreat_started
signal enemy_feint_started
signal special_attack_requested(enemy)

enum EnemyAIState {
	DISABLED,
	IDLE,
	APPROACH,
	ATTACK,
	GUARD,
	RETREAT,
	FEINT,
	HITSTUN,
	KNOCKBACK,
	DOWN,
	KO,
	SPECIAL_ATTACK_REQUEST,
}

var fighter_definition: Resource
var base_max_hp := 100
var base_move_speed := 300.0
var base_air_move_speed := 300.0
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
var base_punch_startup_multiplier := 1.0
var base_kick_startup_multiplier := 1.0
var base_punch_recovery_multiplier := 1.0
var base_kick_recovery_multiplier := 1.0
var base_guard_stamina_multiplier := 1.0
var base_attack_knockback_multiplier := 1.0
var base_received_knockback_multiplier := 1.0
var base_second_hit_damage_scale := 0.90
var base_third_hit_damage_scale := 0.80
var ai_profile: Resource
var ai_decision_timer := 0.0
var ai_action_recovery_timer := 0.0
var ai_movement_timer := 0.0
var ai_movement_direction := 0.0
var last_ai_action: StringName = &""
var repeated_action_count := 0
var ai_state := EnemyAIState.DISABLED
var ai_enabled := false
var ai_reaction_timer := 0.0
var ai_idle_timer := 0.0
var ai_attack_cooldown_timer := 0.0
var ai_retreat_timer := 0.0
var ai_feint_timer := 0.0
var ai_feint_phase: StringName = &""
var ai_feint_cooldown_timer := 0.0
var ai_guard_minimum_timer := 0.0
var ai_current_target_distance := 60.0
var ai_selected_attack_type := ""
var ai_special_request_cooldown_timer := 0.0
var ai_has_pending_action := false
var show_ai_debug := false


func _ready() -> void:
	_capture_base_stats()
	super._ready()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_profile_ai(delta)


func apply_fighter_definition(definition: Resource) -> void:
	apply_character_data(definition)


func apply_character_data(data: Resource) -> void:
	fighter_definition = data
	if not validate_character_data(fighter_definition):
		_restore_base_stats()
		return

	apply_movement_stats()
	apply_attack_stats()
	apply_attack_sequence_stats()
	apply_guard_stats()
	apply_knockback_stats()
	second_hit_damage_scale = base_second_hit_damage_scale * float(fighter_definition.combo_damage_scale)
	third_hit_damage_scale = base_third_hit_damage_scale * float(fighter_definition.combo_damage_scale)
	dev026_second_hit_damage_scale = second_hit_damage_scale
	dev026_third_hit_damage_scale = third_hit_damage_scale
	current_hp = clampi(current_hp, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)
	apply_ai_profile(fighter_definition.ai_profile)
	apply_temporary_color(fighter_definition.temporary_color)
	update_character_status_ui()


func validate_character_data(data: Resource) -> bool:
	if data == null:
		push_warning("[DEV035] Character data missing. Restoring base stats.")
		return false
	if String(data.fighter_id).is_empty() or String(data.display_name).is_empty():
		push_warning("[DEV035] Character data has empty id or display name.")
		return false
	if float(data.max_health) <= 0.0 or float(data.move_speed) <= 0.0 or float(data.jump_force) <= 0.0:
		push_warning("[DEV035] Character data has invalid movement or HP values: %s" % String(data.fighter_id))
		return false
	return true


func apply_movement_stats() -> void:
	max_hp = int(round(float(fighter_definition.max_health)))
	move_speed = float(fighter_definition.move_speed)
	air_move_speed = _definition_float("air_move_speed", move_speed) if _uses_direct_character_stats() else move_speed
	jump_power = absf(float(fighter_definition.jump_force))


func apply_attack_stats() -> void:
	var direct_punch_damage := _definition_float("punch_damage", 0.0)
	var direct_kick_damage := _definition_float("kick_damage", 0.0)
	punch_damage = maxi(1, int(round(direct_punch_damage))) if _uses_direct_character_stats() and direct_punch_damage > 0.0 else maxi(1, int(round(float(base_punch_damage) * fighter_definition.punch_damage_scale)))
	kick_damage = maxi(1, int(round(direct_kick_damage))) if _uses_direct_character_stats() and direct_kick_damage > 0.0 else maxi(1, int(round(float(base_kick_damage) * fighter_definition.kick_damage_scale)))
	throw_damage = maxi(1, int(round(float(base_throw_damage) * fighter_definition.throw_damage_scale)))
	if _uses_direct_character_stats():
		punch_startup_multiplier = maxf(_definition_float("punch_startup_multiplier", base_punch_startup_multiplier), 0.01)
		kick_startup_multiplier = maxf(_definition_float("kick_startup_multiplier", base_kick_startup_multiplier), 0.01)
		punch_recovery_multiplier = maxf(_definition_float("punch_recovery_multiplier", base_punch_recovery_multiplier), 0.01)
		kick_recovery_multiplier = maxf(_definition_float("kick_recovery_multiplier", base_kick_recovery_multiplier), 0.01)
	else:
		var legacy_recovery_multiplier := 1.0 / maxf(float(fighter_definition.attack_speed_scale), 0.1)
		punch_startup_multiplier = base_punch_startup_multiplier
		kick_startup_multiplier = base_kick_startup_multiplier
		punch_recovery_multiplier = legacy_recovery_multiplier
		kick_recovery_multiplier = legacy_recovery_multiplier


func apply_attack_sequence_stats() -> void:
	if has_method("apply_attack_sequence") and not fighter_definition.attack_sequence.is_empty():
		apply_attack_sequence(fighter_definition.attack_sequence)
		dev026_max_combo_hits = int(fighter_definition.max_attack_chain_count) if int(fighter_definition.max_attack_chain_count) > 0 else fighter_definition.attack_sequence.size()


func apply_guard_stats() -> void:
	if _uses_direct_character_stats():
		guard_damage_rate = _definition_float("guard_damage_multiplier", base_guard_damage_rate)
		guard_stamina_multiplier = _definition_float("guard_stamina_multiplier", base_guard_stamina_multiplier)
	else:
		guard_damage_rate = base_guard_damage_rate * float(fighter_definition.guard_damage_scale)
		guard_stamina_multiplier = base_guard_stamina_multiplier


func apply_knockback_stats() -> void:
	if _uses_direct_character_stats():
		attack_knockback_multiplier = _definition_float("attack_knockback_multiplier", base_attack_knockback_multiplier)
		received_knockback_multiplier = _definition_float("received_knockback_multiplier", base_received_knockback_multiplier)
	else:
		attack_knockback_multiplier = float(fighter_definition.knockback_scale)
		received_knockback_multiplier = base_received_knockback_multiplier
	punch_knockback_x = base_punch_knockback_x
	punch_knockback_y = base_punch_knockback_y
	kick_knockback_x = base_kick_knockback_x
	kick_knockback_y = base_kick_knockback_y


func update_character_status_ui() -> void:
	print("[DEV035] Character data loaded: %s" % String(fighter_definition.fighter_id))
	print("[DEV035] Type: %s" % _display_type_text())
	print("[DEV035] HP: %d" % max_hp)
	print("[DEV035] Move speed: %d" % int(round(move_speed)))
	print("[DEV035] Punch damage: %d" % punch_damage)
	print("[DEV035] Kick damage: %d" % kick_damage)


func update_character_select_stats() -> void:
	update_character_status_ui()


func reset_character_stats() -> void:
	_restore_base_stats()


func apply_ai_profile(profile: Resource) -> void:
	ai_profile = profile
	reset_ai_state()
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
	if _profile_bool(&"can_combo", false):
		dev026_ai_combo_continue_probability = _profile_float(&"combo_rate", dev026_ai_combo_continue_probability)
		dev026_ai_third_hit_probability = _profile_float(&"combo_rate", dev026_ai_third_hit_probability) * 0.65
	show_ai_debug = _profile_bool(&"show_ai_debug", show_ai_debug)


func apply_temporary_color(color: Color) -> void:
	if visual_root == null:
		return
	visual_root.modulate = color


func clear_ai_action_state() -> void:
	reset_ai_state()


func reset_ai_state() -> void:
	ai_decision_timer = 0.0
	ai_action_recovery_timer = 0.0
	ai_movement_timer = 0.0
	ai_movement_direction = 0.0
	last_ai_action = &""
	repeated_action_count = 0
	ai_enabled = false
	ai_reaction_timer = 0.0
	ai_idle_timer = 0.0
	ai_attack_cooldown_timer = 0.0
	ai_retreat_timer = 0.0
	ai_feint_timer = 0.0
	ai_feint_phase = &""
	ai_feint_cooldown_timer = 0.0
	ai_guard_minimum_timer = 0.0
	ai_current_target_distance = _randomized_preferred_distance()
	ai_selected_attack_type = ""
	ai_special_request_cooldown_timer = 0.0
	ai_has_pending_action = false
	_clear_guard_state()
	_set_ai_state(EnemyAIState.DISABLED)


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

	lines.append("AI STATE: %s" % _debug_ai_action_text())
	lines.append("AI DISTANCE: %.0f" % distance)
	lines.append("AI TARGET DISTANCE: %.0f" % ai_current_target_distance)
	lines.append("AI REACTION: %.2f" % ai_reaction_timer)
	lines.append("AI COOLDOWN: %.2f" % ai_attack_cooldown_timer)
	lines.append("SELECTED ATTACK: %s" % ("NONE" if ai_selected_attack_type.is_empty() else ai_selected_attack_type.to_upper()))
	lines.append("AGGRESSION: %.2f" % _profile_float(&"aggression_rate", 0.0))
	lines.append("GUARD RATE: %.2f" % _profile_float(&"guard_rate", 0.0))
	lines.append("RETREAT RATE: %.2f" % _profile_float(&"retreat_rate", 0.0))
	lines.append("COMBO RATE: %d%%" % int(round(_profile_float(&"combo_rate", 0.0) * 100.0)))
	lines.append("THROW ESCAPE: %d%%" % int(round(_profile_float(&"throw_escape_probability", 0.0) * 100.0)))
	return lines


func _capture_base_stats() -> void:
	base_max_hp = max_hp
	base_move_speed = move_speed
	base_air_move_speed = air_move_speed
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
	base_punch_startup_multiplier = punch_startup_multiplier
	base_kick_startup_multiplier = kick_startup_multiplier
	base_punch_recovery_multiplier = punch_recovery_multiplier
	base_kick_recovery_multiplier = kick_recovery_multiplier
	base_guard_stamina_multiplier = guard_stamina_multiplier
	base_attack_knockback_multiplier = attack_knockback_multiplier
	base_received_knockback_multiplier = received_knockback_multiplier
	base_second_hit_damage_scale = second_hit_damage_scale
	base_third_hit_damage_scale = third_hit_damage_scale


func _restore_base_stats() -> void:
	max_hp = base_max_hp
	move_speed = base_move_speed
	air_move_speed = base_air_move_speed
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
	punch_startup_multiplier = base_punch_startup_multiplier
	kick_startup_multiplier = base_kick_startup_multiplier
	punch_recovery_multiplier = base_punch_recovery_multiplier
	kick_recovery_multiplier = base_kick_recovery_multiplier
	guard_stamina_multiplier = base_guard_stamina_multiplier
	attack_knockback_multiplier = base_attack_knockback_multiplier
	received_knockback_multiplier = base_received_knockback_multiplier
	second_hit_damage_scale = base_second_hit_damage_scale
	third_hit_damage_scale = base_third_hit_damage_scale
	dev026_second_hit_damage_scale = base_second_hit_damage_scale
	dev026_third_hit_damage_scale = base_third_hit_damage_scale
	apply_temporary_color(Color.WHITE)
	clear_ai_action_state()


func _definition_float(property_name: String, fallback: float) -> float:
	if fighter_definition == null:
		return fallback
	var value = fighter_definition.get(property_name)
	if value == null:
		return fallback
	return float(value)


func _uses_direct_character_stats() -> bool:
	return fighter_definition != null and fighter_definition.team_type == &"ALLY"


func _display_type_text() -> String:
	if fighter_definition == null:
		return ""
	var type_text := String(fighter_definition.fighter_type)
	if type_text.is_empty():
		return ""
	return type_text.capitalize()


func _update_profile_ai(delta: float) -> void:
	if ai_profile == null or name != "Enemy" or input_enabled:
		return
	if hit_stop_timer > 0.0:
		return
	if not is_round_active or current_hp <= 0 or _get_opponent() == null:
		disable_ai()
		return
	enable_ai()
	update_ai(delta)


func enable_ai() -> void:
	if ai_enabled:
		return
	ai_enabled = true
	ai_current_target_distance = _randomized_preferred_distance()
	enter_idle()


func disable_ai() -> void:
	if not ai_enabled and ai_state == EnemyAIState.DISABLED:
		return
	cancel_current_ai_action()
	ai_enabled = false
	_set_ai_state(EnemyAIState.DISABLED)


func can_ai_act() -> bool:
	if not ai_enabled or ai_profile == null:
		return false
	if not is_round_active or current_hp <= 0:
		return false
	if input_enabled or name != "Enemy":
		return false
	if _get_opponent() == null:
		return false
	if hit_stop_timer > 0.0 or is_hit or is_guard_hit:
		return false
	if _is_throw_busy() or _is_knockdown_busy():
		return false
	if current_attack_type != "" or attack_active_timer > 0.0 or kick_active_timer > 0.0:
		return false
	return true


func update_ai(delta: float) -> void:
	if _sync_ai_locked_state():
		return

	ai_attack_cooldown_timer = maxf(ai_attack_cooldown_timer - delta, 0.0)
	ai_feint_cooldown_timer = maxf(ai_feint_cooldown_timer - delta, 0.0)
	ai_special_request_cooldown_timer = maxf(ai_special_request_cooldown_timer - delta, 0.0)
	ai_reaction_timer = maxf(ai_reaction_timer - delta, 0.0)
	if ai_reaction_timer > 0.0:
		return

	match ai_state:
		EnemyAIState.IDLE:
			_update_idle(delta)
		EnemyAIState.APPROACH:
			update_approach(delta)
		EnemyAIState.GUARD:
			_update_ai_guard_state(delta)
		EnemyAIState.RETREAT:
			update_retreat(delta)
		EnemyAIState.FEINT:
			update_feint(delta)
		EnemyAIState.ATTACK:
			_update_attack_wait()
		EnemyAIState.SPECIAL_ATTACK_REQUEST:
			_update_special_request()
		_:
			enter_idle()


func can_choose_guard() -> bool:
	return _can_start_guard_or_crouch() and not is_guarding and not is_crouch_guarding


func update_enemy_target(_target: Node) -> void:
	reset_ai_state()


func _profile_float(property_name: StringName, fallback: float) -> float:
	if ai_profile == null:
		return fallback
	var value = ai_profile.get(String(property_name))
	if value == null:
		return fallback
	return float(value)


func _profile_bool(property_name: StringName, fallback: bool) -> bool:
	if ai_profile == null:
		return fallback
	var value = ai_profile.get(String(property_name))
	if value == null:
		return fallback
	return bool(value)


func _debug_ai_action_text() -> String:
	return EnemyAIState.keys()[ai_state]


func evaluate_distance() -> float:
	var opponent := _get_opponent()
	if not (opponent is Node2D):
		return 999999.0
	return absf(opponent.global_position.x - global_position.x)


func choose_next_action() -> void:
	if not can_ai_act():
		return
	var distance := evaluate_distance()
	if distance > _profile_float(&"attack_distance", 55.0):
		enter_approach()
		return
	if distance < _profile_float(&"retreat_distance", 35.0) and should_retreat():
		enter_retreat()
		return
	if should_guard_against_player():
		enter_guard()
		return
	if should_use_feint():
		enter_feint()
		return
	if should_request_special_attack():
		request_special_attack()
		return
	if should_attack_player():
		enter_attack()
		return
	if should_retreat():
		enter_retreat()
		return
	enter_idle()


func enter_idle() -> void:
	cancel_current_ai_action(false)
	_set_ai_state(EnemyAIState.IDLE)
	ai_idle_timer = randf_range(_profile_float(&"idle_time_min", 0.25), _profile_float(&"idle_time_max", 0.65))
	ai_reaction_timer = randf_range(_profile_float(&"reaction_time_min", 0.20), _profile_float(&"reaction_time_max", 0.45))
	ai_current_target_distance = _randomized_preferred_distance()


func enter_approach() -> void:
	if not can_ai_act():
		return
	_set_ai_state(EnemyAIState.APPROACH)
	ai_action_started.emit("approach")


func enter_attack() -> void:
	if not can_ai_act() or ai_attack_cooldown_timer > 0.0:
		enter_idle()
		return
	ai_selected_attack_type = choose_attack_type()
	if ai_selected_attack_type.is_empty():
		enter_idle()
		return
	_set_ai_state(EnemyAIState.ATTACK)
	_face_opponent()
	enemy_attack_requested.emit(ai_selected_attack_type)
	ai_action_started.emit(ai_selected_attack_type)
	if not request_existing_attack(ai_selected_attack_type):
		enter_idle()
		return
	ai_attack_cooldown_timer = randf_range(_profile_float(&"attack_cooldown_min", 0.30), _profile_float(&"attack_cooldown_max", 0.60))
	_register_ai_action(StringName(ai_selected_attack_type))
	print("[DEV037][%s] Attack selected: %s" % [_debug_enemy_id(), ai_selected_attack_type])


func enter_guard() -> void:
	if not can_choose_guard():
		enter_idle()
		return
	_set_ai_state(EnemyAIState.GUARD)
	is_guarding = true
	is_crouch_guarding = false
	is_crouching = false
	guard_type = "stand"
	ai_guard_timer = randf_range(_profile_float(&"guard_time_min", 0.30), _profile_float(&"guard_time_max", 0.75))
	ai_guard_minimum_timer = minf(ai_guard_timer, 0.20)
	_face_opponent()
	enemy_guard_requested.emit()
	ai_action_started.emit("guard")
	_register_ai_action(&"guard")


func enter_retreat() -> void:
	if not can_ai_act() or not _profile_bool(&"can_retreat", true):
		enter_idle()
		return
	_set_ai_state(EnemyAIState.RETREAT)
	ai_retreat_timer = randf_range(_profile_float(&"retreat_time_min", 0.35), _profile_float(&"retreat_time_max", 0.80))
	enemy_retreat_started.emit()
	ai_action_started.emit("retreat")
	_register_ai_action(&"retreat")


func enter_feint() -> void:
	if not can_ai_act() or not _profile_bool(&"can_feint", false) or ai_feint_cooldown_timer > 0.0:
		enter_idle()
		return
	_set_ai_state(EnemyAIState.FEINT)
	ai_feint_phase = &"back"
	ai_feint_timer = randf_range(0.20, 0.35)
	ai_feint_cooldown_timer = randf_range(_profile_float(&"feint_cooldown_min", 2.0), _profile_float(&"feint_cooldown_max", 4.0))
	enemy_feint_started.emit()
	ai_action_started.emit("feint")
	_register_ai_action(&"feint")
	print("[DEV037][%s] FEINT started" % _debug_enemy_id())


func update_approach(delta: float) -> void:
	if not can_ai_act():
		return
	var opponent := _get_opponent()
	if not (opponent is Node2D):
		disable_ai()
		return
	var distance := evaluate_distance()
	if distance <= _profile_float(&"attack_distance", 55.0) or distance <= ai_current_target_distance:
		choose_next_action()
		return
	_face_opponent()
	var direction := signf(opponent.global_position.x - global_position.x)
	_move_ai(direction, _profile_float(&"approach_speed_multiplier", 1.0), delta)


func update_retreat(delta: float) -> void:
	if not can_ai_act():
		return
	var opponent := _get_opponent()
	if not (opponent is Node2D):
		disable_ai()
		return
	ai_retreat_timer = maxf(ai_retreat_timer - delta, 0.0)
	var direction := -signf(opponent.global_position.x - global_position.x)
	if direction == 0.0:
		direction = -facing_direction
	_move_ai(direction, _profile_float(&"retreat_speed_multiplier", 0.9), delta)
	if ai_retreat_timer == 0.0:
		ai_action_finished.emit("retreat")
		enter_idle()


func update_feint(delta: float) -> void:
	if not can_ai_act():
		return
	var opponent := _get_opponent()
	if not (opponent is Node2D):
		disable_ai()
		return
	ai_feint_timer = maxf(ai_feint_timer - delta, 0.0)
	match ai_feint_phase:
		&"back":
			var back_direction := -signf(opponent.global_position.x - global_position.x)
			if back_direction == 0.0:
				back_direction = -facing_direction
			_move_ai(back_direction, _profile_float(&"retreat_speed_multiplier", 1.0), delta)
			if ai_feint_timer == 0.0:
				ai_feint_phase = &"pause"
				ai_feint_timer = randf_range(0.10, 0.20)
		&"pause":
			if ai_feint_timer == 0.0:
				ai_feint_phase = &"reapproach"
				ai_feint_timer = 0.80
				print("[DEV037][%s] FEINT -> APPROACH" % _debug_enemy_id())
		&"reapproach":
			var distance := evaluate_distance()
			if distance <= _profile_float(&"attack_distance", 55.0):
				print("[DEV037][%s] FEINT attack requested" % _debug_enemy_id())
				enter_attack()
				return
			var toward := signf(opponent.global_position.x - global_position.x)
			_move_ai(toward, _profile_float(&"approach_speed_multiplier", 1.0), delta)
			if ai_feint_timer == 0.0:
				enter_approach()


func should_guard_against_player() -> bool:
	if not _profile_bool(&"can_guard", true) or not can_choose_guard():
		return false
	var opponent := _get_opponent()
	if not _is_player_attack_threatening(opponent):
		return false
	if randf() > _profile_float(&"guard_rate", _profile_float(&"guard_weight", 0.15)):
		return false
	print("[DEV037][%s] Guard selected" % _debug_enemy_id())
	return true


func should_attack_player() -> bool:
	if ai_attack_cooldown_timer > 0.0 or evaluate_distance() > _profile_float(&"attack_distance", 55.0):
		return false
	return randf() <= _profile_float(&"aggression_rate", 0.60)


func should_retreat() -> bool:
	if not _profile_bool(&"can_retreat", true):
		return false
	return randf() <= _profile_float(&"retreat_rate", 0.20)


func should_use_feint() -> bool:
	if not _profile_bool(&"can_feint", false) or ai_feint_cooldown_timer > 0.0:
		return false
	return randf() <= _profile_float(&"feint_rate", 0.0)


func should_request_special_attack() -> bool:
	if not _profile_bool(&"can_request_special_attack", false) or ai_special_request_cooldown_timer > 0.0:
		return false
	return randf() <= _profile_float(&"special_attack_rate", 0.0)


func choose_attack_type() -> String:
	if _profile_bool(&"can_combo", false) and randf() <= _profile_float(&"combo_rate", 0.20):
		if not get_next_attack_id("punch").is_empty():
			return "punch"
	var punch_score := _profile_float(&"punch_weight", 0.40)
	var kick_score := _profile_float(&"kick_weight", 0.25)
	var total := maxf(punch_score + kick_score, 0.01)
	return "kick" if randf() <= kick_score / total else "punch"


func request_existing_attack(attack_type: String) -> bool:
	if not can_ai_act():
		return false
	match attack_type:
		"kick":
			_dev_start_kick()
		_:
			_dev_start_attack()
	return current_attack_type != ""


func request_special_attack() -> bool:
	_set_ai_state(EnemyAIState.SPECIAL_ATTACK_REQUEST)
	special_attack_requested.emit(self)
	print("[DEV037][%s] Special attack requested" % _debug_enemy_id())
	ai_special_request_cooldown_timer = 2.0
	if has_method("perform_special_attack"):
		var result: bool = bool(call("perform_special_attack"))
		if result:
			return true
	print("[DEV037][%s] Special attack unavailable" % _debug_enemy_id())
	print("[DEV037][%s] Fallback to normal attack" % _debug_enemy_id())
	enter_attack()
	return false


func cancel_current_ai_action(clear_guard := true) -> void:
	ai_movement_timer = 0.0
	ai_movement_direction = 0.0
	ai_idle_timer = 0.0
	ai_retreat_timer = 0.0
	ai_feint_timer = 0.0
	ai_feint_phase = &""
	ai_has_pending_action = false
	ai_selected_attack_type = ""
	if clear_guard:
		_clear_guard_state()
		ai_guard_timer = 0.0
		ai_guard_minimum_timer = 0.0


func clear_ai_timers() -> void:
	ai_reaction_timer = 0.0
	ai_idle_timer = 0.0
	ai_attack_cooldown_timer = 0.0
	ai_retreat_timer = 0.0
	ai_feint_timer = 0.0
	ai_guard_timer = 0.0
	ai_guard_minimum_timer = 0.0


func set_ai_debug_state(state_name: String) -> void:
	if debug_state_label_enabled and state_label != null:
		state_label.text = state_name


func _update_idle(delta: float) -> void:
	ai_idle_timer = maxf(ai_idle_timer - delta, 0.0)
	if ai_idle_timer > 0.0:
		return
	choose_next_action()


func _update_ai_guard_state(delta: float) -> void:
	if not can_choose_guard() and not is_guarding:
		enter_idle()
		return
	ai_guard_timer = maxf(ai_guard_timer - delta, 0.0)
	ai_guard_minimum_timer = maxf(ai_guard_minimum_timer - delta, 0.0)
	is_guarding = true
	is_crouch_guarding = false
	is_crouching = false
	guard_type = "stand"
	if ai_guard_timer == 0.0 and ai_guard_minimum_timer == 0.0:
		_clear_guard_state()
		ai_action_finished.emit("guard")
		enter_idle()


func _update_attack_wait() -> void:
	if current_attack_type != "" or attack_active_timer > 0.0 or kick_active_timer > 0.0:
		return
	ai_action_finished.emit(ai_selected_attack_type)
	if should_retreat():
		enter_retreat()
	else:
		enter_idle()


func _update_special_request() -> void:
	if current_attack_type == "":
		enter_idle()


func _sync_ai_locked_state() -> bool:
	if current_hp <= 0:
		cancel_current_ai_action()
		_set_ai_state(EnemyAIState.KO)
		return true
	if _is_knockdown_busy():
		cancel_current_ai_action()
		if knockdown_state == &"KNOCKBACK":
			_set_ai_state(EnemyAIState.KNOCKBACK)
		else:
			_set_ai_state(EnemyAIState.DOWN)
		return true
	if is_hit or is_guard_hit:
		cancel_current_ai_action(not is_guard_hit)
		_set_ai_state(EnemyAIState.HITSTUN)
		return true
	return false


func _move_ai(direction: float, speed_multiplier: float, delta: float) -> void:
	if direction == 0.0:
		return
	position.x += direction * move_speed * _profile_float(&"ai_move_speed_multiplier", 1.0) * speed_multiplier * delta
	_clamp_to_screen()


func _set_ai_state(next_state: int) -> void:
	if ai_state == next_state:
		return
	var previous := ai_state
	ai_state = next_state
	ai_state_changed.emit(EnemyAIState.keys()[previous], EnemyAIState.keys()[next_state])
	if show_ai_debug:
		print("[DEV037][%s] %s -> %s" % [_debug_enemy_id(), EnemyAIState.keys()[previous], EnemyAIState.keys()[next_state]])


func _randomized_preferred_distance() -> float:
	return _profile_float(&"preferred_distance", 60.0) + randf_range(
		-_profile_float(&"distance_random_range", 8.0),
		_profile_float(&"distance_random_range", 8.0)
	)


func _is_player_attack_threatening(opponent: Node) -> bool:
	if not (opponent is Node2D):
		return false
	var opponent_attack_type := String(opponent.get("current_attack_type"))
	if opponent_attack_type.is_empty():
		return false
	var direction_to_enemy := signf(global_position.x - opponent.global_position.x)
	if direction_to_enemy != 0.0 and signf(float(opponent.get("facing_direction"))) != direction_to_enemy:
		return false
	var distance := evaluate_distance()
	var estimated_range := 70.0
	var attack_data = opponent.get("current_attack_data")
	if attack_data != null:
		estimated_range = absf(float(attack_data.hitbox_offset.x)) + (float(attack_data.hitbox_size.x) * 0.5)
	return distance <= estimated_range + 20.0


func _register_ai_action(action: StringName) -> void:
	if action == last_ai_action:
		repeated_action_count += 1
	else:
		last_ai_action = action
		repeated_action_count = 1


func _uses_ai_guard() -> bool:
	if ai_profile != null and name == "Enemy" and not input_enabled:
		return false
	return ai_guard_enabled and name == "Enemy" and is_round_active and not input_enabled and not is_hit and not is_guard_hit and not _is_throw_busy()


func _update_ai_throw(delta: float) -> void:
	if ai_profile != null and name == "Enemy" and not input_enabled:
		return
	if name != "Enemy" or input_enabled:
		return

	ai_throw_cooldown_timer = maxf(ai_throw_cooldown_timer - delta, 0.0)
	ai_throw_check_timer = maxf(ai_throw_check_timer - delta, 0.0)
	if ai_throw_check_timer > 0.0:
		return

	ai_throw_check_timer = ai_throw_check_interval
	if ai_throw_cooldown_timer > 0.0:
		return
	if not _can_start_throw() or is_guarding:
		return
	if _get_throw_target() == null:
		return
	if randf() > ai_throw_probability:
		return

	ai_throw_cooldown_timer = ai_throw_cooldown
	_face_opponent()
	_start_throw()


func _debug_enemy_id() -> String:
	if fighter_definition != null and not String(fighter_definition.fighter_id).is_empty():
		return String(fighter_definition.fighter_id)
	return name


func _update_visual_state() -> void:
	super._update_visual_state()
	if name != "Enemy" or ai_profile == null or not debug_state_label_enabled or state_label == null:
		return
	state_label.text += "\nAI: %s\nDIST: %.0f\nCD: %.2f" % [
		_debug_ai_action_text(),
		evaluate_distance(),
		ai_attack_cooldown_timer,
	]
