extends "res://scripts/player/player_movement.gd"

const PlayerAttackDataScript := preload("res://scripts/data/player_attack_data.gd")
const CombatCommandBufferScript := preload("res://scripts/input/combat_command_buffer.gd")

@export_range(0.10, 0.18, 0.01) var directional_input_buffer_seconds := 0.15
@export_range(0.06, 0.15, 0.01) var directional_repeat_grace_seconds := 0.12
var combat_commands := CombatCommandBufferScript.new()
var last_combat_command: Dictionary = {}
var command_attack_elapsed := 0.0

signal attack_started(attack_id)
signal attack_became_active(attack_id)
signal attack_hit(attack_id, target)
signal attack_finished(attack_id)
signal combo_advanced(attack_id, combo_index)
signal combo_finished
signal hitstop_started(duration)
signal hitstop_finished
signal special_gauge_changed(current_value, max_value)

enum AttackPhase {
	NONE,
	STARTUP,
	ACTIVE,
	RECOVERY,
}

enum CombatInput {
	PUNCH,
	KICK,
	THROW,
	SPECIAL,
}

@export var dev026_combo_input_buffer_time := 0.18
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
@export var dev052_punch_1_hitstop_attacker := 0.045
@export var dev052_punch_1_hitstop_defender := 0.065
@export var dev052_punch_2_hitstop_attacker := 0.050
@export var dev052_punch_2_hitstop_defender := 0.075
@export var dev052_kick_1_hitstop_attacker := 0.060
@export var dev052_kick_1_hitstop_defender := 0.085
@export var dev052_finisher_hitstop_attacker := 0.070
@export var dev052_finisher_hitstop_defender := 0.100
@export var dev052_guard_hitstop_attacker := 0.035
@export var dev052_guard_hitstop_defender := 0.050
@export var technical_combo_escape_hitstun := 0.06
@export_range(0.0, 1.0, 0.05) var technical_ai_guard_escape_rate := 0.70

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
var current_attack_id := ""
var attack_phase := AttackPhase.NONE
var attack_phase_timer := 0.0
var attack_forward_timer := 0.0
var attack_forward_speed := 0.0
var attack_startup_time_actual := 0.0
var attack_active_time_actual := 0.0
var attack_recovery_time_actual := 0.0
var crouch_sweep_hurtbox_adjusted := false
var crouch_sweep_hurtbox_restore_position := Vector2.ZERO
var crouch_sweep_hurtbox_restore_size := Vector2.ZERO
var pending_air_landing_data: PlayerAttackData
var air_kick_attack_data: Resource
var air_punch_down_attack_data: Resource
var crouch_kick_sweep_attack_data: Resource
var has_used_air_attack := false
var jump_combo_pending := false
var is_air_attack_active := false
var jump_kick_air_control_multiplier := 0.65
var ai_jump_launch_pending := false
var ai_jump_launch_direction := 0.0
var ai_jump_launch_speed_multiplier := 1.0


func _physics_process(delta: float) -> void:
	_sample_combat_commands(delta)
	if _update_hit_stop(delta):
		return
	_update_guard_recoil(delta)
	landing_recovery_remaining = maxf(landing_recovery_remaining-delta,0.0)
	jump_landing_visual_timer = maxf(jump_landing_visual_timer - delta, 0.0)
	jump_start_visual_timer = maxf(jump_start_visual_timer - delta, 0.0)

	var direction := _get_horizontal_movement_input()
	var is_kicking := kick_active_timer > 0.0

	_update_invincibility(delta)
	_update_hit_reaction(delta)
	_update_guard_hit(delta)
	_update_throw_state(delta)
	_update_combo_timer(delta)
	_update_cancel_window(delta)
	_update_attack_buffer(delta)
	_update_ai_throw(delta)

	if input_enabled and not is_backstepping and not is_hit and not is_guard_hit and not _is_throw_busy():
		_update_defensive_state(delta)
	elif _uses_ai_guard():
		_update_ai_guard(delta)
	if not is_backstepping:
		_face_opponent()
	if not _is_landing_recovery_busy():
		_update_double_tap_movement(delta)

	var is_air_attack_current := _is_air_attack_currently_active()
	if _is_landing_recovery_busy() or current_attack_type != "" or is_kicking or is_crouching or is_crouch_guarding or is_hit or _is_throw_busy() or is_character_special_busy() or guard_recoil_timer > 0.0 or is_backstepping:
		direction = 0.0
		if is_air_attack_current and input_enabled:
			direction = _get_horizontal_movement_input() * jump_kick_air_control_multiplier
	elif is_guarding:
		direction = 0.0

	if not is_hit and not _is_throw_busy() and not is_character_special_busy():
		if is_on_floor():
			if is_backstepping:
				velocity.x = backstep_direction * move_speed * backstep_speed_multiplier
			elif (is_guarding or is_crouch_guarding) and not is_guard_hit:
				velocity.x = 0.0
			else:
				velocity.x = direction * get_current_move_speed()
		else:
			_update_air_movement(direction, delta)

	var was_on_floor_before_move := is_on_floor()
	if is_on_floor():
		jump_pressed_this_airtime = false
		has_used_air_attack = false
		var ai_jump_requested := not _is_landing_recovery_busy() and not input_enabled and guard_recoil_timer <= 0.0 and ai_jump_launch_pending and current_attack_type == "" and not is_crouching and not is_kicking and not is_guarding and not is_crouch_guarding and not is_hit and not is_guard_hit and not _is_throw_busy() and not is_character_special_busy()
		var player_jump_requested := not _is_landing_recovery_busy() and input_enabled and guard_recoil_timer <= 0.0 and current_attack_type == "" and _is_jump_input_just_pressed() and not jump_pressed_this_airtime and not is_backstepping and not is_crouching and not is_kicking and not is_guarding and not is_crouch_guarding and not is_hit and not is_guard_hit and not _is_throw_busy() and not is_character_special_busy()
		if player_jump_requested or ai_jump_requested:
			has_used_air_attack = false
			_prepare_jump_visual_state()
			_play_audio_manager_se("jump")
			var jump_direction := ai_jump_launch_direction if ai_jump_requested else _get_horizontal_input_direction()
			velocity.y = -jump_power
			if jump_direction != 0.0:
				velocity.x = jump_direction * jump_horizontal_speed * (ai_jump_launch_speed_multiplier if ai_jump_requested else 1.0)
			if ai_jump_requested:
				ai_jump_launch_pending = false
			_spawn_movement_dust(global_position + Vector2(0.0, -4.0), 1.0)
		elif not is_hit:
			velocity.y = 0.0
	else:
		velocity.y += gravity * delta

	_dispatch_combat_command()

	if not is_hit and not is_guard_hit and not _is_throw_busy():
		_update_attack(delta)
		_update_kick(delta)
	_apply_dive_motion()
	_update_visual_state()
	var was_air_attack := is_air_attack_active and current_attack_type != ""
	move_and_slide()
	_apply_post_move_stabilization()
	if not was_on_floor_before_move and is_on_floor():
		jump_combo_pending = false
		if was_air_attack or pending_air_landing_data != null:
			_finish_air_attack_on_landing()
	_update_movement_feedback(direction, was_on_floor_before_move)

	if is_guard_hit and is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)



func _sample_combat_commands(delta: float) -> void:
	combat_commands.buffer_seconds = directional_input_buffer_seconds
	combat_commands.advance(delta)
	if not input_enabled or not is_round_active or current_hp <= 0:
		combat_commands.clear()
		return
	for entry in [["left", "move_left"], ["right", "move_right"], ["down", "down"], ["punch", "attack"], ["kick", "kick"], ["throw", "throw_attack"], ["jump", "jump"]]:
		combat_commands.record(entry[0], Input.is_action_pressed(entry[1]), facing_direction)
	combat_commands.record("special", Input.is_action_pressed("special_attack") or Input.is_action_pressed("special"), facing_direction)


func _dispatch_combat_command() -> void:
	if not input_enabled:
		try_continue_combo()
		return
	if is_hit or is_guard_hit or _is_throw_busy() or is_character_special_busy():
		combat_commands.pending.clear()
		return
	var command: Dictionary = combat_commands.peek()
	if command.is_empty():
		try_continue_combo()
		return
	last_combat_command = command.duplicate()
	if command.kind == "jump":
		if _request_jump_cancel():
			combat_commands.consume(command)
		return
	var move_id := _resolve_directional_move(command)
	if not move_id.is_empty():
		if current_attack_type != "" and move_id == current_attack_id:
			# Street Fighter-like control: never cancel a move into itself.
			# Only a fresh tap in the final 120 ms may fire on recovery.
			# Older taps are dropped, never stacked for later execution.
			if attack_phase != AttackPhase.RECOVERY or attack_phase_timer > directional_repeat_grace_seconds:
				combat_commands.consume(command)
			return
		# Keep the existing explicitly authored cancel rules for DIFFERENT
		# moves, but do not add new animation cancellations for repeats.
		if _request_directional_move(move_id):
			combat_commands.consume(command)
		return
	if current_attack_data != null and not String(current_attack_data.command_direction).is_empty() and command.kind in ["punch", "kick"]:
		var target := _directional_cancel_target(String(command.kind))
		if not target.is_empty() and _request_directional_move(target):
			combat_commands.consume(command)
		return
	var accepted := false
	match String(command.kind):
		"special": accepted = request_combat_input(CombatInput.SPECIAL)
		"throw": accepted = request_combat_input(CombatInput.THROW)
		"punch": accepted = request_combat_input(CombatInput.PUNCH)
		"kick": accepted = request_combat_input(CombatInput.KICK)
	# Legacy combo buffering stores the request even before it can cancel.
	if accepted or (command.kind in ["punch", "kick"] and dev_buffered_attack != &""):
		combat_commands.consume(command)


func _directional_cancel_target(kind: String) -> String:
	for target_id in current_attack_data.cancel_targets:
		var target := _get_attack_data(target_id)
		if target != null and String(target.command_direction).is_empty() and String(target.attack_type).to_lower() == kind:
			return target_id
	return ""


func _resolve_directional_move(command: Dictionary) -> String:
	var best_id := ""
	var best_priority := -2147483648
	for move in attack_data_sequence:
		if move == null or (String(move.command_direction).is_empty() and not bool(move.airborne_only)):
			continue
		if (String(move.command_direction) != "any" and String(move.command_direction) != String(command.direction)) or String(move.attack_type).to_lower() != String(command.kind):
			continue
		if bool(move.ground_only) and not is_on_floor():
			continue
		if bool(move.airborne_only) and is_on_floor():
			continue
		if int(move.command_priority) > best_priority:
			best_id = String(move.attack_id)
			best_priority = int(move.command_priority)
	return best_id


func _request_directional_move(move_id: String, is_ai_request := false) -> bool:
	var move := _get_attack_data(move_id)
	if move != null and String(move.attack_type) == "throw":
		return _request_directional_throw(move, is_ai_request)
	if move == null or not _can_accept_attack_input(is_ai_request):
		return false
	if bool(move.ground_only) and not is_on_floor():
		return false
	if bool(move.airborne_only) and is_on_floor():
		return false
	if current_attack_type != "":
		if current_attack_data == null or float(current_attack_data.cancel_start) < 0.0:
			return false
		if command_attack_elapsed < float(current_attack_data.cancel_start) or command_attack_elapsed > float(current_attack_data.cancel_end):
			return false
		if not current_attack_data.cancel_targets.has(move_id):
			return false
		if not dev_current_attack_connected and not bool(current_attack_data.can_cancel_on_whiff):
			return false
		if dev_current_attack_connected and not bool(current_attack_data.can_cancel_on_hit):
			return false
		if combo_count >= _combo_hit_limit():
			return false
		start_combo_attack(StringName(move_id))
	else:
		if bool(move.airborne_only):
			if not (_can_start_air_kick_attack(is_ai_request) if String(move.attack_type).to_lower() == "kick" else _can_start_air_punch_down_attack(is_ai_request)):
				return false
		elif not _can_start_attack_from_input(_attack_type_to_state_name(String(move.attack_type)), is_ai_request):
			return false
		if bool(move.airborne_only) and jump_combo_pending and combo_count > 0:
			start_combo_attack(StringName(move_id))
		else:
			start_attack(move_id)
		jump_combo_pending = false
	if bool(move.airborne_only) and current_attack_id == move_id:
		is_air_attack_active = true
		has_used_air_attack = true
	return current_attack_id == move_id


func _request_jump_cancel(is_ai_request := false) -> bool:
	if not is_on_floor() or current_attack_data == null or not _can_accept_attack_input(is_ai_request):
		return false
	if not current_attack_data.cancel_targets.has("jump") or not current_attack_data.can_cancel_on_hit or not dev_current_attack_connected:
		return false
	if command_attack_elapsed < current_attack_data.cancel_start or command_attack_elapsed > current_attack_data.cancel_end:
		return false
	if combo_count >= _combo_hit_limit():
		return false
	reset_attack_state(false)
	close_combo_window()
	is_crouching = false
	jump_combo_pending = true
	has_used_air_attack = false
	jump_pressed_this_airtime = true
	_prepare_jump_visual_state()
	velocity.y = -jump_power
	var direction := _get_horizontal_input_direction()
	if direction != 0.0:
		velocity.x = direction * jump_horizontal_speed
	_play_audio_manager_se("jump")
	return true


func _update_air_movement(direction: float, delta: float) -> void:
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * air_move_speed, air_control_acceleration * delta)
		return
	velocity.x = move_toward(velocity.x, 0.0, air_brake_acceleration * delta)


func _sync_attack_visual_phase() -> void:
	# These reviewed clips have an explicit contact pose. Drive them from the
	# combat clock so hitstop and fighter speed modifiers cannot desynchronize it.
	if current_attack_data == null or animated_character_sprite == null:
		return
	var contact_frames := {"player1_punch_1": Vector2i(2, 2), "player1_punch_2": Vector2i(2, 2), "player1_kick_finish": Vector2i(2, 3)}
	var authored_contact := int(current_attack_data.contact_start_frame) >= 0
	var definition: Resource = get("fighter_definition")
	var is_gou := definition != null and String(definition.get("fighter_id")) == "player_02_gou" and definition.get("motion_atlas") != null
	var is_seiya := definition != null and String(definition.get("fighter_id")) == "player_03_seiya" and definition.get("motion_atlas") != null
	var is_leon := definition != null and String(definition.get("fighter_id")) == "enemy_08_leon_crow"
	if is_leon or _uses_readable_grapple():
		for id in ["fallback_punch", "fallback_kick", "fallback_jump_kick", "player1_jump_punch_down", "player1_crouch_punch", "player1_crouch_kick_sweep"]:
			contact_frames[id] = Vector2i(1,1)
	if is_seiya:
		for id in ["player3_punch_1", "player3_punch_2", "player3_punch_3", "player3_kick_finish", "player1_crouch_kick_sweep"]:
			contact_frames[id] = Vector2i(3, 3)
		contact_frames["fallback_jump_kick"] = Vector2i(1, 1)
		contact_frames["player1_jump_punch_down"] = Vector2i(1, 1)
	if is_gou:
		for id in ["player2_punch_1", "player2_punch_2", "player2_kick_finish", "player1_crouch_kick_sweep"]:
			contact_frames[id] = Vector2i(3, 3)
		contact_frames["fallback_jump_kick"] = Vector2i(1, 1)
		contact_frames["player1_jump_punch_down"] = Vector2i(1, 1)
	if definition != null and String(definition.get("fighter_id")) == "enemy_01_crusher":
		contact_frames["fallback_punch"] = Vector2i(1, 1)
		contact_frames["fallback_kick"] = Vector2i(1, 1)
		contact_frames["fallback_jump_kick"] = Vector2i(2, 2)
		contact_frames["player1_jump_punch_down"] = Vector2i(2, 2)
	if definition != null and String(definition.get("fighter_id")) == "enemy_04_rei_kageyama":
		for id in ["rei_straight", "rei_uppercut", "rei_roundhouse", "rei_air_kick", "rei_air_punch", "rei_sweep"]:
			contact_frames[id] = Vector2i(1, 1)
	if definition != null and String(definition.get("fighter_id")) == "enemy_07_teki_fighter":
		for id in ["teki_straight", "teki_elbow", "teki_high_kick", "teki_sweep", "teki_air_punch", "teki_air_kick"]:
			contact_frames[id] = Vector2i(1, 1)
	if definition != null and String(definition.get("fighter_id")) == "enemy_05_cross_murasame":
		for id in ["cross_punch","cross_chop","cross_wrist_finish","cross_kick","cross_knee","cross_joint_finish","cross_sweep","cross_air_punch","cross_air_kick"]:
			contact_frames[id] = Vector2i(2, 2) if id.ends_with("finish") else Vector2i(1, 1)
	# Authored move data takes precedence over legacy fighter fallbacks.
	if authored_contact:
		contact_frames[current_attack_id] = Vector2i(current_attack_data.contact_start_frame, maxi(current_attack_data.contact_end_frame, current_attack_data.contact_start_frame))
	if not contact_frames.has(current_attack_id) or (not authored_contact and is_crouching and current_attack_id != "rei_sweep" and current_attack_id != "teki_sweep" and current_attack_id != "cross_sweep" and not is_gou and not is_seiya and not is_leon and not _uses_readable_grapple()):
		return
	var contact: Vector2i = contact_frames[current_attack_id]
	var count := animated_character_sprite.sprite_frames.get_frame_count(animated_character_sprite.animation)
	var first := 0
	var last := contact.x - 1
	var duration := attack_startup_time_actual
	if attack_phase == AttackPhase.ACTIVE:
		first = contact.x
		last = contact.y
		duration = attack_active_time_actual
	elif attack_phase == AttackPhase.RECOVERY:
		first = contact.y + 1
		last = count - 1
		duration = attack_recovery_time_actual
	var progress := clampf(1.0 - attack_phase_timer / maxf(duration, 0.001), 0.0, 0.9999)
	animated_character_sprite.pause()
	animated_character_sprite.set_frame_and_progress(clampi(first + int(progress * (last - first + 1)), 0, count - 1), 0.0)
	if current_attack_id == "player1_kick_finish" and attack_phase == AttackPhase.ACTIVE:
		kick_area.position.y = (-90.0 if animated_character_sprite.frame == 2 else -140.0) * battle_visual_scale_multiplier


func _dev_start_attack() -> void:
	request_attack_input(&"Punch", true)


func _dev_start_kick() -> void:
	request_attack_input(&"Kick", true)


func _start_throw() -> void:
	directional_throw_data = null
	interrupt_combo()
	super._start_throw()


var directional_throw_data: PlayerAttackData
var directional_throw_origin := Vector2.ZERO
var directional_throw_victim_origin := Vector2.ZERO
var directional_throw_facing := 1.0
var directional_throw_elapsed := 0.0
var directional_throw_prepared := false


func _request_directional_throw(move: PlayerAttackData, is_ai_request := false) -> bool:
	if not is_ai_request and not input_enabled:
		return false
	# Down is a command, so allow it to leave the crouch pose before grabbing.
	var crouched := is_crouching
	is_crouching = false
	if is_backstepping or is_character_special_busy() or not _can_start_throw():
		is_crouching = crouched
		return false
	_start_throw()
	directional_throw_data = move
	directional_throw_origin = global_position
	directional_throw_facing = facing_direction
	directional_throw_elapsed = 0.0
	directional_throw_prepared = false
	throw_startup_timer = move.startup_time
	_play_throw_animation("throw_start")
	return true


func _update_active_throw(delta: float) -> void:
	directional_throw_elapsed += delta
	if directional_throw_data != null and throw_state == "THROW_HOLD" and not directional_throw_prepared and directional_throw_data.throw_prepare_seconds > 0.0:
		if throw_hold_timer <= directional_throw_data.throw_prepare_seconds + delta and _is_valid_throw_target(current_throw_target):
			directional_throw_prepared = true
			if _has_visual_animation(directional_throw_data.throw_prepare_animation):
				_play_visual_animation(directional_throw_data.throw_prepare_animation, true)
			if current_throw_target._has_visual_animation(directional_throw_data.throw_victim_prepare_animation):
				current_throw_target._play_visual_animation(directional_throw_data.throw_victim_prepare_animation, true)
	super._update_active_throw(delta)


func _get_throw_target() -> Node:
	var target := super._get_throw_target()
	if target != null or directional_throw_data == null or not is_throwing or throw_state != "THROW_STARTUP":
		return target
	var move := directional_throw_data
	if move.throw_counter_range <= 0.0 or directional_throw_elapsed > move.throw_counter_window:
		return null
	target = _get_opponent()
	if target == null or not target.can_be_thrown(self) or not _is_facing_attacker(target):
		return null
	if absf(target.global_position.y - global_position.y) > throw_vertical_tolerance or _get_throw_gap_to(target) > move.throw_counter_range:
		return null
	# Observe motion toward us, not the opponent's input or a move-ID matchup.
	if target.velocity.x * signf(global_position.x - target.global_position.x) < 80.0:
		return null
	return target


func _connect_throw(target: Node, damage_override: int = -1) -> void:
	if directional_throw_data == null:
		super._connect_throw(target, damage_override)
		return
	directional_throw_victim_origin = target.global_position
	var saved_damage := throw_damage
	var saved_hold := throw_hold_time
	var saved_force := throw_knockback
	var saved_vertical := throw_vertical_force
	var resistance := 1.0
	var definition: Resource = target.get("fighter_definition")
	if definition != null:
		resistance = clampf(float(definition.throw_received_damage_scale), 0.25, 1.0)
	throw_damage = maxi(1, roundi(saved_damage * directional_throw_data.damage_multiplier * resistance))
	throw_hold_time = directional_throw_data.throw_hold_seconds
	throw_knockback = directional_throw_data.throw_velocity.x
	throw_vertical_force = directional_throw_data.throw_velocity.y
	super._connect_throw(target, damage_override)
	throw_damage = saved_damage
	throw_hold_time = saved_hold
	throw_knockback = saved_force
	throw_vertical_force = saved_vertical


func _release_throw() -> void:
	if directional_throw_data == null:
		super._release_throw()
		return
	if has_throw_damage_applied:
		return
	var target := current_throw_target
	if _is_valid_throw_target(target) and directional_throw_data.throw_release_offset != Vector2.ZERO:
		var offset := directional_throw_data.throw_release_offset
		target.global_position.x += offset.x * directional_throw_facing
		target.global_position.y = minf(target.global_position.y, stage_floor_y + directional_throw_data.throw_hold_offset.y + offset.y)
	if _is_valid_throw_target(target) and directional_throw_data.throw_swap_positions:
		global_position.x = clampf(directional_throw_victim_origin.x, _stage_min_x(), _stage_max_x())
		target.global_position.x = clampf(directional_throw_origin.x, _stage_min_x(), _stage_max_x())
		target.global_position.y = stage_floor_y
		if directional_throw_data.throw_face_swapped_target:
			facing_direction = -directional_throw_facing
			target.facing_direction = directional_throw_facing
			_set_visual_facing()
			target._set_visual_facing()
		target.pending_throw_velocity = Vector2(-directional_throw_data.throw_velocity.x * directional_throw_facing, directional_throw_data.throw_velocity.y)
		target.pending_throw_direction = -directional_throw_facing
	super._release_throw()
	throw_recovery_timer = directional_throw_data.recovery_time


func _fail_throw() -> void:
	super._fail_throw()
	if directional_throw_data != null:
		throw_recovery_timer = directional_throw_data.throw_whiff_seconds
		if _has_visual_animation(directional_throw_data.throw_whiff_animation):
			_play_visual_animation(directional_throw_data.throw_whiff_animation, true)


func _finish_throw() -> void:
	super._finish_throw()
	directional_throw_data = null
	directional_throw_prepared = false


func _lock_throw_target_position(target: Node) -> void:
	if directional_throw_data == null:
		super._lock_throw_target_position(target)
		return
	var offset := directional_throw_data.throw_hold_offset
	var target_definition: Resource = target.get("fighter_definition")
	if target_definition != null:
		var configured = directional_throw_data.throw_hold_offsets_by_fighter.get(String(target_definition.fighter_id), offset)
		if configured is Vector2:
			offset = configured
	if offset == Vector2.ZERO:
		super._lock_throw_target_position(target)
		return
	offset.x *= directional_throw_facing
	var target_x := clampf(global_position.x + offset.x, _stage_min_x() + 64.0, _stage_max_x() - 64.0)
	global_position.x = clampf(target_x - offset.x, _stage_min_x(), _stage_max_x())
	var preparation := 0.0
	if directional_throw_data.throw_prepare_seconds > 0.0:
		preparation = clampf(1.0 - throw_hold_timer / directional_throw_data.throw_prepare_seconds, 0.0, 1.0)
	target.global_position = Vector2(target_x, stage_floor_y + offset.y + directional_throw_data.throw_release_offset.y * preparation)
	target.velocity = Vector2.ZERO
	target.facing_direction = -directional_throw_facing
	target._set_visual_facing()


func _play_throw_animation(animation_name := "Throw") -> void:
	if directional_throw_data != null:
		var authored := directional_throw_data.throw_release_animation if animation_name == "throw_release" else directional_throw_data.throw_start_animation
		if authored == &"":
			authored = directional_throw_data.throw_prepare_animation
		if animation_name in ["throw_start", "throw_release"] and _has_visual_animation(authored):
			_play_visual_animation(authored, true)
			return
	if directional_throw_data != null and animation_name == "throw_hold":
		var hold_clip := directional_throw_data.throw_hold_animation
		if hold_clip == &"":
			hold_clip = &"directional_throw_hold"
		if _has_visual_animation(hold_clip):
			_play_visual_animation(hold_clip, true)
			return
	super._play_throw_animation(animation_name)


func _directional_throw_visual_animation() -> StringName:
	if directional_throw_data == null:
		return &""
	var clip: StringName = &""
	if throw_state == "THROW_WHIFF" and _has_visual_animation(directional_throw_data.throw_whiff_animation):
		clip = directional_throw_data.throw_whiff_animation
	elif throw_state in ["THROW_STARTUP", "THROW_WHIFF"]:
		clip = directional_throw_data.throw_start_animation
	elif throw_state == "THROW_HOLD" and directional_throw_prepared:
		clip = directional_throw_data.throw_prepare_animation
	elif throw_state == "THROW_HOLD":
		clip = directional_throw_data.throw_hold_animation
	elif throw_state == "THROW_RECOVERY":
		clip = directional_throw_data.throw_release_animation
	return clip if _has_visual_animation(clip) else &""


func _directional_throw_victim_animation() -> StringName:
	if not is_instance_valid(pending_throw_attacker) or pending_throw_attacker.get("directional_throw_data") == null:
		return &""
	var holder := pending_throw_attacker
	if holder.directional_throw_prepared:
		var clip: StringName = holder.directional_throw_data.throw_victim_prepare_animation
		if _has_visual_animation(clip):
			return clip
	var hold_clip: StringName = holder.directional_throw_data.throw_victim_hold_animation
	if _has_visual_animation(hold_clip):
		return hold_clip
	# A fighter without a dedicated directional victim atlas must still show a
	# held pose, rather than falling through to a flying/thrown pose while held.
	if _has_visual_animation(&"grabbed"):
		return &"grabbed"
	return &""


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
	dev026_max_combo_hits = mini(3, maxi(1, attack_data_sequence.size()))
	reset_attack_state()


func set_air_kick_attack_data(data: Resource) -> void:
	air_kick_attack_data = data
	if air_kick_attack_data == null:
		return
	var attack_id := String(air_kick_attack_data.attack_id)
	if attack_id.is_empty():
		return
	attack_data_by_id[attack_id] = air_kick_attack_data


func set_air_punch_down_attack_data(data: Resource) -> void:
	air_punch_down_attack_data = data
	if air_punch_down_attack_data == null:
		return
	var attack_id := String(air_punch_down_attack_data.attack_id)
	if attack_id.is_empty():
		return
	attack_data_by_id[attack_id] = air_punch_down_attack_data


func set_crouch_kick_sweep_attack_data(data: Resource) -> void:
	crouch_kick_sweep_attack_data = data
	if crouch_kick_sweep_attack_data == null:
		return
	var attack_id := String(crouch_kick_sweep_attack_data.attack_id)
	if attack_id.is_empty():
		return
	attack_data_by_id[attack_id] = crouch_kick_sweep_attack_data


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


func request_air_kick_attack() -> void:
	var attack_id := _ensure_air_kick_attack_data()
	if attack_id.is_empty():
		return
	start_attack(attack_id)
	if current_attack_id == attack_id:
		is_air_attack_active = true
		has_used_air_attack = true


func request_air_punch_down_attack() -> void:
	var attack_id := _ensure_air_punch_down_attack_data()
	if attack_id.is_empty():
		return
	start_attack(attack_id)
	if current_attack_id == attack_id:
		is_air_attack_active = true
		has_used_air_attack = true


func request_crouch_kick_sweep_attack() -> void:
	var attack_id := _ensure_crouch_kick_sweep_attack_data()
	if attack_id.is_empty():
		return
	start_attack(attack_id)
	if current_attack_id == attack_id:
		is_crouching = true


func request_combat_input(combat_input: CombatInput, is_ai_request := false) -> bool:
	if not is_ai_request and is_backstepping:
		return false
	match combat_input:
		CombatInput.PUNCH:
			return request_attack_input(&"Punch", is_ai_request)
		CombatInput.KICK:
			return request_attack_input(&"Kick", is_ai_request)
		CombatInput.THROW:
			if not is_ai_request and not input_enabled:
				return false
			if is_character_special_busy() or not _can_start_throw():
				return false
			_start_throw()
			return true
		CombatInput.SPECIAL:
			return request_character_special(is_ai_request)
		_:
			return false


func request_attack_input(attack_type: StringName, is_ai_request := false) -> bool:
	if attack_type != &"Punch" and attack_type != &"Kick":
		return false
	if not _can_accept_attack_input(is_ai_request):
		return false
	if attack_type == &"Punch" and _can_start_air_punch_down_attack(is_ai_request):
		request_air_punch_down_attack()
		return current_attack_type == "Punch"
	if attack_type == &"Kick" and _can_start_air_kick_attack(is_ai_request):
		request_air_kick_attack()
		return current_attack_type == "Kick"
	if attack_type == &"Kick" and _can_start_crouch_kick_sweep_attack(is_ai_request):
		request_crouch_kick_sweep_attack()
		return current_attack_type == "Kick"
	if current_attack_type != "":
		buffer_attack(attack_type)
		return try_continue_combo()
	if not _can_start_attack_from_input(attack_type, is_ai_request):
		return false
	if attack_type == &"Kick":
		request_kick_attack()
	else:
		request_punch_attack()
	return current_attack_type != ""


func _can_accept_attack_input(is_ai_request: bool) -> bool:
	if not is_ai_request and not input_enabled:
		return false
	return not _is_landing_recovery_busy() and current_hp > 0 and is_round_active and guard_recoil_timer <= 0.0 and not is_hit and not is_guard_hit and not _is_throw_busy() and not is_character_special_busy() and (is_ai_request or not _is_throw_input_held())


func _can_start_attack_from_input(attack_type: StringName, is_ai_request: bool) -> bool:
	if current_attack_type != "" or is_guarding or is_crouch_guarding or is_character_special_busy():
		return false
	if not is_ai_request and not input_enabled:
		return false
	if not is_on_floor():
		return false
	if attack_type == &"Punch":
		return attack_cooldown_timer <= 0.0 and kick_active_timer <= 0.0
	return kick_cooldown_timer <= 0.0 and attack_active_timer <= 0.0


func _can_start_air_kick_attack(is_ai_request: bool) -> bool:
	return current_attack_type == "" \
		and not is_on_floor() \
		and not has_used_air_attack \
		and current_hp > 0 \
		and is_round_active \
		and not is_hit \
		and not is_guard_hit \
		and not is_guarding \
		and not is_crouching \
		and not is_crouch_guarding \
		and not _is_throw_busy() \
		and not is_character_special_busy() \
		and kick_cooldown_timer <= 0.0 \
		and attack_active_timer <= 0.0 \
		and (is_ai_request or input_enabled)


func _can_start_air_punch_down_attack(is_ai_request: bool) -> bool:
	return current_attack_type == "" \
		and not is_on_floor() \
		and not has_used_air_attack \
		and current_hp > 0 \
		and is_round_active \
		and not is_hit \
		and not is_guard_hit \
		and not is_guarding \
		and not is_crouching \
		and not is_crouch_guarding \
		and not _is_throw_busy() \
		and not is_character_special_busy() \
		and attack_cooldown_timer <= 0.0 \
		and kick_active_timer <= 0.0 \
		and (is_ai_request or input_enabled)


func _can_start_crouch_kick_sweep_attack(is_ai_request: bool) -> bool:
	return current_attack_type == "" \
		and is_on_floor() \
		and is_crouching \
		and not is_guarding \
		and not is_crouch_guarding \
		and current_hp > 0 \
		and is_round_active \
		and not is_hit \
		and not is_guard_hit \
		and not _is_throw_busy() \
		and not is_character_special_busy() \
		and kick_cooldown_timer <= 0.0 \
		and attack_active_timer <= 0.0 \
		and (is_ai_request or input_enabled)


func start_attack(attack_id: String) -> void:
	var attack_data := _get_attack_data(attack_id)
	if attack_data == null:
		return

	if not dev_starting_combo_attack:
		dev_combo_step = 1
		dev_last_attack_type = &""
	else:
		dev_combo_step = mini(combo_count + 1, _combo_hit_limit())

	reset_attack_state(false)
	current_attack_data = attack_data
	if attack_data.airborne_only and attack_data.landing_recovery > 0.0:
		pending_air_landing_data = attack_data
	current_attack_id = attack_id
	command_attack_elapsed = 0.0
	current_attack_type = _attack_type_to_state_name(String(attack_data.attack_type))
	if not String(attack_data.command_direction).is_empty():
		is_crouching = false
	_play_audio_manager_se("kick_whiff" if current_attack_type == "Kick" else "punch_whiff")
	_apply_crouch_sweep_hurtbox_if_needed(attack_data)
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
	_restore_crouch_sweep_hurtbox()
	clear_attack_movement()
	if combo_count > 0 and not dev_current_attack_connected:
		reset_combo()
	_settle_crouch_state_after_action()
	current_attack_type = ""
	current_attack_data = null
	current_attack_id = ""
	attack_phase = AttackPhase.NONE
	attack_phase_timer = 0.0
	attack_active_timer = 0.0
	kick_active_timer = 0.0
	attack_cooldown_timer = 0.0
	kick_cooldown_timer = 0.0
	is_air_attack_active = false
	if is_crouching:
		_play_visual_animation(&"crouch_idle", true)
	clear_attack_buffer()
	close_combo_window()
	if combo_count >= _combo_hit_limit():
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
	var scale_multiplier := battle_visual_scale_multiplier
	target_area.position = Vector2(float(data.hitbox_offset.x) * scale_multiplier * facing_direction, float(data.hitbox_offset.y) * scale_multiplier)
	if is_crouching and String(data.attack_type).to_lower() == "punch":
		target_area.position.y = -65.0 * scale_multiplier
	# Gou's new art uses a feet origin. Keep damage/timing unchanged, but place
	# legacy air/low hitboxes on the authored fists and geta instead of the floor.
	var definition: Resource = get("fighter_definition")
	if definition != null and String(definition.get("fighter_id")) == "player_02_gou" and definition.get("motion_atlas") != null:
		var offset := Vector2(data.hitbox_offset)
		if is_crouching and String(data.attack_type).to_lower() == "punch":
			offset = Vector2(95, -95)
		elif String(data.animation_name) == "jump_kick":
			offset = Vector2(82, -82)
		elif String(data.animation_name) == "jump_punch_down":
			offset = Vector2(76, -120)
		elif String(data.animation_name) in ["crouch_kick_sweep", "crouch_sweep_kick"]:
			offset = Vector2(100, -24)
		target_area.position = Vector2(offset.x * facing_direction, offset.y) * scale_multiplier
	if definition != null and String(definition.get("fighter_id")) == "player_03_seiya" and definition.get("motion_atlas") != null:
		var offset := Vector2(data.hitbox_offset)
		if is_crouching and String(data.attack_type).to_lower() == "punch":
			offset = Vector2(86, -72)
		elif String(data.animation_name) == "jump_kick":
			offset = Vector2(90, -85)
		elif String(data.animation_name) == "jump_punch_down":
			offset = Vector2(85, -90)
		elif String(data.animation_name) in ["crouch_kick_sweep", "crouch_sweep_kick"]:
			offset = Vector2(96, -24)
		target_area.position = Vector2(offset.x * facing_direction, offset.y) * scale_multiplier
	if target_shape != null:
		if target_shape.shape == null or not (target_shape.shape is RectangleShape2D):
			target_shape.shape = RectangleShape2D.new()
		else:
			target_shape.shape = target_shape.shape.duplicate()
		target_shape.shape.size = data.hitbox_size * scale_multiplier
	if definition != null:
		var geometry_scale: float = definition.combat_geometry_scale
		target_area.position *= geometry_scale
		target_shape.shape.size *= geometry_scale


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
			if attack_data != null and String(attack_data.command_direction) not in ["", "neutral"]:
				continue
			if attack_data != null and String(attack_data.attack_type).to_lower() == normalized_type:
				return String(attack_data.attack_id)
		return ""

	for attack_data in attack_data_sequence:
		if attack_data != null and String(attack_data.command_direction) not in ["", "neutral"]:
			continue
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
	if current_attack_data != null and not String(current_attack_data.command_direction).is_empty():
		velocity.x = attack_forward_speed * step / maxf(delta, 0.001)
	else:
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
	_restore_crouch_sweep_hurtbox()
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
	is_air_attack_active = false
	if clear_combo_state:
		clear_attack_buffer()
		close_combo_window()


func _apply_crouch_sweep_hurtbox_if_needed(attack_data: Resource) -> void:
	if attack_data == null or String(attack_data.animation_name) != "crouch_sweep_kick" or hurt_shape == null or not (hurt_shape.shape is RectangleShape2D):
		return
	crouch_sweep_hurtbox_restore_position = hurt_shape.position
	crouch_sweep_hurtbox_restore_size = hurt_shape.shape.size
	hurt_shape.shape = hurt_shape.shape.duplicate()
	hurt_shape.position = Vector2(0.0, -39.0)
	hurt_shape.shape.size = Vector2(86.0, 78.0)
	crouch_sweep_hurtbox_adjusted = true


func _restore_crouch_sweep_hurtbox() -> void:
	if not crouch_sweep_hurtbox_adjusted or hurt_shape == null or not (hurt_shape.shape is RectangleShape2D):
		return
	hurt_shape.position = crouch_sweep_hurtbox_restore_position
	hurt_shape.shape = hurt_shape.shape.duplicate()
	hurt_shape.shape.size = crouch_sweep_hurtbox_restore_size
	crouch_sweep_hurtbox_adjusted = false


func request_character_special(_is_ai_request := false) -> bool:
	return false


func is_character_special_busy() -> bool:
	return false


func _is_special_input_just_pressed() -> bool:
	var primary := InputMap.has_action("special_attack") and Input.is_action_just_pressed("special_attack")
	var legacy := InputMap.has_action("special") and Input.is_action_just_pressed("special")
	return primary or legacy


func receive_attack(attack_data: Dictionary, attack_direction: float, hit_position: Vector2, attacker: Node) -> bool:
	if _try_guard_technical_combo_escape(attack_data, attack_direction, hit_position, attacker):
		return false
	if _can_guard_attack(attack_data, attacker):
		_receive_guarded_attack(attack_data, attack_direction, hit_position, attacker)
		return false

	interrupt_combo()
	reset_attack_state()
	_cancel_current_action()
	_enter_hit_state()
	var combo_hit_index := int(attack_data.get("combo_hit_index", 1))
	if _is_technical_combo_attack(attack_data) and combo_hit_index >= 2:
		# The first two hits may confirm, but the defender recovers before later
		# technical hits so holding guard or countering can break the sequence.
		hit_reaction_timer = minf(hit_reaction_timer, technical_combo_escape_hitstun)
	elif combo_hit_index < _combo_hit_limit():
		hit_reaction_timer = maxf(hit_reaction_timer, dev026_combo_hitstun_time)
	apply_damage(attack_data["damage"])
	damage_feedback_requested.emit(self, int(attack_data["damage"]), false, hit_position)
	_flash_damage()
	if attacker != null and attacker.has_method("register_combo_hit"):
		attacker.register_combo_hit(self)
		if current_hp == 0 and attacker.has_method("_finish_combo_after_ko"):
			attacker._finish_combo_after_ko()
	_apply_knockback(attack_data, attack_direction)
	if not bool(attack_data.get("allows_combo_followup", false)):
		_start_invincibility()
	_start_hit_stop_seconds(_get_defender_hitstop_duration(attack_data))
	_spawn_hit_effect(hit_position, attack_data["effect_size"])
	_play_hit_se(attack_data["se_type"])
	if attacker != null and attacker.has_method("start_hit_stop_seconds"):
		attacker.start_hit_stop_seconds(_get_attacker_hitstop_duration(attack_data))
	screen_shake_requested.emit(attack_data["screen_shake"])
	if current_hp <= 0:
		_play_ko_feedback(hit_position, attack_direction)
	return true


func _apply_attack_to_target(target: Node, attack_data: Dictionary) -> void:
	if not target.has_method("receive_attack"):
		return

	var scaled_attack_data := _build_combo_scaled_attack_data(attack_data, target)
	var did_hit: bool = bool(target.receive_attack(scaled_attack_data, facing_direction, _get_hit_position(target), self))
	if did_hit:
		register_attack_hit(target)
		if has_method("gain_special_gauge_for_attack_hit"):
			call("gain_special_gauge_for_attack_hit", scaled_attack_data)


func _receive_guarded_attack(attack_data: Dictionary, attack_direction: float, hit_position: Vector2, attacker: Node) -> void:
	_select_special_guard_reaction(attack_data)
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
	if attacker != null and attacker.has_method("apply_guard_recoil"):
		attacker.apply_guard_recoil(attack_data)
	if attacker != null and attacker.has_method("gain_special_gauge_for_guarded_attack"):
		attacker.gain_special_gauge_for_guarded_attack(attack_data)
	_enter_guard_hit_state()
	var authored_guard_time := float(attack_data.get("guard_hit_time", guard_hit_timer))
	var guarded_attack_type := String(attack_data.get("attack_type", "")).to_lower()
	guard_hit_timer = authored_guard_time if guarded_attack_type == "special" or guarded_attack_type == "ultimate" else minf(authored_guard_time, 0.09)
	special_guard_duration = guard_hit_timer if special_guard_animation != &"" else 0.0
	var guard_damage := _get_guard_damage_from_attack_data(attack_data)
	apply_damage(guard_damage)
	if has_method("gain_special_gauge_from_damage"):
		call("gain_special_gauge_from_damage", guard_damage, attack_data)
	damage_feedback_requested.emit(self, guard_damage, true, hit_position)
	_flash_guard()
	_apply_guard_knockback(attack_data, attack_direction)
	_start_hit_stop_seconds(_get_guard_defender_hitstop_duration(attack_data))
	_spawn_guard_effect(hit_position)
	_play_guard_se()
	if attacker != null and attacker.has_method("start_hit_stop_seconds"):
		attacker.start_hit_stop_seconds(_get_guard_attacker_hitstop_duration(attack_data))
	if has_method("_on_successful_guard"):
		call("_on_successful_guard", attack_data, attacker)
	if current_hp <= 0:
		_play_ko_feedback(hit_position, attack_direction)


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
	command_attack_elapsed += delta

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

	combo_count = mini(combo_count + 1, _combo_hit_limit())
	dev_current_attack_connected = true
	dev_last_attack_type = StringName(current_attack_type)
	dev_combo_step = combo_count
	combo_timer = dev026_combo_reset_time
	combo_changed.emit(combo_count, self)
	combo_advanced.emit(current_attack_id, combo_count)
	if combo_log_enabled and combo_count >= 2:
		print("Combo: %s %d HIT" % [_get_combo_log_name(), combo_count])

	if combo_count < _combo_hit_limit() and current_hp > 0:
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



func _try_cancel_attack_from_input() -> bool:
	return try_continue_combo()


func _can_cancel_attack() -> bool:
	return is_round_active and dev_combo_window_open and can_cancel and cancel_window_timer > 0.0 and current_attack_type != "" and current_hp > 0 and (dev_current_attack_connected or can_chain_on_whiff()) and combo_count < _combo_hit_limit() and is_on_floor() and not is_hit and not is_guard_hit and not is_guarding and not is_crouching and not is_crouch_guarding and not _is_throw_busy()


func can_chain_attack(current_attack: StringName, next_attack: StringName) -> bool:
	if current_attack_data == null:
		return false
	if current_attack == &"Punch" and combo_count <= 1:
		return next_attack == &"Punch" and not get_next_attack_id("punch").is_empty()
	if current_attack == &"Punch" and combo_count == 2:
		return next_attack == &"Kick" and not get_next_attack_id("kick").is_empty()
	if current_attack == &"Kick" and combo_count <= 1:
		return next_attack == &"Kick" and not get_next_attack_id("kick").is_empty()
	return false


func try_continue_combo() -> bool:
	if current_attack_data != null and not String(current_attack_data.command_direction).is_empty():
		var target := _directional_cancel_target(String(dev_buffered_attack).to_lower())
		if not target.is_empty() and _request_directional_move(target, not input_enabled):
			clear_attack_buffer()
			return true
		return false
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
	dev_combo_step = mini(combo_count + 1, _combo_hit_limit())
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
	var damage_scale := _get_combo_damage_scale_for_hit(hit_index)
	scaled_attack_data["base_damage"] = attack_data["damage"]
	scaled_attack_data["damage"] = maxi(1, int(round(float(attack_data["damage"]) * damage_scale)))
	scaled_attack_data["knockback_x"] = float(attack_data["knockback_x"]) * knockback_scale
	scaled_attack_data["knockback_y"] = float(attack_data["knockback_y"]) * knockback_scale
	scaled_attack_data["combo_hit_index"] = hit_index
	scaled_attack_data["attacker_archetype"] = String(_get_combat_archetype())
	# The receiver must judge finishers from the attacker's combo definition, not its own.
	scaled_attack_data["combo_hit_max"] = _combo_hit_limit()
	scaled_attack_data["damage_scale"] = damage_scale
	scaled_attack_data["allows_combo_followup"] = current_attack_data != null and (not current_attack_data.next_attack_ids.is_empty() or not current_attack_data.cancel_targets.is_empty())
	return scaled_attack_data


func _get_next_combo_hit_index(target: Node) -> int:
	if combo_timer <= 0.0 or dev_combo_target == null or not is_instance_valid(dev_combo_target) or dev_combo_target != target:
		return 1
	return mini(combo_count + 1, _combo_hit_limit())


func get_combo_damage_scale() -> float:
	return _get_combo_damage_scale_for_hit(maxi(combo_count, 1))


func _get_combo_damage_scale_for_hit(hit_index: int) -> float:
	var archetype := _get_combat_archetype()
	if archetype == &"technical":
		if hit_index <= 1:
			return 1.0
		if hit_index == 2:
			return 0.85
		if hit_index == 3:
			return 0.70
		if hit_index == 4:
			return 0.58
		return 0.50
	if archetype == &"power":
		return 1.0 if hit_index <= 1 else 0.95
	if archetype == &"balance":
		if hit_index <= 1:
			return 1.0
		if hit_index == 2:
			return 0.90
		return 0.80
	if hit_index <= 2:
		return 1.0
	if hit_index <= 4:
		return dev026_second_hit_damage_scale
	if hit_index <= 6:
		return dev026_third_hit_damage_scale
	if hit_index <= 8:
		return 0.70
	return 0.60


func _get_combat_archetype() -> StringName:
	var definition: Resource = get("fighter_definition")
	if definition == null:
		return &"other"
	var fighter_type := String(definition.get("fighter_type")).to_upper()
	if fighter_type.contains("POWER"):
		return &"power"
	if fighter_type == "BALANCE":
		return &"balance"
	if fighter_type.contains("TECHNICAL") or fighter_type.contains("SPEED"):
		return &"technical"
	return &"other"


func _is_technical_combo_attack(attack_data: Dictionary) -> bool:
	return String(attack_data.get("attacker_archetype", "")).to_lower() == "technical"


func _try_guard_technical_combo_escape(attack_data: Dictionary, attack_direction: float, hit_position: Vector2, attacker: Node) -> bool:
	if not _is_technical_combo_attack(attack_data):
		return false
	if int(attack_data.get("combo_hit_index", 1)) < 3:
		return false
	if not bool(attack_data.get("is_guardable", true)) or current_hp <= 0 or not is_round_active or not is_on_floor():
		return false
	if String(attack_data.get("attack_height", "middle")).to_lower() == "throw":
		return false

	var wants_guard := is_guarding or is_crouch_guarding
	if input_enabled:
		wants_guard = Input.is_action_pressed("guard")
		if wants_guard:
			is_crouch_guarding = _is_crouch_input_pressed()
			is_guarding = true
			guard_type = "low" if is_crouch_guarding else "high"
	elif name == "Enemy":
		wants_guard = randf() <= technical_ai_guard_escape_rate
		if wants_guard:
			var attack_height := String(attack_data.get("attack_height", "middle")).to_lower()
			is_crouch_guarding = attack_height == "low"
			is_guarding = true
			guard_type = "low" if is_crouch_guarding else "high"

	if not wants_guard or not _is_facing_attacker(attacker) or not _is_attack_height_guardable(String(attack_data.get("attack_height", "middle"))):
		return false

	is_hit = false
	hit_reaction_timer = 0.0
	_receive_guarded_attack(attack_data, attack_direction, hit_position, attacker)
	return true


func get_combo_knockback_scale() -> float:
	return _get_combo_knockback_scale_for_hit(maxi(combo_count, 1))


func _get_combo_knockback_scale_for_hit(hit_index: int) -> float:
	if hit_index <= 1:
		return dev026_first_combo_knockback_scale
	if hit_index == 2 and _combo_hit_limit() > 2:
		return dev026_second_combo_knockback_scale
	return 1.0


func interrupt_combo() -> void:
	jump_combo_pending = false
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
	if not dev_combo_window_open or dev_buffered_attack != &"" or combo_count >= _combo_hit_limit():
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
			if combo_count <= 1 and not get_next_attack_id("punch").is_empty():
				return &"Punch"
			if combo_count == 2 and not get_next_attack_id("kick").is_empty():
				return &"Kick"
			return &""
		&"Kick":
			return &""
		_:
			return &""


func _play_attack_animation(animation_name: StringName) -> void:
	_play_visual_animation(animation_name, true)
	if uses_animated_character_art:
		if animation_player != null and animation_player.is_playing():
			animation_player.stop()
		return
	if animation_player == null:
		return
	if animation_player.has_animation(String(animation_name)):
		animation_player.play(String(animation_name))
	elif animation_player.has_animation("Punch") and current_attack_type == "Punch":
		animation_player.play("Punch")
	elif animation_player.has_animation("Kick") and current_attack_type == "Kick":
		animation_player.play("Kick")


func _get_attack_animation_name(attack_type: StringName) -> StringName:
	if _is_cross_grappler() and current_attack_data != null:
		return StringName(current_attack_data.animation_name)
	if attack_type == &"Punch":
		return &"punch_2" if dev_combo_step == 2 else &"punch_1"
	if current_attack_data != null:
		var configured_animation := StringName(current_attack_data.animation_name)
		if configured_animation == &"kick_1" or configured_animation == &"kick_2":
			return configured_animation
	if dev_combo_step >= _combo_hit_limit():
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
	var default_attack_height := "middle"
	if attack_type == "Punch":
		default_attack_height = "high"
	elif attack_type == "Kick" and String(current_attack_id).contains("crouch"):
		default_attack_height = "low"
	var attack_height := default_attack_height
	var resource_height := String(attack_data.get("attack_height"))
	if not resource_height.is_empty() and resource_height != "default":
		attack_height = resource_height
	# Any attack performed from the crouch state is a low. Jump startup clears
	# crouch, so airborne attacks still resolve as overheads below.
	if is_crouching:
		attack_height = "low"
	# Air attacks are overheads: standing guard blocks them, crouch guard does not.
	if String(attack_data.get("attack_category")).to_lower() == "air":
		attack_height = "overhead"
	var result := {
		"damage": maxi(1, int(round(float(base_damage) * float(attack_data.base_damage)))),
		"attacker_archetype": String(_get_combat_archetype()),
		"attack_height": attack_height,
		"attack_category": String(attack_data.get("attack_category")),
		"knockback_x": final_knockback.x,
		"knockback_y": final_knockback.y,
		"hit_stop_frames": maxi(6 if attack_type == "Kick" else 4, int(round(float(attack_data.hitstop_time) * 60.0))),
		"hitstop_attacker": _get_attack_hitstop_attacker(attack_data, attack_type),
		"hitstop_defender": _get_attack_hitstop_defender(attack_data, attack_type),
		"guard_hitstop_attacker": dev052_guard_hitstop_attacker,
		"guard_hitstop_defender": dev052_guard_hitstop_defender,
		"effect_size": 1.5 if attack_type == "Kick" else 1.0,
		"screen_shake": 4.5 if attack_type == "Kick" else 2.8,
		"se_type": "strong" if attack_type == "Kick" else "weak",
		"attack_id": current_attack_id,
		"attack_type": String(attack_data.attack_type),
	}
	if not String(attack_data.command_direction).is_empty():
		result.merge({
		"launch_velocity": Vector2(attack_data.launch_velocity),
		"causes_knockdown": bool(attack_data.knockdown),
		"hit_reaction": StringName(attack_data.hit_reaction),
		"ground_bounces": int(attack_data.ground_bounces),
		"ground_bounce_velocity": Vector2(attack_data.ground_bounce_velocity),
		"counter_hitstun_bonus": float(attack_data.counter_hitstun_bonus),
		"hitstun_time": float(attack_data.hitstun_time),
		"is_guardable": bool(attack_data.is_guardable),
		"guard_damage_multiplier": float(attack_data.guard_damage_multiplier),
		"guard_hit_time": float(attack_data.guard_hit_time),
		"guard_knockback": Vector2(attack_data.guard_knockback),
		}, true)
	return result


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
	fallback_data.next_attack_ids.clear()
	fallback_data.animation_name = "Kick" if normalized_type == "kick" else "Punch"
	var definition: Resource = get("fighter_definition")
	if definition != null and String(definition.get("fighter_id")) == "enemy_01_crusher":
		# Crusher's new sheet has an anticipation, contact and recovery pose.
		# Keep the existing active duration and enable collision only at contact.
		fallback_data.startup_time = 0.10 if normalized_type == "kick" else 0.08
		fallback_data.animation_name = "kick_1" if normalized_type == "kick" else "punch_1"
		fallback_data.hitbox_offset = Vector2(100, -112) if normalized_type == "kick" else Vector2(100, -145)
		fallback_data.hitbox_size = Vector2(85, 48) if normalized_type == "kick" else Vector2(75, 52)
	attack_data_by_id[fallback_id] = fallback_data
	return fallback_id


func _ensure_air_kick_attack_data() -> String:
	if air_kick_attack_data != null:
		var configured_id := String(air_kick_attack_data.attack_id)
		if not configured_id.is_empty():
			attack_data_by_id[configured_id] = air_kick_attack_data
			return configured_id

	var fallback_id := "fallback_jump_kick"
	if attack_data_by_id.has(fallback_id):
		return fallback_id

	var fallback_data: Resource = PlayerAttackDataScript.new()
	fallback_data.attack_id = fallback_id
	fallback_data.display_name = "Jump Kick"
	fallback_data.attack_type = "kick"
	fallback_data.attack_category = "air"
	fallback_data.base_damage = 1.10
	fallback_data.startup_time = 0.214
	fallback_data.active_time = 0.143
	fallback_data.recovery_time = 0.214
	fallback_data.combo_input_start = 0.0
	fallback_data.combo_input_end = 0.0
	fallback_data.hitbox_size = Vector2(90.0, 52.0)
	fallback_data.hitbox_offset = Vector2(58.0, -50.0)
	fallback_data.forward_move_distance = 0.0
	fallback_data.forward_move_duration = 0.0
	fallback_data.knockback = Vector2(250.0, -90.0)
	fallback_data.hitstop_time = 0.09
	fallback_data.hitstun_time = 0.30
	fallback_data.guard_hit_time = 0.22
	fallback_data.guard_knockback = Vector2(95.0, 0.0)
	fallback_data.next_attack_ids.clear()
	fallback_data.can_cancel_on_hit = false
	fallback_data.can_cancel_on_whiff = false
	fallback_data.animation_name = "jump_kick"
	air_kick_attack_data = fallback_data
	attack_data_by_id[fallback_id] = fallback_data
	return fallback_id


func _ensure_air_punch_down_attack_data() -> String:
	if air_punch_down_attack_data != null:
		var configured_id := String(air_punch_down_attack_data.attack_id)
		if not configured_id.is_empty():
			attack_data_by_id[configured_id] = air_punch_down_attack_data
			return configured_id

	var fallback_id := "player1_jump_punch_down"
	if attack_data_by_id.has(fallback_id):
		return fallback_id

	var fallback_data: Resource = PlayerAttackDataScript.new()
	fallback_data.attack_id = fallback_id
	fallback_data.display_name = "Jump Punch Down"
	fallback_data.attack_type = "punch"
	fallback_data.attack_category = "air"
	fallback_data.base_damage = 0.95
	fallback_data.startup_time = 0.25
	fallback_data.active_time = 0.17
	fallback_data.recovery_time = 0.25
	fallback_data.combo_input_start = 0.0
	fallback_data.combo_input_end = 0.0
	fallback_data.hitbox_size = Vector2(68.0, 70.0)
	fallback_data.hitbox_offset = Vector2(46.0, 32.0)
	fallback_data.forward_move_distance = 0.0
	fallback_data.forward_move_duration = 0.0
	fallback_data.knockback = Vector2(190.0, 120.0)
	fallback_data.hitstop_time = 0.07
	fallback_data.hitstun_time = 0.25
	fallback_data.guard_hit_time = 0.18
	fallback_data.guard_knockback = Vector2(70.0, 0.0)
	fallback_data.attack_height = "middle"
	fallback_data.next_attack_ids.clear()
	fallback_data.can_cancel_on_hit = false
	fallback_data.can_cancel_on_whiff = false
	fallback_data.animation_name = "jump_punch_down"
	air_punch_down_attack_data = fallback_data
	attack_data_by_id[fallback_id] = fallback_data
	return fallback_id


func _ensure_crouch_kick_sweep_attack_data() -> String:
	if crouch_kick_sweep_attack_data != null:
		var configured_id := String(crouch_kick_sweep_attack_data.attack_id)
		if not configured_id.is_empty():
			attack_data_by_id[configured_id] = crouch_kick_sweep_attack_data
			return configured_id

	var fallback_id := "player1_crouch_kick_sweep"
	if attack_data_by_id.has(fallback_id):
		return fallback_id

	var fallback_data: Resource = PlayerAttackDataScript.new()
	fallback_data.attack_id = fallback_id
	fallback_data.display_name = "Crouch Sweep"
	fallback_data.attack_type = "kick"
	fallback_data.attack_category = "crouch"
	fallback_data.base_damage = 0.90
	fallback_data.startup_time = 0.22
	fallback_data.active_time = 0.16
	fallback_data.recovery_time = 0.28
	fallback_data.combo_input_start = 0.0
	fallback_data.combo_input_end = 0.0
	fallback_data.hitbox_size = Vector2(86.0, 34.0)
	fallback_data.hitbox_offset = Vector2(54.0, 42.0)
	fallback_data.forward_move_distance = 0.0
	fallback_data.forward_move_duration = 0.0
	fallback_data.knockback = Vector2(210.0, 22.0)
	fallback_data.hitstop_time = 0.07
	fallback_data.hitstun_time = 0.28
	fallback_data.guard_hit_time = 0.18
	fallback_data.guard_knockback = Vector2(75.0, 0.0)
	fallback_data.attack_height = "low"
	fallback_data.next_attack_ids.clear()
	fallback_data.can_cancel_on_hit = false
	fallback_data.can_cancel_on_whiff = false
	fallback_data.animation_name = "crouch_kick_sweep"
	crouch_kick_sweep_attack_data = fallback_data
	attack_data_by_id[fallback_id] = fallback_data
	return fallback_id


func _attack_type_to_state_name(attack_type: String) -> String:
	return "Kick" if attack_type.to_lower() == "kick" else "Punch"


func _get_attack_startup_multiplier(attack_type: String) -> float:
	return kick_startup_multiplier if attack_type == "Kick" else punch_startup_multiplier


func _get_attack_recovery_multiplier(attack_type: String) -> float:
	return kick_recovery_multiplier if attack_type == "Kick" else punch_recovery_multiplier


func _attack_animation_name(attack_data: Resource) -> StringName:
	if attack_data != null and not String(attack_data.command_direction).is_empty():
		return StringName(attack_data.animation_name)
	if _is_cross_grappler() and attack_data != null:
		return StringName(attack_data.animation_name)
	if attack_data != null:
		var configured_animation := String(attack_data.animation_name)
		if configured_animation == "jump_kick" or configured_animation == "jump_punch_down" or configured_animation == "crouch_sweep_kick" or configured_animation == "crouch_kick_sweep":
			return StringName(configured_animation)
	if _is_air_kick_attack_active():
		return &"jump_kick"
	if String(current_attack_type) == "Kick" and combo_count <= 0 and not dev_starting_combo_attack:
		return &"kick_1"
	if String(current_attack_type) == "Kick" and dev_combo_step >= _combo_hit_limit():
		return &"combo_finisher"
	if attack_data != null and not String(attack_data.animation_name).is_empty():
		return StringName(attack_data.animation_name)
	return _get_attack_animation_name(StringName(current_attack_type))


func _update_pose_collision() -> void:
	super._update_pose_collision()
	if current_attack_data == null or String(current_attack_data.command_direction).is_empty():
		return
	if hurt_box == null or hurt_shape == null or not (hurt_shape.shape is RectangleShape2D):
		return
	if command_attack_elapsed < float(current_attack_data.hurtbox_start) or command_attack_elapsed > float(current_attack_data.hurtbox_end):
		return
	var height := default_hurt_box_size.y * clampf(float(current_attack_data.hurtbox_height_scale), 0.25, 1.25)
	hurt_shape.shape.size = Vector2(default_hurt_box_size.x * clampf(float(current_attack_data.hurtbox_width_scale), 0.25, 1.25), height)
	var offset: Vector2 = current_attack_data.hurtbox_offset * battle_visual_scale_multiplier
	offset.x *= facing_direction
	hurt_box.position = default_hurt_box_position + Vector2(0.0, (default_hurt_box_size.y - height) * 0.5) + offset


func _get_attack_hitstop_attacker(attack_data: Resource, attack_type: String) -> float:
	if attack_data != null and not String(attack_data.command_direction).is_empty():
		return float(attack_data.hitstop_time)
	if attack_type == "Kick":
		if attack_data != null and String(attack_data.animation_name) == "jump_kick":
			return dev052_kick_1_hitstop_attacker
		if dev_combo_step >= _combo_hit_limit() or (attack_data != null and String(attack_data.animation_name) == "combo_finisher"):
			return dev052_finisher_hitstop_attacker
		return dev052_kick_1_hitstop_attacker
	if dev_combo_step == 2:
		return dev052_punch_2_hitstop_attacker
	return dev052_punch_1_hitstop_attacker


func _get_attack_hitstop_defender(attack_data: Resource, attack_type: String) -> float:
	if attack_data != null and not String(attack_data.command_direction).is_empty():
		return float(attack_data.hitstop_time)
	if attack_type == "Kick":
		if attack_data != null and String(attack_data.animation_name) == "jump_kick":
			return 0.09
		if dev_combo_step >= _combo_hit_limit() or (attack_data != null and String(attack_data.animation_name) == "combo_finisher"):
			return dev052_finisher_hitstop_defender
		return dev052_kick_1_hitstop_defender
	if dev_combo_step == 2:
		return dev052_punch_2_hitstop_defender
	return dev052_punch_1_hitstop_defender


func _get_attacker_hitstop_duration(attack_data: Dictionary) -> float:
	if attack_data.has("hitstop_attacker"):
		return float(attack_data["hitstop_attacker"])
	return float(attack_data.get("hit_stop_frames", 4)) / 60.0


func _get_defender_hitstop_duration(attack_data: Dictionary) -> float:
	if attack_data.has("hitstop_defender"):
		return float(attack_data["hitstop_defender"])
	return float(attack_data.get("hit_stop_frames", 4)) / 60.0


func _get_guard_attacker_hitstop_duration(attack_data: Dictionary) -> float:
	return float(attack_data.get("guard_hitstop_attacker", dev052_guard_hitstop_attacker))


func _get_guard_defender_hitstop_duration(attack_data: Dictionary) -> float:
	return float(attack_data.get("guard_hitstop_defender", dev052_guard_hitstop_defender))


func _setup_attack_forward_movement(attack_data: Resource) -> void:
	clear_attack_movement()
	if attack_data == null:
		return
	var duration := float(attack_data.forward_move_duration)
	if duration <= 0.0:
		return
	attack_forward_timer = duration
	attack_forward_speed = (float(attack_data.forward_move_distance) / duration) * facing_direction


func _is_air_kick_attack_active() -> bool:
	return is_air_attack_active and current_attack_type == "Kick" and not is_on_floor()


func _is_air_attack_currently_active() -> bool:
	return is_air_attack_active and current_attack_type != "" and not is_on_floor()


func clear_pending_air_landing() -> void:
	pending_air_landing_data = null


func _apply_dive_motion() -> void:
	if is_on_floor() or is_hit or is_guard_hit or current_attack_data == null or attack_phase == AttackPhase.STARTUP:
		return
	var dive: Vector2 = current_attack_data.dive_velocity
	if dive.y > 0.0:
		velocity = Vector2(dive.x*facing_direction,maxf(velocity.y,dive.y))


func _finish_air_attack_on_landing() -> void:
	var landing_data := pending_air_landing_data
	if landing_data == null and current_attack_data != null:
		landing_data = current_attack_data
	finish_attack()
	has_used_air_attack = false
	jump_combo_pending = false
	pending_air_landing_data = null
	landing_recovery_remaining = float(landing_data.landing_recovery) if landing_data != null else 0.0
	landing_recovery_animation = landing_data.landing_animation if landing_data != null else &"jump_land"
	if _is_landing_recovery_busy():
		velocity.x = 0.0
		is_crouching = false
		_clear_guard_state()
	_play_visual_animation(landing_recovery_animation, true)


func _target_debug_name(target: Node) -> String:
	if target == null:
		return "Unknown"
	if target.name == "Enemy":
		return "Enemy1"
	return String(target.name)


func _update_visual_state() -> void:
	super._update_visual_state()
	_sync_attack_visual_phase()
	if not debug_state_label_enabled:
		return
	if _is_landing_recovery_busy():
		state_label.text += "\nLANDING RECOVERY: %.2fs" % landing_recovery_remaining
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


func _combo_hit_limit() -> int:
	if current_attack_data != null and current_attack_data.combo_route_hit_limit > 0:
		return clampi(current_attack_data.combo_route_hit_limit, 1, 6)
	return dev026_max_combo_hits
