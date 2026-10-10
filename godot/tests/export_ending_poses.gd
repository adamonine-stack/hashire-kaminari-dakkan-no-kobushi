extends SceneTree

# Extract existing authored poses verbatim. Endings do not need combat atlases.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var folder := "res://assets/endings/cast"
	DirAccess.make_dir_recursive_absolute(folder)
	var manifest := {}
	for id in ["ally_balance", "ally_power", "ally_speed"]:
		var actor = load("res://scenes/Player.tscn").instantiate()
		root.add_child(actor)
		actor.apply_fighter_definition(load("res://data/fighters/%s.tres" % id))
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		var textures := {}
		var bytes := 0
		var frames: SpriteFrames = actor.animated_character_sprite.sprite_frames
		for animation in frames.get_animation_names():
			for index in range(frames.get_frame_count(animation)):
				var texture := frames.get_frame_texture(animation, index)
				if texture is AtlasTexture: texture = texture.atlas
				if not textures.has(texture.get_instance_id()):
					textures[texture.get_instance_id()] = true
					bytes += texture.get_width() * texture.get_height() * 4
		print("ENDING_COMBAT_TEXTURE_RGBA_BYTES %s %d" % [id, bytes])
		var poses := {}
		for clip in ["idle_prebattle", "guard"]:
			actor.character_visual_controller.play_animation(clip, true)
			var sprite: AnimatedSprite2D = actor.animated_character_sprite
			var image := sprite.sprite_frames.get_frame_texture(clip, 0).get_image()
			if image.is_compressed(): image.decompress()
			assert(image.save_png(folder.path_join("%s_%s.png" % [id, clip])) == OK)
			poses[clip] = {"scale": [sprite.scale.x, sprite.scale.y], "position": [sprite.position.x, sprite.position.y], "height": image.get_used_rect().size.y * absf(sprite.scale.y)}
			if sprite.material is ShaderMaterial:
				var material: ShaderMaterial = sprite.material
				var cell: Vector4 = material.get_shader_parameter("cell_rect")
				var head: Vector4 = material.get_shader_parameter("head_rect")
				var anchor: Vector2 = material.get_shader_parameter("head_anchor")
				var neck: Vector2 = material.get_shader_parameter("neck_direction")
				poses[clip]["head"] = {"rect": [head.x - cell.x, head.y - cell.y, head.z, head.w], "anchor": [anchor.x - cell.x, anchor.y - cell.y], "neck": [neck.x, neck.y], "scale": material.get_shader_parameter("head_scale")}
		manifest[id] = poses
		actor.queue_free()
		await process_frame
	var file := FileAccess.open(folder.path_join("poses.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	print("ENDING_POSES_EXPORTED ", manifest)
	quit()
