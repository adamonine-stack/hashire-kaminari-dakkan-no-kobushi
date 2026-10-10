extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var stage := "after" if "--after" in args else "before"
	if stage == "after" and DisplayServer.get_name() == "headless":
		stage = "after_headless"
	if "--upper-lower" in args:
		stage = "upper_lower_after"
	if "--revision-upper-lower" in args:
		stage = "upper_lower_all_headless" if DisplayServer.get_name() == "headless" else "upper_lower_all_native"
	if "--air-punch" in args:
		stage = "air_punch_after"
	if "--revision-air" in args:
		stage = "air_all_headless" if DisplayServer.get_name() == "headless" else "air_all_native"
	if "--back-throw" in args:
		stage = "back_throw_after"
	if "--revision-back-throw" in args:
		stage = "back_throw_all_headless" if DisplayServer.get_name() == "headless" else "back_throw_all_native"
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/body_dimensions/" + stage)
	if "--special-guard" in args: stage = "special_guard_after"
	if "--revision-special-guard" in args: stage = "special_guard_all_headless" if DisplayServer.get_name() == "headless" else "special_guard_all_native"
	if "--ground-bounce" in args: stage = "ground_bounce_after"
	if "--revision-ground-bounce" in args: stage = "ground_bounce_all_headless" if DisplayServer.get_name() == "headless" else "ground_bounce_all_native"
	if "--wall" in args: stage = "wall_after"
	if "--revision-wall" in args: stage = "wall_all_headless" if DisplayServer.get_name() == "headless" else "wall_all_native"
	for arg in args:
		if arg.begins_with("--label="): stage = arg.trim_prefix("--label=")
	folder = ProjectSettings.globalize_path("res://../audit_evidence/body_dimensions/" + stage)
	DirAccess.make_dir_recursive_absolute(folder)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 480)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var rows: Array[Dictionary] = []
	var paths: Array[String] = ["fighters/ally_balance.tres", "enemies/enemy_01_standard.tres"]
	for directory in ["fighters", "enemies"]:
		for file in DirAccess.get_files_at("res://data/" + directory):
			var path: String = directory + "/" + file
			if file.ends_with(".tres") and not path in paths:
				paths.append(path)
	for path in paths:
		if "--seiya-only" in args and path != "fighters/ally_speed.tres": continue
		if "--heroes" in args and path not in ["fighters/ally_power.tres", "fighters/ally_speed.tres"]:
			continue
		if "--akky-only" in args and path != "fighters/ally_balance.tres":
			continue
		var definition: Resource = load("res://data/" + path)
		if not definition is FighterDefinition:
			continue
		var actor: Node2D = load("res://scenes/Player.tscn").instantiate()
		viewport.add_child(actor)
		actor.set_physics_process(false)
		actor.position = Vector2(320, 430)
		actor.apply_fighter_definition(definition)
		actor.shadow_sprite.visible = false
		var sprite: AnimatedSprite2D = actor.animated_character_sprite
		var baseline := sprite.scale
		var actor_folder := folder.path_join(String(definition.fighter_id))
		DirAccess.make_dir_recursive_absolute(actor_folder)
		for clip in sprite.sprite_frames.get_animation_names():
			var selected_clips: PackedStringArray = []
			for arg in args:
				if arg.begins_with("--clips="): selected_clips = arg.trim_prefix("--clips=").split(",")
			if not selected_clips.is_empty() and String(clip) not in selected_clips: continue
			if "--wall" in args and clip not in [&"idle", &"wall_hit", &"wall_fall"]: continue
			if "--ground-bounce" in args and clip not in [&"idle", &"ground_impact", &"ground_bounce"]: continue
			if "--special-guard" in args and clip not in [&"idle", &"special_guard"]: continue
			if "--back-throw" in args and clip not in [&"idle", &"akky_throw_back_start", &"akky_throw_back_release"]:
				continue
			if "--air-punch" in args and clip not in [&"idle", &"akky_air_punch"]:
				continue
			if "--upper-lower" in args and clip not in [&"idle", &"damage_high", &"damage_low"]:
				continue
			for facing in [1, -1]:
				actor.facing_direction = facing
				actor._set_visual_facing()
				actor._play_visual_animation(clip, true)
				sprite.pause()
				for frame in range(sprite.sprite_frames.get_frame_count(clip)):
					sprite.frame = frame
					var texture := sprite.sprite_frames.get_frame_texture(clip, frame)
					var raw := texture.get_image()
					var file := "%s_%s_%03d" % [clip, "right" if facing > 0 else "left", frame]
					if facing > 0:
						raw.save_png(actor_folder.path_join(file + "_source.png"))
					var render_file := ""
					if DisplayServer.get_name() != "headless":
						await process_frame
						RenderingServer.force_draw(false)
						render_file = file + ".png"
						viewport.get_texture().get_image().save_png(actor_folder.path_join(render_file))
					rows.append({"actor": definition.fighter_id, "clip": clip, "frame": frame, "facing": facing,
						"canvas": str(texture.get_size()), "source_size": str(raw.get_size()), "alpha_bounds": str(raw.get_used_rect()),
						"region": str(texture.region) if texture is AtlasTexture else "", "margin": str(texture.margin) if texture is AtlasTexture else "",
						"source": texture.get_meta("source_texture_path", texture.atlas.resource_path if texture is AtlasTexture else texture.resource_path),
						"measured_source_region": str(texture.get_meta("measured_source_region", "")), "source_unit_scale": texture.get_meta("source_scale", 1.0),
						"scale": str(sprite.scale), "global_scale": str(sprite.global_scale), "position": str(sprite.position), "offset": str(sprite.offset), "fps": sprite.sprite_frames.get_animation_speed(clip),
						"scale_status": "pass" if sprite.scale.is_equal_approx(baseline) else "fail", "flip_status": "pass" if sprite.flip_h == (facing < 0) else "fail",
						"anatomy_status": "unverified", "ground_status": "unverified", "render_file": render_file})
					if definition.fighter_id == &"player_03_seiya" and sprite.material is ShaderMaterial:
						rows[-1]["render_head_scale"] = sprite.material.get_shader_parameter("head_scale")
						rows[-1]["source_head_rect"] = str(sprite.material.get_shader_parameter("head_rect"))
		actor.queue_free()
		await process_frame
		print("BODY_DIMENSIONS actor=", definition.fighter_id, " cumulative_frames=", rows.size())
	var output := FileAccess.open(folder.path_join("inventory.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify(rows, "  "))
	print("BODY_DIMENSIONS frames=", rows.size(), " renderer=", DisplayServer.get_name())
	quit()
