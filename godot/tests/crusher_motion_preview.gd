extends SceneTree

func _initialize() -> void:
	var atlas: FighterMotionAtlas = load("res://assets/characters/enemy01/animations/crusher_v1/motion_atlas.tres")
	assert(atlas != null and atlas.texture != null)
	assert(atlas.texture.get_size() == Vector2(1600, 1960))
	var expected := {"idle": 1, "walk": 4, "punch_2": 4, "dash": 2,
		"jump_start": 2, "jump_land": 2, "kick_1": 3, "guard": 1,
		"crouch": 1, "damage_high": 2, "ko": 2, "stand_up": 4,
		"crouch_punch": 3, "throw": 4}
	for name in atlas.clips:
		var clip: Dictionary = atlas.clips[name]
		assert(clip.frames.size() > 0)
		if expected.has(name):
			assert(clip.frames.size() == expected[name])
		for index in clip.frames:
			var cell := Rect2i(index % atlas.columns * atlas.cell_size.x,
				index / atlas.columns * atlas.cell_size.y, atlas.cell_size.x, atlas.cell_size.y)
			assert(cell.end.x <= atlas.texture.get_width())
			assert(cell.end.y <= atlas.texture.get_height())
	print("CRUSHER_ATLAS_OK clips=%d cells=25" % atlas.clips.size())
	quit()
