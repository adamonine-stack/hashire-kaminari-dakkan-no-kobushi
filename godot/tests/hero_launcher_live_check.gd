extends "res://tests/directional_attacks_check.gd"

func run() -> void:
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/hero_design_20261010/launcher_live")
	DirAccess.make_dir_recursive_absolute(folder)
	var rows: Array[Dictionary] = []
	var repeats := 6 if "--review" in OS.get_cmdline_user_args() else 1
	for hero in ["gou", "seiya"]:
		var battle: Node = load("res://scenes/Battle.tscn").instantiate()
		battle.get_node("BattleManager").active_enemy_count_limit = 1
		root.add_child(battle)
		current_scene = battle
		await process_frame
		var manager: Node = battle.get_node("BattleManager")
		manager.select_player_by_id("player_02_gou" if hero == "gou" else "player_03_seiya")
		for tick in range(500):
			await physics_frame
			if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
			if manager.isRoundActive: break
		check(manager.isRoundActive, hero + " round ready")
		player = battle.get_node("Player")
		enemy = battle.get_node("Enemy")
		for actor in [player,enemy]:
			actor.ai_enabled = false
			actor.ai_profile = null
			actor.ai_guard_enabled = false
			actor.input_enabled = actor == player
		await ticks(3)
		for repeat in range(repeats):
			for facing in [1.0,-1.0]:
				reset_pair()
				player.global_position = Vector2(600,520)
				enemy.global_position = Vector2(600+62*facing,520)
				player.velocity = Vector2(0,40)
				enemy.velocity = Vector2(0,40)
				player.move_and_slide()
				enemy.move_and_slide()
				player.facing_direction = facing
				var floor_y: float = enemy.global_position.y
				var hp: int = enemy.current_hp
				var scale: Vector2 = player.animated_character_sprite.scale
				var origin: Vector2 = player.animated_character_sprite.position
				var lowest_y := floor_y
				var saw_contact := false
				var previous := ""
				check(player._request_directional_move(hero+"_down_punch"), hero + " launch starts")
				for tick in range(90):
					await physics_frame
					lowest_y = minf(lowest_y, enemy.global_position.y)
					var sprite: AnimatedSprite2D = player.animated_character_sprite
					check(sprite.scale.is_equal_approx(scale) and sprite.position.is_equal_approx(origin), hero + " fixed transform")
					if sprite.animation == StringName(hero+"_down_punch") and sprite.frame == 2: saw_contact = true
					var key := "%s/%d/%s/%d" % [sprite.animation,sprite.frame,enemy.animated_character_sprite.animation,enemy.animated_character_sprite.frame]
					var file := ""
					if repeat == 0 and key != previous and DisplayServer.get_name() != "headless":
						RenderingServer.force_draw(false)
						file = "%s_%d_%03d.png" % [hero,int(facing),tick]
						root.get_texture().get_image().save_png(folder.path_join(file))
					rows.append({"hero":hero,"repeat":repeat,"facing":facing,"tick":tick,"player_clip":sprite.animation,"player_frame":sprite.frame,"enemy_y":enemy.global_position.y,"enemy_hp":enemy.current_hp,"image":file})
					previous = key
				check(saw_contact, hero + " rising contact pose observed")
				check(enemy.current_hp < hp, hero + " damage connected")
				check(floor_y-lowest_y > 60.0, hero + " real enemy launched upward")
				print("HERO_LAUNCHER_LIVE hero=",hero," facing=",facing," rise=",floor_y-lowest_y," damage=",hp-enemy.current_hp)
		manager.cleanup_battle_before_transition()
		battle.queue_free()
		await process_frame
		await process_frame
	var output := FileAccess.open(folder.path_join("inventory_%s.json" % DisplayServer.get_name()),FileAccess.WRITE)
	output.store_string(JSON.stringify({"frames":rows,"failures":failures},"  "))
	print("HERO_LAUNCHER_LIVE_CHECK failures=",failures)
	quit(0 if failures.is_empty() else 1)
