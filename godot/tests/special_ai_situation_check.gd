extends "res://tests/special_reversal_check.gd"

func run() -> void:
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	manager = battle.get_node("BattleManager")
	manager._hide_player_selection()
	manager._set_battle_active(true)
	paused = false
	player = battle.get_node("Player")
	player.apply_character_data(load("res://data/fighters/ally_balance.tres"))
	enemy = battle.get_node("Enemy")
	for i in range(5): await physics_frame
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	var definitions := ["enemy_01_standard","enemy_02_speed","enemy_03_guard","enemy_04_throw",
		"enemy_05_power","enemy_06_combo","enemy_07_tricky","enemy_08_boss","enemy_09_seiya"]
	for definition in definitions:
		enemy.apply_character_data(load("res://data/enemies/%s.tres" % definition))
		reset_pair()
		enemy.position.x = 630
		enemy.ai_enabled = true
		var order: int = enemy.fighter_definition.enemy_order
		var factor := 0.30 if order <= 3 else (0.65 if order <= 7 else 1.0)
		check(is_equal_approx(enemy._special_ai_chance(), enemy.special_ai_use_chance * factor), definition + " counter/reversal same type rate")
		# Do not change shared cached resources while testing optional tags.
		enemy.character_special_data = enemy.character_special_data.duplicate(true)
		enemy.character_special_data.ai_special_tags.assign(["reversal"])
		player.request_punch_attack()
		enemy._update_reversal_threat_observation(0.20)
		check(not enemy.should_use_character_special(), definition + " reversal-only disallows counter")
		enemy.character_special_data.ai_special_tags.assign(["counter"])
		enemy.special_ai_use_chance = 10.0
		enemy.is_hit = true
		enemy.reversal_ai_observation = 0.20
		enemy._try_observed_special_reversal()
		check(not enemy.is_character_special_busy(), definition + " counter-only disallows hitstun break")
		enemy.is_hit = false
		enemy._update_reversal_threat_observation(0.0)
		check(enemy.should_use_character_special(), definition + " observed attack permits counter")
		check(not enemy.should_use_character_special(), definition + " at most one counter trial")
		player._cancel_current_action()
		enemy._update_reversal_threat_observation(0.02)
		check(enemy.reversal_visible_threat_time == 0.0 and not enemy.reversal_counter_checked, definition + " quiet state resets observation")
		Input.action_press("attack")
		enemy._update_reversal_threat_observation(0.30)
		check(enemy.reversal_visible_threat_time == 0.0 and not enemy.should_use_character_special(), definition + " raw input creates no threat")
		Input.action_release("attack")
		player.request_punch_attack()
		enemy._update_reversal_threat_observation(0.11)
		check(not enemy.should_use_character_special(), definition + " no instantaneous counter")
		enemy._update_reversal_threat_observation(0.02)
		check(enemy.should_use_character_special(), definition + " counter after visible reaction delay")
		player._cancel_current_action()
		enemy._update_reversal_threat_observation(0.0)
		enemy.special_ai_use_chance = 0.0
		player.request_punch_attack()
		enemy._update_reversal_threat_observation(0.20)
		check(not enemy.should_use_character_special() and enemy.reversal_counter_checked, definition + " failed roll consumes this threat's trial")
		enemy.special_ai_use_chance = 10.0
		check(not enemy.should_use_character_special(), definition + " cannot reroll same threat")
		player._cancel_current_action()
		enemy._update_reversal_threat_observation(0.0)
		player.start_character_special()
		enemy._update_reversal_threat_observation(0.11)
		check(not enemy.should_use_character_special(), definition + " visible special still has observation delay")
		enemy._update_reversal_threat_observation(0.02)
		check(enemy.should_use_character_special(), definition + " special rendered state is a threat")
		enemy.apply_character_special_stats()
		check(enemy.reversal_visible_threat_time == 0.0 and not enemy.reversal_counter_checked, definition + " fighter change clears stale observation")
	print("SPECIAL_AI_SITUATION_CHECK characters=9 failures=%s" % [failures])
	for audio in root.find_children("*", "AudioStreamPlayer", true, false): audio.stop()
	for audio in root.find_children("*", "AudioStreamPlayer2D", true, false): audio.stop()
	OS.delay_msec(200)
	battle.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures.is_empty() else 1)
