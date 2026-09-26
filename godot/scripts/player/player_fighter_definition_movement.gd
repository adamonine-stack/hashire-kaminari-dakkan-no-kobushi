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
	JUMP,
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
var ai_jump_cooldown_timer := 0.0
var ai_jump_direction := 0.0
var ai_jump_attack_plan: StringName = &""
var ai_jump_attack_used := false
var ai_approach_jump_checked := false
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
	if has_method("apply_attack_sequence"):
		apply_attack_sequence(fighter_definition.attack_sequence)
		dev026_max_combo_hits = int(fighter_definition.max_attack_chain_count) if int(fighter_definition.max_attack_chain_count) > 0 else maxi(1, fighter_definition.attack_sequence.size())
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
	ai_jump_cooldown_timer = 0.0
	ai_jump_direction = 0.0
	ai_jump_attack_plan = &""
	ai_jump_attack_used = false
	ai_approach_jump_checked = false
	ai_jump_launch_pending = false
	ai_jump_launch_direction = 0.0
	ai_jump_launch_speed_multiplier = 1.0
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
	ai_jump_cooldown_timer = maxf(ai_jump_cooldown_timer - delta, 0.0)
	ai_throw_cooldown_timer = maxf(ai_throw_cooldown_timer - delta, 0.0)
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
		EnemyAIState.JUMP:
			update_jump(delta)
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
	elif ai_state == EnemyAIState.JUMP:
		state_limit = maxf(ai_state_watchdog_limit, 2.5)

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
	if should_jump_player(distance):
		enter_jump()
		return
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
	if should_throw_player():
		enter_throw()
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
	ai_approach_jump_checked = false
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


func enter_throw() -> void:
	if not can_ai_act() or not _can_start_throw() or _get_throw_target() == null:
		enter_idle()
		return
	_set_ai_state(EnemyAIState.ATTACK)
	ai_selected_attack_type = "throw"
	_face_opponent()
	ai_throw_cooldown_timer = _profile_float(&"throw_cooldown", 1.50)
	ai_action_started.emit("throw")
	_register_ai_action(&"throw")
	_start_throw()
	print("[DEV054][%s] Throw selected" % _debug_enemy_id())


func enter_jump() -> void:
	if not can_ai_act() or not is_on_floor() or not _profile_bool(&"can_jump", true):
		enter_idle()
		return
	var opponent := _get_opponent()
	if not (opponent is Node2D):
		enter_idle()
		return
	_set_ai_state(EnemyAIState.JUMP)
	_face_opponent()
	ai_jump_direction = signf(opponent.global_position.x - global_position.x)
	if ai_jump_direction == 0.0:
		ai_jump_direction = facing_direction
	ai_jump_launch_pending = true
	ai_jump_launch_direction = ai_jump_direction
	ai_jump_launch_speed_multiplier = _profile_float(&"jump_forward_speed_multiplier", 0.80)
	ai_jump_attack_plan = _choose_jump_attack_plan()
	ai_jump_attack_used = false
	ai_jump_cooldown_timer = _profile_float(&"jump_cooldown", 2.20)
	ai_action_started.emit("jump")
	_register_ai_action(&"jump")
	print("[DEV054][%s] Jump selected" % _debug_enemy_id())


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
	var attack_distance := _profile_float(&"attack_distance", 55.0)
	if not ai_approach_jump_checked and distance <= attack_distance + 78.0 and distance > attack_distance + 6.0:
		ai_approach_jump_checked = true
		if should_jump_player(distance, 1.35):
			enter_jump()
			return
	if distance <= attack_distance or distance <= ai_current_target_distance:
		choose_next_action()
		return
	_face_opponent()
	var direction := signf(opponent.global_position.x - global_position.x)
	_move_ai(direction, _profile_float(&"approach_speed_multiplier", 1.0), delta)


func update_jump(delta: float) -> void:
	if current_hp <= 0 or not is_round_active:
		return
	if is_on_floor():
		velocity.x = 0.0
		ai_jump_direction = 0.0
		ai_jump_attack_plan = &""
		ai_jump_attack_used = false
		ai_action_finished.emit("jump")
		enter_idle()
		return
	var desired_speed := ai_jump_direction * jump_horizontal_speed * _profile_float(&"jump_forward_speed_multiplier", 0.80)
	velocity.x = move_toward(velocity.x, desired_speed, air_control_acceleration * delta * 0.35)
	_face_opponent()
	_try_ai_jump_attack()


func _choose_jump_attack_plan() -> StringName:
	if randf() > _profile_float(&"jump_attack_rate", 0.55):
		return &""
	var kick_weight := maxf(_profile_float(&"jump_kick_weight", 0.65), 0.0)
	var punch_weight := maxf(_profile_float(&"jump_punch_weight", 0.35), 0.0)
	var total := kick_weight + punch_weight
	if total <= 0.0:
		return &""
	# At close range bias the descending punch so both air attacks are actually
	# represented in normal play; at longer range the forward kick remains safer.
	var distance := evaluate_distance()
	var punch_distance := _profile_float(&"jump_punch_distance", 110.0)
	if distance <= punch_distance * 1.10 and punch_weight > 0.0:
		var close_punch_chance := clampf(punch_weight / total + 0.20, 0.0, 0.80)
		if randf() <= close_punch_chance:
			return &"punch"
	return &"kick" if randf() <= kick_weight / total else &"punch"


func _try_ai_jump_attack() -> void:
	if ai_jump_attack_used or ai_jump_attack_plan.is_empty() or current_attack_type != "":
		return
	if is_on_floor() or is_hit or is_guard_hit or _is_throw_busy() or is_character_special_busy():
		return
	var distance := evaluate_distance()
	if ai_jump_attack_plan == &"kick":
		if distance > _profile_float(&"jump_kick_distance", 155.0):
			return
		# Fire after the launch frame but allow ascent, apex, and early descent.
		if velocity.y < -jump_power * 0.88 or velocity.y > jump_power * 0.50:
			return
		if request_attack_input(&"Kick", true):
			ai_jump_attack_used = true
			ai_action_started.emit("jump_kick")
			_register_ai_action(&"jump_kick")
			print("[DEV055][%s] Jump kick selected" % _debug_enemy_id())
		return
	if ai_jump_attack_plan == &"punch":
		if velocity.y < -20.0 or distance > _profile_float(&"jump_punch_distance", 125.0):
			return
		if request_attack_input(&"Punch", true):
			ai_jump_attack_used = true
			ai_action_started.emit("jump_punch")
			_register_ai_action(&"jump_punch")
			print("[DEV055][%s] Jump punch selected" % _debug_enemy_id())


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
	var guard_rate := _profile_float(&"guard_rate", _profile_float(&"guard_weight", 0.15))
	var is_threatening := _is_player_attack_threatening(opponent)
	if not is_threatening:
		var proactive_distance := _profile_float(&"attack_distance", 55.0) * 0.90
		if evaluate_distance() > proactive_distance:
			return false
		guard_rate *= 0.30
	if randf() > guard_rate:
		return false
	print("[DEV054][%s] Guard selected%s" % [_debug_enemy_id(), " (read)" if not is_threatening else ""])
	return true


func should_throw_player() -> bool:
	if ai_throw_cooldown_timer > 0.0 or not _can_start_throw():
		return false
	if _get_throw_target() == null:
		return false
	var chance := _profile_float(&"throw_weight", 0.10)
	if last_ai_action == &"throw":
		chance *= 0.35
	return randf() <= chance


func should_jump_player(distance: float, rate_multiplier := 1.0) -> bool:
	if not _profile_bool(&"can_jump", true) or ai_jump_cooldown_timer > 0.0 or not is_on_floor():
		return false
	if last_ai_action == &"jump" and repeated_action_count >= 1:
		return false
	var attack_distance := _profile_float(&"attack_distance", 55.0)
	# The old lower bound sat above Crusher's preferred spacing, so jump checks
	# were skipped during normal neutral play. Keep jumps available throughout
	# the preferred/attack band while still avoiding point-blank hop spam.
	var min_distance := maxf(_profile_float(&"retreat_distance", 35.0) * 0.70, attack_distance * 0.55)
	var max_distance := attack_distance + 120.0
	if distance < min_distance or distance > max_distance:
		return false
	return randf() <= clampf(_profile_float(&"jump_rate", 0.12) * rate_multiplier, 0.0, 1.0)


func should_attack_player() -> bool:
	if ai_attack_cooldown_timer > 0.0 or evaluate_distance() > _profile_float(&"attack_distance", 55.0):
		return false
	return randf() <= _profile_float(&"aggression_rate", 0.60)


func should_retreat() -> bool: