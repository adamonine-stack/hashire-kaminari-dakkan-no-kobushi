extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var battle = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var manager = battle.get_node("BattleManager")
	for entry in manager.player_team:
		manager.select_order_character(String(entry.fighter_id))
	manager.confirm_player_order()
	for i in range(300):
		await physics_frame
		if manager.isRoundActive:
			break
	var player = battle.get_node("Player")
	var enemy = battle.get_node("Enemy")
	enemy.ai_enabled = false
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	for fighter in [player, enemy]:
		var sprite = fighter.get_node("VisualRoot/AnimatedCharacterSprite")
		print("AUDIT fighter=", fighter.name, " scale=", sprite.scale, " offset=", sprite.position,
			" hurt=", fighter.hurt_box.position, " size=", fighter.hurt_shape.shape.size)
		print("AUDIT animations=", sprite.sprite_frames.get_animation_names())
	player.start_attack("player1_punch_1")
	print("AUDIT punch=", player.punch_area.position, " size=", player.punch_shape.shape.size)
	var output = ProjectSettings.globalize_path("res://../audit_evidence")
	DirAccess.make_dir_recursive_absolute(output)
	var frames = player.get_node("VisualRoot/AnimatedCharacterSprite").sprite_frames
	for clip in ["idle", "walk_forward", "jump_start", "jump_land", "punch_1", "kick_1"]:
		for i in range(frames.get_frame_count(clip)):
			frames.get_frame_texture(clip, i).get_image().save_png(output.path_join("%s_%02d.png" % [clip, i]))
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	await create_timer(1.0).timeout
	quit()
