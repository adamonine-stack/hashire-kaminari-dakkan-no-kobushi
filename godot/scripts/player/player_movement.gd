extends CharacterBody2D

@export var move_speed := 300.0
@export var jump_power := 500.0
@export var screen_margin := 36.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("MoveLeft", "MoveRight")
	velocity.x = direction * move_speed

	if is_on_floor():
		if Input.is_action_just_pressed("Jump"):
			velocity.y = -jump_power
		else:
			velocity.y = 0.0
	else:
		velocity.y += gravity * delta

	move_and_slide()

	var viewport_width := get_viewport_rect().size.x
	position.x = clampf(position.x, screen_margin, viewport_width - screen_margin)
