extends CharacterBody2D

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

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
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
	punch_area.area_entered.connect(_on_punch_hitbox_area_entered)
	kick_area.area_entered.connect(_on_kick_hitbox_area_entered)
	_set_punch_hitbox_active(false, false)
	_set_kick_hitbox_active(false, false)


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var is_kicking := kick_active_timer > 0.0

	_update_defensive_state()

	if is_kicking or is_guarding or is_crouching or is_crouch_guarding:
		direction = 0.0

	if direction != 0.0:
		facing_direction = signf(direction)
		visual_root.scale.x = facing_direction

	velocity.x = direction * move_speed

	if is_on_floor():
		if Input.is_action_just_pressed("jump") and not is_crouching and not is_kicking and not is_guarding and not is_crouch_guarding:
			velocity.y = -jump_power
		else:
			velocity.y = 0.0
	else:
		velocity.y += gravity * delta

	if not is_kicking and not is_guarding and not is_crouching and not is_crouch_guarding and Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0.0:
		_start_attack()
	if not is_guarding and not is_crouching and not is_crouch_guarding and Input.is_action_just_pressed("kick") and kick_cooldown_timer <= 0.0 and attack_active_timer <= 0.0:
		_start_kick()

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


func _on_kick_hitbox_area_entered(area: Area2D) -> void:
	if not kick_hitbox_active:
		return

	var hit_target := _get_valid_hurtbox_target(area)
	if hit_target == null or kick_hit_targets.has(hit_target):
		return

	kick_hit_targets.append(hit_target)
	print("Kick Hit")


func _get_valid_hurtbox_target(area: Area2D) -> Node:
	if area == hurt_box or area.name != "HurtBox":
		return null

	var target := area.get_parent()
	if target == self:
		return null

	return target


func _update_visual_state() -> void:
	if is_crouch_guarding:
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
