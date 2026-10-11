extends "res://tests/basic_moves_combat_check.gd"

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/normal_chains_20261011/rendered")
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
	for n in [0,1,2,3,6,9,7,4,8,5,10,11]:
		var definition: Resource = load("res://data/"+Inventory.DEFINITIONS[n]+".tres")
		actor = enemy if definition.team_type == &"ENEMY" else player
		opponent = player if actor == enemy else enemy
		actor.apply_fighter_definition(definition)
		settle()
		actor.position = Vector2(540,520)
		opponent.position = Vector2(1050,520)
		actor.facing_direction = 1.0
		actor._set_visual_facing()
		var sprite: AnimatedSprite2D = actor.animated_character_sprite
		for clip in sprite.sprite_frames.get_animation_names():
			if clip != &"idle" and clip != &"basic_down_launcher" and not String(clip).begins_with("normal_"):
				continue
			actor.reset_attack_state()
			actor.is_crouching = (String(clip)=="normal_punch_3" and n in [0,2,6,9,7,10,11]) or (String(clip)=="normal_punch_4" and n==8)
			for frame in range(sprite.sprite_frames.get_frame_count(clip)):
				actor._play_visual_animation(clip,true)
				sprite.pause()
				sprite.set_frame_and_progress(frame,0.0)
				await process_frame
				await process_frame
				RenderingServer.force_draw(false)
				var filename := "%s__%s__%02d.png" % [definition.fighter_id,clip,frame]
				root.get_texture().get_image().get_region(Rect2i(300,160,500,420)).save_png(folder.path_join(filename))
	manager.cleanup_battle_before_transition()
	print("NORMAL_CHAINS_RENDERED_OK")
	quit()
