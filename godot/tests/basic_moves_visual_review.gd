extends "res://tests/basic_moves_combat_check.gd"

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/basic_moves_20261010/rendered")
	DirAccess.make_dir_recursive_absolute(folder)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	battle.get_node("BattleManager").active_enemy_count_limit = 1
	root.add_child(battle)
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager.select_player_by_id("player_01_akky")
	for i in range(500):
		await physics_frame
		if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible:
			manager.enemy_intro_finished.emit()
		if manager.isRoundActive: break
	player = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	var camera: Camera2D = battle.get_node("BattleCamera")
	camera.set_process(false)
	camera.set_physics_process(false)
	camera.position = Vector2(640,360)
	camera.zoom = Vector2.ONE
	var records: Array = []
	for path in Inventory.DEFINITIONS:
		var definition: Resource = load("res://data/"+path+".tres")
		actor = enemy if definition.team_type == &"ENEMY" else player
		opponent = player if actor == enemy else enemy
		actor.apply_fighter_definition(definition)
		settle()
		actor.position = Vector2(540,520)
		opponent.position = Vector2(1050,520)
		actor.facing_direction = 1.0
		actor._set_visual_facing()
		var sprite: AnimatedSprite2D = actor.animated_character_sprite
		for key in CONTROLS:
			var data: Resource = actor._get_attack_data(actor.basic_move_ids[key])
			var record := {"actor":String(definition.fighter_id),"key":key,"title":String(data.display_name),"startup":data.startup_time,"active":data.active_time,"recovery":data.recovery_time,"contact":data.contact_start_frame,"frames":[]}
			actor.start_attack(String(data.attack_id))
			for frame in range(sprite.sprite_frames.get_frame_count(data.animation_name)):
				actor._play_visual_animation(StringName(data.animation_name),true)
				sprite.pause()
				sprite.set_frame_and_progress(frame,0.0)
				await process_frame
				await process_frame
				RenderingServer.force_draw(false)
				var filename := "%s__%s__%02d.png" % [definition.fighter_id,key,frame]
				var image := root.get_texture().get_image()
				image.get_region(Rect2i(300,160,500,420)).save_png(folder.path_join(filename))
				record.frames.append(filename)
			records.append(record)
			actor.reset_attack_state()
	FileAccess.open(folder.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(records,"\t"))
	manager.cleanup_battle_before_transition()
	root.get_node("AudioManager").stop_bgm()
	battle.queue_free()
	await process_frame
	await create_timer(1.0).timeout
	print("BASIC_MOVES_RENDERED_OK clips=",records.size())
	quit()
