extends SceneTree

var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fighter = load("res://data/fighters/ally_balance.tres")
	if fighter == null:
		push_error("Fighter resource failed to load")
		quit(1)
		return
	var controller = load("res://scripts/characters/character_visual_controller.gd").new()
	var sprite := AnimatedSprite2D.new()
	var fallback := Sprite2D.new()
	root.add_child(controller)
	root.add_child(sprite)
	root.add_child(fallback)
	check(controller.setup(fighter, sprite, fallback), "new motion atlas loads")
	if sprite.sprite_frames == null:
		quit(1)
		return
	var scale_before := sprite.scale
	var position_before := sprite.position
	var frames := sprite.sprite_frames
	var checked := 0
	# Match production merge order, including lazy path-based atlases.
	var sources:Array=[fighter.motion_atlas,fighter.supplemental_motion_atlas]
	sources.append_array(fighter.extra_motion_atlases)
	for path in fighter.extra_motion_atlas_paths:
		sources.append(load(path))
	var approved:Dictionary={}
	for atlas in sources:
		if atlas==null: continue
		for clip in atlas.clips:
			approved[String(clip)]=atlas
	var bounds_cache:Dictionary={}
	for clip in frames.get_animation_names():
		controller.play_animation(StringName(clip), true)
		check(sprite.scale.is_equal_approx(scale_before), clip + ": uniform scale")
		check(sprite.position.is_equal_approx(position_before), clip + ": fixed origin")
		check(frames.get_frame_count(clip)>0,clip+": not empty")
		var expected=approved.get(String(clip),fighter.motion_atlas)
		for index in range(frames.get_frame_count(clip)):
			var texture=frames.get_frame_texture(clip,index)
			check(texture is AtlasTexture,clip+": atlas texture")
			if not texture is AtlasTexture: continue
			check(texture.atlas.resource_path==expected.texture.resource_path,clip+": approved authored texture")
			check(texture.get_size()==Vector2(expected.cell_size),clip+": authored cell dimensions")
			check(Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region),clip+": atlas region bounds")
			var key=texture.atlas.resource_path+str(texture.region)
			if not bounds_cache.has(key): bounds_cache[key]=texture.get_image().get_used_rect()
			var rect:Rect2i=bounds_cache[key]
			check(rect.has_area(),clip+": nonblank body")
			check(rect.position.x>0 and rect.position.y>0 and rect.end.x<texture.get_width() and rect.end.y<texture.get_height(),clip+": unclipped body")
			checked+=1
	for required in ["idle_ready", "idle_prebattle", "dash", "jump_start", "jump_fall", "jump_land", "throw", "special_thunder_drive", "stand_up", "ko"]:
		check(frames.has_animation(required), required + ": explicit clip")
	check(is_equal_approx(fighter.visual_scale_adjustment, 1.05), "approved 105 percent display size preserved")
	check(not frames.get_animation_loop("ko"), "KO never loops to standing")
	check(frames.get_frame_texture("ko", frames.get_frame_count("ko")-1).region == frames.get_frame_texture("down", 0).region, "KO holds prone pose")
	check(frames.get_frame_count("jump_land") == 2, "landing phases not stripped twice")
	check(frames.get_frame_count("walk_forward") == 8, "full eight-key walk cycle")
	print("AKKY_MOTION_ATLAS_RESULT clips=%d frames=%d failures=%d" % [frames.get_animation_names().size(), checked, failures.size()])
	controller.queue_free()
	sprite.queue_free()
	fallback.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
