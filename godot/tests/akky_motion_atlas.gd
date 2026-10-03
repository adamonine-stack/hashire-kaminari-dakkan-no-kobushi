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
			var expected: Texture2D = fighter.supplemental_motion_atlas.texture if String(clip).begins_with("cross_react_") else fighter.motion_atlas.texture
			for extra in fighter.extra_motion_atlases:
				if extra.clips.has(String(clip)):
					expected = extra.texture
			if String(clip).begins_with("grapple_"):
				expected = load("res://assets/characters/player01/animations/readable_grapple_v1/motion_atlas.tres").texture
			if String(clip).begins_with("cross_muei_"):
				expected = load("res://assets/characters/player01/animations/cross_muei_received_v1/motion_atlas.tres").texture
			if String(clip).begins_with("received_shadow_counter_"):
				expected = load("res://assets/characters/player01/animations/shadow_counter_received_v1/motion_atlas.tres").texture
			if String(clip).begins_with("received_seiya_two_"):
				expected = load("res://assets/characters/player01/animations/seiya_two_received_v1/motion_atlas.tres").texture
			if String(clip).begins_with("received_rei_uppercut_"):
				var rei_atlas = load("res://assets/characters/special_received_rei_v1/ally_balance/motion_atlas.tres")
				check(texture is AtlasTexture and texture.atlas == rei_atlas.texture,clip + ": dedicated Rei receiver original")
				check(texture.get_size() == Vector2(512,448),clip + ": Rei receiver canvas")
				var rei_rect := texture.get_image().get_used_rect()
				check(rei_rect.has_area() and rei_rect.position.x >= 3 and rei_rect.position.y >= 3 and rei_rect.end.x <= 509 and rei_rect.end.y <= 445,clip + ": unclipped Rei receiver")
				checked += 1
				continue
			if String(clip).begins_with("received_teki_palm_"):
				var teki_atlas = load("res://assets/characters/special_received_teki_v1/ally_balance/motion_atlas.tres")
				check(texture is AtlasTexture and texture.atlas == teki_atlas.texture,clip + ": dedicated Teki receiver original")
				check(texture.get_size() == Vector2(512,448),clip + ": Teki receiver canvas")
				var teki_rect := texture.get_image().get_used_rect()
				check(teki_rect.has_area() and teki_rect.position.x >= 3 and teki_rect.position.y >= 3 and teki_rect.end.x <= 509 and teki_rect.end.y <= 445,clip + ": unclipped Teki receiver")
				checked += 1
				continue
			if String(clip).begins_with("received_cross_muei_guard"):
				var cross_atlas = load("res://assets/characters/cross_special_guard_v1/ally_balance/motion_atlas.tres")
				check(texture is AtlasTexture and texture.atlas == cross_atlas.texture,clip + ": dedicated Cross receiver original")
				check(texture.get_size() == Vector2(512,448),clip + ": Cross receiver canvas")
				var cross_rect := texture.get_image().get_used_rect()
				check(cross_rect.has_area() and cross_rect.position.x >= 3 and cross_rect.position.y >= 3 and cross_rect.end.x <= 509 and cross_rect.end.y <= 445,clip + ": unclipped Cross receiver")
				checked += 1
				continue
			check(texture is AtlasTexture and texture.atlas == expected, clip + ": approved authored texture")
			var crusher_reaction := String(clip).begins_with("received_crusher_hammer_")
			check(texture.get_size() == (Vector2(512,384) if crusher_reaction else Vector2(320,224)), clip + ": common cell")
			var rect := texture.get_image().get_used_rect()
			check(rect.has_area() and rect.position.x >= 3 and rect.position.y >= 3 and rect.end.x <= (509 if crusher_reaction else 317) and rect.end.y <= (288 if crusher_reaction else 221), clip + ": unclipped body")
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
