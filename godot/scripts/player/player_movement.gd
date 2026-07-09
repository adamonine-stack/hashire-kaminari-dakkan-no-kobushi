extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal hp_depleted
signal screen_shake_requested(strength: float)
signal throw_hit(target: Node)

@export var move_speed := 300.0
@export var crouch_speed := 120.0
@export var jump_power := 500.0
@export var screen_margin := 36.0
@export var attack_active_time := 0.12
@export var attack_cooldown_time := 0.35
@export var attack_offset := 56.0
@export var kick_active_time := 0.18
@export var kick_cooldown_time := 0.5
@export var kick_offset := 72.0
@export var max_hp := 100
@export var punch_damage := 5
@export var kick_damage := 8
@export var punch_knockback_x := 180.0
@export var punch_knockback_y := 160.0
@export var kick_knockback_x := 280.0
@export var kick_knockback_y := 260.0
@export var hit_reaction_time := 0.25
@export var invincibility_time := 0.3
@export var input_enabled := true
@export var can_guard := true
@export var guard_damage_rate := 0.2
@export var guard_hit_time := 0.25
@export var guard_knockback_scale := 0.35
@export var throw_range := 40.0
@export var throw_body_width := 72.0
@export var throw_damage := 12
@export var throw_self_recovery_time := 0.45
@export var throw_target_recovery_time := 0.6
@export var throw_escape_window := 0.18
@export var throw_escape_pushback := 30.0
@export var throw_escape_freeze_time := 0.25
@export var ai_throw_escape_rate := 0.35

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_hp := 100
var facing_direction := 1.0
var attack_active_timer := 0.0
var attack_cooldown_timer := 0.0
var kick_active_timer := 0.0
var kick_cooldown_timer := 0.0
var is_guarding := false
var is_crouching := false
var is_crouch_guarding := false
var guard_type := "none"
var punch_hitbox_active := false
var kick_hitbox_active := false
var punch_hit_targets: Array[Node] = []
var kick_hit_targets: Array[Node] = []
var is_hit := false
var is_invincible := false
var is_guard_hit := false
var is_throwing := false
var is_throw_locked := false
var is_throw_escape_pending := false
var is_throw_escaping := false
var is_round_active := false
var hit_reaction_timer := 0.0
var invincibility_timer := 0.0
var hit_stop_timer := 0.0
var guard_hit_timer := 0.0
var throw_recovery_timer := 0.0
var throw_escape_timer := 0.0
var pending_throw_damage := 0
var pending_throw_hit_position := Vector2.ZERO
var pending_throw_direction := 0.0
var pending_throw_attacker: Node
var pending_throw_ai_checked := false
var weak_hit_se: AudioStreamPlayer2D
var strong_hit_se: AudioStreamPlayer2D
var guard_hit_se: AudioStreamPlayer2D
var throw_se: AudioStreamPlayer2D
var throw_escape_se: AudioStreamPlayer2D

@onready var visual_root := $VisualRoot
@onready var state_label := $VisualRoot/IdlePlaceholder/IdleStateLabel
@onready var guard_visual := $VisualRoot/IdlePlaceholder/GuardPlaceholder
@onready var crouch_visual := $VisualRoot/IdlePlaceholder/CrouchPlaceholder
@onready var crouch_guard_visual := $VisualRoot/IdlePlaceholder/CrouchGuardPlaceholder
@onready var punch_area := $PunchHitBox
@onready var punch_shape := $PunchHitBox/CollisionShape2D
@onready var kick_area := $KickHitBox
@onready var kick_shape := $KickHitBox/CollisionShape2D
@onready var hurt_box := $HurtBox
@onready var animation_player := get_node_or_null("AnimationPlayer") as AnimationPlayer


func _ready() -> void:
	current_hp = max_hp
	punch_area.area_entered.connect(_on_punch_hitbox_area_entered)
	kick_area.area_entered.connect(_on_kick_hitbox_area_entered)
	_setup_hit_audio()
	_set_punch_hitbox_active(false, false)
	_set_kick_hitbox_active(false, false)
	hp_changed.emit(current_hp, max_hp)


func _physics_process(delta: float) -> void:
	if _update_hit_stop(delta):
		return

	var direction := Input.get_axis("move_left", "move_right") if input_enabled else 0.0
	var is_kicking := kick_active_timer > 0.0

	_update_invincibility(delta)
	_update_hit_reaction(delta)
	_update_guard_hit(delta)
	_update_throw_escape(delta)
	_update_throw_recovery(delta)

	if input_enabled and not is_hit and not is_guard_hit and not _is_throw_busy():
		_update_defensive_state()

	if is_kicking or is_guarding or is_crouching or is_crouch_guarding or is_hit or is_guard_hit or _is_throw_busy():
		direction = 0.0

	if direction != 0.0 and not is_hit and not is_guard_hit and not _is_throw_busy():
		facing_direction = signf(direction)
		visual_root.scale.x = facing_direction

	if not is_hit and not is_guard_hit and not _is_throw_busy():
		velocity.x = direction * move_speed

	if is_on_floor():
		if input_enabled and Input.is_action_just_pressed("jump") and not is_crouching and not is_kicking and not is_guarding and not is_crouch_guarding and not is_hit and not is_guard_hit and not _is_throw_busy():
			velocity.y = -jump_power
		elif not is_hit:
			velocity.y = 0.0
	else:
		velocity.y += gravity * delta

	if input_enabled and _is_throw_input_held() and _can_start_throw():
		_try_start_throw()
	if input_enabled and not is_kicking and not is_guarding and not is_crouching and not is_crouch_guarding and not is_hit and not is_guard_hit and not _is_throw_busy() and not _is_throw_input_held() and Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0.0:
		_start_attack()
	if input_enabled and not is_guarding and not is_crouching and not is_crouch_guarding and not is_hit and not is_guard_hit and not _is_throw_busy() and not _is_throw_input_held() and Input.is_action_just_pressed("kick") and kick_cooldown_timer <= 0.0 and attack_active_timer <= 0.0:
		_start_kick()

	if not is_hit and not is_guard_hit and not _is_throw_busy():
		_update_attack(delta)
		_update_kick(delta)
	_update_visual_state()
	move_and_slide()

	if is_guard_hit and is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)

	var viewport_width := get_viewport_rect().size.x
	position.x = clampf(position.x, screen_margin, viewport_width - screen_margin)


func _start_attack() -> void:
	attack_active_timer = attack_active_time
	attack_cooldown_timer = attack_cooldown_time
	punch_hit_targets.clear()
	punch_area.position.x = facing_direction * attack_offset
	_set_punch_hitbox_active(true)


func _update_defensive_state() -> void:
	var down_pressed := Input.is_action_pressed("down")
	var guard_pressed := _is_holding_back_against_opponent()

	if not _can_start_guard_or_crouch():
		_clear_guard_state()
		if not is_on_floor():
			is_crouching = false
		return

	if guard_pressed:
		is_guarding = true
		is_crouch_guarding = down_pressed
		is_crouching = false
		guard_type = "crouch" if down_pressed else "stand"
		velocity.x = 0.0
		return

	_clear_guard_state()
	is_crouching = down_pressed and is_on_floor()
	if is_crouching:
		velocity.x = 0.0


func _start_kick() -> void:
	print("Kick Start")
	kick_active_timer = kick_active_time
	kick_cooldown_timer = kick_cooldown_time
	velocity.x = 0.0
	kick_hit_targets.clear()
	kick_area.position.x = facing_direction * kick_offset
	_set_kick_hitbox_active(true)


func _try_start_throw() -> void:
	var target := _get_throw_target()
	if target == null:
		return

	is_throwing = true
	throw_recovery_timer = throw_self_recovery_time
	velocity = Vector2.ZERO
	_clear_guard_state()
	is_crouching = false
	_play_throw_animation()
	print("ThrowHit")
	throw_hit.emit(target)
	target.receive_throw(self, throw_damage, _get_hit_position(target), facing_direction)


func receive_throw(attacker: Node, damage: int, hit_position: Vector2, throw_direction: float) -> void:
	if not can_be_thrown(attacker):
		return

	attack_active_timer = 0.0
	kick_active_timer = 0.0
	_clear_guard_state()
	is_crouching = false
	is_guard_hit = false
	is_hit = false
	is_throwing = false
	is_throw_locked = true
	is_throw_escape_pending = true
	is_throw_escaping = false
	throw_recovery_timer = throw_target_recovery_time
	throw_escape_timer = throw_escape_window
	pending_throw_attacker = attacker
	pending_throw_damage = damage
	pending_throw_hit_position = hit_position
	pending_throw_direction = throw_direction
	pending_throw_ai_checked = false
	velocity = Vector2.ZERO
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)


func _get_throw_target() -> Node:
	var target := _get_opponent()
	if target == null or not target.has_method("receive_throw"):
		return null
	if _get_throw_gap_to(target) > throw_range:
		return null
	if not target.can_be_thrown(self):
		return null
	return target


func _can_start_throw() -> bool:
	return input_enabled and is_round_active and is_on_floor() and not is_hit and not is_guard_hit and not _is_throw_busy() and not is_guarding and not is_crouching and not is_crouch_guarding and attack_active_timer <= 0.0 and kick_active_timer <= 0.0


func can_be_thrown(attacker: Node) -> bool:
	return is_round_active and current_hp > 0 and is_on_floor() and not is_hit and not is_guard_hit and not is_throwing and not is_throw_locked and not is_throw_escape_pending and not is_throw_escaping and not is_invincible


func _get_throw_gap_to(target: Node) -> float:
	return maxf(absf(global_position.x - target.global_position.x) - throw_body_width, 0.0)


func _is_throw_input_pressed() -> bool:
	return (Input.is_action_just_pressed("attack") and Input.is_action_pressed("kick")) or (Input.is_action_just_pressed("kick") and Input.is_action_pressed("attack"))


func _is_throw_input_held() -> bool:
	return Input.is_action_pressed("attack") and Input.is_action_pressed("kick")


func _is_throw_busy() -> bool:
	return is_throwing or is_throw_locked or is_throw_escape_pending or is_throw_escaping


func _update_throw_escape(delta: float) -> void:
	if not is_throw_escape_pending:
		return

	if _should_escape_throw():
		_complete_throw_escape()
		return

	throw_escape_timer = maxf(throw_escape_timer - delta, 0.0)
	if throw_escape_timer == 0.0:
		_complete_throw_hit()


func _should_escape_throw() -> bool:
	if not _can_escape_throw():
		return false
	if input_enabled and _is_throw_input_held():
		return true
	if not input_enabled and not pending_throw_ai_checked:
		pending_throw_ai_checked = true
		return randf() <= ai_throw_escape_rate
	return false


func _can_escape_throw() -> bool:
	return is_throw_escape_pending and throw_escape_timer > 0.0 and current_hp > 0 and is_on_floor() and not is_hit and not is_guard_hit


func _complete_throw_escape() -> void:
	var attacker := pending_throw_attacker
	is_throw_escape_pending = false
	is_throw_escaping = true
	is_throw_locked = true
	throw_recovery_timer = throw_escape_freeze_time
	throw_escape_timer = 0.0
	velocity = Vector2.ZERO
	_clear_pending_throw()

	if attacker != null and attacker.has_method("enter_throw_escape_recovery"):
		attacker.enter_throw_escape_recovery(self)

	_push_throw_escape_apart(attacker)
	_spawn_throw_escape_effect(global_position)
	_play_throw_escape_se()


func enter_throw_escape_recovery(escaped_target: Node) -> void:
	is_throwing = false
	is_throw_locked = true
	is_throw_escaping = true
	throw_recovery_timer = throw_escape_freeze_time
	velocity = Vector2.ZERO
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)


func _complete_throw_hit() -> void:
	var attacker := pending_throw_attacker
	var hit_position := pending_throw_hit_position
	var damage := pending_throw_damage
	is_throw_escape_pending = false
	throw_escape_timer = 0.0
	_clear_pending_throw()
	apply_damage(damage)

	if attacker != null and attacker.has_method("_spawn_hit_effect"):
		attacker._spawn_hit_effect(hit_position, 1.0)
	if attacker != null and attacker.has_method("_play_throw_se"):
		attacker._play_throw_se()


func _clear_pending_throw() -> void:
	pending_throw_attacker = null
	pending_throw_damage = 0
	pending_throw_hit_position = Vector2.ZERO
	pending_throw_direction = 0.0
	pending_throw_ai_checked = false


func _push_throw_escape_apart(attacker: Node) -> void:
	if not (attacker is Node2D):
		return

	var direction_from_attacker := signf(global_position.x - attacker.global_position.x)
	if direction_from_attacker == 0.0:
		direction_from_attacker = 1.0
	position.x += direction_from_attacker * throw_escape_pushback
	var attacker_2d := attacker as Node2D
	attacker_2d.position.x -= direction_from_attacker * throw_escape_pushback


func _spawn_throw_escape_effect(effect_position: Vector2) -> void:
	var effect_root := Node2D.new()
	effect_root.global_position = effect_position
	effect_root.name = "ThrowEscapeEffect"

	var flash := Polygon2D.new()
	var points := PackedVector2Array()
	var radius := 22.0
	for point_index in range(12):
		var angle := TAU * float(point_index) / 12.0
		var point_radius := radius if point_index % 2 == 0 else radius * 0.45
		points.append(Vector2(cos(angle), sin(angle)) * point_radius)
	flash.color = Color(0.55, 0.95, 1.0, 0.78)
	flash.polygon = points
	effect_root.add_child(flash)
	get_tree().current_scene.add_child(effect_root)

	var tween := effect_root.create_tween()
	tween.tween_property(effect_root, "scale", Vector2(1.5, 1.5), 0.16)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.16)
	tween.tween_callback(effect_root.queue_free)


func _update_throw_recovery(delta: float) -> void:
	if not _is_throw_busy():
		return

	throw_recovery_timer = maxf(throw_recovery_timer - delta, 0.0)
	if throw_recovery_timer > 0.0:
		return

	is_throwing = false
	is_throw_locked = false
	is_throw_escaping = false


func _play_throw_animation() -> void:
	if animation_player != null and animation_player.has_animation("Throw"):
		animation_player.play("Throw")


func _update_attack(delta: float) -> void:
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer = maxf(attack_cooldown_timer - delta, 0.0)

	if attack_active_timer <= 0.0:
		_set_punch_hitbox_active(false)
		return

	attack_active_timer = maxf(attack_active_timer - delta, 0.0)
	if attack_active_timer == 0.0:
		_set_punch_hitbox_active(false)


func _update_kick(delta: float) -> void:
	if kick_cooldown_timer > 0.0:
		kick_cooldown_timer = maxf(kick_cooldown_timer - delta, 0.0)

	if kick_active_timer <= 0.0:
		_set_kick_hitbox_active(false)
		return

	kick_active_timer = maxf(kick_active_timer - delta, 0.0)
	if kick_active_timer == 0.0:
		_set_kick_hitbox_active(false)
		print("Kick End")


func _set_punch_hitbox_active(is_active: bool, should_print := true) -> void:
	if punch_hitbox_active == is_active:
		return

	punch_hitbox_active = is_active
	punch_area.set_deferred("monitoring", is_active)
	punch_shape.set_deferred("disabled", not is_active)
	if not is_active:
		punch_hit_targets.clear()
	if should_print:
		print("Punch HitBox ON" if is_active else "Punch HitBox OFF")


func _set_kick_hitbox_active(is_active: bool, should_print := true) -> void:
	if kick_hitbox_active == is_active:
		return

	kick_hitbox_active = is_active
	kick_area.set_deferred("monitoring", is_active)
	kick_shape.set_deferred("disabled", not is_active)
	if not is_active:
		kick_hit_targets.clear()
	if should_print:
		print("Kick HitBox ON" if is_active else "Kick HitBox OFF")


func _on_punch_hitbox_area_entered(area: Area2D) -> void:
	if not punch_hitbox_active:
		return

	var hit_target := _get_valid_hurtbox_target(area)
	if hit_target == null or punch_hit_targets.has(hit_target):
		return

	punch_hit_targets.append(hit_target)
	print("Punch Hit")
	_apply_attack_to_target(hit_target, _get_punch_attack_data())


func _on_kick_hitbox_area_entered(area: Area2D) -> void:
	if not kick_hitbox_active:
		return

	var hit_target := _get_valid_hurtbox_target(area)
	if hit_target == null or kick_hit_targets.has(hit_target):
		return

	kick_hit_targets.append(hit_target)
	print("Kick Hit")
	_apply_attack_to_target(hit_target, _get_kick_attack_data())


func _get_valid_hurtbox_target(area: Area2D) -> Node:
	if area == hurt_box or area.name != "HurtBox":
		return null

	var target := area.get_parent()
	if target == self:
		return null
	if not target.has_method("apply_damage"):
		return null
	if target.get("is_invincible") == true:
		return null

	return target


func apply_damage(damage: int) -> void:
	var was_alive := current_hp > 0
	current_hp = maxi(current_hp - damage, 0)
	print("Damage: %d" % damage)
	print("HP: %d" % current_hp)
	hp_changed.emit(current_hp, max_hp)
	if current_hp == 0 and was_alive:
		print("HP reached 0")
		hp_depleted.emit()


func receive_attack(attack_data: Dictionary, attack_direction: float, hit_position: Vector2, attacker: Node) -> void:
	if _can_guard_attack(attack_data, attacker):
		_receive_guarded_attack(attack_data, attack_direction, hit_position, attacker)
		return

	_cancel_current_action()
	_enter_hit_state()
	apply_damage(attack_data["damage"])
	_apply_knockback(attack_data, attack_direction)
	_start_invincibility()
	_start_hit_stop(attack_data["hit_stop_frames"])
	_spawn_hit_effect(hit_position, attack_data["effect_size"])
	_play_hit_se(attack_data["se_type"])
	if attacker != null and attacker.has_method("start_hit_stop"):
		attacker.start_hit_stop(attack_data["hit_stop_frames"])
	screen_shake_requested.emit(attack_data["screen_shake"])


func start_hit_stop(frame_count: int) -> void:
	_start_hit_stop(frame_count)


func _apply_attack_to_target(target: Node, attack_data: Dictionary) -> void:
	if not target.has_method("receive_attack"):
		return

	target.receive_attack(attack_data, facing_direction, _get_hit_position(target), self)


func _get_punch_attack_data() -> Dictionary:
	return {
		"damage": punch_damage,
		"attack_height": "middle",
		"knockback_x": punch_knockback_x,
		"knockback_y": punch_knockback_y,
		"hit_stop_frames": 3,
		"effect_size": 1.0,
		"screen_shake": 2.0,
		"se_type": "weak",
	}


func _get_kick_attack_data() -> Dictionary:
	return {
		"damage": kick_damage,
		"attack_height": "low",
		"knockback_x": kick_knockback_x,
		"knockback_y": kick_knockback_y,
		"hit_stop_frames": 8,
		"effect_size": 1.5,
		"screen_shake": 4.0,
		"se_type": "strong",
	}


func _get_hit_position(target: Node) -> Vector2:
	if target is Node2D:
		return (global_position + target.global_position) * 0.5
	return global_position


func _cancel_current_action() -> void:
	attack_active_timer = 0.0
	kick_active_timer = 0.0
	_clear_guard_state()
	is_crouching = false
	is_guard_hit = false
	is_throwing = false
	is_throw_locked = false
	is_throw_escape_pending = false
	is_throw_escaping = false
	throw_recovery_timer = 0.0
	throw_escape_timer = 0.0
	_clear_pending_throw()
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)


func _enter_hit_state() -> void:
	is_hit = true
	hit_reaction_timer = hit_reaction_time


func _apply_knockback(attack_data: Dictionary, attack_direction: float) -> void:
	velocity.x = attack_data["knockback_x"] * attack_direction
	if not is_on_floor():
		velocity.y = -attack_data["knockback_y"]


func _receive_guarded_attack(attack_data: Dictionary, attack_direction: float, hit_position: Vector2, attacker: Node) -> void:
	attack_active_timer = 0.0
	kick_active_timer = 0.0
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)
	_enter_guard_hit_state()
	apply_damage(_get_guard_damage(attack_data["damage"]))
	_apply_guard_knockback(attack_data, attack_direction)
	_start_hit_stop(attack_data["hit_stop_frames"])
	_spawn_guard_effect(hit_position)
	_play_guard_se()
	if attacker != null and attacker.has_method("start_hit_stop"):
		attacker.start_hit_stop(attack_data["hit_stop_frames"])


func _enter_guard_hit_state() -> void:
	is_guard_hit = true
	is_hit = false
	guard_hit_timer = guard_hit_time


func _get_guard_damage(damage: int) -> int:
	return maxi(1, int(round(float(damage) * guard_damage_rate)))


func _apply_guard_knockback(attack_data: Dictionary, attack_direction: float) -> void:
	velocity.x = attack_data["knockback_x"] * guard_knockback_scale * attack_direction
	if is_on_floor():
		velocity.y = 0.0


func _can_guard_attack(attack_data: Dictionary, attacker: Node) -> bool:
	if not can_guard or not is_round_active or is_guard_hit:
		return false
	if is_hit or is_invincible or not is_on_floor():
		return false
	if attack_active_timer > 0.0 or kick_active_timer > 0.0:
		return false
	if not is_guarding:
		return false
	if not _is_holding_back_against_attacker(attacker):
		return false
	return _is_attack_height_guardable(str(attack_data.get("attack_height", "middle")))


func _is_attack_height_guardable(attack_height: String) -> bool:
	match attack_height:
		"high":
			return guard_type == "stand" or guard_type == "crouch"
		"middle":
			return guard_type == "stand"
		"low":
			return guard_type == "crouch"
		_:
			return false


func _can_start_guard_or_crouch() -> bool:
	return can_guard and is_round_active and is_on_floor() and attack_active_timer <= 0.0 and kick_active_timer <= 0.0 and not is_hit and not is_guard_hit


func _is_holding_back_against_opponent() -> bool:
	return _is_holding_back_against_attacker(_get_opponent())


func _is_holding_back_against_attacker(attacker: Node) -> bool:
	if attacker is Node2D and input_enabled:
		var direction_to_attacker := signf(attacker.global_position.x - global_position.x)
		var input_direction := Input.get_axis("move_left", "move_right")
		return direction_to_attacker != 0.0 and input_direction != 0.0 and signf(input_direction) == -direction_to_attacker

	return is_guarding


func _get_opponent() -> Node:
	var parent_node := get_parent()
	if parent_node == null:
		return null
	if name == "Player":
		return parent_node.get_node_or_null("Enemy")
	if name == "Enemy":
		return parent_node.get_node_or_null("Player")
	return null


func _clear_guard_state() -> void:
	is_guarding = false
	is_crouch_guarding = false
	guard_type = "none"


func _update_guard_hit(delta: float) -> void:
	if not is_guard_hit:
		return

	guard_hit_timer = maxf(guard_hit_timer - delta, 0.0)
	if guard_hit_timer > 0.0:
		return

	is_guard_hit = false
	_clear_guard_state()
	if input_enabled:
		_update_defensive_state()


func _start_invincibility() -> void:
	is_invincible = true
	invincibility_timer = invincibility_time
	hurt_box.set_deferred("monitorable", false)
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)


func _update_invincibility(delta: float) -> void:
	if not is_invincible:
		return

	invincibility_timer = maxf(invincibility_timer - delta, 0.0)
	if invincibility_timer == 0.0:
		is_invincible = false
		hurt_box.set_deferred("monitorable", true)


func _start_hit_stop(frame_count: int) -> void:
	hit_stop_timer = maxf(hit_stop_timer, float(frame_count) / 60.0)


func _update_hit_stop(delta: float) -> bool:
	if hit_stop_timer <= 0.0:
		return false

	hit_stop_timer = maxf(hit_stop_timer - delta, 0.0)
	return hit_stop_timer > 0.0


func _update_hit_reaction(delta: float) -> void:
	if not is_hit:
		return

	hit_reaction_timer = maxf(hit_reaction_timer - delta, 0.0)
	if hit_reaction_timer == 0.0:
		is_hit = false
		if is_on_floor():
			velocity.x = 0.0


func _spawn_hit_effect(hit_position: Vector2, effect_size: float) -> void:
	var effect_root := Node2D.new()
	effect_root.global_position = hit_position
	effect_root.name = "HitEffect"

	var flash := Polygon2D.new()
	var size := 18.0 * effect_size
	flash.color = Color(1.0, 0.95, 0.25, 0.75)
	flash.polygon = PackedVector2Array([
		Vector2(0, -size),
		Vector2(size, 0),
		Vector2(0, size),
		Vector2(-size, 0),
	])
	effect_root.add_child(flash)
	get_tree().current_scene.add_child(effect_root)

	var timer := get_tree().create_timer(0.15)
	timer.timeout.connect(effect_root.queue_free)


func _setup_hit_audio() -> void:
	weak_hit_se = AudioStreamPlayer2D.new()
	weak_hit_se.name = "WeakHitSE"
	weak_hit_se.stream = _create_hit_stream(540.0)
	add_child(weak_hit_se)

	strong_hit_se = AudioStreamPlayer2D.new()
	strong_hit_se.name = "StrongHitSE"
	strong_hit_se.stream = _create_hit_stream(220.0)
	add_child(strong_hit_se)

	guard_hit_se = AudioStreamPlayer2D.new()
	guard_hit_se.name = "GuardHitSE"
	guard_hit_se.stream = _create_hit_stream(760.0)
	add_child(guard_hit_se)

	throw_se = AudioStreamPlayer2D.new()
	throw_se.name = "ThrowSE"
	throw_se.stream = _create_hit_stream(140.0)
	add_child(throw_se)

	throw_escape_se = AudioStreamPlayer2D.new()
	throw_escape_se.name = "ThrowEscapeSE"
	throw_escape_se.stream = _create_hit_stream(920.0)
	add_child(throw_escape_se)


func _create_hit_stream(frequency: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.08
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	for sample_index in sample_count:
		var fade := 1.0 - (float(sample_index) / float(sample_count))
		var value := int(sin(TAU * frequency * float(sample_index) / float(sample_rate)) * 12000.0 * fade)
		data.append(value & 0xff)
		data.append((value >> 8) & 0xff)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _play_hit_se(se_type: String) -> void:
	if se_type == "strong":
		strong_hit_se.play()
	else:
		weak_hit_se.play()


func _play_guard_se() -> void:
	guard_hit_se.play()


func _play_throw_se() -> void:
	throw_se.play()


func _play_throw_escape_se() -> void:
	throw_escape_se.play()


func _spawn_guard_effect(hit_position: Vector2) -> void:
	var effect_root := Node2D.new()
	effect_root.global_position = hit_position
	effect_root.name = "GuardEffect"

	var flash := Polygon2D.new()
	var points := PackedVector2Array()
	var radius := 16.0
	for point_index in range(16):
		var angle := TAU * float(point_index) / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	flash.color = Color(0.45, 0.9, 1.0, 0.65)
	flash.polygon = points
	effect_root.add_child(flash)
	get_tree().current_scene.add_child(effect_root)

	var tween := effect_root.create_tween()
	tween.tween_property(effect_root, "scale", Vector2(1.7, 1.7), 0.12)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.12)
	tween.tween_callback(effect_root.queue_free)


func _update_visual_state() -> void:
	if is_throw_escaping:
		state_label.text = "ThrowEscape"
	elif is_throwing or is_throw_locked or is_throw_escape_pending:
		state_label.text = "Throw"
	elif is_guard_hit:
		state_label.text = "GuardHit"
	elif is_hit:
		state_label.text = "Hit"
	elif is_crouch_guarding:
		state_label.text = "CrouchGuard"
	elif is_guarding:
		state_label.text = "Guard"
	elif is_crouching:
		state_label.text = "Crouch"
	elif kick_active_timer > 0.0:
		state_label.text = "Kick"
	elif attack_active_timer > 0.0:
		state_label.text = "Punch"
	elif absf(velocity.x) > 0.0:
		state_label.text = "Walk"
	else:
		state_label.text = "Idle"

	guard_visual.visible = is_guarding and not is_crouch_guarding
	crouch_visual.visible = is_crouching
	crouch_guard_visual.visible = is_crouch_guarding
	var target_y_scale := 0.7 if is_crouching or is_crouch_guarding else 1.0
	visual_root.scale.y = target_y_scale
