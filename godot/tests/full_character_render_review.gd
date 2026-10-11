extends SceneTree

const Inventory = preload("res://tests/basic_moves_inventory.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	var label := "rendered"
	for arg in args:
		if arg.begins_with("--label="): label = arg.trim_prefix("--label=")
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/full_character_review_20261011/" + label)
	DirAccess.make_dir_recursive_absolute(folder)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 480)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var rows: Array = []
	for path in Inventory.DEFINITIONS:
		if "--seiya-pair" in args and path not in ["fighters/ally_speed", "enemies/enemy_09_seiya"]: continue
		var actor: Node2D = load("res://scenes/Player.tscn").instantiate()
		viewport.add_child(actor)
		actor.set_physics_process(false)
		actor.position = Vector2(320, 430)
		var definition: Resource = load("res://data/" + path + ".tres")
		actor.apply_fighter_definition(definition)
		actor.facing_direction = -1.0 if "--left" in args else 1.0
		actor._set_visual_facing()
		# Freeze only the evidence capture's aura clock so cross-run pixel
		# comparisons distinguish head changes from animated purple effects.
		if "--freeze-aura" in args and is_instance_valid(actor.get("aura_controller")):
			actor.aura_controller.set_process(false)
			actor.aura_controller.clock_time = 0.0
			actor.aura_controller.queue_redraw()
		if "--uncorrected" in args:
			var proportions := actor.get_node_or_null("SeiyaProportions")
			if proportions != null:
				proportions.reviewed_head_sizes.clear()
				proportions.update_head()
		actor.shadow_sprite.visible = false
		var sprite: AnimatedSprite2D = actor.animated_character_sprite
		var unique: Dictionary = {}
		var id := String(definition.fighter_id)
		DirAccess.make_dir_recursive_absolute(folder.path_join(id))
		for clip in sprite.sprite_frames.get_animation_names():
			actor._play_visual_animation(clip, true)
			sprite.pause()
			for frame in range(sprite.sprite_frames.get_frame_count(clip)):
				sprite.set_frame_and_progress(frame, 0.0)
				var tex := sprite.sprite_frames.get_frame_texture(clip, frame)
				var hash_context := HashingContext.new()
				hash_context.start(HashingContext.HASH_SHA256)
				hash_context.update(tex.get_image().get_data())
				var key: String = hash_context.finish().hex_encode() + str(sprite.scale) + str(sprite.position)
				if sprite.material is ShaderMaterial:
					key += str(sprite.material.get_shader_parameter("head_scale")) + str(sprite.material.get_shader_parameter("head_rect"))
				var filename: String = unique.get(key, "")
				if filename.is_empty():
					await process_frame
					await process_frame
					RenderingServer.force_draw(false)
					filename = "%s/%s_%03d.png" % [id, clip, frame]
					viewport.get_texture().get_image().save_png(folder.path_join(filename))
					unique[key] = filename
				rows.append({"actor":id, "clip":clip, "frame":frame, "file":filename, "scale":str(sprite.scale), "position":str(sprite.position), "source":tex.get_meta("source_texture_path", tex.atlas.resource_path if tex is AtlasTexture else tex.resource_path)})
		print("FULL_RENDER actor=", id, " unique=", unique.size())
		actor.queue_free()
		await process_frame
	var output := FileAccess.open(folder.path_join("inventory.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify(rows, "  "))
	print("FULL_CHARACTER_RENDER_OK frames=", rows.size())
	quit()
