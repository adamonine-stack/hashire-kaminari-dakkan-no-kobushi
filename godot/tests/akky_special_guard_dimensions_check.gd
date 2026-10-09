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
	for clip in [&"special_guard"]:
		var frames := sprite.sprite_frames
		check(frames.get_frame_count(clip) == 3, "frame count")
		check(frames.get_animation_speed(clip) == 12.0 and not frames.get_animation_loop(clip), "timing")
		for facing in [1,-1]:
			actor.facing_direction = facing
			actor._set_visual_facing()
			actor._play_visual_animation(clip,true)
			sprite.pause()
			for index in range(frames.get_frame_count(clip)):
				sprite.frame = index
				var texture := frames.get_frame_texture(clip,index)
				check(texture.get_size()==Vector2(320,224), "common canvas")
				check(is_equal_approx(float(texture.get_meta("source_scale")),0.28*724.0/725.0), "common source units")
				check(sprite.scale.is_equal_approx(scale) and sprite.position.is_equal_approx(origin), "fixed transform")
				check(sprite.flip_h == (facing<0), "flip")
				var used := texture.get_image().get_used_rect()
				check(used.end.y >= 207 and used.end.y <= 209, "foot anchor")
			actor._play_visual_animation(&"idle",true)
			check(sprite.scale.is_equal_approx(scale) and sprite.position.is_equal_approx(origin), "idle return")
	print("AKKY_SPECIAL_GUARD_DIMENSIONS_CHECK failures=",failures)
	quit(0 if failures.is_empty() else 1)
