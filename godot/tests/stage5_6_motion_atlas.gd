extends SceneTree

const CASES := [
	{
		"label": "stage5_shadow_boxer",
		"fighter_path": "res://data/enemies/enemy_02_speed.tres",
		"stage_path": "res://data/stages/stage_05_shadow.tres",
		"fighter_id": &"enemy_02_shadow_boxer",
		"display_name": "シャドウボクサー",
		"atlas_path": "res://assets/characters/enemy05/animations/shadow_boxer_v1/motion_atlas.tres",
		"cell": Vector2i(153, 159),
	},
	{
		"label": "stage6_rio_garcia",
		"fighter_path": "res://data/enemies/enemy_06_combo.tres",
		"stage_path": "res://data/stages/stage_06_rio.tres",
		"fighter_id": &"enemy_06_rio_flick_garcia",
		"display_name": "リオ・“フリック”・ガルシア",
		"atlas_path": "res://assets/characters/enemy06/animations/rio_garcia_v1/motion_atlas.tres",
		"cell": Vector2i(157, 155),
	},
]

var failures: Array[String] = []
var clip_total := 0
var frame_total := 0

func _initialize() -> void:
	call_deferred("run_review")

func run_review() -> void:
	for case in CASES:
		_review_fighter(case)
	if failures.is_empty():
		print("STAGE5_6_MOTION_ATLAS_OK fighters=2 clips=%d frames=%d constant_sprite_scale=true" % [clip_total, frame_total])
		quit()
	else:
		for failure in failures:
			push_error(failure)
		print("STAGE5_6_MOTION_ATLAS_FAILED failures=%d" % failures.size())
		quit(1)

func _review_fighter(case: Dictionary) -> void:
	var fighter: FighterDefinition = load(case.fighter_path)
	var stage: StageDefinition = load(case.stage_path)
	var atlas: FighterMotionAtlas = load(case.atlas_path)
	_check(fighter != null, "%s fighter resource loads" % case.label)
	_check(stage != null, "%s stage resource loads" % case.label)
	_check(atlas != null, "%s motion atlas resource loads" % case.label)
	if fighter == null or stage == null or atlas == null:
		return
	_check(stage.enemy_definition.fighter_id == case.fighter_id, "%s stage points at the correct fighter" % case.label)
	_check(fighter.fighter_id == case.fighter_id, "%s preserves its saved fighter id" % case.label)
	_check(fighter.display_name == case.display_name, "%s display name matches the design" % case.label)
	_check(fighter.motion_atlas == atlas, "%s fighter uses its dedicated authored atlas" % case.label)
	_check(atlas.columns == 8, "%s atlas uses eight fixed columns" % case.label)
	_check(atlas.cell_size == case.cell, "%s atlas cells have a fixed design size" % case.label)
	_check(atlas.texture.get_width() >= atlas.columns * atlas.cell_size.x, "%s atlas width covers every cell" % case.label)
	_check(atlas.texture.get_height() >= 8 * atlas.cell_size.y, "%s atlas height covers eight motion rows" % case.label)

	var controller := CharacterVisualController.new()
	var animated := AnimatedSprite2D.new()
	var fallback := Sprite2D.new()
	root.add_child(controller)
	root.add_child(animated)
	root.add_child(fallback)
	_check(controller.setup(fighter, animated, fallback), "%s animated art initializes" % case.label)
	var fixed_scale := animated.scale
	var sprite_frames: SpriteFrames = animated.sprite_frames
	var idle_texture: Texture2D = sprite_frames.get_frame_texture("idle", 0)
	var idle_body_height := idle_texture.get_image().get_used_rect().size.y if idle_texture != null else 0
	var scale_sensitive_clips := ["idle", "idle_prebattle", "walk", "walk_forward", "walk_backward", "dash", "punch", "punch_1", "punch_2", "kick", "kick_1", "kick_2", "special"]
	for key in atlas.clips:
		var clip := StringName(String(key))
		_check(sprite_frames.has_animation(clip), "%s clip %s exists" % [case.label, clip])
		if not sprite_frames.has_animation(clip):
			continue
		clip_total += 1
		controller.play_animation(clip, true)
		_check(animated.scale.is_equal_approx(fixed_scale), "%s clip %s keeps the stage scale" % [case.label, clip])
		for index in range(sprite_frames.get_frame_count(clip)):
			var frame: Texture2D = sprite_frames.get_frame_texture(clip, index)
			_check(frame is AtlasTexture, "%s clip %s frame %d uses a fixed atlas cell" % [case.label, clip, index])
			if frame is AtlasTexture:
				_check(frame.atlas == atlas.texture, "%s clip %s frame %d uses the dedicated texture" % [case.label, clip, index])
				_check(Vector2i(frame.region.size) == atlas.cell_size, "%s clip %s frame %d keeps cell dimensions" % [case.label, clip, index])
				_check(frame.region.position.x >= 0.0 and frame.region.position.y >= 0.0, "%s clip %s frame %d starts inside the atlas" % [case.label, clip, index])
				_check(frame.region.end.x <= atlas.texture.get_width() and frame.region.end.y <= atlas.texture.get_height(), "%s clip %s frame %d stays inside the atlas" % [case.label, clip, index])
				var used_rect := frame.get_image().get_used_rect()
				_check(used_rect.has_area(), "%s clip %s frame %d contains character art" % [case.label, clip, index])
				if String(clip) in scale_sensitive_clips:
					_check(used_rect.size.y >= int(float(idle_body_height) * 0.65), "%s clip %s frame %d retains at least 65%% of idle character height" % [case.label, clip, index])
			frame_total += 1
		_check(animated.scale.is_equal_approx(fixed_scale), "%s scale stays unchanged after clip %s" % [case.label, clip])
	_check(sprite_frames.has_animation("idle_prebattle"), "%s has a dedicated entrance pose" % case.label)
	_check(sprite_frames.has_animation("victory"), "%s has a victory pose" % case.label)
	_check(sprite_frames.has_animation("ko"), "%s has a non-looping defeat pose" % case.label)
	if sprite_frames.has_animation("ko"):
		_check(not sprite_frames.get_animation_loop("ko"), "%s defeat pose does not loop" % case.label)
	controller.queue_free()
	animated.queue_free()
	fallback.queue_free()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
