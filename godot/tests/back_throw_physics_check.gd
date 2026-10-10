extends "res://tests/directional_throws_check.gd"

func run() -> void:
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	battle.get_node("BattleManager").active_enemy_count_limit = 1
	root.add_child(battle)
	current_scene = battle
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager.select_player_by_id("player_01_akky")
	for tick in range(360):
		await physics_frame
		if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible:
			manager.enemy_intro_finished.emit()
		if manager.isRoundActive: break
	player = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	enemy.ai_enabled = false
	enemy.ai_profile = null
	enemy.ai_guard_enabled = false
	enemy.throw_escape_probability = 0.0
	for tick in range(3): await physics_frame
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/body_dimensions/back_throw_review/physics_capture")
	DirAccess.make_dir_recursive_absolute(folder)
	var rows: Array[Dictionary] = []
	var baseline: Vector2 = player.animated_character_sprite.scale
	var mobile: Node = battle.find_child("MobileControls",true,false)
	for facing in [1.0,-1.0]:
		player.set_physics_process(false)
		enemy.set_physics_process(false)
		reset_pair(facing)
		player.move_and_slide()
		enemy.move_and_slide()
		var initial_hp: int = enemy.current_hp
		var move: Resource = load("res://data/attacks/akky_back_throw.tres")
		var expected_damage := roundi(player.throw_damage * move.damage_multiplier)
		var button_name := "MoveLeftButton" if facing>0 else "MoveRightButton"
		var button: Button = mobile.left_controls.get_node(button_name)
		mobile._on_direction_button_down(button,mobile.DIRECTION_BUTTONS[button_name])
		player._sample_combat_commands(0.12)
		# Directional throw is valid while the back D-pad is HELD.
		# Releasing it before the throw must now produce a neutral throw.
		mobile._on_tap_button_down(mobile.right_controls.get_node("ThrowButton"),"throw_attack")
		player._sample_combat_commands(0.0)
		player._dispatch_combat_command()
		check(player.directional_throw_data == move, "held back command selected %s"%facing)
		mobile._on_direction_button_up(button,mobile.DIRECTION_BUTTONS[button_name])
		check(not Input.is_action_pressed("move_left" if facing > 0 else "move_right"), "back D-pad releases immediately %s"%facing)
		player.set_physics_process(true)
		enemy.set_physics_process(true)
		var held := false
		var swapped := false
		var observed: Array[String] = []
		var previous := ""
		for tick in range(120):
			await physics_frame
			if tick == 0: Input.action_release("throw_attack")
			var sprite: AnimatedSprite2D = player.animated_character_sprite
			var key := "%s/%d/%s" % [sprite.animation,sprite.frame,player.throw_state]
			if player.throw_state == "THROW_HOLD": held = true
			if player.throw_state == "THROW_RECOVERY" and (player.position.x-enemy.position.x)*facing > 50: swapped = true
			if String(sprite.animation) not in observed: observed.append(String(sprite.animation))
			check(sprite.scale.is_equal_approx(baseline), "runtime scale %s/%s"%[facing,tick])
			var record := {"facing":facing,"tick":tick,"animation":sprite.animation,"frame":sprite.frame,"actor_facing":player.facing_direction,"player_position":str(player.position),"enemy_position":str(enemy.position),"throw_state":player.throw_state,"enemy_hp":enemy.current_hp,"image":""}
			if DisplayServer.get_name() != "headless" and key != previous:
				RenderingServer.force_draw(true)
				record.image = "%d_%03d.png" % [int(facing),tick]
				root.get_texture().get_image().save_png(folder.path_join(record.image))
				previous = key
			rows.append(record)
		mobile.release_all_touch_inputs()
		check(held and swapped, "hold and back position swap %s"%facing)
		check(initial_hp-enemy.current_hp == expected_damage, "one release damage %s"%facing)
		check("akky_throw_back_start" in observed and "akky_throw_back_release" in observed, "authored routing %s"%facing)
		check(not player.is_throwing and player.is_on_floor(), "recovery returns ground control %s"%facing)
		print("BACK_THROW_LIVE facing=",facing," held=",held," swapped=",swapped," damage=",initial_hp-enemy.current_hp," expected=",expected_damage," clips=",observed)
	var output := FileAccess.open(folder.path_join("inventory.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify({"frames":rows,"failures":failures,"renderer":DisplayServer.get_name(),"manual_play":false},"  "))
	print("BACK_THROW_PHYSICS_CHECK failures=",failures)
	manager.cleanup_battle_before_transition()
	quit(0 if failures.is_empty() else 1)
