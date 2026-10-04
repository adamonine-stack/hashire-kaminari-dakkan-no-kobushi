extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var actor: Node = load("res://scenes/Player.tscn").instantiate()
	root.add_child(actor)
	await process_frame
	actor.set_physics_process(false)
	var base := ProjectSettings.globalize_path("res://../art_sources/teki_reversal_v1/frames")
	for pair in [["akky","ally_balance"],["gou","ally_power"],["seiya","ally_speed"]]:
		actor.apply_character_data(load("res://data/fighters/%s.tres" % pair[1]))
		var frames: SpriteFrames = actor.animated_character_sprite.sprite_frames
		for source in [["received_shadow_counter_hit","hit"],["received_shadow_counter_air","air"],["received_shadow_counter_down","down"],["received_rei_uppercut_guard","guard"]]:
			for index in range(frames.get_frame_count(source[0])):
				frames.get_frame_texture(source[0],index).get_image().save_png(base.path_join("%s_%s_%d.png" % [pair[0],source[1],index]))
	print("TEKI_RECEIVER_EXPORT_OK")
	actor.queue_free()
	await process_frame
	quit()
