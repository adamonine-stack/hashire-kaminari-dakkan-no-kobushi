extends SceneTree

const CASES := [
	{"label":"stage7_masato", "fighter":"res://data/enemies/enemy_03_guard.tres", "stage":"res://data/stages/stage_07_masato.tres", "atlas":"res://assets/characters/enemy03/animations/masato_v1/motion_atlas.tres", "id":&"enemy_03_masato_takahashi", "backdrop":&"island_hideout_entrance", "height":168.0},
	{"label":"stage8_leon", "fighter":"res://data/enemies/enemy_08_boss.tres", "stage":"res://data/stages/stage_08_leon.tres", "atlas":"res://assets/characters/enemy08/animations/leon_v2/motion_atlas.tres", "id":&"enemy_08_leon_crow", "backdrop":&"island_hideout_boss_room", "height":188.0},
]
var failures: Array[String] = []
var clips_checked := 0

func _initialize() -> void:
	call_deferred("run_review")

func run_review() -> void:
	for case in CASES:
		_review(case)
	if failures.is_empty():
		print("STAGE7_8_MOTION_ATLAS_OK fighters=2 clips=%d fixed_scale=true night_backdrops=true" % clips_checked)
		quit()
	else:
		for failure in failures: push_error(failure)
		print("STAGE7_8_MOTION_ATLAS_FAILED failures=%d" % failures.size())
		quit(1)

func _review(case: Dictionary) -> void:
	var fighter: FighterDefinition = load(case.fighter)
	var stage: StageDefinition = load(case.stage)
	var atlas: FighterMotionAtlas = load(case.atlas)
	_check(fighter != null and stage != null and atlas != null, "%s resources load" % case.label)
	if fighter == null or stage == null or atlas == null: return
	_check(stage.stage_number == (7 if case.id == &"enemy_03_masato_takahashi" else 8), "%s campaign slot is correct" % case.label)
	_check(stage.enemy_definition.fighter_id == case.id and fighter.fighter_id == case.id, "%s fighter id is preserved" % case.label)
	_check(stage.backdrop_id == case.backdrop, "%s uses its dedicated night hideout backdrop" % case.label)
	var leon: bool = case.id == &"enemy_08_leon_crow"
	_check(fighter.motion_atlas == atlas and atlas.columns == 6 and atlas.cell_size == (Vector2i(512,448) if leon else Vector2i(320,320)), "%s uses a fixed-cell dedicated atlas" % case.label)
	_check(atlas.texture.get_width() == (3072 if leon else 1920) and atlas.texture.get_height() == (3584 if leon else 1920), "%s complete atlas dimensions" % case.label)
	_check(is_equal_approx(fighter.character_height_cm, case.height), "%s retains its reference character height" % case.label)
	var controller := CharacterVisualController.new()
	var animated := AnimatedSprite2D.new()
	var fallback := Sprite2D.new()
	root.add_child(controller); root.add_child(animated); root.add_child(fallback)
	_check(controller.setup(fighter, animated, fallback), "%s authored artwork initializes" % case.label)
	var fixed_scale := animated.scale
	var frames: SpriteFrames = animated.sprite_frames
	var idle := frames.get_frame_texture(&"idle", 0)
	var idle_height := idle.get_image().get_used_rect().size.y if idle != null else 0
	for key in atlas.clips:
		var clip := StringName(String(key))
		_check(frames.has_animation(clip), "%s clip %s exists" % [case.label, clip])
		if not frames.has_animation(clip): continue
		clips_checked += 1
		controller.play_animation(clip, true)
		_check(animated.scale.is_equal_approx(fixed_scale), "%s clip %s does not resize the fighter" % [case.label, clip])
		for i in range(frames.get_frame_count(clip)):
			var texture: Texture2D = frames.get_frame_texture(clip, i)
			_check(texture is AtlasTexture and Vector2i(texture.region.size) == atlas.cell_size, "%s clip %s frame %d stays in a fixed cell" % [case.label, clip, i])
			if texture != null:
				var used := texture.get_image().get_used_rect()
				_check(used.has_area(), "%s clip %s frame %d has visible art" % [case.label, clip, i])
				if String(clip) in ["idle", "walk", "dash", "punch", "punch_1", "punch_2", "kick", "kick_1", "kick_2", "special"]:
					_check(used.size.y >= int(float(idle_height) * 0.62), "%s attack/movement %s does not unexpectedly shrink" % [case.label, clip])
		_check(animated.scale.is_equal_approx(fixed_scale), "%s scale remains fixed through clip %s" % [case.label, clip])
	for required in [&"idle_prebattle", &"throw", &"special", &"victory", &"ko"]:
		_check(frames.has_animation(required), "%s has %s" % [case.label, required])
	controller.queue_free(); animated.queue_free(); fallback.queue_free()

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
