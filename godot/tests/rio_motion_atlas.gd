extends SceneTree

var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fighter = load("res://data/enemies/enemy_06_combo.tres")
	if fighter == null:
		push_error("Rio fighter resource failed to load")
		quit(1)
		return

	check(String(fighter.fighter_id) == "enemy_06_rio_flick_garcia", "stage 6 uses Rio fighter")
	check(fighter.motion_atlas != null, "Rio authored motion atlas assigned")
	check(String(fighter.sprite_sheet_format) == "authored_atlas", "legacy per-pose fitting disabled")
	check(is_equal_approx(fighter.character_height_cm, 178.0), "Rio official height is 178cm")
	check(is_equal_approx(fighter.sprite_body_height_px, 128.0), "Rio reference body height fixed")
	check(is_equal_approx(fighter.visual_scale_adjustment, 1.0), "Rio has no per-pose scale adjustment")

	var controller = load("res://scripts/characters/character_visual_controller.gd").new()
	var sprite := AnimatedSprite2D.new()
	var fallback := Sprite2D.new()
	root.add_child(controller)
	root.add_child(sprite)
	root.add_child(fallback)
	check(controller.setup(fighter, sprite, fallback), "Rio embedded motion atlas decodes")
	if sprite.sprite_frames == null:
		quit(1)
		return

	check(controller.get_debug_source() == "motion_atlas", "Rio uses authoritative atlas path")
	var scale_before := sprite.scale
	var position_before := sprite.position
	var frames := sprite.sprite_frames
	var checked := 0
	for clip in frames.get_animation_names():
		controller.play_animation(StringName(clip), true)
		check(sprite.scale.is_equal_approx(scale_before), clip + ": scale never changes")
		check(sprite.position.is_equal_approx(position_before), clip + ": common origin never changes")
		check(frames.get_frame_count(clip) > 0, clip + ": not empty")
		for index in range(frames.get_frame_count(clip)):
			var texture := frames.get_frame_texture(clip, index)
			check(texture is AtlasTexture, clip + ": authored atlas texture")
			check(texture.get_size() == Vector2(256, 192), clip + ": fixed 256x192 cell")
			checked += 1

	for required in [
		"idle", "walk", "dash", "backstep", "jump_start", "jump_air", "jump_fall", "jump_land",
		"guard", "crouch", "punch_1", "punch_2", "kick_1", "kick_2", "jump_punch_down",
		"crouch_kick_sweep", "damage_light", "damage_heavy", "knockdown", "down", "stand_up",
		"throw_start", "throw_hold", "throw_release", "special_startup", "special_attack", "special_recovery", "ko"
	]:
		check(frames.has_animation(required), required + ": explicit Rio clip")

	check(not frames.get_animation_loop("ko"), "KO never loops")
	check(frames.get_frame_texture("idle", 0).get_size() == frames.get_frame_texture("punch_1", 1).get_size(), "idle and attack share exact cell size")
	check(frames.get_frame_texture("idle", 0).get_size() == frames.get_frame_texture("jump_air", 0).get_size(), "idle and air pose share exact cell size")
	print("RIO_MOTION_ATLAS_RESULT clips=%d frames=%d scale=%s position=%s failures=%d" % [frames.get_animation_names().size(), checked, str(scale_before), str(position_before), failures.size()])

	controller.queue_free()
	sprite.queue_free()
	fallback.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
