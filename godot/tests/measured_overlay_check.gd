extends SceneTree

var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)

func _initialize() -> void:
	var controller := CharacterVisualController.new()
	root.add_child(controller)
	var source := Image.create(32, 24, false, Image.FORMAT_RGBA8)
	source.fill(Color.TRANSPARENT)
	source.fill_rect(Rect2i(4, 4, 8, 12), Color.WHITE)
	source.set_pixel(0, 0, Color(1, 1, 1, 0.02))
	var atlas := FighterMotionAtlas.new()
	atlas.texture = ImageTexture.create_from_image(source)
	atlas.cell_size = Vector2i(32, 24)
	atlas.columns = 1
	atlas.frame_regions = [Rect2i(0, 0, 16, 24)]
	atlas.frame_offsets = [Vector2i(3, 5)]
	atlas.frame_source_scales = [0.5]
	atlas.frame_offsets_are_display_pixels = true
	atlas.source_alpha_threshold = 0.04
	atlas.clips = {"probe": {"frames": [0], "fps": 14.0, "loop": false}}
	var frames := SpriteFrames.new()
	frames.add_animation("probe")
	frames.add_frame("probe", atlas.texture)
	controller._overlay_authored_motion_atlas(frames, atlas)
	check(frames.get_frame_count("probe") == 1, "overlay replaces existing clip")
	check(frames.get_animation_speed("probe") == 14.0, "fps preserved")
	check(not frames.get_animation_loop("probe"), "loop preserved")
	var packed := frames.get_frame_texture("probe", 0)
	check(packed.get_size() == Vector2(32, 24), "common display canvas preserved")
	check(packed.get_image().get_pixel(6, 8).a > 0.9, "measured region mapped to explicit display offset")
	check(packed.get_image().get_pixel(3, 5).a < 0.01, "near transparent source noise removed")
	# Existing measured sources keep their original bottom-aligned convention.
	atlas.frame_offsets_are_display_pixels = false
	atlas.frame_offsets = [Vector2i(0, 0)]
	var legacy := controller._build_authored_motion_atlas(atlas)
	check(legacy.get_frame_texture("probe", 0).get_image().get_pixel(7, 16).a > 0.9, "legacy packing convention preserved")
	print("MEASURED_OVERLAY_CHECK failures=", failures)
	quit(0 if failures.is_empty() else 1)
