extends SceneTree

var failures: Array[String] = []
var rows: Array[Dictionary] = []
var hashes: Dictionary = {}

func pixel_hash(texture: Texture2D) -> String:
	var key := texture.get_instance_id()
	if not hashes.has(key):
		var context := HashingContext.new()
		context.start(HashingContext.HASH_SHA256)
		context.update(texture.get_image().get_data())
		hashes[key] = context.finish().hex_encode()
	return hashes[key]

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for hero in ["gou", "seiya"]:
		var before: Resource = load("res://tests/fixtures/hero_design/%s_before.tres" % hero)
		var after: Resource = load("res://data/fighters/ally_%s.tres" % ("power" if hero == "gou" else "speed"))
		var old_actor: Node2D = load("res://scenes/Player.tscn").instantiate()
		var actor: Node2D = load("res://scenes/Player.tscn").instantiate()
		root.add_child(old_actor)
		root.add_child(actor)
		old_actor.set_physics_process(false)
		actor.set_physics_process(false)
		old_actor.apply_fighter_definition(before)
		actor.apply_fighter_definition(after)
		for property in before.get_property_list():
			var name := String(property.name)
			if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0 or name in ["motion_display_canvas_size", "extra_motion_atlas_paths", "extra_motion_atlases", "resource_path", "resource_name"]: continue
			var a: Variant = before.get(name)
			var b: Variant = after.get(name)
			check(a.resource_path == b.resource_path if a is Resource and b is Resource else a == b, hero + " unchanged property " + name)
		var old_sprite: AnimatedSprite2D = old_actor.animated_character_sprite
		var sprite: AnimatedSprite2D = actor.animated_character_sprite
		var frames := sprite.sprite_frames
		check(sprite.scale.is_equal_approx(old_sprite.scale), hero + " master scale unchanged")
		check(sprite.position.is_equal_approx(old_sprite.position), hero + " master origin unchanged")
		check(frames.get_animation_names() == old_sprite.sprite_frames.get_animation_names(), hero + " animation names unchanged")
		var changed := 0
		for clip in frames.get_animation_names():
			var old_frames := old_sprite.sprite_frames
			check(frames.get_frame_count(clip) == old_frames.get_frame_count(clip), hero + "/" + clip + " count unchanged")
			check(frames.get_animation_speed(clip) == old_frames.get_animation_speed(clip) and frames.get_animation_loop(clip) == old_frames.get_animation_loop(clip), hero + "/" + clip + " timing unchanged")
			for index in range(frames.get_frame_count(clip)):
				var texture := frames.get_frame_texture(clip,index) as AtlasTexture
				var old := old_frames.get_frame_texture(clip,index) as AtlasTexture
				var label := "%s/%s/%d" % [hero,clip,index]
				check(texture.get_size() == Vector2(768,640), label + " common canvas")
				check(frames.get_frame_duration(clip,index) == old_frames.get_frame_duration(clip,index), label + " duration unchanged")
				var is_launcher: bool = clip == StringName(hero + "_down_punch")
				if is_launcher:
					var rising := frames.get_frame_texture(hero + "_back_punch",index) as AtlasTexture
					check(pixel_hash(texture) == pixel_hash(rising) and texture.region == rising.region, label + " rising uppercut art")
					changed += 1
				else:
					check(pixel_hash(texture) == pixel_hash(old) and texture.region == old.region, label + " source pixels unchanged")
					check((texture.margin.position-texture.get_size()*0.5).is_equal_approx(old.margin.position-old.get_size()*0.5), label + " source world pivot unchanged")
				for facing in [1,-1]:
					actor.facing_direction = facing
					actor._set_visual_facing()
					actor._play_visual_animation(clip,true)
					sprite.pause()
					sprite.frame = index
					check(sprite.scale.is_equal_approx(old_sprite.scale) and sprite.position.is_equal_approx(old_sprite.position), label + " runtime transform fixed")
					check(sprite.flip_h == (facing < 0), label + " facing")
				rows.append({"actor":hero,"clip":clip,"frame":index,"canvas":str(texture.get_size()),"source":texture.atlas.resource_path,"source_region":str(texture.region),"padding":str(texture.margin),"anatomy_status":"unverified"})
		check(changed == 5, hero + " exactly five launcher frames replaced")
		actor.queue_free()
		old_actor.queue_free()
		await process_frame
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/hero_design_20261010")
	DirAccess.make_dir_recursive_absolute(folder)
	var output := FileAccess.open(folder.path_join("canvas_check.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify({"frames":rows,"failures":failures,"baseline":"c04874e"},"  "))
	print("HERO_DISPLAY_CANVAS_CHECK frames=", rows.size(), " failures=",failures)
	quit(0 if failures.is_empty() else 1)
