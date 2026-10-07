extends "res://scripts/player/player_combo_movement.gd"

signal knockdown_started(character: Node)
signal get_up_started(character: Node)
signal get_up_finished(character: Node)

var directional_throw_down_remaining := 0.0
var ground_bounces_remaining := 0
var ground_bounce_contacts := 0
var ground_bounce_velocity := Vector2.ZERO
var ground_bounce_phase := ""
var ground_bounce_timer := 0.0

@export var knockdown_duration := 0.80
@export var get_up_duration := 0.55
@export var get_up_invincible_time := 0.45
@export var knockdown_horizontal_force := 320.0
@export var knockdown_vertical_force := -180.0
@export var ground_landing_velocity_threshold := 30.0
@export var knockdown_ground_offset := 0.0
@export var minimum_knockdown_damage := 18.0
@export var knockdown_combo_finisher_only := true
@export var get_up_separation_distance := 28.0
@export var knockdown_camera_shake_strength := 2.0

var knockdown_state: StringName = &""
var special_landing_feedback := false
var special_ko_flight := false
var special_landing_color := Color(0.35,0.8,1.0)
var special_reaction_edge_padding := Vector2.ZERO
var special_wall_phase := ""
var special_wall_timer := 0.0
var special_wall_direction := 1.0
var special_wall_speed := 0.0
var special_wall_start_y := 0.0
var special_wall_contacts := 0
var last_special_wall_animation: StringName = &""
var last_special_wall_fall_animation: StringName = &""
var special_wall_screen_limits := Vector2.ZERO
var special_keep_flight_in_view := false
var special_backflip_enabled := false
var special_backflip_elapsed := 0.0
var special_backflip_duration := 0.0
var special_backflip_direction := 1.0
var special_backflip_turn := 0.0
var special_prone_alignment := Vector2.ZERO
var special_flight_gravity := 0.0
var special_headfirst_enabled := false
var special_headfirst_phase := ""
var special_headfirst_elapsed := 0.0
var special_headfirst_apex_time := 0.0
var special_headfirst_timer := 0.0
var special_headfirst_direction := 1.0
var special_headfirst_anchor := Vector2.ZERO
var special_headfirst_tip := Vector2.ZERO
var special_headfirst_contact := Vector2.ZERO
var special_headfirst_root_x := 0.0
var special_headfirst_prone_root_x := 0.0
var last_special_headfirst_fall_animation: StringName = &""
var knockdown_timer := 0.0
var get_up_timer := 0.0
var get_up_invincible_timer := 0.0
var did_get_up_separation := false
var default_visual_position := Vector2.ZERO
var seiya_followup_owner: WeakRef
var seiya_followup_sequence := -1
var seiya_lift_elapsed := 0.0

func can_receive_seiya_followup(packet: Dictionary, attacker: Node) -> bool:
	return current_hp > 0 and is_instance_valid(attacker) and attacker.has_method("is_seiya_confirmed_followup_target") and attacker.is_seiya_confirmed_followup_target(self,packet)


func _ready() -> void:
	super._ready()
	default_visual_position = visual_root.position


func _physics_process(delta: float) -> void:
	if _is_knockdown_busy():
		if _update_hit_stop(delta):
			return
		_update_knockdown_flow(delta)
		_update_visual_state()
		move_and_slide()
		# Resolve Gou's last turn and the prone pose in the collision frame,
		# rather than leaving an extra airborne-looking frame after landing.
		if (special_backflip_enabled or ground_bounces_remaining > 0 or ground_bounce_phase == "air") and knockdown_state == &"KNOCKBACK" and is_on_floor() and velocity.y >= -ground_landing_velocity_threshold:
			update_knockback(0.0)
			_update_visual_state()
		if special_wall_phase == "" or knockdown_state != &"KNOCKBACK":
			_apply_post_move_stabilization()
		_clamp_special_reaction_art()
		return

	super._physics_process(delta)


func can_receive_attack() -> bool:
	return current_hp > 0 and not _is_knockdown_busy() and not is_invincible


func can_be_thrown(attacker: Node) -> bool:
	return super.can_be_thrown(attacker) and not _is_knockdown_busy()


func receive_attack(attack_data: Dictionary, attack_direction: float, hit_position: Vector2, attacker: Node) -> bool:
	if not can_receive_attack():
		return false
	if _try_guard_technical_combo_escape(attack_data, attack_direction, hit_position, attacker):
		return false
	if _can_guard_attack(attack_data, attacker):
		_receive_guarded_attack(attack_data, attack_direction, hit_position, attacker)
		return false
	# Counter state is observed before cancelling the receiving attack. No move
	# ID matchup priority is involved; collision and timing have already won.
	if attack_phase == AttackPhase.STARTUP and float(attack_data.get("counter_hitstun_bonus", 0.0)) > 0.0:
		attack_data = attack_data.duplicate()
		attack_data["counter_hit"] = true
		attack_data["hitstun_time"] = float(attack_data.get("hitstun_time", hit_reaction_time)) + float(attack_data.counter_hitstun_bonus)

	var final_damage := int(attack_data["damage"])
	var combo_hit_index := int(attack_data.get("combo_hit_index", 1))
	var combo_hit_max := int(attack_data.get("combo_hit_max", 0))
	# A one-hit attack is not a combo finisher. Use the attacker's combo length so
	# fighters with a one-step local attack table (such as Stage 1 Crusher) do not
	# fall down from every ordinary hit they receive.
	var is_combo_finisher := combo_hit_max > 1 and combo_hit_index >= combo_hit_max
	var causes_down := should_cause_knockdown(
		attack_data,
		float(final_damage),
		is_combo_finisher
	)
	# Power armor is checked before normal hitstun/action cancellation. Damage is
	# still applied, but ordinary non-finishing strikes cannot stop an armored
	# attack that is already in progress.
	if not causes_down and final_damage < current_hp and _has_active_power_armor(attack_data, attacker):
		_receive_power_armor_hit(attack_data, final_damage, hit_position, attacker)
		return true

	interrupt_combo()
	_cancel_current_action()
	last_special_knockback_animation = StringName(attack_data.get("special_knockback_reaction", &"")) if bool(attack_data.get("is_special", false)) else &""
	special_landing_feedback = bool(attack_data.get("is_special", false)) and causes_down
	special_landing_color = attack_data.get("special_effect_color", Color(0.35,0.8,1.0))
	var authored_air := _get_special_received_animation(attack_data, "airborne")
	if authored_air != &"": last_special_knockback_animation = authored_air
	if causes_down or final_damage >= current_hp:
		last_knockdown_animation = _get_knockdown_animation_from_attack(attack_data)
	else:
		last_knockdown_animation = &""

	last_damage_animation = _get_damage_animation_from_attack(attack_data)
	if bool(attack_data.get("backflip_on_launch",false)) or bool(attack_data.get("headfirst_on_launch",false)):
		# All Gou reaction originals face right; lock the victim toward Gou.
		var toward_gou := -signf(attack_direction)
		if attacker != null: toward_gou = signf(attacker.global_position.x-global_position.x)
		if toward_gou != 0.0: facing_direction = toward_gou
		_set_visual_facing()
	_enter_hit_state()
	_play_visual_animation(last_damage_animation, true)
	hit_reaction_timer = maxf(hit_reaction_timer, float(attack_data.get("hitstun_time", hit_reaction_timer)))
	if _is_technical_combo_attack(attack_data) and combo_hit_index >= 2 and not causes_down:
		hit_reaction_timer = minf(hit_reaction_timer, technical_combo_escape_hitstun)
	elif causes_down:
		hit_reaction_timer = maxf(hit_reaction_timer, dev026_combo_hitstun_time)
	apply_damage(final_damage)
	if has_method("gain_special_gauge_from_damage"):
		call("gain_special_gauge_from_damage", final_damage, attack_data)
	damage_feedback_requested.emit(self, final_damage, false, hit_position)
	_flash_damage()
	if attacker != null and attacker.has_method("register_combo_hit"):
		attacker.register_combo_hit(self)

	if current_hp <= 0:
		var ko_air := last_special_knockback_animation
		reset_knockdown_state()
		set_hurtbox_enabled(false)
		_play_ko_feedback(hit_position, attack_direction)
		if bool(attack_data.get("is_special", false)):
			special_ko_flight = true
			special_landing_feedback = true
			last_special_knockback_animation = ko_air
			_clear_control_state_for_knockdown()
			knockdown_state = &"KNOCKBACK"
			velocity = _get_knockdown_force(attack_data, attacker, attack_direction)
			_cache_special_reaction_edge_padding()
			_begin_special_wall_launch(attack_data)
			set_hurtbox_enabled(false)
			_start_special_flight_trail()
		if attacker != null and attacker.has_method("_finish_combo_after_ko"):
			attacker._finish_combo_after_ko()
		return true

	_apply_knockback(attack_data, attack_direction)
	var launch: Vector2 = attack_data.get("launch_velocity", Vector2.ZERO)
	if launch != Vector2.ZERO and not causes_down:
		velocity = Vector2(launch.x * attack_direction, -absf(launch.y))
		if _has_visual_animation(&"launch_hit"):
			last_damage_animation = &"launch_hit"
		elif _has_visual_animation(&"knockback"):
			last_damage_animation = &"knockback"
		_play_visual_animation(last_damage_animation, true)
	_start_hit_stop_seconds(_get_defender_hitstop_duration(attack_data))
	_spawn_hit_effect(hit_position, attack_data["effect_size"])
	_play_hit_se(attack_data["se_type"])
	if attacker != null and attacker.has_method("start_hit_stop_seconds"):
		attacker.start_hit_stop_seconds(_get_attacker_hitstop_duration(attack_data))
	screen_shake_requested.emit(attack_data["screen_shake"])

	if causes_down:
		print("KNOCKDOWN HIT")
		if attacker != null:
			_end_attacker_combo_for_knockdown(attacker)
		enter_knockback(attacker, _get_knockdown_force(attack_data, attacker, attack_direction))
		_begin_special_wall_launch(attack_data)
		_configure_ground_bounce(int(attack_data.get("ground_bounces",0)), attack_data.get("ground_bounce_velocity",Vector2.ZERO))
		if int(attack_data.get("seiya_two_hit_stage",-1)) == 0:
			seiya_followup_owner = weakref(attacker)
			seiya_followup_sequence = int(attack_data.seiya_two_hit_sequence)
			seiya_lift_elapsed = 0.0
			velocity = Vector2(35.0*attack_direction,-360.0)
			set_hurtbox_enabled(true)
		if bool(attack_data.get("is_special", false)):
			_start_special_flight_trail()
	elif not bool(attack_data.get("allows_combo_followup", false)):
		_start_invincibility()

	return true


func _has_active_power_armor(_attack_data: Dictionary, _attacker: Node) -> bool:
	return false


func _receive_power_armor_hit(attack_data: Dictionary, final_damage: int, hit_position: Vector2, attacker: Node) -> void:
	last_knockdown_animation = &""
	apply_damage(final_damage)
	if has_method("gain_special_gauge_from_damage"):
		call("gain_special_gauge_from_damage", final_damage, attack_data)
	damage_feedback_requested.emit(self, final_damage, false, hit_position)
	_flash_damage()
	if attacker != null and attacker.has_method("register_combo_hit"):
		attacker.register_combo_hit(self)
	# Preserve attack state/animation while retaining a short readable impact.
	_start_hit_stop_seconds(0.035)
	_spawn_hit_effect(hit_position, float(attack_data.get("effect_size", 1.0)))
	_play_hit_se(String(attack_data.get("se_type", "strong")))
	if attacker != null and attacker.has_method("start_hit_stop_seconds"):
		attacker.start_hit_stop_seconds(0.04)
	screen_shake_requested.emit(float(attack_data.get("screen_shake", 0.0)) * 0.65)


func _complete_throw_hit() -> void:
	last_special_knockback_animation = &""
	last_knockdown_animation = &""
	var attacker := pending_throw_attacker
	var hit_position := pending_throw_hit_position
	var damage := pending_throw_damage
	var throw_velocity := pending_throw_velocity
	var directional_move: PlayerAttackData = attacker.directional_throw_data if is_instance_valid(attacker) and attacker.get("directional_throw_data") != null else null
	is_throw_escape_pending = false
	is_throw_locked = false
	throw_state = ""
	throw_escape_timer = 0.0
	_clear_pending_throw()
	last_damage_animation = &"damage_heavy"
	if is_instance_valid(attacker) and attacker.has_method("_uses_readable_grapple") and attacker._uses_readable_grapple() and _has_visual_animation(&"grapple_air"):
		last_damage_animation = &"grapple_air"
		last_special_knockback_animation = &"grapple_air"
		last_knockdown_animation = &"grapple_down"
	if is_instance_valid(attacker) and attacker.has_method("_is_cross_muei_throw") and attacker._is_cross_muei_throw() and _has_visual_animation(&"cross_muei_air"):
		last_damage_animation = &"cross_muei_air"
		last_special_knockback_animation = &"cross_muei_air"
		last_knockdown_animation = &"cross_muei_down"
	elif is_instance_valid(attacker) and attacker.has_method("_is_cross_grappler") and attacker._is_cross_grappler():
		var reaction: StringName = &"cross_react_shoulder" if attacker.cross_throw_variant in [0, 4, 5] else &"cross_react_reap"
		if _has_visual_animation(reaction):
			last_damage_animation = reaction
			last_special_knockback_animation = reaction
			last_knockdown_animation = StringName(String(reaction) + "_down")
	if directional_move != null and _has_visual_animation(directional_move.throw_victim_air_animation):
		last_damage_animation = directional_move.throw_victim_air_animation
		last_special_knockback_animation = directional_move.throw_victim_air_animation
		if _has_visual_animation(directional_move.throw_victim_down_animation):
			last_knockdown_animation = directional_move.throw_victim_down_animation
	elif directional_move != null and _has_visual_animation(&"thrown"):
		# Keep an airborne throw reaction when the requested dedicated victim
		# clip is unavailable; a standing heavy-hit pose is not a throw flight.
		last_damage_animation = &"thrown"
		last_special_knockback_animation = &"thrown"
		if _has_visual_animation(&"knockdown"):
			last_knockdown_animation = &"knockdown"
	_enter_hit_state()
	_play_visual_animation(last_damage_animation, true)
	apply_damage(damage)
	if has_method("gain_special_gauge_from_damage"):
		call("gain_special_gauge_from_damage", damage, {
			"attack_type": "throw",
			"causes_knockdown": true,
		})
	damage_feedback_requested.emit(self, damage, false, hit_position)
	_flash_damage()

	if attacker != null and attacker.has_method("_spawn_throw_impact_effect"):
		attacker._spawn_throw_impact_effect(hit_position)
	if attacker != null and attacker.has_method("_play_throw_se"):
		attacker._play_throw_se()

	if current_hp <= 0:
		var muei_down := last_knockdown_animation == &"cross_muei_down"
		reset_knockdown_state()
		if muei_down: last_knockdown_animation = &"cross_muei_down"
		_play_ko_feedback(hit_position, signf(throw_velocity.x))
		return

	var throw_direction := signf(throw_velocity.x)
	if throw_direction == 0.0:
		throw_direction = 1.0
	enter_knockback(attacker, calculate_received_knockback(Vector2(
		maxf(absf(throw_velocity.x), knockdown_horizontal_force) * throw_direction,
		minf(throw_velocity.y, knockdown_vertical_force)
	)))
	if directional_move != null and current_hp > 0:
		# Authored throws use their own trajectory instead of the legacy minimum
		# forward force. A slam therefore stays near the point of release.
		velocity = calculate_received_knockback(throw_velocity)
		directional_throw_down_remaining = directional_move.throw_down_seconds
		_configure_ground_bounce(directional_move.ground_bounces,directional_move.ground_bounce_velocity)


func _get_valid_hurtbox_target(area: Area2D) -> Node:
	var target := super._get_valid_hurtbox_target(area)
	if target == null:
		return null
	if target.has_method("can_receive_attack") and not target.can_receive_attack():
		return null
	return target


func should_cause_knockdown(attack_data: Dictionary, final_damage: float, is_combo_finisher: bool) -> bool:
	if bool(attack_data.get("causes_knockdown", false)):
		return true
	if str(attack_data.get("attack_type", "")) == "throw":
		return true
	if is_combo_finisher:
		return true
	if not knockdown_combo_finisher_only and final_damage >= minimum_knockdown_damage:
		return true
	return false


func enter_knockback(attacker: Node, knockback_force: Vector2) -> void:
	if current_hp <= 0 or _is_knockdown_busy():
		return

	_clear_control_state_for_knockdown()
	knockdown_state = &"KNOCKBACK"
	velocity = knockback_force
	_cache_special_reaction_edge_padding()
	if velocity.y > knockdown_vertical_force:
		velocity.y = knockdown_vertical_force
	set_hurtbox_enabled(false)
	if _has_visual_animation(last_special_knockback_animation):
		_play_state_animation(last_special_knockback_animation, &"Throw")
	elif last_damage_animation == &"damage_low" and hit_stop_timer > 0.0 and _has_visual_animation(last_damage_animation):
		_play_state_animation(last_damage_animation, &"Throw")
	elif _has_visual_animation(last_knockdown_animation):
		_play_state_animation(last_knockdown_animation, &"Throw")
	else:
		_play_state_animation(&"knockback", &"Throw")
	knockdown_started.emit(self)


func update_knockback(delta: float) -> void:
	if ground_bounce_phase == "impact":
		velocity = Vector2.ZERO
		ground_bounce_timer = maxf(ground_bounce_timer-delta,0.0)
		if ground_bounce_timer == 0.0:
			ground_bounce_phase = "air"
			velocity = ground_bounce_velocity
		return
	if seiya_followup_owner != null:
		seiya_lift_elapsed += delta
		if velocity.y >= 0.0 and _has_visual_animation(&"received_seiya_two_fall"):
			last_special_knockback_animation = &"received_seiya_two_fall"
	if special_headfirst_enabled:
		if special_headfirst_phase in ["head_impact","collapse"]:
			_update_special_headfirst_ground(delta)
			return
		special_headfirst_elapsed += delta
		var turn := smoothstep(0.30,0.95,special_headfirst_elapsed/special_headfirst_apex_time)*PI
		animated_character_sprite.rotation = special_headfirst_direction*turn
		animated_character_sprite.offset = (special_headfirst_anchor*animated_character_sprite.scale).rotated(-animated_character_sprite.rotation)/animated_character_sprite.scale-special_headfirst_anchor
		if velocity.y >= 0.0: special_headfirst_phase = "fall"
	if special_backflip_enabled:
		special_backflip_elapsed += delta
		# Stay in the rotating pose until physical floor contact; there is no
		# separate airborne prone/settling phase.
		var landed := is_on_floor() and velocity.y >= -ground_landing_velocity_threshold
		var progress := 1.0 if landed else clampf(special_backflip_elapsed / special_backflip_duration,0.0,0.9999)
		special_backflip_turn = progress*(PI*1.5)
		if animated_character_sprite != null:
			if not landed:
				animated_character_sprite.rotation = special_backflip_direction*special_backflip_turn
				# Move toward the prone drawing's body center while still rotating.
				# Convert the translation back through the Sprite's rotation and scale.
				var lowering := smoothstep(0.45,1.0,progress)
				var shift := special_prone_alignment*animated_character_sprite.scale*lowering
				animated_character_sprite.offset = shift.rotated(-animated_character_sprite.rotation)/animated_character_sprite.scale
			else:
				animated_character_sprite.rotation = 0.0
				animated_character_sprite.offset = Vector2.ZERO
	if special_wall_phase == "fly":
		velocity.x = special_wall_speed * special_wall_direction
		# Fast horizontal launch stays airborne until the far wall, even when
		# the recipient starts near the opposite end of the stage.
		if global_position.y <= special_wall_start_y - 140.0:
			global_position.y = special_wall_start_y - 140.0
			velocity.y = 0.0
		return
	if special_wall_phase == "impact":
		velocity = Vector2.ZERO
		special_wall_timer = maxf(special_wall_timer-delta,0.0)
		if special_wall_timer == 0.0:
			special_wall_phase = "fall"
			velocity.y = 80.0
		return
	if special_wall_phase == "fall":
		velocity.x = 0.0
	if not is_on_floor():
		velocity.y += (special_flight_gravity if special_flight_gravity > 0.0 else gravity) * delta
	velocity.x = move_toward(velocity.x, 0.0, move_speed * 0.35 * delta)

	if is_on_floor() and velocity.y >= -ground_landing_velocity_threshold:
		if special_headfirst_enabled: _begin_special_headfirst_impact()
		else:
			if not _try_begin_ground_bounce(): enter_knockdown()


func _start_special_flight_trail() -> void:
	_lock_special_flight_camera()
	var trail: Node2D = load("res://scripts/combat/special_flight_trail.gd").new()
	add_child(trail)
	trail.setup(self, special_landing_color)

func _lock_special_flight_camera() -> void:
	var controller := get_parent()
	while controller != null:
		if controller.has_method("begin_special_flight_camera"):
			var limits: Vector2 = controller.begin_special_flight_camera(self)
			if special_wall_phase == "fly" or special_keep_flight_in_view: special_wall_screen_limits = limits
			return
		controller = controller.get_parent()

func enter_knockdown() -> void:
	seiya_followup_owner = null
	if current_hp <= 0 and not special_ko_flight:
		reset_knockdown_state()
		return

	ground_bounce_phase = ""
	knockdown_state = &"KNOCKDOWN"
	if (special_backflip_enabled or special_headfirst_enabled) and animated_character_sprite != null:
		animated_character_sprite.rotation = 0.0
		animated_character_sprite.offset = Vector2.ZERO
	knockdown_timer = knockdown_duration
	knockdown_timer = maxf(knockdown_timer, directional_throw_down_remaining)
	directional_throw_down_remaining = 0.0
	velocity = Vector2.ZERO
	set_hurtbox_enabled(false)
	close_combo_window()
	clear_attack_buffer()
	# The six-frame knockdown sequence starts during knockback. Do not force a
	# second animation at ground contact or the sequence jumps back to frame 1.
	if _has_visual_animation(last_special_knockback_animation) and _has_visual_animation(last_knockdown_animation):
		_play_state_animation(last_knockdown_animation, &"Throw")
	elif not _has_visual_animation(last_knockdown_animation):
		_play_state_animation(&"knockdown", &"Throw")
	_spawn_knockdown_impact_effect(global_position)
	if special_landing_feedback:
		var impact: Node2D = load("res://scripts/combat/reversal_effect.gd").new()
		add_child(impact)
		impact.setup(self, "impact", 0.3)
		impact.tint = special_landing_color
		special_landing_feedback = false
	screen_shake_requested.emit(knockdown_camera_shake_strength)


func update_knockdown(delta: float) -> void:
	if special_ko_flight and current_hp <= 0: return
	velocity = Vector2.ZERO
	knockdown_timer = maxf(knockdown_timer - delta, 0.0)
	if knockdown_timer == 0.0:
		start_get_up()


func start_get_up() -> void:
	if current_hp <= 0:
		reset_knockdown_state()
		return

	knockdown_state = &"GET_UP"
	get_up_timer = get_up_duration
	get_up_invincible_timer = get_up_invincible_time
	is_invincible = true
	did_get_up_separation = false
	set_hurtbox_enabled(false)
	_separate_from_opponent_on_get_up()
	_play_state_animation(&"stand_up", &"Throw")
	get_up_started.emit(self)


func update_get_up(delta: float) -> void:
	velocity = Vector2.ZERO
	get_up_timer = maxf(get_up_timer - delta, 0.0)
	get_up_invincible_timer = maxf(get_up_invincible_timer - delta, 0.0)
	if get_up_timer == 0.0:
		finish_get_up()


func finish_get_up() -> void:
	_clear_ground_bounce()
	special_backflip_enabled = false
	special_headfirst_enabled = false
	special_headfirst_phase = ""
	special_flight_gravity = 0.0
	special_wall_phase = ""
	last_special_wall_animation = &""
	last_special_wall_fall_animation = &""
	last_knockdown_animation = &""
	knockdown_state = &""
	knockdown_timer = 0.0
	get_up_timer = 0.0
	get_up_invincible_timer = 0.0
	is_invincible = false
	is_hit = false
	hit_reaction_timer = 0.0
	velocity = Vector2.ZERO
	set_hurtbox_enabled(true)
	restore_sprite_transform()
	clear_attack_buffer()
	close_combo_window()
	get_up_finished.emit(self)


func set_hurtbox_enabled(enabled: bool) -> void:
	if hurt_box == null:
		return
	hurt_box.set_deferred("monitorable", enabled)


func restore_sprite_transform() -> void:
	if animated_character_sprite != null:
		animated_character_sprite.rotation = 0.0
		animated_character_sprite.offset = Vector2.ZERO
	visual_root.position = default_visual_position
	visual_root.rotation_degrees = 0.0
	visual_root.scale.y = 1.0


func reset_knockdown_state() -> void:
	_clear_ground_bounce()
	directional_throw_down_remaining = 0.0
	seiya_followup_owner = null
	seiya_followup_sequence = -1
	special_backflip_enabled = false
	special_headfirst_enabled = false
	special_headfirst_phase = ""
	special_flight_gravity = 0.0
	special_backflip_elapsed = 0.0
	special_backflip_turn = 0.0
	special_wall_phase = ""
	special_wall_timer = 0.0
	special_wall_contacts = 0
	special_wall_screen_limits = Vector2.ZERO
	special_keep_flight_in_view = false
	last_special_wall_animation = &""
	last_special_wall_fall_animation = &""
	special_reaction_edge_padding = Vector2.ZERO
	special_ko_flight = false
	special_landing_feedback = false
	last_special_knockback_animation = &""
	knockdown_state = &""
	knockdown_timer = 0.0
	get_up_timer = 0.0
	get_up_invincible_timer = 0.0
	did_get_up_separation = false
	is_invincible = false
	restore_sprite_transform()
	set_hurtbox_enabled(true)


func _update_knockdown_flow(delta: float) -> void:
	match knockdown_state:
		&"KNOCKBACK":
			update_knockback(delta)
		&"KNOCKDOWN":
			update_knockdown(delta)
		&"GET_UP":
			update_get_up(delta)


func _is_knockdown_busy() -> bool:
	return knockdown_state == &"KNOCKBACK" or knockdown_state == &"KNOCKDOWN" or knockdown_state == &"GET_UP"


func _cache_special_reaction_edge_padding() -> void:
	special_reaction_edge_padding = Vector2.ZERO
	if last_special_knockback_animation == &"" or animated_character_sprite == null: return
	var sprite := animated_character_sprite
	for clip in [last_special_knockback_animation, last_knockdown_animation, &"wall_hit", &"wall_fall", &"ground_impact", &"ground_bounce"]:
		if not _has_visual_animation(clip): continue
		for index in range(sprite.sprite_frames.get_frame_count(clip)):
			var texture := sprite.sprite_frames.get_frame_texture(clip,index)
			var used := texture.get_image().get_used_rect()
			var left := float(used.position.x)-texture.get_width()*0.5
			var right := float(used.end.x)-texture.get_width()*0.5
			if sprite.flip_h:
				var old_left := left
				left = -right
				right = -old_left
			var world_left: Vector2 = sprite.global_transform * Vector2(left,0)
			var world_right: Vector2 = sprite.global_transform * Vector2(right,0)
			special_reaction_edge_padding.x = maxf(special_reaction_edge_padding.x, global_position.x-world_left.x)
			special_reaction_edge_padding.y = maxf(special_reaction_edge_padding.y, world_right.x-global_position.x)

func _clamp_special_reaction_art() -> void:
	if special_reaction_edge_padding == Vector2.ZERO or knockdown_state == &"GET_UP": return
	var left := stage_left_limit + maxf(fighter_body_half_width,special_reaction_edge_padding.x)+8.0
	var right := stage_right_limit - maxf(fighter_body_half_width,special_reaction_edge_padding.y)-8.0
	if special_wall_screen_limits != Vector2.ZERO:
		left = special_wall_screen_limits.x + maxf(fighter_body_half_width,special_reaction_edge_padding.x)+8.0
		right = special_wall_screen_limits.y - maxf(fighter_body_half_width,special_reaction_edge_padding.y)-8.0
	if left >= right: return
	global_position.x = clampf(global_position.x,left,right)
	if special_wall_phase == "fly" and ((special_wall_direction < 0 and global_position.x <= left+0.5) or (special_wall_direction > 0 and global_position.x >= right-0.5)):
		_enter_special_wall_impact()
	if (global_position.x <= left and velocity.x < 0) or (global_position.x >= right and velocity.x > 0): velocity.x = 0.0

func _begin_special_wall_launch(attack_data: Dictionary) -> void:
	special_keep_flight_in_view = bool(attack_data.get("keep_special_flight_in_view",false))
	special_wall_phase = ""
	special_wall_contacts = 0
	special_backflip_enabled = bool(attack_data.get("is_special",false)) and bool(attack_data.get("backflip_on_launch",false))
	special_backflip_elapsed = 0.0
	special_backflip_turn = 0.0
	special_prone_alignment = Vector2.ZERO
	special_flight_gravity = float(attack_data.get("special_launch_gravity",0.0)) if bool(attack_data.get("is_special",false)) else 0.0
	special_headfirst_enabled = bool(attack_data.get("is_special",false)) and bool(attack_data.get("headfirst_on_launch",false))
	special_headfirst_elapsed = 0.0
	special_headfirst_phase = "rise" if special_headfirst_enabled else ""
	if special_headfirst_enabled:
		special_headfirst_direction = signf(velocity.x)
		special_headfirst_apex_time = maxf(0.1,absf(velocity.y)/maxf(special_flight_gravity,1.0))
		var texture := animated_character_sprite.sprite_frames.get_frame_texture(last_special_knockback_animation,0)
		var bounds := texture.get_image().get_used_rect()
		special_headfirst_anchor = Vector2(bounds.get_center())-texture.get_size()*0.5
		# Anchor the actual topmost opaque head pixel, not an empty AABB corner.
		var image := texture.get_image()
		var head_point := Vector2(bounds.get_center().x,bounds.position.y)
		for y in range(bounds.position.y,mini(bounds.position.y+20,bounds.end.y)):
			var first := -1
			var last := -1
			for x in range(bounds.position.x,bounds.end.x):
				if image.get_pixel(x,y).a >= 0.5:
					if first == -1: first = x
					last = x
			if first != -1:
				head_point = Vector2((first+last)*0.5,y+0.5)
				break
		special_headfirst_tip = head_point-texture.get_size()*0.5
		if animated_character_sprite.flip_h:
			special_headfirst_anchor.x = -special_headfirst_anchor.x
			special_headfirst_tip.x = -special_headfirst_tip.x
		last_special_headfirst_fall_animation = _get_special_received_animation(attack_data,"fall")
	if special_backflip_enabled:
		# Reapply the authored low launch after the ordinary knockdown minimum.
		var requested_cap: Vector2 = attack_data.get("special_launch_speed_cap",Vector2.ZERO)
		if requested_cap.y > 0.0: velocity.y = maxf(velocity.y,-requested_cap.y)
		special_backflip_direction = signf(velocity.x)
		if _has_visual_animation(last_knockdown_animation):
			var prone_texture := animated_character_sprite.sprite_frames.get_frame_texture(last_knockdown_animation,0)
			var prone_bounds := prone_texture.get_image().get_used_rect()
			var prone_center := Vector2(prone_bounds.get_center())-prone_texture.get_size()*0.5
			var air_texture := animated_character_sprite.sprite_frames.get_frame_texture(last_special_knockback_animation,0)
			var air_center := Vector2(air_texture.get_image().get_used_rect().get_center())-air_texture.get_size()*0.5
			if animated_character_sprite.flip_h:
				prone_center.x = -prone_center.x
				air_center.x = -air_center.x
			var rotated_air_center := (air_center*animated_character_sprite.scale).rotated(special_backflip_direction*PI*1.5)/animated_character_sprite.scale
			special_prone_alignment = prone_center-rotated_air_center
		# Rotate backward 270 degrees into a head-toward-Gou prone landing.
		# Rotate the Sprite about its body center, never the ground/feet origin.
		special_backflip_duration = maxf(0.1,2.0*absf(velocity.y)/maxf(special_flight_gravity if special_flight_gravity > 0.0 else gravity,1.0)+2.0/Engine.physics_ticks_per_second)
	if not bool(attack_data.get("is_special",false)) or not bool(attack_data.get("wall_slam",false)): return
	special_wall_phase = "fly"
	special_wall_contacts = 0
	special_wall_direction = signf(velocity.x)
	special_wall_speed = maxf(absf(velocity.x),1800.0)
	special_wall_start_y = global_position.y
	last_special_wall_animation = _get_special_received_animation(attack_data,"wall")
	last_special_wall_fall_animation = _get_special_received_animation(attack_data,"fall")
	if not _has_visual_animation(last_special_wall_animation):
		last_special_wall_animation = &"wall_hit" if _has_visual_animation(&"wall_hit") else last_damage_animation
	if not _has_visual_animation(last_special_wall_fall_animation) and _has_visual_animation(&"wall_fall"):
		last_special_wall_fall_animation = &"wall_fall"
	_cache_special_reaction_edge_padding()
	velocity.x = special_wall_speed * special_wall_direction

func _enter_special_wall_impact() -> void:
	special_wall_phase = "impact"
	special_wall_timer = 0.16
	special_wall_contacts += 1
	velocity = Vector2.ZERO
	var impact: Node2D = load("res://scripts/combat/reversal_effect.gd").new()
	add_child(impact)
	impact.setup(self,"wall",0.28)
	var wall_padding := special_reaction_edge_padding.y if special_wall_direction > 0 else special_reaction_edge_padding.x
	impact.position = Vector2(special_wall_direction*wall_padding,-120)
	impact.scale.x = 1.0
	impact.tint = special_landing_color
	screen_shake_requested.emit(6.0)
	_play_hit_se("strong")

func _get_knockdown_force(attack_data: Dictionary, attacker: Node, fallback_direction: float) -> Vector2:
	var direction := fallback_direction
	if attacker is Node2D:
		direction = signf(global_position.x - attacker.global_position.x)
	if direction == 0.0:
		direction = fallback_direction
	if direction == 0.0:
		direction = 1.0

	var force_x := maxf(float(attack_data.get("knockback_x", knockdown_horizontal_force)), knockdown_horizontal_force)
	var force_y := maxf(float(attack_data.get("knockback_y", absf(knockdown_vertical_force))), absf(knockdown_vertical_force))
	var force := calculate_received_knockback(Vector2(force_x * direction, -force_y))
	if bool(attack_data.get("is_special", false)):
		force.x = maxf(absf(force.x), 600.0) * direction
		force.y = minf(force.y, -400.0)
		if bool(attack_data.get("wall_slam",false)):
			force.x = maxf(absf(force.x),1800.0) * direction
		var cap: Vector2 = attack_data.get("special_launch_speed_cap",Vector2.ZERO)
		if cap.x > 0: force.x = minf(absf(force.x),cap.x)*direction
		if cap.y > 0: force.y = -cap.y if bool(attack_data.get("headfirst_on_launch",false)) else maxf(force.y,-cap.y)
	return force


func _clear_control_state_for_knockdown() -> void:
	attack_active_timer = 0.0
	attack_cooldown_timer = 0.0
	kick_active_timer = 0.0
	kick_cooldown_timer = 0.0
	_clear_guard_state()
	is_crouching = false
	is_guard_hit = false
	is_hit = false
	is_throwing = false
	is_throw_locked = false
	is_throw_escape_pending = false
	is_throw_escaping = false
	throw_state = ""
	throw_startup_timer = 0.0
	throw_hold_timer = 0.0
	throw_recovery_timer = 0.0
	throw_escape_timer = 0.0
	current_throw_target = null
	has_throw_connected = false
	has_throw_damage_applied = false
	_clear_pending_throw()
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)
	if has_method("reset_character_special_state"):
		call("reset_character_special_state", false)
	clear_attack_buffer()
	close_combo_window()
	reset_combo()


func _end_attacker_combo_for_knockdown(attacker: Node) -> void:
	if attacker.has_method("clear_attack_buffer"):
		attacker.clear_attack_buffer()
	if attacker.has_method("close_combo_window"):
		attacker.close_combo_window()
	if attacker.has_method("reset_combo"):
		attacker.reset_combo()


func _separate_from_opponent_on_get_up() -> void:
	if did_get_up_separation:
		return
	did_get_up_separation = true
	var opponent := _get_opponent()
	if not (opponent is Node2D):
		return
	var gap: float = global_position.x - opponent.global_position.x
	if absf(gap) >= get_up_separation_distance:
		return
	var direction := signf(gap)
	if direction == 0.0:
		direction = -facing_direction
	position.x += direction * (get_up_separation_distance - absf(gap))
	_clamp_to_screen()


func _play_state_animation(animation_name: StringName, fallback_name: StringName) -> void:
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


func _spawn_knockdown_impact_effect(effect_position: Vector2) -> void:
	var effect_root := Node2D.new()
	effect_root.name = "KnockdownImpactEffect"
	effect_root.z_index = 20
	_get_character_effect_parent().add_child(effect_root)
	effect_root.global_position = effect_position

	var dust := Polygon2D.new()
	dust.color = Color(0.75, 0.72, 0.62, 0.65)
	dust.polygon = PackedVector2Array([
		Vector2(-22, 0),
		Vector2(-10, -10),
		Vector2(14, -8),
		Vector2(28, 0),
		Vector2(8, 8),
		Vector2(-18, 7),
	])
	effect_root.add_child(dust)

	var tween := effect_root.create_tween()
	tween.tween_property(effect_root, "scale", Vector2(1.45, 1.25), 0.16)
	tween.parallel().tween_property(dust, "modulate:a", 0.0, 0.16)
	tween.tween_callback(effect_root.queue_free)


func _clamp_to_screen() -> void:
	_apply_post_move_stabilization()


func _update_visual_state() -> void:
	super._update_visual_state()
	if uses_official_character_art:
		visual_root.scale.y = 1.0
		visual_root.position.y = default_visual_position.y
	if not debug_state_label_enabled:
		return
	if not _is_knockdown_busy():
		return

	if uses_official_character_art:
		pass
	elif knockdown_state == &"KNOCKDOWN":
		visual_root.scale.y = 0.35
		visual_root.position.y = default_visual_position.y + knockdown_ground_offset
	elif knockdown_state == &"GET_UP":
		visual_root.scale.y = 0.65
	else:
		visual_root.scale.y = 1.0

	state_label.text = "STATE: %s\nDOWN TIMER: %.2f\nGET UP TIMER: %.2f\nINVINCIBLE: %s\nHURTBOX: %s" % [
		String(knockdown_state),
		knockdown_timer,
		get_up_timer,
		str(is_invincible).to_upper(),
		"ENABLED" if hurt_box.get("monitorable") else "DISABLED",
	]

func _begin_special_headfirst_impact() -> void:
	special_headfirst_phase = "head_impact"
	special_headfirst_timer = 0.09
	velocity = Vector2.ZERO
	var sprite := animated_character_sprite
	sprite.rotation = special_headfirst_direction*PI
	var head := sprite.global_transform*(special_headfirst_tip+sprite.offset)
	special_headfirst_contact = Vector2(head.x,global_position.y)
	sprite.offset = sprite.to_local(special_headfirst_contact)-special_headfirst_tip
	special_headfirst_root_x = global_position.x
	var texture := sprite.sprite_frames.get_frame_texture(last_knockdown_animation,0)
	var bounds := texture.get_image().get_used_rect()
	var down_head := Vector2(bounds.end.x-bounds.size.x*0.18,bounds.get_center().y)-texture.get_size()*0.5
	if sprite.flip_h: down_head.x = -down_head.x
	special_headfirst_prone_root_x = special_headfirst_contact.x-(sprite.global_position.x-global_position.x+down_head.x*sprite.scale.x)
	var impact: Node2D = load("res://scripts/combat/reversal_effect.gd").new()
	add_child(impact)
	impact.setup(self,"impact",0.22)
	impact.position = special_headfirst_contact-global_position
	impact.tint = special_landing_color
	screen_shake_requested.emit(knockdown_camera_shake_strength)

func _update_special_headfirst_ground(delta: float) -> void:
	velocity = Vector2.ZERO
	special_headfirst_timer = maxf(0.0,special_headfirst_timer-delta)
	if special_headfirst_phase == "head_impact":
		if special_headfirst_timer == 0.0:
			special_headfirst_phase = "collapse"
			special_headfirst_timer = 0.18
		return
	var progress := clampf(1.0-special_headfirst_timer/0.18,0.0,1.0)
	var eased := smoothstep(0.0,1.0,progress)
	global_position.x = lerpf(special_headfirst_root_x,special_headfirst_prone_root_x,eased)
	var sprite := animated_character_sprite
	sprite.rotation = special_headfirst_direction*(PI+PI*0.5*eased)
	sprite.offset = sprite.to_local(special_headfirst_contact)-special_headfirst_tip
	# Let the head roll over as the torso settles into the final prone drawing.
	var texture := sprite.sprite_frames.get_frame_texture(last_knockdown_animation,0)
	var center := Vector2(texture.get_image().get_used_rect().get_center())-texture.get_size()*0.5
	if sprite.flip_h: center.x = -center.x
	var goal := sprite.global_position+center*sprite.scale
	var settling_center := special_headfirst_anchor
	if _is_rio_garcia() or _is_shadow_boxer():
		var current_texture := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
		settling_center = Vector2(current_texture.get_image().get_used_rect().get_center())-current_texture.get_size()*0.5
		if sprite.flip_h: settling_center.x = -settling_center.x
	var actual := sprite.global_transform*(settling_center+sprite.offset)
	var settle_start := 0.0 if (_is_rio_garcia() or _is_shadow_boxer()) else 0.65
	var shift := (goal-actual)*smoothstep(settle_start,1.0,progress)
	if _is_rio_garcia() or _is_shadow_boxer():
		# These fighters use a non-unit Sprite scale: basis_xform_inv assumes an orthonormal basis.
		sprite.offset += sprite.global_transform.affine_inverse().basis_xform(shift)
	else:
		sprite.offset += sprite.global_transform.basis_xform_inv(shift)
	if special_headfirst_timer == 0.0:
		special_headfirst_phase = "down"
		enter_knockdown()


func _clear_ground_bounce() -> void:
	ground_bounces_remaining = 0
	ground_bounce_contacts = 0
	ground_bounce_velocity = Vector2.ZERO
	ground_bounce_phase = ""
	ground_bounce_timer = 0.0


func _configure_ground_bounce(count: int, force: Vector2) -> void:
	_clear_ground_bounce()
	if current_hp <= 0 or not _has_visual_animation(&"ground_bounce") or not _has_visual_animation(&"ground_impact"):
		return
	ground_bounces_remaining = clampi(count,0,1)
	ground_bounce_velocity = Vector2(clampf(force.x,-80.0,80.0),-clampf(absf(force.y),80.0,200.0))


func _try_begin_ground_bounce() -> bool:
	if ground_bounces_remaining <= 0 or current_hp <= 0:
		return false
	ground_bounces_remaining -= 1
	ground_bounce_contacts += 1
	ground_bounce_phase = "impact"
	ground_bounce_timer = 0.07
	velocity = Vector2.ZERO
	set_hurtbox_enabled(false)
	_spawn_knockdown_impact_effect(global_position)
	_start_hit_stop_seconds(0.025)
	return true
