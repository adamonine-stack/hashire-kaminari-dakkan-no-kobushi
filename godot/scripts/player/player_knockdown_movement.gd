extends "res://scripts/player/player_combo_movement.gd"

signal knockdown_started(character: Node)
signal get_up_started(character: Node)
signal get_up_finished(character: Node)

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
var knockdown_timer := 0.0
var get_up_timer := 0.0
var get_up_invincible_timer := 0.0
var did_get_up_separation := false
var default_visual_position := Vector2.ZERO


func _ready() -> void:
	super._ready()
	default_visual_position = visual_root.position


func _physics_process(delta: float) -> void:
	if _update_hit_stop(delta):
		return

	if _is_knockdown_busy():
		_update_knockdown_flow(delta)
		_update_visual_state()
		move_and_slide()
		_clamp_to_screen()
		return

	super._physics_process(delta)


func can_receive_attack() -> bool:
	return current_hp > 0 and not _is_knockdown_busy() and not is_invincible


func can_be_thrown(attacker: Node) -> bool:
	return super.can_be_thrown(attacker) and not _is_knockdown_busy()


func receive_attack(attack_data: Dictionary, attack_direction: float, hit_position: Vector2, attacker: Node) -> bool:
	if not can_receive_attack():
		return false
	if _can_guard_attack(attack_data, attacker):
		_receive_guarded_attack(attack_data, attack_direction, hit_position, attacker)
		return false

	interrupt_combo()
	_cancel_current_action()
	var final_damage := int(attack_data["damage"])
	var causes_down := should_cause_knockdown(
		attack_data,
		float(final_damage),
		int(attack_data.get("combo_hit_index", 1)) >= dev026_max_combo_hits
	)

	_enter_hit_state()
	hit_reaction_timer = maxf(hit_reaction_timer, float(attack_data.get("hitstun_time", hit_reaction_timer)))
	if causes_down:
		hit_reaction_timer = maxf(hit_reaction_timer, dev026_combo_hitstun_time)
	apply_damage(final_damage)
	damage_feedback_requested.emit(self, final_damage, false, hit_position)
	_flash_damage()
	if attacker != null and attacker.has_method("register_combo_hit"):
		attacker.register_combo_hit(self)

	if current_hp <= 0:
		reset_knockdown_state()
		_play_ko_feedback(hit_position, attack_direction)
		if attacker != null and attacker.has_method("_finish_combo_after_ko"):
			attacker._finish_combo_after_ko()
		return true

	_apply_knockback(attack_data, attack_direction)
	_start_hit_stop(attack_data["hit_stop_frames"])
	_spawn_hit_effect(hit_position, attack_data["effect_size"])
	_play_hit_se(attack_data["se_type"])
	if attacker != null and attacker.has_method("start_hit_stop"):
		attacker.start_hit_stop(attack_data["hit_stop_frames"])
	screen_shake_requested.emit(attack_data["screen_shake"])

	if causes_down:
		print("KNOCKDOWN HIT")
		if attacker != null:
			_end_attacker_combo_for_knockdown(attacker)
		enter_knockback(attacker, _get_knockdown_force(attack_data, attacker, attack_direction))
	else:
		_start_invincibility()

	return true


func _complete_throw_hit() -> void:
	var attacker := pending_throw_attacker
	var hit_position := pending_throw_hit_position
	var damage := pending_throw_damage
	var throw_velocity := pending_throw_velocity
	is_throw_escape_pending = false
	is_throw_locked = false
	throw_state = ""
	throw_escape_timer = 0.0
	_clear_pending_throw()
	_enter_hit_state()
	apply_damage(damage)
	damage_feedback_requested.emit(self, damage, false, hit_position)
	_flash_damage()

	if attacker != null and attacker.has_method("_spawn_throw_impact_effect"):
		attacker._spawn_throw_impact_effect(hit_position)
	if attacker != null and attacker.has_method("_play_throw_se"):
		attacker._play_throw_se()

	if current_hp <= 0:
		reset_knockdown_state()
		_play_ko_feedback(hit_position, signf(throw_velocity.x))
		return

	var throw_direction := signf(throw_velocity.x)
	if throw_direction == 0.0:
		throw_direction = 1.0
	enter_knockback(attacker, calculate_received_knockback(Vector2(
		maxf(absf(throw_velocity.x), knockdown_horizontal_force) * throw_direction,
		minf(throw_velocity.y, knockdown_vertical_force)
	)))


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
	if velocity.y > knockdown_vertical_force:
		velocity.y = knockdown_vertical_force
	set_hurtbox_enabled(false)
	_play_state_animation(&"knockback", &"Throw")
	knockdown_started.emit(self)


func update_knockback(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = move_toward(velocity.x, 0.0, move_speed * 0.35 * delta)

	if is_on_floor() and velocity.y >= -ground_landing_velocity_threshold:
		enter_knockdown()


func enter_knockdown() -> void:
	if current_hp <= 0:
		reset_knockdown_state()
		return

	knockdown_state = &"KNOCKDOWN"
	knockdown_timer = knockdown_duration
	velocity = Vector2.ZERO
	set_hurtbox_enabled(false)
	close_combo_window()
	clear_attack_buffer()
	_play_state_animation(&"knockdown", &"Throw")
	_spawn_knockdown_impact_effect(global_position)
	screen_shake_requested.emit(knockdown_camera_shake_strength)


func update_knockdown(delta: float) -> void:
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
	_play_state_animation(&"get_up", &"Throw")
	get_up_started.emit(self)


func update_get_up(delta: float) -> void:
	velocity = Vector2.ZERO
	get_up_timer = maxf(get_up_timer - delta, 0.0)
	get_up_invincible_timer = maxf(get_up_invincible_timer - delta, 0.0)
	if get_up_timer == 0.0:
		finish_get_up()


func finish_get_up() -> void:
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
	visual_root.position = default_visual_position
	visual_root.rotation_degrees = 0.0
	visual_root.scale.y = 1.0


func reset_knockdown_state() -> void:
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
	return calculate_received_knockback(Vector2(force_x * direction, -force_y))


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
	if animation_player == null:
		return
	if animation_player.has_animation(String(animation_name)):
		animation_player.play(String(animation_name))
	elif animation_player.has_animation(String(fallback_name)):
		animation_player.play(String(fallback_name))


func _spawn_knockdown_impact_effect(effect_position: Vector2) -> void:
	var effect_root := Node2D.new()
	effect_root.global_position = effect_position
	effect_root.name = "KnockdownImpactEffect"

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
	get_tree().current_scene.add_child(effect_root)

	var tween := effect_root.create_tween()
	tween.tween_property(effect_root, "scale", Vector2(1.45, 1.25), 0.16)
	tween.parallel().tween_property(dust, "modulate:a", 0.0, 0.16)
	tween.tween_callback(effect_root.queue_free)


func _clamp_to_screen() -> void:
	var viewport_width := get_viewport_rect().size.x
	position.x = clampf(position.x, screen_margin, viewport_width - screen_margin)


func _update_visual_state() -> void:
	super._update_visual_state()
	if not debug_state_label_enabled:
		return
	if not _is_knockdown_busy():
		return

	if knockdown_state == &"KNOCKDOWN":
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
