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
	# Crusher's current 330 px battle height is rendered with the shared 1.2
	# mobile battle multiplier (330 / 192 * 1.2 = 2.0625).
	assert(animated.scale.is_equal_approx(Vector2(2.0625, 2.0625)))
	assert(animated.position.is_equal_approx(Vector2(0.0, -165.0)))
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
	assert(animated.position.is_equal_approx(Vector2(0.0, -165.0)))
	controller.set_facing(1)
	assert(not animated.flip_h)

	# Akky's Walk is intentionally an eight-frame authored cycle. Keep both
	# directions on the same source cycle so forward/backward cannot silently
	# regress to the older five-frame strip.
	var akky_definition := load("res://data/fighters/ally_balance.tres")
	var akky_controller := CharacterVisualController.new()
	var akky_animated := AnimatedSprite2D.new()
	var akky_fallback := Sprite2D.new()
	get_root().add_child(akky_controller)
	akky_controller.add_child(akky_animated)
	akky_controller.add_child(akky_fallback)
	assert(akky_controller.setup(akky_definition, akky_animated, akky_fallback))
	for walk_animation in [&"walk_forward", &"walk_backward"]:
		assert(akky_controller.has_animation(walk_animation))
		assert(akky_animated.sprite_frames.get_frame_count(walk_animation) == 8)
	assert(akky_controller.has_animation(&"ko"))
	assert(akky_animated.sprite_frames.get_frame_count(&"ko") == 6)
	assert(akky_controller.has_animation(&"idle"))
	assert(akky_animated.sprite_frames.get_frame_count(&"idle") == 7)
	assert(akky_controller.has_animation(&"dash"))
	assert(akky_animated.sprite_frames.get_frame_count(&"dash") == 7)
	assert(akky_controller.has_animation(&"jump_kick"))
	assert(akky_animated.sprite_frames.get_frame_count(&"jump_kick") == 7)
	assert(akky_controller.has_animation(&"jump_punch_down"))
	assert(akky_animated.sprite_frames.get_frame_count(&"jump_punch_down") == 7)
	print("DEV052_OK scale=", animated.scale, " position=", animated.position, " offset=", animated.offset)
	quit()
