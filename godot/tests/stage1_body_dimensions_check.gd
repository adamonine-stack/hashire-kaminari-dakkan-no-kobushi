extends SceneTree

var failures: Array[String] = []
var rows: Array[Dictionary] = []
var hashes: Dictionary = {}
const REPAIRED := ["damage_light", "damage_heavy", "damage_high", "damage_low", "akky_air_punch", "akky_throw_back_start", "akky_throw_back_release", "special_guard", "ground_impact", "ground_bounce", "wall_hit", "wall_fall"]

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func texture_hash(texture: Texture2D) -> String:
	var key := texture.get_instance_id()
	if not hashes.has(key):
		var context := HashingContext.new()
		context.start(HashingContext.HASH_SHA256)
		context.update(texture.get_image().get_data())
		hashes[key] = context.finish().hex_encode()
	return hashes[key]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var baseline_actor: Node2D = load("res://scenes/Player.tscn").instantiate()
	root.add_child(baseline_actor)
	baseline_actor.set_physics_process(false)
	var before: Resource = load("res://tests/fixtures/body_dimensions/akky_before.tres")
	baseline_actor.apply_fighter_definition(before)
	var baseline_frames: SpriteFrames = baseline_actor.animated_character_sprite.sprite_frames
	var after: Resource = load("res://data/fighters/ally_balance.tres")
	# Every stored non-art property, including attacks and geometry, is unchanged.
	for property in before.get_property_list():
		var name := String(property.name)
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0 or name in ["extra_motion_atlas_paths", "extra_motion_atlases", "basic_move_paths", "original_motion_sequences", "resource_path", "resource_name"]: continue
		var old_value: Variant = before.get(name)
		var new_value: Variant = after.get(name)
		# Lazy art resources can have distinct instances for the same file.
		if old_value is Resource and new_value is Resource:
			check(old_value.resource_path == new_value.resource_path, "unchanged fighter resource " + name)
		else:
			check(old_value == new_value, "unchanged fighter property " + name)
	var changed_frames := 0
	for path in ["fighters/ally_balance", "fighters/ally_power", "fighters/ally_speed", "enemies/enemy_01_standard"]:
		var definition: Resource = load("res://data/%s.tres" % path)
		var actor: Node2D = load("res://scenes/Player.tscn").instantiate()
		root.add_child(actor)
		actor.set_physics_process(false)
		actor.apply_fighter_definition(definition)
		var sprite: AnimatedSprite2D = actor.animated_character_sprite
		var frames: SpriteFrames = sprite.sprite_frames
		var scale := sprite.scale
		var origin := sprite.position
		var offset := sprite.offset
		var global := sprite.global_scale
		var is_akky: bool = definition.fighter_id == &"player_01_akky"
		if is_akky:
			for old_clip in baseline_frames.get_animation_names():
				check(frames.has_animation(old_clip), "legacy animation preserved " + old_clip)
			check(actor.basic_move_ids.size() == 10, "ten original basic controls registered alongside chain followups")
			check(scale.is_equal_approx(baseline_actor.animated_character_sprite.scale), "master display scale unchanged")
			check(origin.is_equal_approx(baseline_actor.animated_character_sprite.position), "master sprite origin unchanged")
		for clip in frames.get_animation_names():
			var count := frames.get_frame_count(clip)
			if is_akky and baseline_frames.has_animation(clip) and not String(clip).begins_with("basic_"):
				check(count == baseline_frames.get_frame_count(clip), "%s frame count unchanged" % clip)
				check(frames.get_animation_speed(clip) == baseline_frames.get_animation_speed(clip), "%s fps unchanged" % clip)
				check(frames.get_animation_loop(clip) == baseline_frames.get_animation_loop(clip), "%s loop unchanged" % clip)
			for facing in [1, -1]:
				actor.facing_direction = facing
				actor._set_visual_facing()
				actor._play_visual_animation(clip, true)
				sprite.pause()
				for index in range(count):
					sprite.frame = index
					var texture: Texture2D = frames.get_frame_texture(clip, index)
					var label := "%s/%s/%d/%d" % [definition.fighter_id,clip,index,facing]
					check(texture != null, label + " texture")
					if texture == null: continue
					check(sprite.scale.is_equal_approx(scale) and sprite.global_scale.is_equal_approx(global), label + " fixed scale")
					check(sprite.position.is_equal_approx(origin) and sprite.offset.is_equal_approx(offset), label + " fixed origin")
					check(sprite.flip_h == (facing < 0), label + " flip")
					if texture is AtlasTexture:
						check(Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region), label + " atlas bounds")
					var image := texture.get_image()
					check(image.get_used_rect().has_area(), label + " visible pixels")
					if is_akky and facing == 1 and baseline_frames.has_animation(clip) and not String(clip).begins_with("basic_"):
						check(frames.get_frame_duration(clip,index) == baseline_frames.get_frame_duration(clip,index), label + " duration unchanged")
						var old: Texture2D = baseline_frames.get_frame_texture(clip,index)
						var changed := texture_hash(texture) != texture_hash(old)
						if changed: changed_frames += 1
						check(not changed or String(clip) in REPAIRED, label + " only targeted art changed")
					rows.append({"actor":definition.fighter_id,"clip":clip,"frame":index,"facing":facing,"canvas":str(texture.get_size()),"scale":str(sprite.scale),"position":str(sprite.position),"fps":frames.get_animation_speed(clip),"loop":frames.get_animation_loop(clip),"anatomy_status":"unverified"})
			actor._play_visual_animation(&"idle",true)
			check(sprite.scale.is_equal_approx(scale) and sprite.position.is_equal_approx(origin), "%s/%s idle return" % [definition.fighter_id,clip])
		actor.queue_free()
		await process_frame
	check(changed_frames == 26, "26 intended Akky frame images replaced")
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/body_dimensions/stage1_release_gate")
	DirAccess.make_dir_recursive_absolute(folder)
	var output := FileAccess.open(folder.path_join("inventory.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify({"frames":rows,"failures":failures,"baseline":"7d0c79c","changed_akky_frames":changed_frames,"anatomy_status":"unverified"},"  "))
	print("STAGE1_BODY_DIMENSIONS_CHECK frames=",rows.size()," changed=",changed_frames," failures=",failures)
	baseline_actor.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
