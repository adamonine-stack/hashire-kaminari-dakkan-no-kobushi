extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fighter_scene := load("res://scenes/Player.tscn") as PackedScene
	assert(fighter_scene != null)

	var arena := Node2D.new()
	arena.name = "ArchetypeBalanceArena"
	get_root().add_child(arena)

	var balance := fighter_scene.instantiate()
	balance.name = "Balance"
	arena.add_child(balance)
	var power := fighter_scene.instantiate()
	power.name = "Power"
	arena.add_child(power)
	var technical := fighter_scene.instantiate()
	technical.name = "Technical"
	arena.add_child(technical)
	var defender := fighter_scene.instantiate()
	defender.name = "Defender"
	arena.add_child(defender)
	await process_frame

	for fighter in [balance, power, technical, defender]:
		fighter.set_physics_process(false)
		fighter.is_round_active = true
		fighter.current_hp = fighter.max_hp

	var balance_definition := load("res://data/fighters/ally_balance.tres")
	var power_definition := load("res://data/fighters/ally_power.tres")
	var technical_definition := load("res://data/fighters/ally_speed.tres")
	assert(balance_definition != null)
	assert(power_definition != null)
	assert(technical_definition != null)

	balance.apply_character_data(balance_definition)
	power.apply_character_data(power_definition)
	technical.apply_character_data(technical_definition)
	defender.apply_character_data(balance_definition)

	# Archetype identity: power has the highest single-hit damage, balance is
	# the baseline, and technical keeps the lowest single-hit damage / longest chain.
	assert(balance._get_combat_archetype() == &"balance")
	assert(power._get_combat_archetype() == &"power")
	assert(technical._get_combat_archetype() == &"technical")
	assert(power.punch_damage == 18)
	assert(power.kick_damage == 25)
	assert(balance.punch_damage == 11)
	assert(balance.kick_damage == 15)
	assert(technical.punch_damage == 9)
	assert(technical.kick_damage == 13)
	assert(power.dev026_max_combo_hits == 2)
	assert(balance.dev026_max_combo_hits == 3)
	assert(technical.dev026_max_combo_hits == 4)

	# Combo damage falls off by archetype. Technical keeps four hits but earns
	# less guaranteed damage from the back half of the string.
	assert(is_equal_approx(power._get_combo_damage_scale_for_hit(1), 1.0))
	assert(is_equal_approx(power._get_combo_damage_scale_for_hit(2), 0.95))
	assert(is_equal_approx(balance._get_combo_damage_scale_for_hit(1), 1.0))
	assert(is_equal_approx(balance._get_combo_damage_scale_for_hit(2), 0.90))
	assert(is_equal_approx(balance._get_combo_damage_scale_for_hit(3), 0.80))
	assert(is_equal_approx(technical._get_combo_damage_scale_for_hit(1), 1.0))
	assert(is_equal_approx(technical._get_combo_damage_scale_for_hit(2), 0.85))
	assert(is_equal_approx(technical._get_combo_damage_scale_for_hit(3), 0.70))
	assert(is_equal_approx(technical._get_combo_damage_scale_for_hit(4), 0.58))
	technical.combo_timer = 1.0
	technical.combo_count = 2
	technical.dev_combo_target = defender
	var scaled_third_hit: Dictionary = technical._build_combo_scaled_attack_data({
		"damage": 10,
		"knockback_x": 0.0,
		"knockback_y": 0.0,
	}, defender)
	assert(int(scaled_third_hit["combo_hit_index"]) == 3)
	assert(int(scaled_third_hit["damage"]) == 7)
	assert(is_equal_approx(float(scaled_third_hit["damage_scale"]), 0.70))
	technical.reset_combo()

	# The actual knockdown-aware receive path gives the defender a gap after
	# technical hit 2 instead of forcing the old ~0.30 second combo stun.
	defender.current_hp = defender.max_hp
	defender.is_round_active = true
	defender.receive_attack({
		"damage": 5,
		"base_damage": 5,
		"attack_type": "punch",
		"attack_height": "high",
		"attacker_archetype": "technical",
		"combo_hit_index": 2,
		"combo_hit_max": 4,
		"allows_combo_followup": true,
		"hitstun_time": 0.18,
		"knockback_x": 0.0,
		"knockback_y": 0.0,
		"hit_stop_frames": 1,
		"hitstop_attacker": 0.0,
		"hitstop_defender": 0.0,
		"effect_size": 0.0,
		"se_type": "weak",
		"screen_shake": 0.0,
	}, 1.0, Vector2.ZERO, null)
	assert(defender.is_hit)
	assert(defender.hit_reaction_timer <= technical.technical_combo_escape_hitstun + 0.001)
	assert(defender.hit_reaction_timer <= 0.061)

	# A successful normal guard favors the defender slightly: defender guard
	# stun is capped at 0.09s while the attacker receives recoil.
	defender.is_hit = false
	defender.hit_reaction_timer = 0.0
	defender.current_hp = defender.max_hp
	defender.is_round_active = true
	power.guard_recoil_timer = 0.0
	defender._receive_guarded_attack({
		"damage": 10,
		"base_damage": 10,
		"attack_type": "kick",
		"attack_height": "middle",
		"attacker_archetype": "power",
		"guard_hit_time": 0.15,
		"guard_knockback": Vector2.ZERO,
		"guard_hitstop_attacker": 0.0,
		"guard_hitstop_defender": 0.0,
	}, 1.0, Vector2.ZERO, power)
	assert(defender.guard_hit_timer <= 0.091)
	assert(power.guard_recoil_timer >= 0.199)
	assert(power.guard_recoil_timer > defender.guard_hit_timer)

	# Recoil is a real action lock, not only a visual pause.
	power.input_enabled = true
	assert(not power._can_accept_attack_input(false))
	power.guard_recoil_timer = 0.0
	assert(power._can_accept_attack_input(false))

	print("DEV064_ARCHETYPE_BALANCE_OK")
	arena.queue_free()
	await process_frame
	quit()
