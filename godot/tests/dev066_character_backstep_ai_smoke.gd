extends SceneTree

var failures: Array[String] = []

const ALLY_PATHS := [
	"res://data/fighters/ally_balance.tres",
	"res://data/fighters/ally_power.tres",
	"res://data/fighters/ally_speed.tres",
]

const ENEMY_PATHS := [
	"res://data/enemies/enemy_01_standard.tres",
	"res://data/enemies/enemy_02_speed.tres",
	"res://data/enemies/enemy_03_guard.tres",
	"res://data/enemies/enemy_04_throw.tres",
	"res://data/enemies/enemy_05_power.tres",
	"res://data/enemies/enemy_06_combo.tres",
	"res://data/enemies/enemy_07_tricky.tres",
	"res://data/enemies/enemy_08_boss.tres",
]


func check(ok: bool, label: String) -> void:
	if ok:
		return
	failures.append(label)
	push_error(label)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fighter_scene := load("res://scenes/Player.tscn") as PackedScene
	check(fighter_scene != null, "fighter scene loads")
	if fighter_scene == null:
		quit(1)
		return

	var ally_distances: Dictionary = {}
	for path in ALLY_PATHS:
		var definition = load(path)
		check(definition != null, path + ": definition loads")
		if definition == null:
			continue
		var probe = fighter_scene.instantiate()
		probe.name = "Probe"
		get_root().add_child(probe)
		await process_frame
		probe.set_physics_process(false)
		probe.apply_character_data(definition)
		var distance: float = float(probe.move_speed) * float(probe.backstep_speed_multiplier) * float(probe.backstep_duration)
		ally_distances[String(definition.fighter_id)] = distance
		probe.queue_free()
		await process_frame

	check(float(ally_distances.get("player_02_gou", 0.0)) < float(ally_distances.get("player_01_akky", 0.0)), "Gou backstep is shorter than Akky")
	check(float(ally_distances.get("player_01_akky", 0.0)) < float(ally_distances.get("player_03_seiya", 0.0)), "Seiya backstep is longer than Akky")

	var enemy_distances: Dictionary = {}
	for path in ENEMY_PATHS:
		var definition = load(path)
		check(definition != null, path + ": definition loads")
		if definition == null:
			continue
		check(definition.ai_profile != null, String(definition.fighter_id) + ": AI profile exists")
		if definition.ai_profile != null:
			check(bool(definition.ai_profile.can_backstep), String(definition.fighter_id) + ": AI can backstep")
			check(float(definition.ai_profile.backstep_rate) > 0.0, String(definition.fighter_id) + ": proactive backstep rate configured")
			check(float(definition.ai_profile.reactive_backstep_rate) > 0.0, String(definition.fighter_id) + ": reactive backstep rate configured")
			check(float(definition.ai_profile.backstep_cooldown) >= 0.8, String(definition.fighter_id) + ": backstep cooldown configured")

		var probe = fighter_scene.instantiate()
		probe.name = "EnemyProbe"
		get_root().add_child(probe)
		await process_frame
		probe.set_physics_process(false)
		probe.apply_character_data(definition)
		var fighter_id := String(definition.fighter_id)
		enemy_distances[fighter_id] = probe.move_speed * probe.backstep_speed_multiplier * probe.backstep_duration
		var frames: SpriteFrames = probe.animated_character_sprite.sprite_frames
		check(frames != null, fighter_id + ": SpriteFrames load")
		if frames != null:
			check(frames.has_animation("backstep"), fighter_id + ": backstep animation exists")
			if frames.has_animation("backstep"):
				check(frames.get_frame_count("backstep") >= 4, fighter_id + ": backstep has at least four poses")
				check(not frames.get_animation_loop("backstep"), fighter_id + ": backstep is non-looping")
		probe.queue_free()
		await process_frame

	check(float(enemy_distances.get("enemy_01_crusher", 0.0)) < float(enemy_distances.get("enemy_02_shadow_boxer", 0.0)), "Shadow Boxer backstep is longer than Crusher")
	check(float(enemy_distances.get("enemy_03_masato_takahashi", 0.0)) < float(enemy_distances.get("enemy_06_rio_flick_garcia", 0.0)), "Rio backstep is longer than Masato")

	var battle_scene := load("res://scenes/Battle.tscn") as PackedScene
	check(battle_scene != null, "battle scene loads")
	if battle_scene != null:
		var battle = battle_scene.instantiate()
		battle.get_node("BattleManager").active_enemy_count_limit = 1
		get_root().add_child(battle)
		await process_frame
		var manager = battle.get_node("BattleManager")
		await manager.select_player_by_id(String(manager.player_team[0]["fighter_id"]))
		for i in range(360):
			await physics_frame
			if manager.isRoundActive:
				break

		var enemy = battle.get_node("Enemy")
		var player = battle.get_node("Player")
		check(enemy != null and player != null, "battle fighters exist")
		if enemy != null and player != null:
			enemy.input_enabled = false
			enemy.is_round_active = true
			enemy.current_hp = enemy.max_hp
			enemy.reset_attack_state(false)
			enemy.reset_knockdown_state()
			enemy._clear_guard_state()
			enemy.is_hit = false
			enemy.is_guard_hit = false
			enemy.enable_ai()
			enemy.ai_backstep_cooldown_timer = 0.0
			enemy.ai_profile.reactive_backstep_rate = 1.0
			enemy.ai_profile.can_backstep = true
			var battle_distance: float = absf(float(player.global_position.x) - float(enemy.global_position.x))
			check(enemy.should_backstep_player(battle_distance, true), "battle AI selects reactive backstep when configured")
			var away_direction: float = -signf(float(player.global_position.x) - float(enemy.global_position.x))
			enemy.enter_backstep()
			check(String(enemy._debug_ai_action_text()) == "BACKSTEP", "enemy enters BACKSTEP AI state")
			check(enemy.is_backstepping, "enemy backstep movement starts")
			check(signf(enemy.velocity.x) == away_direction, "enemy launches away from player")
			enemy._update_visual_state()
			check(String(enemy.animated_character_sprite.animation) == "backstep", "enemy displays backstep animation")
			var start_x: float = float(enemy.global_position.x)
			for i in range(3):
				await physics_frame
			check(absf(enemy.global_position.x - start_x) > 1.0, "enemy moves during battle backstep")
			enemy.disable_ai()

		manager.cleanup_battle_before_transition()
		var audio = get_root().get_node_or_null("AudioManager")
		if audio != null:
			audio.stop_bgm()
		battle.queue_free()
		await process_frame

	print("DEV066_CHARACTER_BACKSTEP_AI_OK failures=%s ally=%s enemies=%s" % [failures, ally_distances, enemy_distances])
	quit(0 if failures.is_empty() else 1)
