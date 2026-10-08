extends "res://tests/special_reversal_check.gd"

func reset_pair() -> void:
	super.reset_pair()
	# Controlled cases jump timers; remove only effects from the previous case.
	for node in root.find_children("*", "Node2D", true, false):
		if node.get_script() == load("res://scripts/combat/reversal_effect.gd"):
			node.free()

# Exercise actual receiver damage/guard state, not only the resource setting.
func run() -> void:
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	manager = battle.get_node("BattleManager")
	manager.select_player_by_id("player_02_gou")
	for i in range(360):
		await physics_frame
		if manager.get("_enemy_intro_panel") != null and manager._enemy_intro_panel.visible:
			manager.enemy_intro_finished.emit()
		if manager.isRoundActive: break
	player = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	for actor in [player, enemy]:
		actor.set_physics_process(false)
		actor.ai_enabled = false
		actor.input_enabled = false
	for definition in ["ally_power", "ally_speed"]:
		player.apply_character_data(load("res://data/fighters/" + definition + ".tres"))
		for facing in [1.0, -1.0]:
			for stage in range(2 if definition == "ally_speed" else 1):
				reset_pair()
				player.facing_direction = facing
				enemy.facing_direction = -facing
				player.position = Vector2(580, 520)
				enemy.position = Vector2(580 + 70 * facing, 520)
				player.start_character_special()
				player.enter_character_special_active()
				player.seiya_two_hit_stage = stage
				if stage == 1:
					player.character_special_timer = player.character_special_data.active_time - player.character_special_data.sidekick_time - 0.04
				var packet: Dictionary = player._get_character_special_attack_dictionary()
				enemy.is_guarding = true
				enemy.guard_type = "high"
				var hp: int = enemy.current_hp
				check(not enemy.receive_attack(packet, facing, enemy.global_position, player), definition + " guarded")
				check(enemy.current_hp == hp, definition + " stage " + str(stage) + " zero guard damage")
				check(enemy.is_guard_hit and not enemy.is_hit and enemy.knockdown_state == &"", "guard does not launch/down")
				check(absf(enemy.velocity.x) <= 160.0, "bounded guard push")
				await capture_pair(definition + "_" + str(facing) + "_" + str(stage) + "_guard")
				player.enter_character_special_recovery()
				check(player.character_special_timer >= player.character_special_data.recovery_time, "guard retains punishable recovery")
				print("HERO_SPECIAL_PACKET fighter=%s stage=%d damage=%d guard_damage=%d" % [definition, stage, packet.damage, hp - enemy.current_hp])
				reset_pair()
				player.facing_direction = facing
				enemy.facing_direction = -facing
				enemy.position.x = player.position.x + 70 * facing
				player.start_character_special()
				player.enter_character_special_active()
				player.seiya_two_hit_stage = stage
				if stage == 1:
					player.character_special_timer = player.character_special_data.active_time - player.character_special_data.sidekick_time - 0.04
				packet = player._get_character_special_attack_dictionary()
				enemy.request_punch_attack()
				hp = enemy.current_hp
				check(enemy.receive_attack(packet, facing, enemy.global_position, player), "special interrupts attacking receiver")
				check(enemy.current_hp < hp and enemy.current_attack_type.is_empty(), "damage and attack interruption")
				await capture_pair(definition + "_" + str(facing) + "_" + str(stage) + "_hit")
	# Both heroes also receive Crusher's special: check the newly authored guard/reactions.
	for definition in ["ally_power", "ally_speed"]:
		player.apply_character_data(load("res://data/fighters/" + definition + ".tres"))
		for facing in [1.0, -1.0]:
			reset_pair()
			player.facing_direction = facing
			enemy.facing_direction = -facing
			enemy.position.x = player.position.x + 70 * facing
			var packet: Dictionary = enemy._get_character_special_attack_dictionary()
			player.is_guarding = true
			player.guard_type = "high"
			player.velocity.y = 40.0
			player.move_and_slide()
			var hp: int = player.current_hp
			check(not player.receive_attack(packet, -facing, player.global_position, enemy), "hero blocks Crusher")
			check(player.current_hp == hp, "Crusher special guard zero damage")
			for phase in range(3):
				player.guard_hit_timer = player.special_guard_duration * (1.0 - (phase + 0.1) / 3.0)
				player._update_visual_state()
				check(player.animated_character_sprite.animation == &"special_guard", "dedicated hero special guard")
				check(player.animated_character_sprite.frame == phase, "guard pose synchronized to stun")
			await capture_pair(definition + "_received_" + str(facing) + "_guard")
			reset_pair()
			player.facing_direction = facing
			enemy.facing_direction = -facing
			check(player.receive_attack(packet, -facing, player.global_position, enemy), "hero receives Crusher special")
			player._update_visual_state()
			check(String(player.animated_character_sprite.animation).begins_with("received_crusher_hammer_"), "dedicated hero special hit")
			await capture_pair(definition + "_received_" + str(facing) + "_hit")
	print("STAGE1_HEROES_SPECIAL_GUARD_CHECK failures=%s" % [failures])
	battle.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func capture_pair(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/stage1_heroes_special_pair")
	DirAccess.make_dir_recursive_absolute(folder)
	for actor in [player, enemy]:
		actor._update_visual_state()
		actor.animated_character_sprite.pause()
		if actor.animated_character_sprite.animation == &"seiya_two_sidekick":
			actor.animated_character_sprite.frame = 1 # Fixed contact pose, not real-time timing evidence.
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(folder.path_join(label + ".png"))
