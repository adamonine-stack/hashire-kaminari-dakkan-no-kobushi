extends Node

var failures: Array[String] = []

func _ready() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func run() -> void:
	var difficulty = get_tree().root.get_node("DifficultyMode")
	DirAccess.remove_absolute("user://story_progress.cfg")
	difficulty.reload_progress()
	difficulty.select_mode("hard")
	check(not difficulty.is_hard(), "Hard locked on fresh save")
	var title = load("res://scenes/Title.tscn").instantiate()
	get_tree().root.add_child(title)
	await get_tree().process_frame
	check(title.difficulty_button.disabled, "Fresh title locks Hard")
	title.queue_free()
	var battle = load("res://scenes/Battle.tscn").instantiate()
	get_tree().root.add_child(battle)
	await get_tree().process_frame
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
	await get_tree().create_timer(2.6).timeout
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await get_tree().process_frame
	title = load("res://scenes/Title.tscn").instantiate()
	get_tree().root.add_child(title)
	await get_tree().process_frame
	check(not title.difficulty_button.disabled, "Unlocked title permits selection")
	title._toggle_difficulty()
	check(not difficulty.is_hard(), "Title selects Normal")
	title._toggle_difficulty()
	check(difficulty.is_hard(), "Title selects Hard")
	title.queue_free()
	await get_tree().process_frame
	print("DIFFICULTY_MODE_CHECK failures=", JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func quit(code: int) -> void:
	var difficulty = get_tree().root.get_node("DifficultyMode")
	var cfg := ConfigFile.new()
	cfg.load("user://story_progress.cfg")
	var result := {"code":code, "failures":failures, "mode":difficulty.mode, "hard_unlocked":difficulty.hard_unlocked, "saved_normal_clear":bool(cfg.get_value("difficulty", "normal_cleared", false))}
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.difficultyQAResult=" + JSON.stringify(result), true)
		get_tree().change_scene_to_file("res://scenes/Title.tscn")
	else:
		get_tree().quit(code)
