extends SceneTree


func _initialize() -> void:
	var definition := load("res://data/enemies/enemy_01_standard.tres")
	var controller := CharacterVisualController.new()
	var animated := AnimatedSprite2D.new()
	var fallback := Sprite2D.new()
	get_root().add_child(controller)
	controller.add_child(animated)
	controller.add_child(fallback)
	assert(controller.setup(definition, animated, fallback))
	assert(animated.scale.is_equal_approx(Vector2(1.75, 1.75)))
	assert(animated.position.is_equal_approx(Vector2(0.0, -140.0)))
	assert(animated.offset == Vector2.ZERO)
	assert(animated.centered)
	assert(not animated.flip_h)
	assert(is_equal_approx(animated.speed_scale, 1.0))
	var required := [
		&"walk", &"punch", &"kick", &"jump", &"guard", &"crouch",
		&"crouch_guard", &"crouch_punch", &"crouch_kick",
	]
	for animation_name in required:
		assert(controller.has_animation(animation_name))
		assert(animated.sprite_frames.get_frame_count(animation_name) == 8)
		controller.play_animation(animation_name, true)
		assert(animated.animation == animation_name)
	controller.set_facing(-1)
	assert(animated.flip_h)
	assert(animated.position.is_equal_approx(Vector2(0.0, -140.0)))
	controller.set_facing(1)
	assert(not animated.flip_h)
	print("DEV052_OK scale=", animated.scale, " position=", animated.position, " offset=", animated.offset)
	quit()
