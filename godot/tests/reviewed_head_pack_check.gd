extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func run() -> void:
	var table_path := "res://assets/characters/player03/animations/dark_seiya_v1/head_sizes_reviewed.json"
	check(FileAccess.file_exists(table_path), "reviewed head data packaged")
	var table: Variant = JSON.parse_string(FileAccess.get_file_as_string(table_path))
	if not table is Dictionary or table.is_empty():
		print("REVIEWED_HEAD_PACK_CHECK failures=[missing or empty calibration]")
		quit(1)
		return
	var applied: Dictionary = {}
	var protected := 0
	for path in ["fighters/ally_speed", "enemies/enemy_09_seiya"]:
		var actor: Node = load("res://scenes/Player.tscn").instantiate()
		root.add_child(actor)
		actor.set_physics_process(false)
		var definition: Resource = load("res://data/" + path + ".tres")
		actor.apply_fighter_definition(definition)
		var sprite: AnimatedSprite2D = actor.animated_character_sprite
		var baseline_scale := sprite.scale
		var baseline_position := sprite.position
		for clip in sprite.sprite_frames.get_animation_names():
			actor._play_visual_animation(clip, true)
			sprite.pause()
			for frame in range(sprite.sprite_frames.get_frame_count(clip)):
				sprite.set_frame_and_progress(frame, 0.0)
				var texture := sprite.sprite_frames.get_frame_texture(clip, frame)
				var actual: float = sprite.material.get_shader_parameter("head_scale")
				check(sprite.scale == baseline_scale and sprite.position == baseline_position, "full body transform preserved")
				if clip == &"idle":
					check(is_equal_approx(actual, definition.head_scale), "Idle correction unchanged")
					protected += 1
				var authored := float(texture.get_meta("head_scale_override", -1.0))
				if authored >= 0.0:
					check(is_equal_approx(actual, authored), "authored proportions take precedence")
					protected += 1
				elif texture is AtlasTexture:
					var source: String = texture.atlas.resource_path
					var key := "%s/%s:%d:%d" % [source.get_base_dir().get_file(), source.get_file(), texture.region.position.x, texture.region.position.y]
					if table.has(key):
						check(is_equal_approx(actual, float(table[key])), "source correction survives packaging and aliases " + key)
						applied[key] = true
		actor.queue_free()
		await process_frame
	check(applied.size() == table.size(), "all calibrated cells reachable")
	print("REVIEWED_HEAD_PACK_CHECK applied=", applied.size(), " protected=", protected, " failures=", JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
