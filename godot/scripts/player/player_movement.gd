extends Node2D

@export var move_speed := 300.0
@export var screen_margin := 36.0


func _process(delta: float) -> void:
	var direction := Input.get_axis("MoveLeft", "MoveRight")
	var viewport_width := get_viewport_rect().size.x
	var next_x := position.x + direction * move_speed * delta

	position.x = clampf(next_x, screen_margin, viewport_width - screen_margin)
