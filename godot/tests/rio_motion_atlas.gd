extends SceneTree

var failures: Array[String] = []

const EXPECTED_CHUNK_SHA256 := [
	"425767b388f4a56d3676f56eeff6eb2bf5ff31a949c74cb2da837c71392ab71c",
	"b926422d9708c209a26ed4ee87e4e723fe745eed464c9edf54a7b6d2330cf99d",
	"8afc32eda818b79f7e981546eacee83a9dd3d9931cf9d3ae6444ed86f36fedbf",
	"c923aa1557525c177d5cd4157aa644a4dfe147564f1b4cbf4afb632660e8b580",
	"3cc89748a07ceb76f3868f421f1ce661a55ac8e83deb5db6a4f1d5f8e160d237",
	"d7c9999c9e7c8b04ff5408aa521ce22249976606281a76fc539466efaa8f97db",
	"0daf37526be3e641d48ab64551fe41e58b734aaa6ca1d935ced3814ff08f2c57",
	"4f10280b13dfeb4297c6c9f0bd2972c0f033fb16059176483f0ca18adc178ac0",
]

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func sha256_text(value: String) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(value.to_utf8_buffer())
	return context.finish().hex_encode()

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
	check(is_equal_approx(fighter.sprite_body_height_px, 121.0), "Rio standing reference body height fixed")
	check(is_equal_approx(fighter.battle_sprite_height, 174.78516), "Rio battle height matches the standard fighter scale")
	check(is_equal_approx(fighter.visual_scale_adjustment, 1.05), "Rio uses one shared visual scale adjustment")

	var combined := ""
	for index in range(8):
		var chunk: Resource = fighter.motion_atlas.get("embedded_texture_chunk_%d" % index)
		check(chunk != null, "embedded chunk %d exists" % index)
		if chunk != null:
			var data := String(chunk.get("data"))
			var digest := sha256_text(data)
			print("RIO_CHUNK_%02d length=%d sha256=%s" % [index, data.length(), digest])
			check(digest == EXPECTED_CHUNK_SHA256[index], "embedded chunk %d matches source PNG" % index)
			combined += data
	print("RIO_EMBEDDED_BASE64 length=%d sha256=%s" % [combined.length(), sha256_text(combined)])

	var controller = load("res://scripts/characters/character_visual_controller.gd").new()
	var sprite := AnimatedSprite2D.new()
	var fallback := Sprite2D.new()
	root.add_child(controller)
	root.add_child(sprite)
	root.add_child(fallback)
	check(controller.setup(fighter, sprite, fallback), "Rio embedded motion atlas decodes")
	if sprite.sprite_frames == null:
		print("RIO_MOTION_ATLAS_RESULT clips=0 frames=0 failures=%d" % failures.size())
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
		for frame_index in range(frames.get_frame_count(clip)):
			var texture := frames.get_frame_texture(clip, frame_index)
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
