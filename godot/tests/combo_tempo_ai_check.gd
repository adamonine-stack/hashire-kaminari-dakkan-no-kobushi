extends "res://tests/directional_attacks_check.gd"

func run() -> void:
	seed(43)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	player = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	player.apply_fighter_definition(load("res://data/fighters/ally_balance.tres"))
	enemy.apply_fighter_definition(load("res://data/enemies/enemy_01_standard.tres"))
	for fighter in [player, enemy]:
		fighter.set_physics_process(false)
		fighter.ai_enabled = false
		fighter.is_round_active = true
		fighter.global_position.y = 520
		fighter.velocity = Vector2(0, 10)
		fighter.move_and_slide()
	player.global_position.x = 600
	enemy.global_position.x = 660
	player.facing_direction = 1.0
	enemy.facing_direction = -1.0
	var jab: Resource = player._get_attack_data(player.basic_move_ids.neutral_punch)
	player.start_attack(String(jab.attack_id))
	check(player.attack_startup_time_actual > jab.startup_time * 1.5, "readable normal windup")
	var packet: Dictionary = player._get_punch_attack_data()
	packet["normal_chain"] = true
	packet["combo_hit_index"] = 2
	packet["attack_height"] = "middle"
	enemy.is_guarding = true
	enemy.guard_type = "high"
	enemy.is_hit = true
	enemy.input_enabled = true
	Input.action_press("guard")
	check(enemy._try_guard_technical_combo_escape(packet, 1.0, enemy.global_position, player), "held guard interrupts second normal hit")
	Input.action_release("guard")
	enemy.input_enabled = false
	enemy.ai_enabled = true
	var ai_blocks := 0
	for attempt in range(20):
		enemy.is_hit = true
		enemy.is_guard_hit = false
		if enemy._try_guard_technical_combo_escape(packet, 1.0, enemy.global_position, player):
			ai_blocks += 1
	check(ai_blocks >= 8 and ai_blocks < 20, "AI often blocks chains without perfect defense")
	player.current_attack_data = jab.duplicate()
	player.current_attack_data.attack_height = "high"
	check(enemy._choose_ai_guard_type_against_player() == "low", "duck high attack")
	player.current_attack_data.attack_height = "overhead"
	check(enemy._choose_ai_guard_type_against_player() == "high", "stand against overhead")
	var overhead: Resource = enemy._get_attack_data(enemy.basic_move_ids.back_punch)
	check(enemy._select_basic_situation_move("overhead", 60.0) == String(overhead.attack_id), "select overhead against crouch")
	check(enemy._select_basic_situation_move("chain", 1000.0).is_empty(), "avoid out of reach chain")
	print("COMBO_TEMPO_AI_CHECK failures=", JSON.stringify(failures))
	battle.get_node("BattleManager").cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
