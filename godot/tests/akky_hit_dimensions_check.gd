extends SceneTree

var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var actor: Node = load("res://scenes/Player.tscn").instantiate()
	root.add_child(actor)
	actor.set_physics_process(false)
	actor.apply_fighter_definition(load("res://data/fighters/ally_balance.tres"))
	var sprite: AnimatedSprite2D = actor.animated_character_sprite
	var scale := sprite.scale
	var origin := sprite.position
	for clip in [&"damage_light", &"damage_heavy", &"damage_high", &"damage_low"]:
		var frames := sprite.sprite_frames
		check(frames.get_frame_count(clip) == 3, "%s frame count unchanged" % clip)
		check(frames.get_animation_speed(clip) == (12.0 if clip == &"damage_heavy" else 14.0), "%s fps unchanged" % clip)
		check(not frames.get_animation_loop(clip), "%s nonloop unchanged" % clip)
		for facing in [1, -1]:
			actor.facing_direction = facing
			actor._set_visual_facing()
			actor._play_visual_animation(clip, true)
			sprite.pause()
			for index in range(3):
				sprite.frame = index
				var texture := frames.get_frame_texture(clip, index)
				check(texture.get_size() == Vector2(320, 224), "%s common canvas" % clip)
				var expected_scale := 172.0 / 492.0
				if clip == &"damage_high":
					expected_scale = 0.28
				elif clip == &"damage_low":
					expected_scale = 0.28 * 724.0 / 783.0
				check(is_equal_approx(float(texture.get_meta("source_scale")), expected_scale), "%s single source unit conversion" % clip)
				check(sprite.scale.is_equal_approx(scale), "%s invariant sprite scale" % clip)
				check(sprite.position.is_equal_approx(origin), "%s invariant sprite origin" % clip)
				check(sprite.flip_h == (facing < 0), "%s facing" % clip)
				var used := texture.get_image().get_used_rect()
				check(used.end.y >= 207 and used.end.y <= 209, "%s foot edge within one raster pixel of anchor" % clip)
			actor._play_visual_animation(&"idle", true)
			check(sprite.scale.is_equal_approx(scale) and sprite.position.is_equal_approx(origin), "%s returns to idle transform" % clip)
	print("AKKY_HIT_DIMENSIONS_CHECK failures=", failures)
	actor.queue_free()
	quit(0 if failures.is_empty() else 1)
