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

@onready var visual_root := $VisualRoot
@onready var state_label := $VisualRoot/IdlePlaceholder/IdleStateLabel
@onready var guard_visual := $VisualRoot/IdlePlaceholder/GuardPlaceholder
@onready var attack_area := $AttackArea
@onready var attack_shape := $AttackArea/CollisionShape2D
@onready var kick_area := $KickHitBox
@onready var kick_shape := $KickHitBox/CollisionShape2D


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var is_crouching := Input.is_action_pressed("crouch") and is_on_floor()
	var current_speed := crouch_speed if is_crouching else move_speed
	var is_kicking := kick_active_timer > 0.0

	_update_guard_state()

	if is_kicking or is_guarding:
		direction = 0.0
		is_crouching = false

	if direction != 0.0:
		facing_direction = signf(direction)
		visual_root.scale.x = facing_direction

	velocity.x = direction * current_speed

	if is_on_floor():
		if Input.is_action_just_pressed("jump") and not is_crouching and not is_kicking and not is_guarding:
			velocity.y = -jump_power
		else:
			velocity.y = 0.0
	else:
		velocity.y += gravity * delta

	if not is_kicking and not is_guarding and Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0.0:
		_start_attack()
	if not is_guarding and Input.is_action_just_pressed("kick") and kick_cooldown_timer <= 0.0 and attack_active_timer <= 0.0:
		_start_kick()

	_update_attack(delta)
	_update_kick(delta)
	_update_visual_state(is_crouching)
	move_and_slide()

	var viewport_width := get_viewport_rect().size.x
	position.x = clampf(position.x, screen_margin, viewport_width - screen_margin)


func _start_attack() -> void:
	attack_active_timer = attack_active_time
	attack_cooldown_timer = attack_cooldown_time
	attack_area.position.x = facing_direction * attack_offset
	attack_area.set_deferred("monitoring", true)
	attack_shape.set_deferred("disabled", false)


func _update_guard_state() -> void:
	var can_start_guard := attack_active_timer <= 0.0 and kick_active_timer <= 0.0

	if is_guarding:
		if not Input.is_action_pressed("guard"):
			is_guarding = false
			print("Guard End")
		return

	if Input.is_action_just_pressed("guard") and can_start_guard:
		is_guarding = true
		velocity.x = 0.0
		print("Guard Start")


func _start_kick() -> void:
	print("Kick Start")
	kick_active_timer = kick_active_time
	kick_cooldown_timer = kick_cooldown_time
	velocity.x = 0.0
	kick_area.position.x = facing_direction * kick_offset
	kick_area.set_deferred("monitoring", true)
	kick_shape.set_deferred("disabled", false)


func _update_attack(delta: float) -> void:
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer = maxf(attack_cooldown_timer - delta, 0.0)

	if attack_active_timer <= 0.0:
		return

	attack_active_timer = maxf(attack_active_timer - delta, 0.0)
	if attack_active_timer == 0.0:
		attack_area.set_deferred("monitoring", false)
		attack_shape.set_deferred("disabled", true)


func _update_kick(delta: float) -> void:
	if kick_cooldown_timer > 0.0:
		kick_cooldown_timer = maxf(kick_cooldown_timer - delta, 0.0)

	if kick_active_timer <= 0.0:
		return

	kick_active_timer = maxf(kick_active_timer - delta, 0.0)
	if kick_active_timer == 0.0:
		kick_area.set_deferred("monitoring", false)
		kick_shape.set_deferred("disabled", true)
		print("Kick End")


func _update_visual_state(is_crouching: bool) -> void:
	if kick_active_timer > 0.0:
		state_label.text = "Kick"
	elif attack_active_timer > 0.0:
		state_label.text = "Punch"
	elif is_guarding:
		state_label.text = "Guard"
	elif is_crouching:
		state_label.text = "Crouch"
	else:
		state_label.text = "Idle"

	guard_visual.visible = is_guarding
	var target_y_scale := 0.7 if is_crouching else 1.0
	visual_root.scale.y = target_y_scale
