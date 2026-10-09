extends "res://tests/wall_bounce_check.gd"

func run() -> void:
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	current_scene = battle
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager.select_player_by_id("player_01_akky")
	for tick in range(360):
		await physics_frame
		if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
		if manager.isRoundActive: break
	check(manager.isRoundActive,"round ready")
	actors = [battle.get_node("Player"),battle.get_node("Enemy")]
	for actor in actors:
		actor.ai_enabled = false
		actor.ai_profile = null
		actor.input_enabled = false
	var victim: Node = actors[0]
	var attacker: Node = actors[1]
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/body_dimensions/wall_review/physics_capture")
	DirAccess.make_dir_recursive_absolute(folder)
	var rows: Array[Dictionary] = []
	for direction in [1.0,-1.0]:
		reset_pair()
		victim.global_position = Vector2(640,520)
		attacker.global_position = Vector2(640-65*direction,520)
		victim.velocity.y = 40
		attacker.velocity.y = 40
		victim.move_and_slide()
		attacker.move_and_slide()
		victim.facing_direction = -direction
		attacker.facing_direction = direction
		var packet: Dictionary = attacker._get_character_special_attack_dictionary().duplicate(true)
		# Same wall fixture as wall_bounce_check: enable the wall option only in this copied packet.
		packet.wall_slam = true
		var hp: int = victim.current_hp
		var scale: Vector2 = victim.animated_character_sprite.scale
		check(victim.receive_attack(packet,direction,victim.global_position,attacker),"special wall launch accepted")
		var damage: int = hp-victim.current_hp
		victim.set_physics_process(true)
		var seen: Array[String] = []
		var contacts := 0
		var previous := ""
		for tick in range(320):
			await physics_frame
			contacts = maxi(contacts,victim.special_wall_contacts)
			var sprite: AnimatedSprite2D = victim.animated_character_sprite
			var clip := String(sprite.animation)
			if clip not in seen: seen.append(clip)
			check(sprite.scale.is_equal_approx(scale),"runtime fixed scale")
			var key := "%s/%s/%s" % [clip,sprite.frame,victim.special_wall_phase]
			var row := {"facing":direction,"tick":tick,"clip":clip,"frame":sprite.frame,"phase":victim.special_wall_phase,"position":str(victim.position),"hp":victim.current_hp,"image":""}
			if DisplayServer.get_name() != "headless" and key != previous:
				RenderingServer.force_draw(true)
				row.image = "%d_%03d.png" % [int(direction),tick]
				root.get_texture().get_image().save_png(folder.path_join(row.image))
			previous = key
			rows.append(row)
		check("wall_hit" in seen and "wall_fall" in seen and "stand_up" in seen,"wall impact fall wake observed")
		check(contacts == 1 and victim.knockdown_state == &"","one wall contact complete route")
		check(damage>0 and hp-victim.current_hp==damage,"damage only once")
		check(victim.hurt_box.monitorable and victim.is_on_floor(),"ground hurtbox restored")
		print("AKKY_WALL_ROUTE direction=",direction," contacts=",contacts," damage=",damage," seen=",seen)
	var output := FileAccess.open(folder.path_join("inventory.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify({"frames":rows,"failures":failures,"renderer":DisplayServer.get_name(),"manual_play":false,"wall_fixture_flag":true},"  "))
	print("AKKY_WALL_PHYSICS_CHECK failures=",failures)
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	await create_timer(1).timeout
	quit(0 if failures.is_empty() else 1)
