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
	# Fixed 228px authored body, 198/175 height ratio relative to Akky.
	var crusher_scale := 174.78516 * 1.2 * (198.0 / 175.0) * 1.05 / 228.0
	assert(animated.scale.is_equal_approx(Vector2(crusher_scale, crusher_scale)))
	var idle_rect := controller._reference_body_rect_from_idle(Vector2i(400, 280))
	var boot_y := float(idle_rect.end.y - 140)
	assert(absf(boot_y - 120.0) <= 2.0)
	assert(animated.position.is_equal_approx(Vector2(0, -boot_y * crusher_scale)))
	assert(animated.offset == Vector2.ZERO)
	assert(animated.centered)
	assert(not animated.flip_h)
	assert(is_equal_approx(animated.speed_scale, 1.0))
	var required := {
		&"idle": 1, &"walk": 4, &"dash": 2, &"punch": 3,
		&"punch_2": 4, &"kick": 3, &"jump": 3,
		&"jump_start": 2, &"jump_fall": 1, &"jump_land": 2,
		&"jump_kick": 4, &"jump_punch": 4, &"jump_punch_down": 4,
		&"guard": 1, &"crouch": 1, &"crouch_guard": 1,
		&"crouch_punch": 3, &"crouch_kick": 3,
		&"damage_high": 2, &"knockdown": 3,
		&"stand_up": 4, &"ko": 2, &"throw": 4,
	}
	for animation_name in required:
		assert(controller.has_animation(animation_name))
		assert(animated.sprite_frames.get_frame_count(animation_name) == required[animation_name])
		controller.play_animation(animation_name, true)
		assert(animated.animation == animation_name)
	controller.set_facing(-1)
	assert(animated.flip_h)
	assert(animated.position.is_equal_approx(Vector2(0, -boot_y * crusher_scale)))
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
	assert(akky_animated.sprite_frames.get_frame_count(&"ko") == 4)
	assert(akky_controller.has_animation(&"idle"))
	assert(akky_animated.sprite_frames.get_frame_count(&"idle") == 4)
	assert(akky_controller.has_animation(&"dash"))
	assert(akky_animated.sprite_frames.get_frame_count(&"dash") == 4)
	assert(akky_controller.has_animation(&"jump_kick"))
	assert(akky_animated.sprite_frames.get_frame_count(&"jump_kick") == 4)
	assert(akky_controller.has_animation(&"jump_punch_down"))
	assert(akky_animated.sprite_frames.get_frame_count(&"jump_punch_down") == 4)
	print("DEV052_OK scale=", animated.scale, " position=", animated.position, " offset=", animated.offset)
	quit()
