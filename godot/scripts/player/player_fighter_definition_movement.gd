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
	BACKSTEP,
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
var base_backstep_speed_multiplier := 1.55
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
var aura_controller: Node2D
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
var ai_air_guard_observed := 0.0
var ai_air_guard_decided := false
var situation_observed_state := ""
var situation_observed_time := 0.0
var ai_selected_move_id := ""
var ai_idle_timer := 0.0
var ai_attack_cooldown_timer := 0.0
var ai_retreat_timer := 0.0
var ai_backstep_cooldown_timer := 0.0
var ai_feint_timer := 0.0
var ai_feint_phase: StringName = &""
var ai_feint_cooldown_timer := 0.0
var ai_jump_cooldown_timer := 0.0
var ai_jump_direction := 0.0
var ai_jump_attack_plan: StringName = &""
var ai_jump_attack_used := false
var ai_approach_jump_checked := false
var ai_guard_minimum_timer := 0.0
var ai_guard_type := "high"
var ai_guard_counter_pending := false
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
var reversal_elapsed := 0.0
var reversal_cooldown := 0.0
var reversal_connected := false
var reversal_ai_observation := 0.0
var reversal_ai_checked := false
var reversal_input_buffer := 0.0
var reversal_visible_threat_time := 0.0
var reversal_counter_checked := false
var reversal_observed_opponent_id := 0

@export_group("Special Gauge Gain")
@export var special_gauge_passive_per_second := 0.40
@export var special_gauge_guard_success_gain := 8.0
@export var special_gauge_hit_gain := 8.0
@export var special_gauge_kick_hit_gain := 10.0
@export var special_gauge_combo_hit_gain := 9.0
@export var special_gauge_finisher_hit_gain := 14.0
@export var special_gauge_guarded_attack_gain := 3.0
@export var special_gauge_guarded_kick_gain := 4.0
@export var special_gauge_damage_light_gain := 6.0
@export var special_gauge_damage_heavy_gain := 9.0
@export var special_gauge_damage_knockdown_gain := 12.0

@onready var special_area := get_node_or_null("SpecialHitBox") as Area2D
@onready var special_shape := get_node_or_null("SpecialHitBox/CollisionShape2D") as CollisionShape2D


func _ready() -> void:
	_capture_base_stats()
	super._ready()
	if special_area != null:
		special_area.area_entered.connect(_on_special_hitbox_area_entered)
	_set_special_hitbox_active(false)


func _physics_process(delta: float) -> void:
	if input_enabled and _is_special_input_just_pressed():
		reversal_input_buffer = dev026_combo_input_buffer_time
	reversal_cooldown = maxf(reversal_cooldown - delta, 0.0)
	if hit_stop_timer <= 0.0:
		if reversal_input_buffer > 0.0:
			if request_character_special(false):
				reversal_input_buffer = 0.0
			else:
				reversal_input_buffer = maxf(reversal_input_buffer - delta, 0.0)
		_update_reversal_threat_observation(delta)
		if is_character_special_busy():
			reversal_elapsed += delta
		if is_hit:
			reversal_ai_observation += delta
		else:
			reversal_ai_observation = 0.0
			reversal_ai_checked = false
		_try_observed_special_reversal()
	if is_instance_valid(aura_controller) and aura_controller.busy():
		aura_controller.advance(delta)
		return
	super._physics_process(delta)
	if hit_stop_timer > 0.0:
		return
	update_special_gauge_generation(delta)
	update_character_special(delta)
	if _should_start_player_special():
		request_character_special(false)
	update_special_cooldowns(delta)
	check_ultimate_condition()
	update_boss_special_attack(delta)
	_observe_situation_state(delta)
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
	if is_instance_valid(aura_controller):
		aura_controller.cancel()
		aura_controller.queue_free()
		aura_controller = null
	if fighter_definition.aura_attack != null:
		aura_controller = load("res://scripts/combat/dark_aura_controller.gd").new()
		add_child(aura_controller)
		aura_controller.setup(self, fighter_definition.aura_attack)


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
	backstep_speed_multiplier = _definition_float("backstep_speed_multiplier", 1.55)


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
	reversal_visible_threat_time = 0.0
	reversal_counter_checked = false
	reversal_observed_opponent_id = 0
	reversal_ai_observation = 0.0
	reversal_ai_checked = false
	reversal_input_buffer = 0.0
	reversal_cooldown = 0.0
	character_special_data = null
	if fighter_definition != null and fighter_definition.reversal_attack != null:
		character_special_data = fighter_definition.reversal_attack
	if fighter_definition != null and not _is_enemy8() and not fighter_definition.special_attack_sequence.is_empty():
		character_special_data = fighter_definition.special_attack_sequence[0]
	max_special_gauge = maxf(_definition_float("max_special_gauge", 100.0), 1.0)
	special_gauge_cost = clampf(_definition_float("special_gauge_cost", 100.0), 1.0, max_special_gauge)
	if character_special_data != null and character_special_data.special_resource_cost >= 0.0:
		special_gauge_cost = clampf(character_special_data.special_resource_cost, 0.0, max_special_gauge)
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
	situation_observed_state = ""
	situation_observed_time = 0.0
	ai_selected_move_id = ""
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
	ai_backstep_cooldown_timer = 0.0
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
	ai_guard_type = "high"
	ai_guard_counter_pending = false
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
	lines.append("AI MOVE: %s / OBSERVED: %s %.2f" % [ai_selected_move_id, situation_observed_state, situation_observed_time])
	lines.append("AI REACTION: %.2f" % [ai_reaction_timer])
	lines.append("AI COOLDOWN: %.2f" % [ai_attack_cooldown_timer])
	lines.append("SELECTED ATTACK: %s" % ["NONE" if ai_selected_attack_type.is_empty() else ai_selected_attack_type.to_upper()])
	lines.append("AGGRESSION: %.2f" % [_profile_float(&"aggression_rate", 0.0)])
	lines.append("GUARD RATE: %.2f" % [_profile_float(&"guard_rate", 0.0)])
	lines.append("RETREAT RATE: %.2f" % [_profile_float(&"retreat_rate", 0.0)])
	lines.append("BACKSTEP RATE: %.2f" % [_profile_float(&"backstep_rate", 0.0)])
	lines.append("BACKSTEP CD: %.2f" % [ai_backstep_cooldown_timer])
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
	base_backstep_speed_multiplier = backstep_speed_multiplier
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
	backstep_speed_multiplier = base_backstep_speed_multiplier
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
	return fighter_definition != null and (fighter_definition.team_type == &"ALLY" or fighter_definition.use_direct_combat_stats)


func _display_type_text() -> String:
	if fighter_definition == null:
		return ""
	var type_text := String(fighter_definition.fighter_type)
	if type_text.is_empty():
		return ""
	return type_text.capitalize()


func _update_profile_ai(delta: float) -> void:
	if is_character_special_busy():
		return
	if is_instance_valid(aura_controller) and aura_controller.choose_distance_action(delta):
		return
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
	if _is_landing_recovery_busy():
		return false
	if not ai_enabled or ai_profile == null:
		return false
	if not is_round_active or current_hp <= 0:
		return false
	if input_enabled or name != "Enemy":
		return false
	if _get_opponent() == null:
		return false
	if hit_stop_timer > 0.0 or is_hit or is_guard_hit or guard_recoil_timer > 0.0:
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
	ai_backstep_cooldown_timer = maxf(ai_backstep_cooldown_timer - delta, 0.0)
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
		EnemyAIState.BACKSTEP:
			update_backstep(delta)
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
	var player_threatening := _is_player_attack_threatening(_get_opponent())
	# Fast evasive enemies can create space instead of always blocking. Each
	# profile controls how often this happens so heavy fighters stay planted.
	if player_threatening and should_backstep_player(distance, true):
		enter_backstep()
		return
	# When the player is already attacking, let defense compete before raw
	# counter-punching so guard actually becomes part of the neutral game.
	if player_threatening and should_guard_against_player():
		enter_guard()
		return
	if _try_situation_throw():
		return
	if _try_situation_move():
		return
	if should_counter_attack_player(distance):
		enter_attack()
		return
	if should_jump_player(distance):
		enter_jump()
		return
	if distance > _profile_float(&"attack_distance", 55.0):
		enter_approach()
		return
	if distance < _profile_float(&"retreat_distance", 35.0):
		if should_backstep_player(distance):
			enter_backstep()
			return
		if should_retreat():
			enter_retreat()
			return
	if should_sweep_player():
		enter_crouch_sweep()
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


func enter_crouch_sweep() -> void:
	if not can_ai_act() or crouch_kick_sweep_attack_data == null or ai_attack_cooldown_timer > 0.0:
		enter_idle()
		return
	_set_ai_state(EnemyAIState.ATTACK)
	ai_selected_attack_type = "sweep"
	_face_opponent()
	is_crouching = true
	enemy_attack_requested.emit(ai_selected_attack_type)
	ai_action_started.emit(ai_selected_attack_type)
	if not request_attack_input(&"Kick", true):
		is_crouching = false
		enter_idle()
		return
	ai_attack_cooldown_timer = randf_range(_profile_float(&"attack_cooldown_min", 0.30), _profile_float(&"attack_cooldown_max", 0.60))
	_register_ai_action(&"sweep")
	print("[DEV060][%s] Sweep selected" % _debug_enemy_id())


func enter_guard() -> void:
	if not can_choose_guard():
		enter_idle()
		return
	_set_ai_state(EnemyAIState.GUARD)
	ai_guard_type = _choose_ai_guard_type_against_player()
	is_guarding = true
	is_crouch_guarding = is_on_floor() and ai_guard_type == "low"
	is_crouching = false
	guard_type = ai_guard_type if is_on_floor() else "air"
	ai_guard_timer = randf_range(_profile_float(&"guard_time_min", 0.30), _profile_float(&"guard_time_max", 0.75))
	ai_guard_minimum_timer = minf(ai_guard_timer, 0.20)
	_face_opponent()
	enemy_guard_requested.emit()
	ai_action_started.emit("guard")
	_register_ai_action(&"guard")


func _select_ai_throw_move() -> String:
	var moves_by_direction: Dictionary = {}
	for move in attack_data_sequence:
		if move != null and String(move.attack_type) == "throw" and not String(move.command_direction).is_empty():
			moves_by_direction[String(move.command_direction)] = String(move.attack_id)
	if moves_by_direction.is_empty():
		return ""
	var opponent := _get_opponent()
	if not (opponent is Node2D):
		return str(moves_by_direction.get("neutral", ""))
	var own_wall_gap := minf(global_position.x-_stage_min_x(),_stage_max_x()-global_position.x)
	var target_wall_gap := minf(opponent.global_position.x-opponent._stage_min_x(),opponent._stage_max_x()-opponent.global_position.x)
	var direction := "neutral"
	if own_wall_gap <= 80.0:
		direction = "back"
	elif target_wall_gap <= 80.0:
		direction = "forward"
	elif situation_observed_time >= _profile_float(&"move_observation_seconds", 0.22):
		if situation_observed_state == "attack" and opponent.velocity.x * signf(global_position.x-opponent.global_position.x) >= 80.0:
			direction = "back"
		elif situation_observed_state == "recovery" or opponent.is_crouching:
			direction = "down"
	return str(moves_by_direction.get(direction,moves_by_direction.get("neutral","")))


func _try_situation_throw() -> bool:
	if not _profile_bool(&"use_situation_moves", false) or not can_ai_act() or ai_reaction_timer > 0.0:
		return false
	if _select_ai_throw_move().is_empty() or not should_throw_player():
		return false
	# Keep the existing rate/cooldown; let throws compete before a guaranteed jab.
	enter_throw()
	return is_throwing


func _start_ai_selected_throw() -> bool:
	var move_id := _select_ai_throw_move()
	if move_id.is_empty():
		# Existing grapplers without directional data retain their established throws.
		_start_throw()
		return is_throwing
	if not _request_directional_move(move_id,true):
		return false
	ai_selected_move_id = move_id
	return true


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
	if not _start_ai_selected_throw():
		enter_idle()
		return
	print("[DEV054][%s] Throw selected move=%s" % [_debug_enemy_id(), ai_selected_move_id])


func enter_jump() -> void:
	if not can_ai_act() or not is_on_floor() or not _profile_bool(&"can_jump", true):
		enter_idle()
		return
	var opponent := _get_opponent()
	if not (opponent is Node2D):
		enter_idle()
		return
	ai_air_guard_observed = 0.0
	ai_air_guard_decided = false
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


func enter_backstep() -> void:
	if not can_ai_act() or not _profile_bool(&"can_backstep", true) or ai_backstep_cooldown_timer > 0.0 or not is_on_floor():
		enter_idle()
		return
	var opponent := _get_opponent()
	if not (opponent is Node2D):
		enter_idle()
		return
	var direction := -signf(opponent.global_position.x - global_position.x)
	if direction == 0.0:
		direction = -facing_direction
	_face_opponent()
	_set_ai_state(EnemyAIState.BACKSTEP)
	_start_backstep(direction)
	ai_backstep_cooldown_timer = maxf(_profile_float(&"backstep_cooldown", 1.60), backstep_duration + 0.10)
	enemy_retreat_started.emit()
	ai_action_started.emit("backstep")
	_register_ai_action(&"backstep")
	print("[DEV066][%s] Backstep selected" % _debug_enemy_id())


func update_backstep(_delta: float) -> void:
	if current_hp <= 0 or not is_round_active:
		_stop_backstep()
		return
	if is_backstepping:
		return
	ai_action_finished.emit("backstep")
	enter_idle()


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
	if _try_situation_move():
		return
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


func _try_ai_air_guard(delta: float) -> bool:
	if is_on_floor():
		ai_air_guard_observed = 0.0
		ai_air_guard_decided = false
		return false
	if ai_air_guard_decided or current_attack_type != "" or not can_choose_guard():
		return false
	var opponent := _get_opponent()
	if opponent == null or not _is_player_attack_threatening(opponent):
		ai_air_guard_observed = 0.0
		return false
	ai_air_guard_observed += delta
	if ai_air_guard_observed < maxf(_profile_float(&"reaction_time_min", 0.20), 0.12):
		return false
	# One decision per jump, using visible attacks rather than input events.
	ai_air_guard_decided = true
	if not _profile_bool(&"can_guard", true) or randf() > _profile_float(&"reactive_guard_rate", 0.45):
		return false
	enter_guard()
	return is_guarding


func update_jump(delta: float) -> void:
	if current_hp <= 0 or not is_round_active:
		return
	if is_on_floor():
		velocity.x = 0.0
		ai_jump_direction = 0.0
		ai_air_guard_observed = 0.0
		ai_air_guard_decided = false
		ai_jump_attack_plan = &""
		ai_jump_attack_used = false
		ai_action_finished.emit("jump")
		enter_idle()
		return
	if _try_ai_air_guard(delta):
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
		var opponent := _get_opponent()
		if opponent != null and opponent.is_on_floor() and not opponent.is_guarding and velocity.y >= -jump_power * 0.40 and situation_observed_state == "recovery" and situation_observed_time >= _profile_float(&"move_observation_seconds", 0.22):
			for move in attack_data_sequence:
				if move != null and move.ai_tags.has("dive") and distance >= move.ai_distance_min and distance <= move.ai_distance_max:
					if _request_directional_move(String(move.attack_id),true):
						ai_jump_attack_used = true
						ai_selected_move_id = String(move.attack_id)
						ai_action_started.emit(ai_selected_move_id)
						_register_ai_action(StringName(ai_selected_move_id))
						return
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
	if is_threatening:
		guard_rate = maxf(guard_rate, _profile_float(&"reactive_guard_rate", 0.45))
	else:
		var proactive_distance := _profile_float(&"attack_distance", 55.0) * 0.90
		if evaluate_distance() > proactive_distance:
			return false
		guard_rate *= 0.30
	if last_ai_action == &"guard" and repeated_action_count >= 2:
		guard_rate *= 0.45
	if randf() > guard_rate:
		return false
	print("[DEV062][%s] Guard selected type=%s%s" % [_debug_enemy_id(), _choose_ai_guard_type_against_player(), " threat" if is_threatening else " read"])
	return true


func _choose_ai_guard_type_against_player() -> String:
	var opponent := _get_opponent()
	if opponent == null:
		return "high"
	var attack_data = opponent.get("current_attack_data")
	if attack_data != null:
		var category := String(attack_data.get("attack_category")).to_lower()
		var height := String(attack_data.get("attack_height")).to_lower()
		if category == "air" or height == "overhead":
			return "high"
		if height == "low" or category == "crouch":
			return "low"
	# Legacy/fallback attacks may not expose a Resource. A crouch state is an
	# explicit low read; jump startup clears crouch before the fighter becomes airborne.
	if bool(opponent.get("is_crouching")) and not String(opponent.get("current_attack_type")).is_empty():
		return "low"
	if opponent is CharacterBody2D and not opponent.is_on_floor() and not String(opponent.get("current_attack_type")).is_empty():
		return "high"
	return "high"


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


func should_sweep_player() -> bool:
	if crouch_kick_sweep_attack_data == null or not is_on_floor() or ai_attack_cooldown_timer > 0.0:
		return false
	var rate := _profile_float(&"sweep_rate", 0.0)
	if rate <= 0.0:
		return false
	if evaluate_distance() > _profile_float(&"attack_distance", 55.0) * 0.92:
		return false
	if last_ai_action == &"sweep":
		rate *= 0.35
	return randf() <= rate


func should_counter_attack_player(distance: float) -> bool:
	if ai_attack_cooldown_timer > 0.0 or distance > _profile_float(&"attack_distance", 55.0):
		return false
	var opponent := _get_opponent()
	if not _is_player_attack_threatening(opponent):
		return false
	var counter_rate := _profile_float(&"counter_attack_rate", 0.20)
	if _is_power_fighter():
		counter_rate = maxf(counter_rate, 0.75)
	return randf() <= counter_rate


func should_attack_player() -> bool:
	if ai_attack_cooldown_timer > 0.0 or evaluate_distance() > _profile_float(&"attack_distance", 55.0):
		return false
	var aggression := clampf(_profile_float(&"aggression_rate", 0.60), 0.0, 1.0)
	var pressure := clampf(_profile_float(&"pressure_attack_rate", 0.30), 0.0, 1.0)
	# Keep each enemy's personality but make "do damage now" the default goal.
	var combined_attack_chance := 1.0 - ((1.0 - aggression) * (1.0 - pressure))
	return randf() <= combined_attack_chance


func should_retreat() -> bool:
	if not _profile_bool(&"can_retreat", true):
		return false
	return randf() <= _profile_float(&"retreat_rate", 0.20)


func should_backstep_player(distance: float, reactive := false) -> bool:
	if not _profile_bool(&"can_backstep", true) or ai_backstep_cooldown_timer > 0.0:
		return false
	if not is_on_floor() or is_backstepping or is_guarding or is_crouching or is_crouch_guarding:
		return false
	var retreat_distance := _profile_float(&"retreat_distance", 35.0)
	if reactive:
		if distance > maxf(_profile_float(&"attack_distance", 55.0) * 1.25, retreat_distance + 36.0):
			return false
		return randf() <= _profile_float(&"reactive_backstep_rate", 0.28)
	if distance > retreat_distance * 1.20:
		return false
	return randf() <= _profile_float(&"backstep_rate", 0.12)


func should_use_feint() -> bool:
	if not _profile_bool(&"can_feint", false) or ai_feint_cooldown_timer > 0.0:
		return false
	return randf() <= _profile_float(&"feint_rate", 0.0)


func should_request_special_attack() -> bool:
	if not _profile_bool(&"can_request_special_attack", false) or ai_special_request_cooldown_timer > 0.0:
		return false
	return randf() <= _profile_float(&"special_attack_rate", 0.0)


func _observe_situation_state(delta: float) -> void:
	if not _profile_bool(&"use_situation_moves", false):
		return
	var opponent := _get_opponent()
	if opponent == null:
		situation_observed_state = ""
		situation_observed_time = 0.0
		return
	var visible := "idle"
	if not opponent.is_on_floor():
		visible = "air"
	elif opponent.current_attack_type != "":
		visible = "recovery" if opponent.attack_phase == AttackPhase.RECOVERY else "attack"
	if visible != situation_observed_state:
		situation_observed_state = visible
		situation_observed_time = 0.0
	else:
		situation_observed_time += delta


func _select_situation_move() -> String:
	if not _profile_bool(&"use_situation_moves", false):
		return ""
	var opponent := _get_opponent()
	if opponent == null or not is_on_floor():
		return ""
	var distance := evaluate_distance()
	if not opponent.is_on_floor():
		if situation_observed_state != "air" or situation_observed_time < _profile_float(&"move_observation_seconds", 0.22):
			return ""
		for move in attack_data_sequence:
			if move != null and move.ai_tags.has("anti_air") and distance >= move.ai_distance_min and distance <= move.ai_distance_max:
				return String(move.attack_id)
		return ""
	var tag := "close" if distance < 65.0 else ("middle" if distance <= 130.0 else "approach")
	if situation_observed_time >= _profile_float(&"move_observation_seconds", 0.22):
		if situation_observed_state == "recovery":
			tag = "punish"
		elif situation_observed_state == "attack":
			tag = "evade"
		elif situation_observed_state == "idle" and distance > 90.0 and opponent.is_crouching:
			tag = "low"
	elif opponent.current_attack_type != "":
		return ""
	for move in attack_data_sequence:
		if move != null and move.ai_tags.has(tag) and distance >= move.ai_distance_min and distance <= move.ai_distance_max:
			return String(move.attack_id)
	return ""


func _try_situation_move() -> bool:
	if not can_ai_act() or ai_reaction_timer > 0.0 or ai_attack_cooldown_timer > 0.0:
		return false
	var move_id := _select_situation_move()
	if move_id.is_empty():
		return false
	_face_opponent()
	if not _request_directional_move(move_id, true):
		return false
	ai_selected_move_id = move_id
	ai_selected_attack_type = String(current_attack_data.attack_type)
	_set_ai_state(EnemyAIState.ATTACK)
	ai_attack_cooldown_timer = randf_range(_profile_float(&"attack_cooldown_min", 0.30), _profile_float(&"attack_cooldown_max", 0.60))
	_register_ai_action(StringName(move_id))
	ai_action_started.emit(move_id)
	return true


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


func _special_ai_has_tag(tag: String) -> bool:
	if character_special_data == null:
		return false
	# Untagged legacy resources retain their existing situational uses.
	var tags: Array[String] = character_special_data.ai_special_tags
	return tag in tags or (tags.is_empty() and tag in ["reversal", "counter"])


func _special_ai_chance() -> float:
	if fighter_definition == null:
		return 0.0
	var order := int(fighter_definition.enemy_order)
	var type_factor := 0.30 if order <= 3 else (0.65 if order <= 7 else 1.0)
	return clampf(special_ai_use_chance * type_factor, 0.0, 1.0)


func _opponent_has_visible_attack(opponent: Node) -> bool:
	if not is_instance_valid(opponent) or opponent.current_hp <= 0 or not opponent.is_round_active:
		return false
	if not String(opponent.get("current_attack_type")).is_empty():
		return true
	# These are rendered states, not attack-button events.
	return opponent.is_character_special_busy() or opponent.is_boss_special_busy()


func _update_reversal_threat_observation(delta: float) -> void:
	var opponent := _get_opponent()
	var opponent_id := opponent.get_instance_id() if is_instance_valid(opponent) else 0
	if opponent_id != reversal_observed_opponent_id:
		reversal_visible_threat_time = 0.0
		reversal_counter_checked = false
		reversal_observed_opponent_id = opponent_id
	if _opponent_has_visible_attack(opponent):
		reversal_visible_threat_time += delta
	else:
		reversal_visible_threat_time = 0.0
		reversal_counter_checked = false


func should_use_character_special() -> bool:
	if not _special_ai_has_tag("counter") or reversal_counter_checked or not can_start_character_special(true):
		return false
	if evaluate_distance() > _profile_float(&"attack_distance", 55.0) + 35.0:
		return false
	if not _opponent_has_visible_attack(_get_opponent()) or reversal_visible_threat_time < 0.12:
		return false
	# One trial per continuous visible threat prevents repeated random rolls
	# making long attacks an almost guaranteed counter for ordinary enemies.
	reversal_counter_checked = true
	return randf() <= _special_ai_chance()

func request_character_special(is_ai_request := false) -> bool:
	if not can_start_character_special(is_ai_request):
		return false
	start_character_special()
	return character_special_state != CharacterSpecialState.NONE


func can_start_character_special(is_ai_request := false) -> bool:
	if _is_landing_recovery_busy():
		return false
	if character_special_data == null:
		return false
	if reversal_cooldown > 0.0:
		return false
	if special_gauge + 0.001 < special_gauge_cost:
		return false
	if character_special_state != CharacterSpecialState.NONE or is_boss_special_busy():
		return false
	if current_hp <= 0 or not is_round_active or is_guard_hit or guard_recoil_timer > 0.0 or _is_throw_busy():
		return false
	if is_instance_valid(aura_controller) and aura_controller.busy():
		return false
	if is_hit and not character_special_data.can_use_during_hitstun:
		return false
	if current_attack_type != "" or attack_active_timer > 0.0 or kick_active_timer > 0.0:
		return false
	if is_guarding or is_crouching or is_crouch_guarding or not is_on_floor():
		return false
	if _is_knockdown_busy():
		return false
	if name == "Enemy":
		return is_ai_request and ai_enabled and ai_profile != null and _get_opponent() != null and hit_stop_timer <= 0.0
	return input_enabled and not is_ai_request


func start_character_special() -> void:
	var attack_id := String(character_special_data.attack_id) if character_special_data != null else ""
	if attack_id.is_empty():
		attack_id = "character_special"
	set_special_gauge(special_gauge - special_gauge_cost)
	is_hit = false
	hit_reaction_timer = 0.0
	is_invincible = false
	invincibility_timer = 0.0
	visual_root.modulate.a = 1.0
	cancel_current_ai_action()
	if name == "Enemy": _set_ai_state(EnemyAIState.SPECIAL_ATTACK_REQUEST)
	reversal_elapsed = 0.0
	reversal_connected = false
	reversal_cooldown = maxf(float(character_special_data.cooldown), 0.0)
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
	_spawn_reversal_effect("startup", character_special_timer)
	_play_audio_manager_se("special_start")
	character_special_started.emit(character_special_id)
	print("[Special] started id=%s" % character_special_id)


var seiya_somersault_turn := 0.0
var seiya_two_hit_stage := 0
var seiya_two_hit_sequence := 0
var seiya_confirmed_targets: Array[WeakRef] = []
var seiya_pose_centers := {}

func _seiya_pose_center(texture: Texture2D) -> Vector2:
	var key := texture.get_instance_id()
	if not seiya_pose_centers.has(key):
		seiya_pose_centers[key] = Vector2(texture.get_image().get_used_rect().get_center())-texture.get_size()*0.5
	return seiya_pose_centers[key]

func _is_seiya_two_hit() -> bool:
	return character_special_data != null and character_special_data.somersault_sidekick

func is_seiya_confirmed_followup_target(target: Node, packet: Dictionary) -> bool:
	if not _is_seiya_two_hit() or character_special_state != CharacterSpecialState.ACTIVE or seiya_two_hit_stage != 1:
		return false
	if int(packet.get("seiya_two_hit_stage",-1)) != 1 or int(packet.get("seiya_two_hit_sequence",-1)) != seiya_two_hit_sequence:
		return false
	for reference in seiya_confirmed_targets:
		if reference.get_ref() == target: return true
	return false

func _connect_seiya_confirmed_followups() -> void:
	for reference in seiya_confirmed_targets:
		var target: Node = reference.get_ref()
		if not is_instance_valid(target) or target.current_hp <= 0: continue
		# Track the lifted opponent horizontally; retain their descending arc.
		position.x = target.position.x-95.0*character_special_direction
		_clamp_to_screen()
		_queue_character_special_contact(target)

func _update_seiya_two_hitbox() -> void:
	var elapsed: float = character_special_data.active_time-character_special_timer
	if seiya_two_hit_stage == 0 and elapsed >= character_special_data.sidekick_time:
		seiya_two_hit_stage = 1
		character_special_hit_targets.clear()
		apply_character_special_hitbox_data()
		_play_audio_manager_se("special_attack")
		_connect_seiya_confirmed_followups()
	var open: bool = (elapsed < 0.18) if seiya_two_hit_stage == 0 else (elapsed < character_special_data.sidekick_time+character_special_data.sidekick_hit_window)
	_set_character_special_hitbox_active(open)
	if open and special_area.monitoring:
		for area in special_area.get_overlapping_areas():
			_on_character_special_hitbox_area_entered(area)

func enter_character_special_active() -> void:
	if character_special_data == null:
		interrupt_character_special(false)
		return
	seiya_somersault_turn = 0.0
	seiya_two_hit_stage = 0
	seiya_two_hit_sequence += 1
	seiya_confirmed_targets.clear()
	character_special_state = CharacterSpecialState.ACTIVE
	character_special_timer = maxf(float(character_special_data.active_time), 0.01)
	apply_character_special_hitbox_data()
	enable_character_special_hitbox()
	_setup_character_special_movement()
	_play_character_special_animation(&"special_attack", &"kick_1")
	_spawn_reversal_effect("active", character_special_timer)
	_play_audio_manager_se("special_attack")
	character_special_became_active.emit(character_special_id)
	print("[Special] active")


func enter_character_special_recovery() -> void:
	disable_character_special_hitbox()
	stop_character_special_movement()
	character_special_state = CharacterSpecialState.RECOVERY
	character_special_timer = maxf(float(character_special_data.recovery_time), 0.01)
	if not reversal_connected:
		character_special_timer *= maxf(float(character_special_data.whiff_recovery_multiplier), 1.0)
	_play_character_special_animation(&"special_recovery", &"idle")
	_spawn_reversal_effect("finish", 0.22)


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
	seiya_confirmed_targets.clear()
	if reset_gauge:
		reversal_cooldown = 0.0
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
	if character_special_state == CharacterSpecialState.ACTIVE and _is_seiya_two_hit():
		_update_seiya_two_hitbox()
	elif character_special_state == CharacterSpecialState.ACTIVE and character_special_data.special_hit_window > 0.0:
		if character_special_data.active_time-character_special_timer >= character_special_data.special_hit_window:
			disable_character_special_hitbox()
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


func update_special_gauge_generation(delta: float) -> void:
	if delta <= 0.0 or not is_round_active or current_hp <= 0:
		return
	if special_gauge >= max_special_gauge:
		return
	if character_special_state != CharacterSpecialState.NONE or is_boss_special_busy():
		return
	# Passive charge runs every physics frame. Update silently so the debug log
	# remains useful for event-driven gains such as hits, guards and damage.
	set_special_gauge(special_gauge + special_gauge_passive_per_second * delta)


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
	if fighter_definition != null:
		special_area.position *= fighter_definition.combat_geometry_scale
		special_shape.shape.size *= fighter_definition.combat_geometry_scale
	if _is_seiya_two_hit() and seiya_two_hit_stage == 1:
		var geometry: float = battle_visual_scale_multiplier * fighter_definition.combat_geometry_scale
		special_area.position = Vector2(90.0*character_special_direction,-110.0)*geometry
		special_shape.shape.size = Vector2(155.0,100.0)*geometry


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
	# AI lock synchronization also calls this while receiving knockback.
	# Only an active own special owns these visual transforms.
	if character_special_state != CharacterSpecialState.NONE and character_special_data != null and (character_special_data.somersault_on_special or character_special_data.somersault_sidekick) and animated_character_sprite != null:
		animated_character_sprite.rotation = 0.0
		animated_character_sprite.offset = Vector2.ZERO
	character_special_move_timer = 0.0
	character_special_move_speed = 0.0


func _on_character_special_hitbox_area_entered(area: Area2D) -> void:
	if character_special_state != CharacterSpecialState.ACTIVE:
		return
	if _is_seiya_two_hit():
		var elapsed: float = character_special_data.active_time-character_special_timer
		if seiya_two_hit_stage == 0 and elapsed >= 0.18: return
		if seiya_two_hit_stage == 1 and (elapsed < character_special_data.sidekick_time or elapsed >= character_special_data.sidekick_time+character_special_data.sidekick_hit_window): return
	var target := _get_valid_hurtbox_target(area)
	if target == null and _is_seiya_two_hit() and seiya_two_hit_stage == 1 and area.name == "HurtBox":
		var candidate := area.get_parent()
		if candidate != self and candidate.has_method("can_receive_seiya_followup") and candidate.can_receive_seiya_followup(_get_character_special_attack_dictionary(),self):
			target = candidate
	if target == null or character_special_hit_targets.has(target):
		return
	_queue_character_special_contact(target)

func _connect_cross_special_grapple(target: Node, packet: Dictionary, point: Vector2) -> bool:
	# Only a single admitted ground contact may enter the escapeable grip.
	if character_special_state != CharacterSpecialState.ACTIVE or target._can_guard_attack(packet,self) or not target.can_be_thrown(self):
		return false
	var recovery := float(character_special_data.recovery_time)
	_complete_special_contact(target,packet,point,true)
	finish_character_special()
	_start_throw()
	cross_throw_variant = 5
	cross_muei_throw_active = true
	cross_muei_recovery_time = recovery
	_connect_throw(target,int(packet.damage))
	return target.is_throw_locked and current_throw_target == target


func _queue_character_special_contact(target: Node) -> void:
	if character_special_hit_targets.has(target): return
	character_special_hit_targets.append(target)
	var attack_data := _get_character_special_attack_dictionary()
	if is_seiya_confirmed_followup_target(target,attack_data):
		attack_data["is_guardable"] = false
	var resolver := get_tree().root.get_node_or_null("SpecialContactResolver")
	if resolver == null:
		resolver = load("res://scripts/combat/special_contact_resolver.gd").new()
		resolver.name = "SpecialContactResolver"
		get_tree().root.add_child(resolver)
	resolver.enqueue(self, target, attack_data, character_special_direction, _get_character_special_hit_position(target))

func _get_character_special_hit_position(target: Node) -> Vector2:
	# Special contacts must use their own area rather than the ordinary punch area.
	if special_area == null: return _get_hit_position(target)
	var hurt := target.get_node_or_null("HurtBox/CollisionShape2D") as CollisionShape2D
	if hurt != null and hurt.shape is RectangleShape2D:
		var half_size: Vector2 = hurt.shape.size * hurt.global_scale.abs() * 0.5
		return special_area.global_position.clamp(hurt.global_position-half_size,hurt.global_position+half_size)
	return special_area.global_position


func _complete_special_contact(target: Node, attack_data: Dictionary, point: Vector2, did_hit: bool) -> void:
	# A guard counts as contact; invulnerability does not count as a guard.
	reversal_connected = reversal_connected or did_hit or bool(target.get("is_guard_hit"))
	if did_hit:
		if _is_seiya_two_hit() and character_special_state == CharacterSpecialState.ACTIVE and int(attack_data.get("seiya_two_hit_stage",-1)) == 0 and int(attack_data.get("seiya_two_hit_sequence",-1)) == seiya_two_hit_sequence:
			seiya_confirmed_targets.append(weakref(target))
		character_special_hit.emit(String(attack_data.attack_id), target)
		_spawn_hit_effect(point, attack_data["effect_size"])
		_spawn_reversal_effect("impact", 0.28, point)
		print("[Special] hit target=%s" % _target_debug_name(target))
	else:
		character_special_blocked.emit(String(attack_data.attack_id), target)
		print("[Special] blocked")


func _get_character_special_attack_dictionary() -> Dictionary:
	var base_damage := maxi(punch_damage, kick_damage)
	var multiplier := float(character_special_data.damage_multiplier) if character_special_data != null else 1.5
	var raw_knockback: Vector2 = character_special_data.knockback if character_special_data != null else Vector2(kick_knockback_x * 1.4, -kick_knockback_y * 1.4)
	var final_knockback := calculate_attack_knockback(Vector2(absf(float(raw_knockback.x)), absf(float(raw_knockback.y))))
	var packet := {
		"damage": maxi(1, int(round(float(base_damage) * multiplier))),
		"base_damage": maxi(1, int(round(float(base_damage) * multiplier))),
		"attack_height": "middle",
		"attack_type": "special",
		"is_guardable": true,
		"guard_damage_multiplier": float(character_special_data.guard_damage_multiplier) if character_special_data != null else 0.0,
		"is_special": true,
		"special_effect_color": load("res://scripts/combat/reversal_effect.gd").color_for_style(String(fighter_definition.fighter_id)),
		"wall_slam": character_special_data.wall_slam,
		"keep_special_flight_in_view": character_special_data.keep_special_flight_in_view,
		"special_launch_speed_cap": character_special_data.special_launch_speed_cap,
		"backflip_on_launch": character_special_data.backflip_on_launch,
		"headfirst_on_launch": character_special_data.headfirst_on_launch,
		"special_launch_gravity": character_special_data.special_launch_gravity,
		"can_interrupt_attack": character_special_data.can_interrupt_attack,
		"can_break_combo": character_special_data.can_break_combo,
		"special_hit_reaction": character_special_data.special_hit_reaction,
		"special_knockback_reaction": character_special_data.special_knockback_reaction,
		"special_knockdown_reaction": character_special_data.special_knockdown_reaction,
		"special_guard_reaction": character_special_data.special_guard_reaction,
		"guard_hit_time": float(character_special_data.guard_hit_time) if character_special_data != null else 0.28,
		"guard_hitstop_attacker": 0.06,
		"guard_hitstop_defender": 0.08,
		"guard_knockback": character_special_data.guard_knockback if character_special_data != null else Vector2(95.0, 0.0),
		"knockback_x": final_knockback.x,
		"knockback_y": final_knockback.y,
		"hit_stop_frames": 8,
		"hitstop_attacker": float(character_special_data.hitstop_time) * 0.75,
		"hitstop_defender": float(character_special_data.hitstop_time),
		"hitstun_time": float(character_special_data.hitstun_time) if character_special_data != null else 0.36,
		"effect_size": 1.85,
		"screen_shake": character_special_data.camera_shake,
		"se_type": "special",
		"attack_id": String(character_special_data.attack_id),
		"causes_knockdown": true,
	}
	if _is_seiya_two_hit():
		packet["seiya_two_hit_stage"] = seiya_two_hit_stage
		packet["seiya_two_hit_sequence"] = seiya_two_hit_sequence
		packet["headfirst_on_launch"] = false
		packet["hitstop_attacker"] = 0.065
		packet["hitstop_defender"] = 0.065
		packet["special_guard_reaction"] = &"guard_hit"
		packet["keep_special_flight_in_view"] = true
		packet["special_launch_gravity"] = 850.0
		if seiya_two_hit_stage == 0:
			packet["special_hit_reaction"] = &"received_seiya_two_lift"
			packet["special_knockback_reaction"] = &"received_seiya_two_lift"
			packet["special_knockdown_reaction"] = &"received_seiya_two_down"
			packet["special_launch_speed_cap"] = Vector2(35,360)
			packet["knockback_x"] = 35.0
			packet["knockback_y"] = 360.0
		else:
			packet["special_hit_reaction"] = &"received_seiya_two_fly"
			packet["special_knockback_reaction"] = &"received_seiya_two_fly"
			packet["special_knockdown_reaction"] = &"received_seiya_two_down"
			packet["wall_slam"] = true
			packet["special_launch_speed_cap"] = Vector2.ZERO
	return packet


func _play_character_special_animation(primary_name: StringName, fallback_name: StringName) -> void:
	var animation_name := StringName(character_special_data.animation_name) if character_special_data != null and not String(character_special_data.animation_name).is_empty() else primary_name
	if primary_name == &"special_startup":
		animation_name = character_special_data.special_startup_animation
	elif primary_name == &"special_attack":
		animation_name = StringName(character_special_data.animation_name) if character_special_data != null and not String(character_special_data.animation_name).is_empty() else &"special_attack"
	elif primary_name == &"special_recovery":
		animation_name = character_special_data.special_finish_animation
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


func _spawn_reversal_effect(event: String, seconds: float, point := Vector2.ZERO) -> void:
	var custom_scene: PackedScene = character_special_data.hit_effect_scene if event == "impact" else character_special_data.effect_scene
	var effect: Node2D = custom_scene.instantiate() if custom_scene != null else load("res://scripts/combat/reversal_effect.gd").new()
	if event == "impact":
		_get_character_effect_parent().add_child(effect)
		effect.global_position = point
	else:
		add_child(effect)
	if effect.has_method("setup"):
		effect.setup(self, event, seconds)


func gain_special_gauge_for_attack_hit(attack_data: Dictionary) -> void:
	var attack_type := String(attack_data.get("attack_type", current_attack_type)).to_lower()
	var combo_index := int(attack_data.get("combo_hit_index", 1))
	if attack_type == "special" or attack_type == "ultimate" or attack_type == "throw":
		return
	if combo_index >= dev026_max_combo_hits:
		add_special_gauge(special_gauge_finisher_hit_gain)
	elif combo_index >= 2:
		add_special_gauge(special_gauge_combo_hit_gain)
	elif attack_type == "kick" or current_attack_type == "Kick":
		add_special_gauge(special_gauge_kick_hit_gain)
	else:
		add_special_gauge(special_gauge_hit_gain)


func gain_special_gauge_for_guarded_attack(attack_data: Dictionary) -> void:
	var attack_type := String(attack_data.get("attack_type", current_attack_type)).to_lower()
	if attack_type == "special" or attack_type == "ultimate" or attack_type == "throw":
		return
	add_special_gauge(special_gauge_guarded_kick_gain if attack_type == "kick" or current_attack_type == "Kick" else special_gauge_guarded_attack_gain)


func gain_special_gauge_from_damage(amount: int, attack_data: Dictionary) -> void:
	if amount <= 0:
		return
	if bool(attack_data.get("causes_knockdown", false)):
		add_special_gauge(special_gauge_damage_knockdown_gain)
	elif String(attack_data.get("attack_type", "")).to_lower() == "kick" or amount >= maxi(kick_damage, punch_damage + 4):
		add_special_gauge(special_gauge_damage_heavy_gain)
	else:
		add_special_gauge(special_gauge_damage_light_gain)


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
	if is_backstepping:
		_stop_backstep()
	ai_movement_timer = 0.0
	ai_movement_direction = 0.0
	ai_idle_timer = 0.0
	ai_retreat_timer = 0.0
	ai_feint_timer = 0.0
	ai_feint_phase = &""
	ai_has_pending_action = false
	ai_selected_attack_type = ""
	ai_jump_attack_plan = &""
	ai_jump_attack_used = false
	ai_approach_jump_checked = false
	ai_jump_launch_pending = false
	ai_jump_launch_direction = 0.0
	ai_jump_launch_speed_multiplier = 1.0
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
	ai_backstep_cooldown_timer = 0.0
	ai_feint_timer = 0.0
	ai_jump_cooldown_timer = 0.0
	ai_jump_direction = 0.0
	ai_jump_attack_plan = &""
	ai_jump_attack_used = false
	ai_approach_jump_checked = false
	ai_jump_launch_pending = false
	ai_jump_launch_direction = 0.0
	ai_jump_launch_speed_multiplier = 1.0
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
	is_crouch_guarding = is_on_floor() and ai_guard_type == "low"
	is_crouching = false
	guard_type = ai_guard_type if is_on_floor() else "air"
	if ai_guard_timer == 0.0 and ai_guard_minimum_timer == 0.0:
		_clear_guard_state()
		ai_action_finished.emit("guard")
		enter_idle()


func _update_attack_wait() -> void:
	if _is_throw_busy():
		return
	if current_attack_type != "" or attack_active_timer > 0.0 or kick_active_timer > 0.0:
		return
	ai_action_finished.emit(ai_selected_attack_type)
	var distance := evaluate_distance()
	var attack_distance := _profile_float(&"attack_distance", 55.0)
	if ai_attack_cooldown_timer <= 0.0 and distance <= attack_distance * 1.05:
		if randf() <= _profile_float(&"post_attack_pressure_rate", 0.30):
			enter_attack()
			return
	if distance > attack_distance * 1.10:
		enter_approach()
		return
	if should_backstep_player(distance):
		enter_backstep()
		return
	if should_retreat():
		enter_retreat()
	else:
		enter_idle()


func _update_special_request() -> void:
	if current_attack_type == "":
		enter_idle()


func _is_power_fighter() -> bool:
	return (
		fighter_definition != null
		and fighter_definition.team_type == &"ENEMY"
		and String(fighter_definition.fighter_type).to_upper() == "POWER"
	)


func _has_active_power_armor(attack_data: Dictionary, _attacker: Node) -> bool:
	if not _is_power_fighter() or current_attack_type.is_empty():
		return false
	if is_guarding or is_crouch_guarding or _is_knockdown_busy():
		return false
	var incoming_type := String(attack_data.get("attack_type", "")).to_lower()
	# Throws and special/ultimate attacks remain reliable counters to armor.
	return incoming_type != "throw" and incoming_type != "special" and incoming_type != "ultimate"


func _on_successful_guard(_attack_data: Dictionary, _attacker: Node) -> void:
	add_special_gauge(special_gauge_guard_success_gain)
	if name != "Enemy" or input_enabled or ai_profile == null:
		return
	ai_guard_counter_pending = true
	print("[DEV062][%s] Guard success -> counter armed" % _debug_enemy_id())


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
			ai_guard_counter_pending = false
		cancel_current_ai_action(not is_guard_hit)
		_set_ai_state(EnemyAIState.HITSTUN)
		return true
	if ai_guard_counter_pending:
		ai_guard_counter_pending = false
		var counter_distance := evaluate_distance()
		var counter_reach := _profile_float(&"attack_distance", 55.0) * 1.15
		if counter_distance <= counter_reach and randf() <= _profile_float(&"guard_counter_rate", 0.75):
			ai_attack_cooldown_timer = 0.0
			_clear_guard_state()
			print("[DEV062][%s] Guard counter" % _debug_enemy_id())
			enter_attack()
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
	if not ai_enabled:
		return false
	if ai_profile != null and name == "Enemy" and not input_enabled:
		return false
	return ai_guard_enabled and name == "Enemy" and is_round_active and not input_enabled and not is_hit and not is_guard_hit and not _is_throw_busy()


func _update_ai_throw(delta: float) -> void:
	if not ai_enabled:
		return
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
	_start_ai_selected_throw()


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
	# Reject invulnerable contacts before cancelling any move or forced animation.
	if can_receive_seiya_followup(attack_data,attacker):
		reset_knockdown_state()
		# Only the same activation's confirmed target bypasses guard/immunity.
		attack_data = attack_data.duplicate(true)
		attack_data["is_guardable"] = false
		is_invincible = false
	if not can_receive_attack():
		return false
	if is_instance_valid(aura_controller) and aura_controller.busy() and can_receive_attack():
		aura_controller.cancel()
	var was_character_special := is_character_special_busy()
	if was_character_special:
		interrupt_character_special()
	var was_boss_special := is_boss_special_busy()
	if was_boss_special and (bool(attack_data.get("can_interrupt_attack", false)) or _should_interrupt_boss_special()):
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


func can_receive_attack() -> bool:
	if is_character_special_busy() and character_special_data != null:
		if reversal_elapsed < float(character_special_data.startup_invulnerability):
			return false
	return super.can_receive_attack()


func _try_observed_special_reversal() -> void:
	if name != "Enemy" or input_enabled or not is_hit or reversal_ai_checked or not _special_ai_has_tag("reversal"):
		return
	if reversal_ai_observation < 0.12 or not can_start_character_special(true):
		return
	reversal_ai_checked = true
	# One decision after a visible hit, with a lower rate for ordinary enemies.
	if evaluate_distance() <= _profile_float(&"attack_distance", 55.0) + 35.0 and randf() <= _special_ai_chance():
		request_character_special(true)


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
		"attack_type": "ultimate" if _is_ultimate_attack_id(boss_current_attack_id) else "special",
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


func _play_audio_manager_se(se_id: String) -> bool:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play_se"):
		audio.call("play_se", se_id)
		return true
	return false


func _get_current_visual_animation() -> StringName:
	# Select the special clip before the base update, instead of temporarily
	# entering idle_prebattle every frame and restarting the special at frame 0.
	if is_character_special_busy() and character_special_data != null:
		match character_special_state:
			CharacterSpecialState.STARTUP: return character_special_data.special_startup_animation
			CharacterSpecialState.ACTIVE: return StringName(character_special_data.animation_name)
			CharacterSpecialState.RECOVERY: return character_special_data.special_finish_animation
	return super._get_current_visual_animation()

func _update_visual_state() -> void:
	# Preserve reviewed special progress across the base animation update.
	var preserve_authored_special := (_is_enemy8() or _uses_readable_grapple() or _is_cross_grappler() or character_special_id == "shadow_slip_counter") and (is_character_special_busy() or is_boss_special_busy()) and animated_character_sprite != null
	var previous_animation: StringName = animated_character_sprite.animation if preserve_authored_special else &""
	var previous_frame: int = animated_character_sprite.frame if preserve_authored_special else 0
	var previous_progress: float = animated_character_sprite.frame_progress if preserve_authored_special else 0.0
	super._update_visual_state()
	if is_character_special_busy():
		match character_special_state:
			CharacterSpecialState.STARTUP:
				_play_visual_animation(character_special_data.special_startup_animation)
			CharacterSpecialState.ACTIVE:
				_play_visual_animation(StringName(character_special_data.animation_name) if character_special_data != null and not String(character_special_data.animation_name).is_empty() else &"special_attack")
			CharacterSpecialState.RECOVERY:
				_play_visual_animation(character_special_data.special_finish_animation)
		_update_seiya_somersault_visual()
	if is_boss_special_busy():
		match boss_attack_state:
			BossAttackState.SPECIAL_STARTUP:
				_play_visual_animation(&"special_startup" if _is_enemy8() else &"special")
			BossAttackState.SPECIAL_ACTIVE:
				var attack_clip := StringName(boss_current_attack_data.animation_name) if _is_enemy8() and boss_current_attack_data != null else &"special"
				_play_visual_animation(attack_clip)
			BossAttackState.SPECIAL_RECOVERY:
				_play_visual_animation(&"special_recovery" if _is_enemy8() else &"special")
			BossAttackState.ULTIMATE_STARTUP:
				_play_visual_animation(&"ultimate_startup")
			BossAttackState.ULTIMATE_ACTIVE:
				_play_visual_animation(&"ultimate_attack")
			BossAttackState.ULTIMATE_RECOVERY:
				_play_visual_animation(&"ultimate_recovery")
			_:
				_play_visual_animation(&"special")
	if preserve_authored_special and animated_character_sprite.animation == previous_animation:
		animated_character_sprite.set_frame_and_progress(previous_frame,previous_progress)
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

func _update_seiya_somersault_visual() -> void:
	if _is_seiya_two_hit():
		_update_seiya_two_hit_visual()
		return
	if character_special_data == null or not character_special_data.somersault_on_special or animated_character_sprite == null: return
	var sprite := animated_character_sprite
	if character_special_state != CharacterSpecialState.ACTIVE:
		sprite.rotation = 0.0
		sprite.offset = Vector2.ZERO
		return
	var rotation_time := maxf(0.1,character_special_data.active_time-2.0/Engine.physics_ticks_per_second)
	var progress := clampf((character_special_data.active_time-character_special_timer)/rotation_time,0.0,1.0)
	seiya_somersault_turn = progress*TAU
	var index := mini(int(progress*3.0),2)
	sprite.frame = index
	var authored_angles := [0.0,-PI,-TAU+PI*0.25]
	sprite.rotation = character_special_direction*(-seiya_somersault_turn-authored_angles[index])
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation,index)
	var center := Vector2(texture.get_image().get_used_rect().get_center())-texture.get_size()*0.5
	if sprite.flip_h: center.x = -center.x
	var idle := sprite.sprite_frames.get_frame_texture(&"idle",0)
	var anchor := Vector2(idle.get_image().get_used_rect().get_center())-idle.get_size()*0.5
	if sprite.flip_h: anchor.x = -anchor.x
	var jump := Vector2(0,-105.0*sin(PI*progress))
	sprite.offset = (anchor*sprite.scale+jump).rotated(-sprite.rotation)/sprite.scale-center

func _update_seiya_two_hit_visual() -> void:
	# Incoming launches own their rotation; an idle attack must never reset them.
	if not is_character_special_busy(): return
	var sprite := animated_character_sprite
	sprite.rotation = 0.0
	sprite.offset = Vector2.ZERO
	if character_special_state != CharacterSpecialState.ACTIVE: return
	var elapsed: float = character_special_data.active_time-character_special_timer
	if elapsed < 0.60:
		_play_visual_animation(&"seiya_two_somersault")
		var progress := clampf(elapsed/0.54,0.0,1.0)
		seiya_somersault_turn = progress*TAU
		var index := mini(int(progress*3.0),2)
		sprite.frame = index
		var authored := [0.0,-PI,-TAU]
		sprite.rotation = character_special_direction*(-seiya_somersault_turn-authored[index])
		var texture := sprite.sprite_frames.get_frame_texture(sprite.animation,index)
		var center := _seiya_pose_center(texture)
		if sprite.flip_h: center.x = -center.x
		var idle := sprite.sprite_frames.get_frame_texture(&"idle",0)
		var anchor := _seiya_pose_center(idle)
		if sprite.flip_h: anchor.x = -anchor.x
		var jump := Vector2(0,-70.0*sin(PI*progress))
		sprite.offset = sprite.transform.affine_inverse().basis_xform(anchor*sprite.scale+jump)-center
	else:
		_play_visual_animation(&"seiya_two_sidekick")
		var kick_elapsed: float = elapsed-character_special_data.sidekick_time
		sprite.frame = 0 if kick_elapsed < 0.0 else (1 if kick_elapsed < 0.08 else (2 if kick_elapsed < 0.16 else 3))

func _get_horizontal_movement_input() -> float:
	if is_character_special_busy() and character_special_data != null and (character_special_data.somersault_on_special or character_special_data.somersault_sidekick): return 0.0
	return super._get_horizontal_movement_input()
