extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var actor: Node = load("res://scenes/Player.tscn").instantiate()
	root.add_child(actor)
	await process_frame
	actor.set_physics_process(false)
	actor.apply_character_data(load("res://data/enemies/enemy_05_power.tres"))
	var base := ProjectSettings.globalize_path("res://../evidence/cross_stage4_audit")
	DirAccess.make_dir_recursive_absolute(base)
	var frames: SpriteFrames = actor.animated_character_sprite.sprite_frames
	var records: Array = []
	for clip in frames.get_animation_names():
		for index in range(frames.get_frame_count(clip)):
			var texture := frames.get_frame_texture(clip,index)
			var filename := "%s_%02d.png" % [clip,index]
			texture.get_image().save_png(base.path_join(filename))
			records.append({"clip":clip,"index":index,"file":filename,"texture":texture.resource_path,"size":texture.get_size(),"scale":actor.animated_character_sprite.scale})
	var file := FileAccess.open(base.path_join("frames.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"  "))
	print("CROSS_STAGE4_AUDIT_EXPORT frames=",records.size())
	actor.queue_free()
	await process_frame
	quit()
