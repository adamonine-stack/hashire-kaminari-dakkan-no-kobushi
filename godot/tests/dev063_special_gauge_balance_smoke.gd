extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fighter_scene := load("res://scenes/Player.tscn") as PackedScene
	assert(fighter_scene != null)

	var arena := Node2D.new()
	arena.name = "SpecialGaugeArena"
	get_root().add_child(arena)

	var player := fighter_scene.instantiate()
	player.name = "Player"
	arena.add_child(player)

	var enemy := fighter_scene.instantiate()
	enemy.name = "Enemy"
	arena.add_child(enemy)
	await process_frame

	player.set_physics_process(false)
	enemy.set_physics_process(false)

	var player_definition := load("res://data/fighters/ally_balance.tres")
	var enemy_definition := load("res://data/enemies/enemy_04_throw.tres")
	assert(player_definition != null)
	assert(enemy_definition != null)
	player.apply_character_data(player_definition)
	enemy.apply_character_data(enemy_definition)
	enemy.input_enabled = false

	for fighter in [player, enemy]:
		fighter.is_round_active = true
		fighter.current_hp = fighter.max_hp
		fighter.set_special_gauge(0.0)

		# Passive generation is shared by player and enemy.
		fighter.update_special_gauge_generation(10.0)
		assert(is_equal_approx(fighter.get_special_gauge(), 4.0))

		# Event-driven generation uses the same values for both sides.
		fighter.gain_special_gauge_for_attack_hit({
			"attack_type": "punch",
			"combo_hit_index": 1,
		})
		assert(is_equal_approx(fighter.get_special_gauge(), 12.0))

		fighter.gain_special_gauge_for_guarded_attack({
			"attack_type": "punch",
		})
		assert(is_equal_approx(fighter.get_special_gauge(), 15.0))

		fighter.gain_special_gauge_from_damage(5, {
			"attack_type": "punch",
		})
		assert(is_equal_approx(fighter.get_special_gauge(), 21.0))

		fighter._on_successful_guard({"attack_type": "punch"}, null)
		assert(is_equal_approx(fighter.get_special_gauge(), 29.0))

		# A representative normal fight should make the first special realistic.
		fighter.set_special_gauge(0.0)
		fighter.update_special_gauge_generation(50.0)
		for i in range(5):
			fighter.gain_special_gauge_for_attack_hit({
				"attack_type": "punch",
				"combo_hit_index": 1,
			})
		for i in range(4):
			fighter.gain_special_gauge_from_damage(5, {
				"attack_type": "punch",
			})
		for i in range(2):
			fighter._on_successful_guard({"attack_type": "punch"}, null)
		assert(fighter.get_special_gauge() >= fighter.special_gauge_cost)

		# Simulate spending the full gauge. An action-heavy remainder of the same
		# 99-second round can still build a second use without passive charge alone
		# being enough to cause repeated specials.
		fighter.set_special_gauge(fighter.get_special_gauge() - fighter.special_gauge_cost)
		fighter.update_special_gauge_generation(49.0)
		for i in range(4):
			fighter.gain_special_gauge_for_attack_hit({
				"attack_type": "punch",
				"combo_hit_index": 1,
			})
		fighter.gain_special_gauge_for_attack_hit({
			"attack_type": "kick",
			"combo_hit_index": 1,
		})
		fighter.gain_special_gauge_for_attack_hit({
			"attack_type": "kick",
			"combo_hit_index": fighter.dev026_max_combo_hits,
		})
		for i in range(5):
			fighter.gain_special_gauge_from_damage(12, {
				"attack_type": "kick",
			})
		for i in range(2):
			fighter._on_successful_guard({"attack_type": "kick"}, null)
		assert(fighter.get_special_gauge() >= fighter.special_gauge_cost)

	print("DEV063_SPECIAL_GAUGE_BALANCE_OK")
	arena.queue_free()
	await process_frame
	quit()
