extends CharacterBody2D

@export var move_speed := 300.0
@export var crouch_speed := 120.0
@export var jump_power := 500.0
@export var screen_margin := 36.0
@export var attack_active_time := 0.12
@export var attack_cooldown_time := 0.35
@export var attack_offset := 56.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_direction := 1.0
var attack_active_timer := 0.0
var attack_cooldown_timer := 0.0

@onready var visual_root := $VisualRoot
@onready var state_label := $VisualRoot/IdlePlaceholder/IdleStateLabel
@onready var attack_area := $AttackArea
@onready var attack_shape := $AttackArea/CollisionShape2D


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var is_crouching := Input.is_action_pressed("crouch") and is_on_floor()
	var current_speed := crouch_speed if is_crouching else move_speed

	if direction != 0.0:
		facing_direction = signf(direction)
		visual_root.scale.x = facing_direction

	velocity.x = direction * current_speed

	if is_on_floor():
		if Input.is_action_just_pressed("jump") and not is_crouching:
			velocity.y = -jump_power
		else:
			velocity.y = 0.0
	else:
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0.0:
		_start_attack()

	_update_attack(delta)
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


func _update_attack(delta: float) -> void:
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer = maxf(attack_cooldown_timer - delta, 0.0)

	if attack_active_timer <= 0.0:
		return

	attack_active_timer = maxf(attack_active_timer - delta, 0.0)
	if attack_active_timer == 0.0:
		attack_area.set_deferred("monitoring", false)
		attack_shape.set_deferred("disabled", true)


func _update_visual_state(is_crouching: bool) -> void:
	if attack_active_timer > 0.0:
		state_label.text = "Punch"
	elif is_crouching:
		state_label.text = "Crouch"
	else:
		state_label.text = "Idle"

	var target_y_scale := 0.7 if is_crouching else 1.0
	visual_root.scale.y = target_y_scale
