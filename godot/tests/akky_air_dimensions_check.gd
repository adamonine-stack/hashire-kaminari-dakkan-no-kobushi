extends SceneTree

var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)
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
	var frames := sprite.sprite_frames
	check(frames.get_frame_count("akky_air_punch") == 4, "four frames preserved")
	check(frames.get_animation_speed("akky_air_punch") == 12.0, "12 fps preserved")
	check(not frames.get_animation_loop("akky_air_punch"), "nonloop preserved")
	for facing in [1,-1]:
		actor.facing_direction = facing
		actor._set_visual_facing()
		actor._play_visual_animation(&"akky_air_punch",true)
		sprite.pause()
		for index in range(4):
			sprite.frame = index
			var texture := frames.get_frame_texture("akky_air_punch",index)
			check(texture.get_size()==Vector2(320,224), "common canvas")
			check(is_equal_approx(float(texture.get_meta("source_scale")),2.0/7.0), "common source units")
			check(sprite.scale.is_equal_approx(scale) and sprite.position.is_equal_approx(origin), "invariant transform")
			check(sprite.flip_h == (facing<0), "flip")
			var used := texture.get_image().get_used_rect()
			check(used.position.y >= 39 and used.position.y <= 41, "stable head canvas origin")
			check(used.end.y < 208, "tucked airborne boots not grounded")
		actor._play_visual_animation(&"idle",true)
		check(sprite.scale.is_equal_approx(scale) and sprite.position.is_equal_approx(origin), "idle return")
	var attack: Resource = load("res://data/attacks/akky_air_punch.tres")
	check(attack.contact_start_frame == 2 and attack.contact_end_frame == 2, "contact frame contract")
	check(attack.hitbox_size == Vector2(52,48) and attack.hitbox_offset == Vector2(70,-112), "hitbox contract")
	print("AKKY_AIR_DIMENSIONS_CHECK failures=",failures)
	quit(0 if failures.is_empty() else 1)
