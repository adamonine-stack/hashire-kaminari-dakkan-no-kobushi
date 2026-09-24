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
	for clip in frames.get_animation_names():
		controller.play_animation(StringName(clip), true)
		check(sprite.scale.is_equal_approx(scale_before), clip + ": uniform scale")
		check(sprite.position.is_equal_approx(position_before), clip + ": fixed origin")
		check(frames.get_frame_count(clip) > 0, clip + ": not empty")
		for index in range(frames.get_frame_count(clip)):
			var texture := frames.get_frame_texture(clip, index)
			check(texture is AtlasTexture and texture.atlas == fighter.motion_atlas.texture, clip + ": no legacy texture")
			check(texture.get_size() == Vector2(320, 224), clip + ": common cell")
			var rect := texture.get_image().get_used_rect()
			check(rect.has_area() and rect.position.x >= 3 and rect.position.y >= 3 and rect.end.x <= 317 and rect.end.y <= 221, clip + ": unclipped body")
			checked += 1
	for required in ["idle_ready", "idle_prebattle", "dash", "jump_start", "jump_fall", "jump_land", "throw", "special_thunder_drive", "stand_up", "ko"]:
		check(frames.has_animation(required), required + ": explicit clip")
	check(is_equal_approx(fighter.visual_scale_adjustment, 1.05), "approved 105 percent display size preserved")
	check(not frames.get_animation_loop("ko"), "KO never loops to standing")
	check(frames.get_frame_texture("ko", 3).region == frames.get_frame_texture("down", 0).region, "KO holds prone pose")
	check(frames.get_frame_count("jump_land") == 2, "landing phases not stripped twice")
	check(frames.get_frame_count("walk_forward") == 8, "full eight-key walk cycle")
	print("AKKY_MOTION_ATLAS_RESULT clips=%d frames=%d failures=%d" % [frames.get_animation_names().size(), checked, failures.size()])
	controller.queue_free()
	sprite.queue_free()
	fallback.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
