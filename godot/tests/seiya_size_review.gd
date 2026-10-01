extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var floor_line := Line2D.new()
	floor_line.points = PackedVector2Array([Vector2(40, 520), Vector2(1240, 520)])
	floor_line.width = 2
	stage.add_child(floor_line)
	var paths := ["fighters/ally_balance", "fighters/ally_power", "fighters/ally_speed", "enemies/enemy_09_seiya"]
	for i in range(paths.size()):
		var fighter = load("res://scenes/Player.tscn").instantiate()
		stage.add_child(fighter)
		fighter.set_physics_process(false)
		fighter.position = Vector2(190 + i * 290, 520)
		fighter.apply_fighter_definition(load("res://data/%s.tres" % paths[i]))
		fighter._play_visual_animation(&"idle", true)
		fighter.animated_character_sprite.pause()
		var proportions = fighter.get_node_or_null("SeiyaProportions")
		if proportions != null: print("HEAD_REVIEW ",proportions.head_bounds)
		var label := Label.new()
		label.text = str(fighter.fighter_definition.display_name)
		label.position = Vector2(-80, 20)
		fighter.add_child(label)
		print("SIZE_REVIEW ", paths[i], " scale=", fighter.animated_character_sprite.scale, " pos=", fighter.animated_character_sprite.position, " hurt=", fighter.hurt_shape.shape.size)
	await process_frame
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../evidence/seiya")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join("size_comparison.png"))
	stage.queue_free()
	await process_frame
	quit()
