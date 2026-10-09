extends "res://tests/wall_bounce_check.gd"

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
	check(manager.isRoundActive,"round ready")
	actors = [battle.get_node("Player"), battle.get_node("Enemy")]
	for actor in actors:
		actor.ai_enabled = false
		actor.ai_profile = null
		actor.ai_guard_enabled = false
		actor.input_enabled = false
	var victim: Node = actors[0]
	var attacker: Node = actors[1]
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/body_dimensions/ground_bounce_review/physics_capture")
	DirAccess.make_dir_recursive_absolute(folder)
	var rows: Array[Dictionary] = []
	for facing in [1.0,-1.0]:
		reset_pair()
		attacker.global_position = Vector2(600,520)
		victim.global_position = Vector2(600+56*facing,520)
		attacker.velocity.y = 40
		victim.velocity.y = 40
		attacker.move_and_slide()
		victim.move_and_slide()
		attacker.facing_direction = facing
		victim.facing_direction = -facing
		var scale: Vector2 = victim.animated_character_sprite.scale
		var anchor: Vector2 = victim.animated_character_sprite.position
		var hp: int = victim.current_hp
		var move: Resource = load("res://data/attacks/crusher_down_throw.tres")
		var expected_damage := roundi(attacker.throw_damage*move.damage_multiplier)
		check(attacker._request_directional_move("crusher_down_throw",true),"crusher down throw starts")
		attacker.set_physics_process(true)
		victim.set_physics_process(true)
		var seen: Array[String] = []
		var max_contacts := 0
		var lowest_y := 520.0
		var previous := ""
		for tick in range(260):
			await physics_frame
			max_contacts = maxi(max_contacts,victim.ground_bounce_contacts)
			if victim.ground_bounce_phase != "":
				lowest_y = minf(lowest_y,victim.global_position.y)
				check(not victim.can_receive_attack() and not victim.can_be_thrown(attacker),"bounce excludes repeat hit/throw")
			var sprite: AnimatedSprite2D = victim.animated_character_sprite
			check(sprite.scale.is_equal_approx(scale) and sprite.position.is_equal_approx(anchor),"fixed runtime transform")
			var clip := String(sprite.animation)
			if clip not in seen: seen.append(clip)
			var key := "%s/%s/%s" % [clip,sprite.frame,victim.ground_bounce_phase]
			var record := {"facing":facing,"tick":tick,"clip":clip,"frame":sprite.frame,"phase":victim.ground_bounce_phase,"position":str(victim.position),"hp":victim.current_hp,"image":""}
			if DisplayServer.get_name() != "headless" and key != previous:
				RenderingServer.force_draw(true)
				record.image = "%d_%03d.png" % [int(facing),tick]
				root.get_texture().get_image().save_png(folder.path_join(record.image))
			previous = key
			rows.append(record)
		check("ground_impact" in seen and "ground_bounce" in seen and "stand_up" in seen,"impact rebound wake seen")
		check(max_contacts == 1 and lowest_y>=490,"one bounded low bounce")
		check(hp-victim.current_hp == expected_damage,"single authored throw damage")
		check(victim.knockdown_state == &"" and victim.hurt_box.monitorable and victim.is_on_floor(),"ground control restored")
		print("AKKY_GROUND_ROUTE facing=",facing," contacts=",max_contacts," min_y=",lowest_y," damage=",hp-victim.current_hp," expected=",expected_damage," seen=",seen)
	var output := FileAccess.open(folder.path_join("inventory.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify({"frames":rows,"failures":failures,"renderer":DisplayServer.get_name(),"manual_play":false},"  "))
	print("AKKY_GROUND_BOUNCE_PHYSICS_CHECK failures=",failures)
	manager.cleanup_battle_before_transition()
	quit(0 if failures.is_empty() else 1)
