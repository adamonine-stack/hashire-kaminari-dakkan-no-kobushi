extends "res://scripts/player/player_knockdown_movement.gd"

signal ai_state_changed(previous_state, new_state)
signal ai_action_started(action_name)
signal ai_action_finished(action_name)
signal enemy_attack_requested(attack_type)
signal enemy_guard_requested
signal enemy_retreat_started
signal enemy_feint_started
signal special_attack_requested(enemy)
signal special_attack_started(attack_id)
signal special_attack_became_active(attack_id)
signal special_attack_hit(attack_id, target)
signal special_attack_interrupted(attack_id)
signal special_attack_finished(attack_id)
signal ultimate_requested
signal ultimate_started
signal ultimate_became_active
signal ultimate_interrupted
signal ultimate_finished
signal attack_warning_started(attack_id)
signal attack_warning_finished(attack_id)
signal character_special_started(attack_id)
signal character_special_became_active(attack_id)
signal character_special_hit(attack_id, target)
signal character_special_blocked(attack_id, target)
signal character_special_interrupted(attack_id)
signal character_special_finished(attack_id)

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

enum BossAttackState {
	NONE,
	SPECIAL_STARTUP,
	SPECIAL_ACTIVE,
	SPECIAL_RECOVERY,
	ULTIMATE_STARTUP,
	ULTIMATE_ACTIVE,
	ULTIMATE_RECOVERY,
}

enum CharacterSpecialState {
	NONE,
	STARTUP,
	ACTIVE,
	RECOVERY,
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
var ai_state_watchdog_timer := 0.0
var ai_state_watchdog_limit := 4.0
var show_ai_debug := false
var boss_attack_data_by_id: Dictionary = {}
var boss_attack_state := BossAttackState.NONE
var boss_current_attack_data: Resource
var boss_current_attack_id := ""
var boss_attack_timer := 0.0
var boss_special_common_cooldown := 0.0
var boss_special_cooldowns: Dictionary = {}
var boss_special_hit_targets: Array[Node] = []
var boss_attack_direction := -1.0
var boss_special_move_timer := 0.0
var boss_special_move_speed := 0.0
var ultimate_used := false
var ultimate_pending := false
var ultimate_retry_cooldown := 0.0
var ultimate_interrupt_resistant := false
var ultimate_resistance_timer := 0.0
var boss_warning_node: Node2D
var boss_preview_node: Node2D
var boss_cinematic_overlay: ColorRect
var boss_aura_node: Node2D
var character_special_data: Resource
var character_special_state := CharacterSpecialState.NONE
var character_special_timer := 0.0
var character_special_id := ""
var character_special_direction := 1.0
var character_special_hit_targets: Array[Node] = []
var character_special_move_timer := 0.0
var character_special_move_speed := 0.0
var special_gauge := 0.0
var max_special_gauge := 100.0
var special_gauge_cost := 100.0
var special_ai_use_chance := 0.35
var special_has_armor := false

@onready var special_area := get_node_or_null("SpecialHitBox") as Area2D
@onready var special_shape := get_node_or_null("SpecialHitBox/CollisionShape2D") as CollisionShape2D


func _ready() -> void:
	_capture_base_stats()
	super._ready()
	if special_area != null:
		special_area.area_entered.connect(_on_special_hitbox_area_entered)
	_set_special_hitbox_active(false)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if hit_stop_timer > 0.0:
		return
	update_character_special(delta)
	if _should_start_player_special():
		request_character_special(false)
	update_special_cooldowns(delta)
	check_ultimate_condition()
	update_boss_special_attack(delta)
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
	apply_character_special_stats()
	apply_guard_stats()
	apply_knockback_stats()
	second_hit_damage_scale = base_second_hit_damage_scale * float(fighter_definition.combo_damage_scale)
	third_hit_damage_scale = base_third_hit_damage_scale * float(fighter_definition.combo_damage_scale)
	dev026_second_hit_damage_scale = second_hit_damage_scale
	dev026_third_hit_damage_scale = third_hit_damage_scale
	current_hp = clampi(current_hp, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)
	apply_character_art(fighter_definition)
	apply_ai_profile(fighter_definition.ai_profile)
	if _is_enemy8():
		apply_boss_special_attack_data(fighter_definition.special_attack_sequence)
	else:
		apply_boss_special_attack_data([])
	if fighter_definition.battle_texture == null and fighter_definition.sprite_sheet == null:
		apply_temporary_color(fighter_definition.temporary_color)
	else:
		apply_temporary_color(Color.WHITE)
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
	if has_method("set_air_kick_attack_data"):
		set_air_kick_attack_data(fighter_definition.air_kick_attack)
	if has_method("set_air_punch_down_attack_data"):
		set_air_punch_down_attack_data(fighter_definition.air_punch_down_attack)
	if has_method("set_crouch_kick_sweep_attack_data"):
		set_crouch_kick_sweep_attack_data(fighter_definition.crouch_kick_sweep_attack)


func apply_character_special_stats() -> void:
	character_special_data = null
	if fighter_definition != null and not _is_enemy8() and not fighter_definition.special_attack_sequence.is_empty():
		character_special_data = fighter_definition.special_attack_sequence[0]
	max_special_gauge = maxf(_definition_float("max_special_gauge", 100.0), 1.0)
	special_gauge_cost = clampf(_definition_float("special_gauge_cost", 100.0), 1.0, max_special_gauge)
	special_ai_use_chance = clampf(_definition_float("special_ai_use_chance", 0.35), 0.0, 1.0)
	special_has_armor = bool(fighter_definition.get("special_has_armor")) if fighter_definition != null else false
	set_special_gauge(clampf(special_gauge, 0.0, max_special_gauge))


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
	if uses_official_character_art or uses_animated_character_art:
		visual_root.modulate = Color.WHITE
		if animated_character_sprite != null:
			animated_character_sprite.modulate = Color.WHITE
			animated_character_sprite.self_modulate = Color.WHITE
		if character_sprite != null:
			character_sprite.modulate = Color.WHITE
			character_sprite.self_modulate = Color.WHITE
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
	ai_state_watchdog_timer = 0.0
	_clear_guard_state()
	reset_special_attack_state()
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

	lines.append("AI STATE: %s" % [_debug_ai_action_text()])
	lines.append("AI DISTANCE: %.0f" % [distance])
	lines.append("AI TARGET DISTANCE: %.0f" % [ai_current_target_distance])
	lines.append("AI REACTION: %.2f" % [ai_reaction_timer])
	lines.append("AI COOLDOWN: %.2f" % [ai_attack_cooldown_timer])
	lines.append("SELECTED ATTACK: %s" % ["NONE" if ai_selected_attack_type.is_empty() else ai_selected_attack_type.to_upper()])
	lines.append("AGGRESSION: %.2f" % [_profile_float(&"aggression_rate", 0.0)])
	lines.append("GUARD RATE: %.2f" % [_profile_float(&"guard_rate", 0.0)])
	lines.append("RETREAT RATE: %.2f" % [_profile_float(&"retreat_rate", 0.0)])
	lines.append("COMBO RATE: %d%%" % [int(round(_profile_float(&"combo_rate", 0.0) * 100.0))])
	lines.append("THROW ESCAPE: %d%%" % [int(round(_profile_float(&"throw_escape_probability", 0.0) * 100.0))])
	if _is_enemy8():
		lines.append("BOSS STATE: %s" % [BossAttackState.keys()[boss_attack_state]])
		lines.append("BOSS ATTACK: %s" % ["NONE" if boss_current_attack_id.is_empty() else boss_current_attack_id])
		lines.append("SPECIAL CD: %.2f" % [boss_special_common_cooldown])
		lines.append("ULT USED: %s" % [str(ultimate_used).to_upper()])
		lines.append("ULT PENDING: %s" % [str(ultimate_pending).to_upper()])
		lines.append("ARMOR: %s" % [str(ultimate_interrupt_resistant).to_upper()])
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
	if is_boss_special_busy():
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
	if is_boss_special_busy():
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
	if _update_ai_watchdog(delta):
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


func _update_ai_watchdog(delta: float) -> bool:
	match ai_state:
		EnemyAIState.DISABLED, EnemyAIState.HITSTUN, EnemyAIState.KNOCKBACK, EnemyAIState.DOWN, EnemyAIState.KO:
			ai_state_watchdog_timer = 0.0
			return false

	ai_state_watchdog_timer += delta
	var state_limit := ai_state_watchdog_limit
	if ai_state == EnemyAIState.ATTACK:
		state_limit = maxf(ai_state_watchdog_limit, 4.5)
	elif ai_state == EnemyAIState.FEINT:
		state_limit = maxf(ai_state_watchdog_limit, 3.0)

	if ai_state_watchdog_timer < state_limit:
		return false

	if show_ai_debug:
		print("[DEV044][%s] AI watchdog recovered from %s" % [_debug_enemy_id(), EnemyAIState.keys()[ai_state]])
	if current_attack_type != "":
		_cancel_current_action()
	cancel_current_ai_action()
	velocity.x = 0.0
	enter_idle()
	return true


func can_choose_guard() -> bool:
	return _can_start_guard_or_crouch() and not is_guarding and not is_crouch_guarding


func update_enemy_target(_target: Node) -> void:
	cancel_current_ai_action()
	ai_enabled = false
	_set_ai_state(EnemyAIState.DISABLED)
	if is_boss_special_busy():
		reset_special_attack_state(false)


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
	if should_use_character_special():
		_set_ai_state(EnemyAIState.SPECIAL_ATTACK_REQUEST)
		ai_action_started.emit("character_special")
		if request_character_special(true):
			ai_attack_cooldown_timer = randf_range(_profile_float(&"attack_cooldown_min", 0.30), _profile_float(&"attack_cooldown_max", 0.60))
			return
		enter_idle()
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
	guard_type = "high"
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
			request_attack_input(&"Kick", true)
		_:
			request_attack_input(&"Punch", true)
	return current_attack_type != ""


func should_use_character_special() -> bool:
	if not can_start_character_special(true):
		return false
	if evaluate_distance() > _profile_float(&"attack_distance", 55.0) + 35.0:
		return false
	return randf() <= special_ai_use_chance


func request_character_special(is_ai_request := false) -> bool:
	if not can_start_character_special(is_ai_request):
		return false
	start_character_special()
	return character_special_state != CharacterSpecialState.NONE


func can_start_character_special(is_ai_request := false) -> bool:
	if character_special_data == null:
		return false
	if special_gauge + 0.001 < special_gauge_cost:
		return false
	if character_special_state != CharacterSpecialState.NONE or is_boss_special_busy():
		return false
	if current_hp <= 0 or not is_round_active or is_hit or is_guard_hit or _is_throw_busy():
		return false
	if current_attack_type != "" or attack_active_timer > 0.0 or kick_active_timer > 0.0:
		return false
	if is_guarding or is_crouching or is_crouch_guarding or not is_on_floor():
		return false
	if _is_knockdown_busy():
		return false
	if name == "Enemy":
		return is_ai_request and can_ai_act()
	return input_enabled and not is_ai_request


func start_character_special() -> void:
	var attack_id := String(character_special_data.attack_id) if character_special_data != null else ""
	if attack_id.is_empty():
		attack_id = "character_special"
	set_special_gauge(special_gauge - special_gauge_cost)
	interrupt_combo()
	reset_attack_state(false)
	_clear_guard_state()
	is_crouching = false
	velocity = Vector2.ZERO
	_face_opponent()
	character_special_direction = facing_direction
	_set_visual_facing()
	character_special_id = attack_id
	character_special_hit_targets.clear()
	character_special_state = CharacterSpecialState.STARTUP
	character_special_timer = maxf(float(character_special_data.startup_time), 0.01)
	disable_character_special_hitbox()
	_play_character_special_animation(&"special_startup", &"kick_1")
	character_special_started.emit(character_special_id)
	print("[Special] started id=%s" % character_special_id)


func enter_character_special_active() -> void:
	if character_special_data == null:
		interrupt_character_special(false)
		return
	character_special_state = CharacterSpecialState.ACTIVE
	character_special_timer = maxf(float(character_special_data.active_time), 0.01)
	apply_character_special_hitbox_data()
	enable_character_special_hitbox()
	_setup_character_special_movement()
	_play_character_special_animation(&"special_attack", &"kick_1")
	character_special_became_active.emit(character_special_id)
	print("[Special] active")


func enter_character_special_recovery() -> void:
	disable_character_special_hitbox()
	stop_character_special_movement()
	character_special_state = CharacterSpecialState.RECOVERY
	character_special_timer = maxf(float(character_special_data.recovery_time), 0.01)
	_play_character_special_animation(&"special_recovery", &"idle")


func finish_character_special() -> void:
	var finished_id := character_special_id
	reset_character_special_state(false)
	if not finished_id.is_empty():
		character_special_finished.emit(finished_id)
		print("[Special] finished")


func interrupt_character_special(emit_signal := true) -> void:
	if character_special_state == CharacterSpecialState.NONE:
		return
	var interrupted_id := character_special_id
	reset_character_special_state(false)
	if emit_signal and not interrupted_id.is_empty():
		character_special_interrupted.emit(interrupted_id)
		print("[Special] interrupted")


func reset_character_special_state(reset_gauge := false) -> void:
	disable_character_special_hitbox()
	stop_character_special_movement()
	character_special_state = CharacterSpecialState.NONE
	character_special_timer = 0.0
	character_special_id = ""
	character_special_hit_targets.clear()
	if reset_gauge:
		set_special_gauge(0.0)


func is_character_special_busy() -> bool:
	return character_special_state != CharacterSpecialState.NONE


func update_character_special(delta: float) -> void:
	if character_special_state == CharacterSpecialState.NONE:
		return
	if current_hp <= 0 or not is_round_active:
		reset_character_special_state(false)
		return
	_apply_character_special_movement(delta)
	character_special_timer = maxf(character_special_timer - delta, 0.0)
	match character_special_state:
		CharacterSpecialState.STARTUP:
			if character_special_timer == 0.0:
				enter_character_special_active()
		CharacterSpecialState.ACTIVE:
			if character_special_timer == 0.0:
				enter_character_special_recovery()
		CharacterSpecialState.RECOVERY:
			if character_special_timer == 0.0:
				finish_character_special()


func set_special_gauge(value: float) -> void:
	special_gauge = clampf(value, 0.0, max_special_gauge)
	special_gauge_changed.emit(special_gauge, max_special_gauge)
	if is_equal_approx(special_gauge, max_special_gauge):
		print("[Special] gauge_full")


func add_special_gauge(amount: float) -> void:
	if amount <= 0.0 or current_hp <= 0:
		return
	set_special_gauge(special_gauge + amount)
	print("[Special] gauge_changed=%d" % int(round(special_gauge)))


func get_special_gauge() -> float:
	return special_gauge


func get_max_special_gauge() -> float:
	return max_special_gauge


func get_special_gauge_ratio() -> float:
	return clampf(special_gauge / maxf(max_special_gauge, 1.0), 0.0, 1.0)


func enable_character_special_hitbox() -> void:
	_set_character_special_hitbox_active(true)


func disable_character_special_hitbox() -> void:
	_set_character_special_hitbox_active(false)


func apply_character_special_hitbox_data() -> void:
	if special_area == null or character_special_data == null:
		return
	var scale_multiplier := battle_visual_scale_multiplier
	var offset: Vector2 = character_special_data.hitbox_offset
	special_area.position = Vector2(float(offset.x) * scale_multiplier * character_special_direction, (-52.0 + float(offset.y)) * scale_multiplier)
	if special_shape != null:
		if special_shape.shape == null or not (special_shape.shape is RectangleShape2D):
			special_shape.shape = RectangleShape2D.new()
		else:
			special_shape.shape = special_shape.shape.duplicate()
		special_shape.shape.size = character_special_data.hitbox_size * scale_multiplier


func _set_character_special_hitbox_active(is_active: bool) -> void:
	if special_area != null:
		special_area.set_deferred("monitoring", is_active)
	if special_shape != null:
		special_shape.set_deferred("disabled", not is_active)


func _setup_character_special_movement() -> void:
	stop_character_special_movement()
	if character_special_data == null:
		return
	var duration := float(character_special_data.move_duration)
	var distance := float(character_special_data.move_distance)
	if duration <= 0.0:
		duration = float(character_special_data.forward_move_duration)
		distance = float(character_special_data.forward_move_distance)
	if duration <= 0.0 or distance == 0.0:
		return
	character_special_move_timer = duration
	character_special_move_speed = (distance / duration) * character_special_direction * float(character_special_data.move_speed_multiplier)


func _apply_character_special_movement(delta: float) -> void:
	if character_special_move_timer <= 0.0:
		return
	var step := minf(delta, character_special_move_timer)
	position.x += character_special_move_speed * step
	character_special_move_timer = maxf(character_special_move_timer - delta, 0.0)
	_clamp_to_screen()


func stop_character_special_movement() -> void:
	character_special_move_timer = 0.0
	character_special_move_speed = 0.0


func _on_character_special_hitbox_area_entered(area: Area2D) -> void:
	if character_special_state != CharacterSpecialState.ACTIVE:
		return
	var target := _get_valid_hurtbox_target(area)
	if target == null or character_special_hit_targets.has(target):
		return
	character_special_hit_targets.append(target)
	var attack_data := _get_character_special_attack_dictionary()
	var did_hit: bool = bool(target.receive_attack(attack_data, character_special_direction, _get_hit_position(target), self))
	if did_hit:
		character_special_hit.emit(character_special_id, target)
		_spawn_hit_effect(_get_hit_position(target), attack_data["effect_size"])
		print("[Special] hit target=%s" % _target_debug_name(target))
	else:
		character_special_blocked.emit(character_special_id, target)
		print("[Special] blocked")


func _get_character_special_attack_dictionary() -> Dictionary:
	var base_damage := maxi(punch_damage, kick_damage)
	var multiplier := float(character_special_data.damage_multiplier) if character_special_data != null else 2.8
	if multiplier <= 1.0:
		multiplier = 2.8
	var raw_knockback: Vector2 = character_special_data.knockback if character_special_data != null else Vector2(kick_knockback_x * 1.4, -kick_knockback_y * 1.4)
	var final_knockback := calculate_attack_knockback(Vector2(absf(float(raw_knockback.x)), absf(float(raw_knockback.y))))
	return {
		"damage": maxi(1, int(round(float(base_damage) * multiplier))),
		"base_damage": maxi(1, int(round(float(base_damage) * multiplier))),
		"attack_height": "middle",
		"attack_type": "special",
		"is_guardable": true,
		"guard_damage_multiplier": maxf(float(character_special_data.guard_damage_multiplier), 0.20) if character_special_data != null else 0.20,
		"guard_hit_time": float(character_special_data.guard_hit_time) if character_special_data != null else 0.28,
		"guard_hitstop_attacker": 0.06,
		"guard_hitstop_defender": 0.08,
		"guard_knockback": character_special_data.guard_knockback if character_special_data != null else Vector2(95.0, 0.0),
		"knockback_x": final_knockback.x,
		"knockback_y": final_knockback.y,
		"hit_stop_frames": 8,
		"hitstop_attacker": 0.09,
		"hitstop_defender": 0.13,
		"hitstun_time": float(character_special_data.hitstun_time) if character_special_data != null else 0.36,
		"effect_size": 1.85,
		"screen_shake": 5.8,
		"se_type": "special",
		"attack_id": character_special_id,
		"causes_knockdown": String(fighter_definition.fighter_type) == "power" if fighter_definition != null else false,
	}


func _play_character_special_animation(primary_name: StringName, fallback_name: StringName) -> void:
	var animation_name := StringName(character_special_data.animation_name) if character_special_data != null and not String(character_special_data.animation_name).is_empty() else primary_name
	if primary_name == &"special_startup":
		animation_name = &"special_startup"
	elif primary_name == &"special_attack":
		animation_name = StringName(character_special_data.animation_name) if character_special_data != null and not String(character_special_data.animation_name).is_empty() else &"special_attack"
	elif primary_name == &"special_recovery":
		animation_name = &"special_recovery"
	_play_visual_animation(animation_name, true)
	if uses_animated_character_art:
		if animation_player != null and animation_player.is_playing():
			animation_player.stop()
		return
	if animation_player == null:
		return
	if animation_player.has_animation(String(animation_name)):
		animation_player.play(String(animation_name))
	elif animation_player.has_animation(String(fallback_name)):
		animation_player.play(String(fallback_name))


func gain_special_gauge_for_attack_hit(attack_data: Dictionary) -> void:
	var attack_type := String(attack_data.get("attack_type", current_attack_type)).to_lower()
	var combo_index := int(attack_data.get("combo_hit_index", 1))
	if attack_type == "special" or attack_type == "ultimate" or attack_type == "throw":
		return
	if combo_index >= dev026_max_combo_hits:
		add_special_gauge(12.0)
	elif combo_index >= 2:
		add_special_gauge(7.0)
	elif attack_type == "kick" or current_attack_type == "Kick":
		add_special_gauge(8.0)
	else:
		add_special_gauge(6.0)


func gain_special_gauge_for_guarded_attack(attack_data: Dictionary) -> void:
	var attack_type := String(attack_data.get("attack_type", current_attack_type)).to_lower()
	if attack_type == "special" or attack_type == "ultimate" or attack_type == "throw":
		return
	add_special_gauge(3.0 if attack_type == "kick" or current_attack_type == "Kick" else 2.0)


func gain_special_gauge_from_damage(amount: int, attack_data: Dictionary) -> void:
	if amount <= 0:
		return
	if bool(attack_data.get("causes_knockdown", false)):
		add_special_gauge(10.0)
	elif String(attack_data.get("attack_type", "")).to_lower() == "kick" or amount >= maxi(kick_damage, punch_damage + 4):
		add_special_gauge(8.0)
	else:
		add_special_gauge(5.0)


func request_special_attack() -> bool:
	_set_ai_state(EnemyAIState.SPECIAL_ATTACK_REQUEST)
	special_attack_requested.emit(self)
	print("[DEV037][%s] Special attack requested" % _debug_enemy_id())
	ai_special_request_cooldown_timer = 2.0
	if _is_enemy8():
		var did_start := perform_special_attack()
		if did_start:
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
	ai_state_watchdog_timer = 0.0
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
	guard_type = "high"
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
		reset_character_special_state(false)
		reset_special_attack_state()
		cancel_current_ai_action()
		_set_ai_state(EnemyAIState.KO)
		return true
	if _is_knockdown_busy():
		reset_character_special_state(false)
		cancel_current_ai_action()
		if knockdown_state == &"KNOCKBACK":
			_set_ai_state(EnemyAIState.KNOCKBACK)
		else:
			_set_ai_state(EnemyAIState.DOWN)
		return true
	if is_hit or is_guard_hit:
		if is_hit:
			reset_character_special_state(false)
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
	ai_state_watchdog_timer = 0.0
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


func apply_boss_special_attack_data(sequence: Array) -> void:
	boss_attack_data_by_id.clear()
	for attack_data in sequence:
		if attack_data == null:
			continue
		var attack_id := String(attack_data.attack_id)
		if attack_id.is_empty():
			continue
		boss_attack_data_by_id[attack_id] = attack_data


func perform_special_attack() -> bool:
	print("[DEV042][%s] Special attack requested" % _debug_enemy_id())
	if not can_start_special_attack():
		return false
	if ultimate_pending and can_start_ultimate():
		start_ultimate_attack()
		return true
	var attack_id := choose_special_attack()
	if attack_id.is_empty():
		return false
	start_special_attack(attack_id)
	return true


func can_start_special_attack() -> bool:
	if not _is_enemy8():
		return false
	if boss_attack_state != BossAttackState.NONE or boss_special_common_cooldown > 0.0 or boss_attack_data_by_id.is_empty():
		return false
	if current_hp <= 0 or not is_round_active or is_hit or is_guard_hit or _is_throw_busy():
		return false
	if current_attack_type != "" or attack_active_timer > 0.0 or kick_active_timer > 0.0:
		return false
	if is_guarding or is_crouching or is_crouch_guarding or not is_on_floor():
		return false
	if name == "Enemy":
		return _is_enemy8() and can_ai_act()
	return input_enabled


func has_special_attack() -> bool:
	return not boss_attack_data_by_id.is_empty()


func get_special_cooldown_remaining() -> float:
	var remaining := boss_special_common_cooldown
	for cooldown in boss_special_cooldowns.values():
		remaining = maxf(remaining, float(cooldown))
	return remaining


func get_special_display_name() -> String:
	if fighter_definition != null:
		var custom_name = fighter_definition.get("special_move_name")
		if custom_name != null and not String(custom_name).is_empty():
			return String(custom_name)
	for attack_id in boss_attack_data_by_id.keys():
		var data = boss_attack_data_by_id[attack_id]
		if data != null and not String(data.display_name).is_empty():
			return String(data.display_name)
	return "SPECIAL"


func choose_special_attack() -> String:
	if not _is_enemy8():
		for attack_id in boss_attack_data_by_id.keys():
			var candidate := String(attack_id)
			if not is_special_attack_on_cooldown(candidate):
				return candidate
		return ""
	var distance := evaluate_distance()
	if distance <= 95.0 and not is_special_attack_on_cooldown("enemy8_spin_kick"):
		return "enemy8_spin_kick"
	if distance >= 90.0 and distance <= 220.0 and not is_special_attack_on_cooldown("enemy8_charge_attack"):
		return "enemy8_charge_attack"
	return ""


func start_special_attack(attack_id: String) -> void:
	var attack_data = boss_attack_data_by_id.get(attack_id, null)
	if attack_data == null:
		return
	if _is_enemy8() and attack_id == "enemy8_charge_attack":
		start_charge_attack()
	elif _is_enemy8() and attack_id == "enemy8_spin_kick":
		start_spin_kick()
	elif _is_enemy8():
		return
	else:
		print("[DEV042][%s] Selected: %s" % [_debug_enemy_id(), attack_id])
	boss_current_attack_data = attack_data
	boss_current_attack_id = attack_id
	enter_special_startup()


func start_charge_attack() -> void:
	print("[DEV038][Enemy8] Selected: charge_attack")


func start_spin_kick() -> void:
	print("[DEV038][Enemy8] Selected: spin_kick")


func start_ultimate_attack() -> void:
	var attack_data = boss_attack_data_by_id.get("enemy8_ultimate_shockwave", null)
	if attack_data == null:
		return
	boss_current_attack_data = attack_data
	boss_current_attack_id = "enemy8_ultimate_shockwave"
	ultimate_pending = false
	ultimate_started.emit()
	enter_ultimate_startup()


func enter_special_startup() -> void:
	if boss_current_attack_data == null:
		return
	_prepare_boss_attack()
	boss_attack_state = BossAttackState.SPECIAL_STARTUP
	boss_attack_timer = float(boss_current_attack_data.startup_time)
	show_attack_warning()
	show_attack_preview()
	_show_boss_cinematic_flash()
	_play_boss_attack_animation(StringName(boss_current_attack_data.animation_name), &"Kick")
	_play_audio_manager_se("special_start")
	special_attack_started.emit(boss_current_attack_id)
	print("[DEV042][%s] %s startup" % [_debug_enemy_id(), _boss_log_attack_name()])


func enter_special_active() -> void:
	if boss_current_attack_data == null:
		return
	boss_attack_state = BossAttackState.SPECIAL_ACTIVE
	boss_attack_timer = float(boss_current_attack_data.active_time)
	hide_attack_warning()
	hide_attack_preview()
	apply_special_hitbox_data(boss_current_attack_data)
	enable_special_hitbox()
	_setup_boss_special_movement()
	_play_audio_manager_se("special_attack")
	special_attack_became_active.emit(boss_current_attack_id)
	print("[DEV042][%s] %s active" % [_debug_enemy_id(), _boss_log_attack_name()])


func enter_special_recovery() -> void:
	disable_special_hitbox()
	stop_special_movement()
	hide_attack_warning()
	hide_attack_preview()
	_hide_boss_cinematic_flash()
	boss_attack_state = BossAttackState.SPECIAL_RECOVERY
	boss_attack_timer = float(boss_current_attack_data.recovery_time) if boss_current_attack_data != null else 0.4
	print("[DEV042][%s] %s recovery" % [_debug_enemy_id(), _boss_log_attack_name()])


func enter_ultimate_startup() -> void:
	if boss_current_attack_data == null:
		return
	_prepare_boss_attack()
	boss_attack_state = BossAttackState.ULTIMATE_STARTUP
	boss_attack_timer = float(boss_current_attack_data.startup_time)
	ultimate_resistance_timer = 0.40
	ultimate_interrupt_resistant = false
	show_attack_warning()
	show_attack_preview()
	_show_boss_cinematic_flash()
	_play_boss_attack_animation(&"ultimate_startup", &"Kick")
	_play_hit_se("special")
	_play_audio_manager_se("ultimate_warning")
	ultimate_requested.emit()
	attack_warning_started.emit(boss_current_attack_id)
	print("[DEV038][Enemy8] Ultimate startup")


func enter_ultimate_active() -> void:
	if boss_current_attack_data == null:
		return
	boss_attack_state = BossAttackState.ULTIMATE_ACTIVE
	boss_attack_timer = float(boss_current_attack_data.active_time)
	hide_attack_warning()
	hide_attack_preview()
	_hide_boss_cinematic_flash()
	enable_ultimate_interrupt_resistance()
	apply_special_hitbox_data(boss_current_attack_data)
	enable_special_hitbox()
	_play_boss_attack_animation(&"ultimate_attack", &"Kick")
	_play_audio_manager_se("ultimate_attack")
	ultimate_used = true
	ultimate_pending = false
	ultimate_became_active.emit()
	print("[DEV038][Enemy8] Ultimate active")


func enter_ultimate_recovery() -> void:
	disable_special_hitbox()
	stop_special_movement()
	hide_attack_warning()
	hide_attack_preview()
	_hide_boss_cinematic_flash()
	disable_ultimate_interrupt_resistance()
	boss_attack_state = BossAttackState.ULTIMATE_RECOVERY
	boss_attack_timer = float(boss_current_attack_data.recovery_time) if boss_current_attack_data != null else 1.1
	_play_boss_attack_animation(&"ultimate_recovery", &"Kick")


func enable_special_hitbox() -> void:
	_set_special_hitbox_active(true)


func disable_special_hitbox() -> void:
	_set_special_hitbox_active(false)


func apply_special_hitbox_data(data: Resource) -> void:
	if special_area == null or data == null:
		return
	var scale_multiplier := battle_visual_scale_multiplier
	special_area.position = Vector2(float(data.hitbox_offset.x) * scale_multiplier * boss_attack_direction, (-52.0 + float(data.hitbox_offset.y)) * scale_multiplier)
	if special_shape != null:
		if special_shape.shape == null or not (special_shape.shape is RectangleShape2D):
			special_shape.shape = RectangleShape2D.new()
		else:
			special_shape.shape = special_shape.shape.duplicate()
		special_shape.shape.size = data.hitbox_size * scale_multiplier


func show_attack_warning() -> void:
	hide_attack_warning()
	boss_warning_node = Node2D.new()
	boss_warning_node.name = "BossAttackWarning"
	var warning_mark := Polygon2D.new()
	warning_mark.polygon = PackedVector2Array([
		Vector2(0.0, -24.0),
		Vector2(22.0, 18.0),
		Vector2(-22.0, 18.0),
	])
	warning_mark.color = Color(1.0, 0.25, 0.15, 0.42) if _is_ultimate_state_or_data() else Color(1.0, 0.9, 0.15, 0.38)
	warning_mark.position = Vector2(0.0, -176.0)
	boss_warning_node.add_child(warning_mark)
	add_child(boss_warning_node)
	attack_warning_started.emit(boss_current_attack_id)


func hide_attack_warning() -> void:
	if boss_warning_node != null and is_instance_valid(boss_warning_node):
		boss_warning_node.queue_free()
	boss_warning_node = null
	if not boss_current_attack_id.is_empty():
		attack_warning_finished.emit(boss_current_attack_id)


func show_attack_preview() -> void:
	hide_attack_preview()
	if boss_current_attack_data == null:
		return
	boss_preview_node = Node2D.new()
	boss_preview_node.name = "BossAttackPreview"
	var preview := Polygon2D.new()
	var scale_multiplier := battle_visual_scale_multiplier
	var size: Vector2 = boss_current_attack_data.hitbox_size * scale_multiplier
	var offset: Vector2 = boss_current_attack_data.hitbox_offset * scale_multiplier
	var rect := Rect2(Vector2(-size.x * 0.5, -size.y * 0.5), size)
	preview.polygon = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
	])
	preview.color = Color(1.0, 0.18, 0.1, 0.18) if _is_ultimate_state_or_data() else Color(1.0, 0.85, 0.1, 0.18)
	preview.position = Vector2(offset.x * boss_attack_direction, -52.0 + offset.y)
	boss_preview_node.add_child(preview)
	add_child(boss_preview_node)


func hide_attack_preview() -> void:
	if boss_preview_node != null and is_instance_valid(boss_preview_node):
		boss_preview_node.queue_free()
	boss_preview_node = null


func _show_boss_cinematic_flash() -> void:
	_hide_boss_cinematic_flash()
	if get_tree().current_scene == null:
		return
	var canvas := CanvasLayer.new()
	canvas.name = "BossCinematicLayer"
	canvas.layer = 20
	get_tree().current_scene.add_child(canvas)

	boss_cinematic_overlay = ColorRect.new()
	boss_cinematic_overlay.name = "BossCinematicOverlay"
	boss_cinematic_overlay.color = Color(0.04, 0.02, 0.08, 0.34)
	boss_cinematic_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_cinematic_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(boss_cinematic_overlay)

	boss_aura_node = Node2D.new()
	boss_aura_node.name = "BossUltimateAura"
	boss_aura_node.global_position = global_position + Vector2(0.0, -72.0)
	var aura := Polygon2D.new()
	aura.color = Color(0.72, 0.32, 1.0, 0.42)
	aura.polygon = _circle_points(24, 58.0)
	boss_aura_node.add_child(aura)
	get_tree().current_scene.add_child(boss_aura_node)

	var tween := create_tween()
	tween.tween_interval(0.22)
	tween.tween_property(boss_cinematic_overlay, "color", Color(0.04, 0.02, 0.08, 0.0), 0.08)
	tween.parallel().tween_property(aura, "modulate:a", 0.0, 0.08)
	tween.tween_callback(_hide_boss_cinematic_flash)


func _hide_boss_cinematic_flash() -> void:
	if boss_cinematic_overlay != null and is_instance_valid(boss_cinematic_overlay):
		var canvas := boss_cinematic_overlay.get_parent()
		if canvas != null:
			canvas.queue_free()
	boss_cinematic_overlay = null
	if boss_aura_node != null and is_instance_valid(boss_aura_node):
		boss_aura_node.queue_free()
	boss_aura_node = null


func apply_charge_movement(delta: float) -> void:
	if boss_special_move_timer <= 0.0:
		return
	var step := minf(delta, boss_special_move_timer)
	position.x += boss_special_move_speed * step
	boss_special_move_timer = maxf(boss_special_move_timer - delta, 0.0)
	_clamp_to_screen()


func stop_special_movement() -> void:
	boss_special_move_timer = 0.0
	boss_special_move_speed = 0.0
	velocity.x = 0.0


func register_special_hit(target: Node) -> void:
	if target == null or boss_special_hit_targets.has(target):
		return
	boss_special_hit_targets.append(target)
	special_attack_hit.emit(boss_current_attack_id, target)
	print("[DEV038][Enemy8] %s hit player" % _boss_log_attack_name())


func clear_special_hit_targets() -> void:
	boss_special_hit_targets.clear()


func update_special_cooldowns(delta: float) -> void:
	boss_special_common_cooldown = maxf(boss_special_common_cooldown - delta, 0.0)
	ultimate_retry_cooldown = maxf(ultimate_retry_cooldown - delta, 0.0)
	for attack_id in boss_special_cooldowns.keys():
		boss_special_cooldowns[attack_id] = maxf(float(boss_special_cooldowns[attack_id]) - delta, 0.0)


func is_special_attack_on_cooldown(attack_id: String) -> bool:
	return boss_special_common_cooldown > 0.0 or float(boss_special_cooldowns.get(attack_id, 0.0)) > 0.0


func check_ultimate_condition() -> void:
	if not _is_enemy8() or ultimate_used or ultimate_pending or current_hp <= 0:
		return
	if max_hp <= 0 or float(current_hp) / float(max_hp) > 0.35:
		return
	ultimate_pending = true
	ultimate_requested.emit()
	print("[DEV038][Enemy8] HP below 35%")
	print("[DEV038][Enemy8] Ultimate pending")


func request_ultimate_attack() -> void:
	ultimate_pending = true


func can_start_ultimate() -> bool:
	return _is_enemy8() and ultimate_pending and not ultimate_used and ultimate_retry_cooldown <= 0.0 and can_start_special_attack()


func enable_ultimate_interrupt_resistance() -> void:
	ultimate_interrupt_resistant = true
	print("[DEV038][Enemy8] Ultimate armor enabled")


func disable_ultimate_interrupt_resistance() -> void:
	ultimate_interrupt_resistant = false
	ultimate_resistance_timer = 0.0


func interrupt_special_attack() -> void:
	if boss_attack_state == BossAttackState.NONE:
		return
	var interrupted_attack_id := boss_current_attack_id
	if boss_attack_state == BossAttackState.ULTIMATE_STARTUP:
		ultimate_pending = true
		ultimate_retry_cooldown = 5.0
		ultimate_interrupted.emit()
	elif boss_attack_state == BossAttackState.ULTIMATE_ACTIVE or boss_attack_state == BossAttackState.ULTIMATE_RECOVERY:
		ultimate_used = true
		ultimate_pending = false
	_add_special_cooldown(interrupted_attack_id, 1.5)
	reset_special_attack_state(false)
	special_attack_interrupted.emit(interrupted_attack_id)
	print("[DEV038][Enemy8] %s interrupted" % interrupted_attack_id)


func finish_special_attack() -> void:
	var finished_attack_id := boss_current_attack_id
	var was_ultimate := _is_ultimate_attack_id(finished_attack_id)
	_add_special_cooldown(finished_attack_id, _special_attack_cooldown_for(finished_attack_id))
	reset_special_attack_state(false)
	ai_reaction_timer = randf_range(_profile_float(&"reaction_time_min", 0.20), _profile_float(&"reaction_time_max", 0.45))
	_set_ai_state(EnemyAIState.IDLE)
	if was_ultimate:
		ultimate_used = true
		ultimate_pending = false
		ultimate_finished.emit()
		print("[DEV038][Enemy8] Ultimate finished")
	else:
		special_attack_finished.emit(finished_attack_id)


func reset_special_attack_state(reset_ultimate_state := true) -> void:
	disable_special_hitbox()
	hide_attack_warning()
	hide_attack_preview()
	_hide_boss_cinematic_flash()
	stop_special_movement()
	clear_special_hit_targets()
	boss_attack_state = BossAttackState.NONE
	boss_current_attack_data = null
	boss_current_attack_id = ""
	boss_attack_timer = 0.0
	disable_ultimate_interrupt_resistance()
	if reset_ultimate_state:
		ultimate_used = false
		ultimate_pending = false
		ultimate_retry_cooldown = 0.0
		boss_special_common_cooldown = 0.0
		boss_special_cooldowns.clear()


func update_boss_special_attack(delta: float) -> void:
	if boss_attack_state == BossAttackState.NONE:
		return
	if current_hp <= 0 or not is_round_active:
		reset_special_attack_state(false)
		return
	if boss_attack_state == BossAttackState.ULTIMATE_STARTUP and not ultimate_interrupt_resistant:
		ultimate_resistance_timer = maxf(ultimate_resistance_timer - delta, 0.0)
		if ultimate_resistance_timer == 0.0:
			enable_ultimate_interrupt_resistance()
	boss_attack_timer = maxf(boss_attack_timer - delta, 0.0)
	if boss_attack_state == BossAttackState.SPECIAL_ACTIVE or boss_attack_state == BossAttackState.ULTIMATE_ACTIVE:
		apply_charge_movement(delta)
	match boss_attack_state:
		BossAttackState.SPECIAL_STARTUP:
			if boss_attack_timer == 0.0:
				enter_special_active()
		BossAttackState.SPECIAL_ACTIVE:
			if boss_attack_timer == 0.0:
				enter_special_recovery()
		BossAttackState.SPECIAL_RECOVERY:
			if boss_attack_timer == 0.0:
				finish_special_attack()
		BossAttackState.ULTIMATE_STARTUP:
			if boss_attack_timer == 0.0:
				enter_ultimate_active()
		BossAttackState.ULTIMATE_ACTIVE:
			if boss_attack_timer == 0.0:
				enter_ultimate_recovery()
		BossAttackState.ULTIMATE_RECOVERY:
			if boss_attack_timer == 0.0:
				finish_special_attack()


func receive_attack(attack_data: Dictionary, attack_direction: float, hit_position: Vector2, attacker: Node) -> bool:
	var was_character_special := is_character_special_busy()
	if was_character_special and not special_has_armor:
		interrupt_character_special()
	var was_boss_special := is_boss_special_busy()
	if was_boss_special and _should_interrupt_boss_special():
		interrupt_special_attack()
		return super.receive_attack(attack_data, attack_direction, hit_position, attacker)
	if was_boss_special and ultimate_interrupt_resistant:
		var damage := int(attack_data["damage"])
		apply_damage(damage)
		damage_feedback_requested.emit(self, damage, false, hit_position)
		_start_hit_stop_seconds(_get_defender_hitstop_duration(attack_data))
		_spawn_hit_effect(hit_position, attack_data["effect_size"])
		if attacker != null and attacker.has_method("start_hit_stop_seconds"):
			attacker.start_hit_stop_seconds(_get_attacker_hitstop_duration(attack_data))
		if current_hp <= 0:
			reset_special_attack_state(false)
		return true
	var did_hit: bool = bool(super.receive_attack(attack_data, attack_direction, hit_position, attacker))
	if was_boss_special and current_hp <= 0:
		reset_special_attack_state(false)
	return did_hit


func is_boss_special_busy() -> bool:
	return boss_attack_state != BossAttackState.NONE


func _on_special_hitbox_area_entered(area: Area2D) -> void:
	if character_special_state == CharacterSpecialState.ACTIVE:
		_on_character_special_hitbox_area_entered(area)
		return
	if boss_attack_state != BossAttackState.SPECIAL_ACTIVE and boss_attack_state != BossAttackState.ULTIMATE_ACTIVE:
		return
	var target := _get_valid_hurtbox_target(area)
	if target == null or boss_special_hit_targets.has(target):
		return
	var attack_data := _get_boss_attack_dictionary()
	var did_hit: bool = bool(target.receive_attack(attack_data, boss_attack_direction, _get_hit_position(target), self))
	register_special_hit(target)
	if did_hit and boss_current_attack_data != null:
		_spawn_boss_attack_effect(_get_hit_position(target), _is_ultimate_attack_id(boss_current_attack_id))


func _get_boss_attack_dictionary() -> Dictionary:
	var base_damage := maxi(punch_damage, kick_damage)
	var multiplier := float(boss_current_attack_data.damage_multiplier) if boss_current_attack_data != null else 1.0
	var final_knockback := calculate_attack_knockback(Vector2(absf(float(boss_current_attack_data.knockback.x)), absf(float(boss_current_attack_data.knockback.y))))
	return {
		"damage": maxi(1, int(round(float(base_damage) * multiplier))),
		"base_damage": maxi(1, int(round(float(base_damage) * multiplier))),
		"attack_height": "high",
		"is_guardable": bool(boss_current_attack_data.is_guardable),
		"guard_damage_multiplier": float(boss_current_attack_data.guard_damage_multiplier),
		"guard_hit_time": float(boss_current_attack_data.guard_hit_time),
		"guard_hit_stop_time": float(boss_current_attack_data.hitstop_time) * 0.6,
		"guard_knockback": boss_current_attack_data.guard_knockback,
		"knockback_x": final_knockback.x,
		"knockback_y": absf(final_knockback.y),
		"hit_stop_frames": maxi(9 if _is_ultimate_attack_id(boss_current_attack_id) else 8, int(round(float(boss_current_attack_data.hitstop_time) * 60.0))),
		"hitstun_time": float(boss_current_attack_data.hitstun_time),
		"effect_size": 2.6 if _is_ultimate_attack_id(boss_current_attack_id) else 1.6,
		"screen_shake": 7.5 if _is_ultimate_attack_id(boss_current_attack_id) else 4.8,
		"se_type": "special" if _is_ultimate_attack_id(boss_current_attack_id) else "strong",
		"attack_id": boss_current_attack_id,
	}


func _set_special_hitbox_active(is_active: bool) -> void:
	if special_area != null:
		special_area.set_deferred("monitoring", is_active)
	if special_shape != null:
		special_shape.set_deferred("disabled", not is_active)


func _prepare_boss_attack() -> void:
	interrupt_combo()
	reset_attack_state(false)
	_clear_guard_state()
	is_crouching = false
	velocity = Vector2.ZERO
	_face_opponent()
	boss_attack_direction = facing_direction
	_set_visual_facing()
	clear_special_hit_targets()


func _setup_boss_special_movement() -> void:
	stop_special_movement()
	if boss_current_attack_data == null:
		return
	var duration := float(boss_current_attack_data.move_duration)
	if duration <= 0.0:
		return
	boss_special_move_timer = duration
	boss_special_move_speed = (float(boss_current_attack_data.move_distance) / duration) * boss_attack_direction * float(boss_current_attack_data.move_speed_multiplier)


func _add_special_cooldown(attack_id: String, cooldown: float) -> void:
	if attack_id.is_empty():
		return
	boss_special_common_cooldown = maxf(boss_special_common_cooldown, 3.5)
	boss_special_cooldowns[attack_id] = maxf(float(boss_special_cooldowns.get(attack_id, 0.0)), cooldown)


func _special_attack_cooldown_for(attack_id: String) -> float:
	var attack_data = boss_attack_data_by_id.get(attack_id, null)
	return float(attack_data.cooldown) if attack_data != null else 3.5


func _should_interrupt_boss_special() -> bool:
	if boss_current_attack_data == null:
		return false
	if current_hp <= 0:
		return true
	if boss_attack_state == BossAttackState.SPECIAL_STARTUP:
		return bool(boss_current_attack_data.can_be_interrupted)
	if boss_attack_state == BossAttackState.ULTIMATE_STARTUP:
		return not ultimate_interrupt_resistant
	if boss_attack_state == BossAttackState.SPECIAL_RECOVERY or boss_attack_state == BossAttackState.ULTIMATE_RECOVERY:
		return true
	return false


func _play_boss_attack_animation(animation_name: StringName, fallback_name: StringName) -> void:
	_play_visual_animation(animation_name, true)
	if uses_animated_character_art:
		if animation_player != null and animation_player.is_playing():
			animation_player.stop()
		return
	if animation_player == null:
		return
	if animation_player.has_animation(String(animation_name)):
		animation_player.play(String(animation_name))
	elif animation_player.has_animation(String(fallback_name)):
		animation_player.play(String(fallback_name))


func _spawn_boss_attack_effect(effect_position: Vector2, is_ultimate: bool) -> void:
	var effect_root := Node2D.new()
	_prepare_character_effect_node(effect_root, "BossAttackEffect", 20)
	effect_root.global_position = effect_position
	var flash := Polygon2D.new()
	var size := 36.0 if is_ultimate else 22.0
	flash.color = Color(1.0, 0.2, 0.08, 0.75) if is_ultimate else Color(1.0, 0.85, 0.1, 0.65)
	flash.polygon = PackedVector2Array([
		Vector2(0, -size),
		Vector2(size, 0),
		Vector2(0, size),
		Vector2(-size, 0),
	])
	effect_root.add_child(flash)
	_get_character_effect_parent().add_child(effect_root)
	var tween := effect_root.create_tween()
	tween.tween_property(effect_root, "scale", Vector2(1.8, 1.8), 0.16)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.16)
	tween.tween_callback(effect_root.queue_free)


func _is_ultimate_state_or_data() -> bool:
	return boss_attack_state == BossAttackState.ULTIMATE_STARTUP or boss_attack_state == BossAttackState.ULTIMATE_ACTIVE or _is_ultimate_attack_id(boss_current_attack_id)


func _is_ultimate_attack_id(attack_id: String) -> bool:
	return attack_id == "enemy8_ultimate_shockwave"


func _boss_log_attack_name() -> String:
	if boss_current_attack_id == "enemy8_charge_attack":
		return "Charge"
	if boss_current_attack_id == "enemy8_spin_kick":
		return "Spin"
	if boss_current_attack_id == "enemy8_ultimate_shockwave":
		return "Ultimate"
	return boss_current_attack_id


func _is_enemy8() -> bool:
	if fighter_definition == null:
		return false
	var id := String(fighter_definition.fighter_id)
	return id == "enemy_08_boss" or id == "enemy_08_leon_crow"


func _should_start_player_special() -> bool:
	return false


func _debug_enemy_id() -> String:
	if fighter_definition != null and not String(fighter_definition.fighter_id).is_empty():
		return String(fighter_definition.fighter_id)
	return name


func _play_audio_manager_se(se_id: String) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play_se"):
		audio.call("play_se", se_id)


func _update_visual_state() -> void:
	super._update_visual_state()
	if is_character_special_busy():
		match character_special_state:
			CharacterSpecialState.STARTUP:
				_play_visual_animation(&"special_startup")
			CharacterSpecialState.ACTIVE:
				_play_visual_animation(StringName(character_special_data.animation_name) if character_special_data != null and not String(character_special_data.animation_name).is_empty() else &"special_attack")
			CharacterSpecialState.RECOVERY:
				_play_visual_animation(&"special_recovery")
	if is_boss_special_busy():
		match boss_attack_state:
			BossAttackState.ULTIMATE_STARTUP:
				_play_visual_animation(&"ultimate_startup")
			BossAttackState.ULTIMATE_ACTIVE:
				_play_visual_animation(&"ultimate_attack")
			BossAttackState.ULTIMATE_RECOVERY:
				_play_visual_animation(&"ultimate_recovery")
			_:
				_play_visual_animation(&"special")
	if name != "Enemy" or ai_profile == null or not debug_state_label_enabled or state_label == null:
		return
	state_label.text += "\nAI: %s\nDIST: %.0f\nCD: %.2f" % [
		_debug_ai_action_text(),
		evaluate_distance(),
		ai_attack_cooldown_timer,
	]
	if _is_enemy8():
		state_label.text += "\nBOSS: %s\nSPECIAL: %s\nSP CD: %.2f\nULT USED: %s\nULT PEND: %s\nARMOR: %s" % [
			BossAttackState.keys()[boss_attack_state],
			"NONE" if boss_current_attack_id.is_empty() else boss_current_attack_id,
			boss_special_common_cooldown,
			str(ultimate_used).to_upper(),
			str(ultimate_pending).to_upper(),
			str(ultimate_interrupt_resistant).to_upper(),
		]
