extends SceneTree

# Copy only the film's authored frames, retaining every frame's transform/head.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var folder := "res://assets/endings/true_cast"
	DirAccess.make_dir_recursive_absolute(folder)
	var manifest := {}
	for id in ["ally_balance", "ally_power", "ally_speed"]:
		var actor = load("res://scenes/Player.tscn").instantiate()
		root.add_child(actor)
		actor.apply_fighter_definition(load("res://data/fighters/%s.tres" % id))
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		var sprite: AnimatedSprite2D = actor.animated_character_sprite
		var source: SpriteFrames = sprite.sprite_frames
		var textures := {}
		var bytes := 0
		for clip in source.get_animation_names():
			for i in range(source.get_frame_count(clip)):
				var texture := source.get_frame_texture(clip, i)
				if texture is AtlasTexture: texture = texture.atlas
				if not textures.has(texture.get_instance_id()):
					textures[texture.get_instance_id()] = true
					bytes += texture.get_width() * texture.get_height() * 4
		print("TRUE_ENDING_SOURCE_RGBA_BYTES ", id, " ", bytes)
		var poses := {}
		for clip in (["damage", "walk_forward"] if id == "ally_speed" else ["idle"]):
			actor.character_visual_controller.play_animation(clip, true)
			sprite.stop()
			var records: Array = []
			var count := source.get_frame_count(clip) if clip == "walk_forward" else 1
			for index in range(count):
				sprite.frame = index
				var head_controller: Node = actor.get_node_or_null("SeiyaProportions")
				if head_controller != null: head_controller.update_head()
				var image := source.get_frame_texture(clip, index).get_image()
				if image.is_compressed(): image.decompress()
				var filename := "%s_%s_%02d.png" % [id, clip, index]
				assert(image.save_png(folder.path_join(filename)) == OK)
				var pose := {"file": filename, "duration": source.get_frame_duration(clip, index), "scale": [sprite.scale.x, sprite.scale.y], "position": [sprite.position.x, sprite.position.y]}
				if sprite.material is ShaderMaterial:
					var material: ShaderMaterial = sprite.material
					var cell: Vector4 = material.get_shader_parameter("cell_rect")
					var head: Vector4 = material.get_shader_parameter("head_rect")
					var anchor: Vector2 = material.get_shader_parameter("head_anchor")
					var neck: Vector2 = material.get_shader_parameter("neck_direction")
					pose["head"] = {"rect": [head.x-cell.x, head.y-cell.y, head.z, head.w], "anchor": [anchor.x-cell.x, anchor.y-cell.y], "neck": [neck.x, neck.y], "scale": material.get_shader_parameter("head_scale")}
				records.append(pose)
			poses[clip] = {"frames": records, "fps": source.get_animation_speed(clip), "loop": source.get_animation_loop(clip)}
		manifest[id] = poses
		actor.queue_free()
		await process_frame
	var file := FileAccess.open(folder.path_join("poses.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	print("TRUE_ENDING_CAST_EXPORTED")
	quit()
