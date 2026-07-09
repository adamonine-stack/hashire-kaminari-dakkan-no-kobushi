extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal hp_depleted
signal screen_shake_requested(strength: float)

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
var punch_hitbox_active := false
var kick_hitbox_active := false
var punch_hit_targets: Array[Node] = []
var kick_hit_targets: Array[Node] = []
var is_hit := false
var is_invincible := false
var hit_reaction_timer := 0.0
var invincibility_timer := 0.0
var hit_stop_timer := 0.0
var weak_hit_se: AudioStreamPlayer2D
var strong_hit_se: AudioStreamPlayer2D

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

	if input_enabled and not is_hit:
		_update_defensive_state()

	if is_kicking or is_guarding or is_crouching or is_crouch_guarding or is_hit:
		direction = 0.0

	if direction != 0.0 and not is_hit:
		facing_direction = signf(direction)
		visual_root.scale.x = facing_direction

	if not is_hit:
		velocity.x = direction * move_speed

	if is_on_floor():
		if input_enabled and Input.is_action_just_pressed("jump") and not is_crouching and not is_kicking and not is_guarding and not is_crouch_guarding and not is_hit:
			velocity.y = -jump_power
		elif not is_hit:
			velocity.y = 0.0
	else:
		velocity.y += gravity * delta

	if input_enabled and not is_kicking and not is_guarding and not is_crouching and not is_crouch_guarding and not is_hit and Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0.0:
		_start_attack()
	if input_enabled and not is_guarding and not is_crouching and not is_crouch_guarding and not is_hit and Input.is_action_just_pressed("kick") and kick_cooldown_timer <= 0.0 and attack_active_timer <= 0.0:
		_start_kick()

	if not is_hit:
		_update_attack(delta)
		_update_kick(delta)
	_update_visual_state()
	move_and_slide()

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
	var guard_pressed := Input.is_action_pressed("guard")
	var can_start_defense := is_on_floor() and attack_active_timer <= 0.0 and kick_active_timer <= 0.0

	if is_crouch_guarding:
		if down_pressed and guard_pressed and is_on_floor():
			return

		is_crouch_guarding = false
		print("CrouchGuard End")
		if down_pressed and is_on_floor():
			is_crouching = true
			print("Crouch Start")
		elif guard_pressed:
			is_guarding = true
			print("Guard Start")
		return

	if is_guarding:
		if not guard_pressed:
			is_guarding = false
			print("Guard End")
			if down_pressed and can_start_defense:
				is_crouching = true
				print("Crouch Start")
			return

		if down_pressed and can_start_defense:
			is_guarding = false
			is_crouch_guarding = true
			velocity.x = 0.0
			print("CrouchGuard Start")
		return

	if is_crouching:
		if not down_pressed or not is_on_floor():
			is_crouching = false
			print("Crouch End")
			if guard_pressed and can_start_defense:
				is_guarding = true
				print("Guard Start")
			return

		if guard_pressed and can_start_defense:
			is_crouching = false
			is_crouch_guarding = true
			velocity.x = 0.0
			print("CrouchGuard Start")
		return

	if not can_start_defense:
		return

	if down_pressed and guard_pressed and (Input.is_action_just_pressed("down") or Input.is_action_just_pressed("guard")):
		is_crouch_guarding = true
		velocity.x = 0.0
		print("CrouchGuard Start")
	elif Input.is_action_just_pressed("guard"):
		is_guarding = true
		velocity.x = 0.0
		print("Guard Start")
	elif Input.is_action_just_pressed("down"):
		is_crouching = true
		velocity.x = 0.0
		print("Crouch Start")


func _start_kick() -> void:
	print("Kick Start")
	kick_active_timer = kick_active_time
	kick_cooldown_timer = kick_cooldown_time
	velocity.x = 0.0
	kick_hit_targets.clear()
	kick_area.position.x = facing_direction * kick_offset
	_set_kick_hitbox_active(true)


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
	is_guarding = false
	is_crouching = false
	is_crouch_guarding = false
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)


func _enter_hit_state() -> void:
	is_hit = true
	hit_reaction_timer = hit_reaction_time


func _apply_knockback(attack_data: Dictionary, attack_direction: float) -> void:
	velocity.x = attack_data["knockback_x"] * attack_direction
	if not is_on_floor():
		velocity.y = -attack_data["knockback_y"]


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


func _update_visual_state() -> void:
	if is_hit:
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

	guard_visual.visible = is_guarding
	crouch_visual.visible = is_crouching
	crouch_guard_visual.visible = is_crouch_guarding
	var target_y_scale := 0.7 if is_crouching or is_crouch_guarding else 1.0
	visual_root.scale.y = target_y_scale
