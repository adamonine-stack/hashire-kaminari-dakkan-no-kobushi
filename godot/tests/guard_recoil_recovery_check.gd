extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame

func run() -> void:
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	battle.get_node("BattleManager").active_enemy_count_limit = 1
	root.add_child(battle)
	current_scene = battle
	var manager: Node = battle.get_node("BattleManager")
	await process_frame
	await manager.select_player_by_id("player_01_akky")
	for i in range(420):
		await physics_frame
		if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible:
			manager.enemy_intro_finished.emit()
		if manager.isRoundActive:
			break
	check(manager.isRoundActive, "round starts")
	var player: Node = battle.get_node("Player")
	var enemy: Node = battle.get_node("Enemy")
	for actor in [player, enemy]:
		actor.ai_enabled = false
		actor.ai_profile = null
		actor.input_enabled = false
		actor.is_round_active = true
	await ticks(5)
	# Exercise the real guard response for each actor and attack type without
	# resetting state during recovery: resetting would conceal latched timers.
	for attacker in [player, enemy]:
		var defender: Node = enemy if attacker == player else player
		for kind in [&"Punch", &"Kick"]:
			check(attacker.request_attack_input(kind, true), "%s starts %s" % [attacker.name, kind])
			var packet: Dictionary = attacker._get_attack_data_dictionary(String(kind))
			defender._receive_guarded_attack(packet, attacker.facing_direction, defender.global_position, attacker)
			check(attacker.current_attack_type == "" and attacker.guard_recoil_timer > 0, "guard interrupts into recoil")
			check(not attacker.request_attack_input(kind, true), "cannot attack during recoil")
			await ticks(60)
			check(attacker.guard_recoil_timer == 0, "recoil expires")
			check(attacker.attack_cooldown_timer == 0 and attacker.kick_cooldown_timer == 0,
				"%s cooldowns expire after guarded %s" % [attacker.name, kind])
			check(attacker.request_attack_input(kind, true), "%s attacks again after guarded %s" % [attacker.name, kind])
			await ticks(90)
	# Both directions must still resolve actual Area2D contacts after guards.
	# Drive the player through the same indexed touch path as mobile play.
	var controls: Node = manager.mobile_controls
	controls.show_touch_controls()
	for attacker in [player, enemy]:
		var defender: Node = enemy if attacker == player else player
		for kind in [&"Punch", &"Kick"]:
			player.global_position = Vector2(500, player.stage_floor_y)
			enemy.global_position = Vector2(610, enemy.stage_floor_y)
			await ticks(5)
			var hp_before: int = defender.current_hp
			if attacker == player:
				player.input_enabled = true
				var button: Button = controls.right_controls.get_node("PunchButton" if kind == &"Punch" else "KickButton")
				var event := InputEventScreenTouch.new()
				event.index = 1
				event.position = button.get_global_rect().get_center()
				event.pressed = true
				controls._input(event)
				await ticks(3)
				check(player.current_attack_type == String(kind), "touch %s accepted after guard" % kind)
				event.pressed = false
				controls._input(event)
			else:
				check(attacker.request_attack_input(kind, true), "%s contact %s starts" % [attacker.name, kind])
			await ticks(180)
			check(defender.current_hp < hp_before, "%s %s hits after guard recovery" % [attacker.name, kind])
	controls.release_all_touch_inputs()
	print("GUARD_RECOIL_RECOVERY_CHECK failures=", failures)
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
