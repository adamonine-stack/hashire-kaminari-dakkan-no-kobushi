extends Node2D

## Quiet industrial street: all geometry sits behind the combat plane at y=520.
func _ready() -> void:
	z_index = -20

func _draw() -> void:
	draw_rect(Rect2(-900, -600, 3100, 1800), Color("17232f"))
	# Distant skyline has low contrast, keeping fighters as the visual focus.
	for i in range(-4, 12):
		var h := 130.0 + float(posmod(i * 71, 170))
		var x := float(i * 155)
		draw_rect(Rect2(x, 410 - h, 118, h), Color("233440"))
		for row in range(3):
			for column in range(3):
				draw_rect(Rect2(x + 18 + column * 30, 430 - h + row * 38, 9, 14), Color("3b4849"))
	# Warehouse wall and inset shutters establish the middle distance.
	draw_rect(Rect2(-600, 335, 2500, 185), Color("34454a"))
	draw_line(Vector2(-600, 335), Vector2(1900, 335), Color("536363"), 7)
	for x in [-280, 140, 900, 1320]:
		draw_rect(Rect2(x, 367, 190, 141), Color("29383d"))
		for y in range(380, 505, 16):
			draw_line(Vector2(x + 6, y), Vector2(x + 184, y), Color("3e5053"), 2)
	for x in [-30, 1260]:
		draw_rect(Rect2(x, 250, 8, 270), Color("19292e"))
		draw_rect(Rect2(x - 20, 245, 48, 8), Color("b39c68"))
	# The top of the pavement is exactly the physics floor, never a fake platform.
	draw_rect(Rect2(-900, 520, 3100, 800), Color("454b49"))
	draw_line(Vector2(-900, 520), Vector2(2200, 520), Color("a0a58d"), 4)
	draw_line(Vector2(-900, 536), Vector2(2200, 536), Color("2a3639"), 3)
	for x in range(-800, 2200, 180):
		draw_line(Vector2(x, 540), Vector2(640 + (x - 640) * 2, 1000), Color("373f40"), 2)
	for y in [594, 704, 890]:
		draw_line(Vector2(-900, y), Vector2(2200, y), Color("373f40"), 2)
