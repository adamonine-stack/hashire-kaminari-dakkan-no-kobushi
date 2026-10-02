extends SceneTree

var output := ""

func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> void:
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))

func run() -> void:
	output = ProjectSettings.globalize_path("res://").path_join("../evidence/special_review").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager._hide_player_selection()
	manager._set_battle_active(true)
	paused = false
	for i in range(3): await physics_frame
	var player: Node = battle.get_node("Player")
	var enemy: Node = battle.get_node("Enemy")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	var definitions := ["fighters/ally_balance", "fighters/ally_power", "fighters/ally_speed",
		"enemies/enemy_01_standard", "enemies/enemy_02_speed", "enemies/enemy_03_guard",
		"enemies/enemy_04_throw", "enemies/enemy_05_power", "enemies/enemy_06_combo",
		"enemies/enemy_07_tricky", "enemies/enemy_08_boss", "enemies/enemy_09_seiya"]
	for definition in definitions:
		player.apply_character_data(load("res://data/%s.tres" % definition))
		manager.reset_active_fighter_state(player, Vector2(580,520), 1, player.max_hp)
		manager.reset_active_fighter_state(enemy, Vector2(710,520), -1, enemy.max_hp)
		player.input_enabled = true
		player.is_round_active = true
		enemy.is_round_active = true
		player.set_special_gauge(100)
		player.start_character_special()
		player._update_visual_state()
		await capture(definition.get_file() + "_startup")
		player.enter_character_special_active()
		player._update_visual_state()
		await capture(definition.get_file() + "_active")
		player.reversal_elapsed = 0.2
		player._on_character_special_hitbox_area_entered(enemy.get_node("HurtBox"))
		await process_frame
		enemy._update_visual_state()
		await capture(definition.get_file() + "_hit")
		player.enter_character_special_recovery()
		player._update_visual_state()
		await capture(definition.get_file() + "_finish")
		player.finish_character_special()
	print("SPECIAL_VISUAL_CAPTURE_OK characters=12 screenshots=48")
	battle.queue_free()
	await process_frame
	quit()
