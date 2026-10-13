extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func run() -> void:
	var difficulty = root.get_node("DifficultyMode")
	DirAccess.remove_absolute("user://story_progress.cfg")
	difficulty.reload_progress()
	difficulty.select_mode("hard")
	check(not difficulty.is_hard(), "Hard locked on fresh save")
	var title = load("res://scenes/Title.tscn").instantiate()
	root.add_child(title)
	await process_frame
	check(title.difficulty_button.disabled, "Fresh title locks Hard")
	if not DisplayServer.get_name() == "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../difficulty_title_locked.png")
	title.queue_free()
	var battle = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var enemy = battle.get_node("Enemy")
	var profile = load("res://data/enemy_ai/enemy_01_standard_ai.tres")
	enemy.apply_ai_profile(profile)
	check(is_equal_approx(enemy.dev026_ai_combo_continue_probability, profile.second_hit_probability), "Normal historical combo probability")
	for file in DirAccess.get_files_at("res://data/enemy_ai"):
		if not file.ends_with(".tres"): continue
		var candidate = load("res://data/enemy_ai/" + file)
		enemy.apply_ai_profile(candidate)
		var expected: float = candidate.combo_rate if candidate.can_combo else candidate.second_hit_probability
		check(is_equal_approx(enemy.dev026_ai_combo_continue_probability, expected), "Normal profile " + file)
	var manager = battle.get_node("BattleManager")
	manager.enter_game_clear()
	check(difficulty.hard_unlocked, "Campaign clear unlocks Hard")
	difficulty.reload_progress()
	check(difficulty.hard_unlocked, "Unlock survives reload")
	difficulty.select_mode("hard")
	enemy.apply_ai_profile(profile)
	check(is_equal_approx(enemy.dev026_ai_combo_continue_probability, minf(0.85, profile.second_hit_probability + 0.15)), "Hard preserves current combo probability")
	for file in DirAccess.get_files_at("res://data/enemy_ai"):
		if not file.ends_with(".tres"): continue
		var candidate = load("res://data/enemy_ai/" + file)
		enemy.apply_ai_profile(candidate)
		var expected: float = minf(0.85, candidate.combo_rate + 0.20) if candidate.can_combo else minf(0.85, candidate.second_hit_probability + 0.15)
		check(is_equal_approx(enemy.dev026_ai_combo_continue_probability, expected), "Hard profile " + file)
	difficulty.persist_run_mode()
	difficulty.mode = "normal"
	difficulty.restore_run_mode()
	check(difficulty.is_hard(), "Hard survives checkpoint mode restore")
	manager._flow_sequence_id += 1
	await create_timer(2.6).timeout
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	title = load("res://scenes/Title.tscn").instantiate()
	root.add_child(title)
	await process_frame
	check(not title.difficulty_button.disabled, "Unlocked title permits selection")
	title._toggle_difficulty()
	check(not difficulty.is_hard(), "Title selects Normal")
	title._toggle_difficulty()
	check(difficulty.is_hard(), "Title selects Hard")
	if not DisplayServer.get_name() == "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../difficulty_title_hard.png")
	title.queue_free()
	await process_frame
	print("DIFFICULTY_MODE_CHECK failures=", JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
