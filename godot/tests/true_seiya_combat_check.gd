extends SceneTree

var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run_check")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)
func ticks(count: int) -> void:
	for n in range(count): await physics_frame
func run_check() -> void:
	change_scene_to_file("res://scenes/TrueBattle.tscn")
	await create_timer(1.4).timeout
	var manager = current_scene.get_node("BattleManager")
	var player = manager.player
	var enemy = manager.enemy
	# Movement and hitbox contact through the actual fighter physics.
	enemy.ai_enabled = false
	enemy.ai_profile = null
	enemy.input_enabled = false
	enemy.aura_controller.cancel()
	manager.reset_active_fighter_state(player,Vector2(320,520),1.0,player.max_hp)
	manager._set_battle_active(true)
	enemy.ai_enabled = false
	enemy.ai_profile = null
	await ticks(4)
	var initial_x: float = player.position.x
	Input.action_press("move_right")
	await ticks(12)
	Input.action_release("move_right")
	check(player.position.x > initial_x + 10, "player movement")
	manager.reset_active_fighter_state(player, Vector2(580,520), 1.0, player.max_hp)
	manager.reset_active_fighter_state(enemy, Vector2(680,520), -1.0, enemy.max_hp)
	manager._set_battle_active(true)
	enemy.input_enabled = true
	await ticks(4)
	var enemy_hp: int = enemy.current_hp
	player.request_attack_input(&"Punch")
	await ticks(70)
	check(enemy.current_hp < enemy_hp, "player punch hits Seiya")
	manager.reset_active_fighter_state(player, Vector2(580,520), 1.0, player.max_hp)
	manager.reset_active_fighter_state(enemy, Vector2(680,520), -1.0, enemy.current_hp)
	manager._set_battle_active(true)
	enemy.input_enabled = true
	await ticks(4)
	var player_hp: int = player.current_hp
	enemy.request_attack_input(&"Punch", true)
	await ticks(70)
	check(player.current_hp < player_hp, "Seiya punch hits player")
	check(enemy.character_visual_controller.has_animation(&"damage"), "Seiya damage animation")
	check(enemy.character_visual_controller.has_animation(&"ko"), "Seiya KO animation")
	# Resume and reload must retain the true stage and boss HP.
	manager._set_battle_active(false)
	manager.save_run_progress()
	var saved_boss_hp: int = enemy.current_hp
	change_scene_to_file("res://scenes/Title.tscn")
	for n in range(4): await process_frame
	current_scene.continue_game()
	await create_timer(1.5).timeout
	check(current_scene.scene_file_path == "res://scenes/TrueBattle.tscn", "continue enters TRUE scene")
	manager = current_scene.get_node("BattleManager")
	check(manager.current_enemy_index == 8, "continue stage 9")
	check(manager.enemy_team[8]["current_health"] == saved_boss_hp, "continued Seiya HP")
	manager.select_player_by_id("player_01_akky")
	await create_timer(1.3).timeout
	player = manager.player
	enemy = manager.enemy
	check(enemy.current_hp == saved_boss_hp, "continued Seiya HP survives actor spawn")
	enemy.ai_enabled = false
	enemy.ai_profile = null
	# KO must be reached by contact, not by marking campaign flags.
	manager.reset_active_fighter_state(player, Vector2(580,520), 1.0, player.max_hp)
	manager.reset_active_fighter_state(enemy, Vector2(680,520), -1.0, 1)
	manager._set_battle_active(true)
	enemy.input_enabled = true
	await ticks(4)
	player.request_attack_input(&"Punch")
	await create_timer(4.5).timeout
	var deadline := Time.get_ticks_msec() + 8000
	while (current_scene == null or current_scene.scene_file_path != "res://scenes/TrueEnding.tscn") and Time.get_ticks_msec() < deadline:
		await process_frame
	check(current_scene.scene_file_path == "res://scenes/TrueEnding.tscn", "real hit -> boss KO -> true ending")
	if current_scene.scene_file_path == "res://scenes/TrueEnding.tscn":
		check(not current_scene.akky.input_enabled and not current_scene.seiya.is_round_active, "ending stops battle")
	print("TRUE_SEIYA_COMBAT_CHECK failures=%s" % JSON.stringify(failures))
	current_scene.queue_free()
	for n in range(3): await process_frame
	quit(0 if failures.is_empty() else 1)
