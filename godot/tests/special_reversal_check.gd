extends SceneTree

var failures: Array[String] = []
var player: Node
var enemy: Node
var manager: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func reset_pair() -> void:
	for actor in [player, enemy]:
		actor.reset_character_special_state(true)
		actor.reset_special_attack_state()
		actor.reset_knockdown_state()
		actor._cancel_current_action()
		actor.is_hit = false
		actor.is_guard_hit = false
		actor.is_invincible = false
		actor.hit_stop_timer = 0.0
		actor.guard_recoil_timer = 0.0
		actor.current_hp = actor.max_hp
		actor.is_round_active = true
		actor.set_special_gauge(actor.max_special_gauge)
		actor._clear_guard_state()
	player.input_enabled = true
	enemy.input_enabled = false
	player.position = Vector2(580, 520)
	enemy.position = Vector2(660, 520)
	player.facing_direction = 1.0
	enemy.facing_direction = -1.0

func run() -> void:
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	manager = battle.get_node("BattleManager")
	await manager.select_player_by_id(String(manager.player_team[0].fighter_id))
	for i in range(360):
		await physics_frame
		if manager.isRoundActive: break
	player = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	enemy.ai_enabled = false
	await physics_frame
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	var definitions := ["fighters/ally_balance", "fighters/ally_power", "fighters/ally_speed",
		"enemies/enemy_01_standard", "enemies/enemy_02_speed", "enemies/enemy_03_guard",
		"enemies/enemy_04_throw", "enemies/enemy_05_power", "enemies/enemy_06_combo",
		"enemies/enemy_07_tricky", "enemies/enemy_08_boss", "enemies/enemy_09_seiya"]
	for definition in definitions:
		player.apply_character_data(load("res://data/%s.tres" % definition))
		check(player.character_special_data != null, definition + " reversal resource")
		if player.character_special_data == null: continue
		var data: Dictionary = player._get_character_special_attack_dictionary()
		check(data.damage == roundi(maxi(player.punch_damage, player.kick_damage) * 1.5), definition + " 1.5 damage")
		check(data.is_guardable and data.can_interrupt_attack, definition + " guard/interrupt contract")
		print("SPECIAL_DAMAGE %s=%d" % [definition, data.damage])
	player.apply_character_data(load("res://data/fighters/ally_balance.tres"))
	enemy.apply_character_data(load("res://data/enemies/enemy_04_throw.tres"))
	reset_pair()
	player.is_hit = true
	player.hit_reaction_timer = 0.25
	check(not player.request_attack_input(&"Punch"), "hitstun blocks punch")
	check(not player.request_attack_input(&"Kick"), "hitstun blocks kick")
	check(not player._can_start_throw(), "hitstun blocks throw")
	check(player.request_character_special(), "hitstun permits special")
	check(not player.is_hit and player.hit_reaction_timer == 0.0, "reversal exits hitstun")
	check(not player.can_receive_attack(), "startup protection")
	player.reversal_elapsed = 0.11
	check(player.can_receive_attack(), "startup protection expires")
	player.enter_character_special_active()
	player.enter_character_special_recovery()
	check(player.character_special_timer > player.character_special_data.recovery_time, "whiff recovery")
	player.finish_character_special()
	player.set_special_gauge(100.0)
	check(not player.request_character_special(), "cooldown prevents immediate reuse")
	reset_pair()
	player.knockdown_state = &"KNOCKDOWN"
	check(not player.request_character_special(), "down blocks special")
	player.knockdown_state = &""
	player.current_hp = 0
	check(not player.request_character_special(), "KO blocks special")
	reset_pair()
	player.is_throw_locked = true
	check(not player.request_character_special(), "throw blocks special")
	player.is_throw_locked = false
	reset_pair()
	player.start_character_special()
	player.enter_character_special_active()
	var packet: Dictionary = player._get_character_special_attack_dictionary()
	enemy.request_punch_attack()
	check(enemy.receive_attack(packet, 1.0, enemy.global_position, player), "special hits attacking enemy")
	check(enemy.current_attack_type.is_empty() and enemy.is_hit, "hit interrupts attack")
	reset_pair()
	enemy.is_guarding = true
	enemy.guard_type = "high"
	var hp: int = enemy.current_hp
	check(not enemy.receive_attack(packet, 1.0, enemy.global_position, player), "special guarded")
	check(enemy.is_guard_hit and not enemy.is_hit, "guard uses guard reaction")
	check(hp - enemy.current_hp == enemy._get_guard_damage_from_attack_data(packet), "authored chip only")
	# Exercise the real Area2D entry callbacks for a simultaneous special trade.
	reset_pair()
	player.start_character_special()
	enemy.start_character_special()
	player.enter_character_special_active()
	enemy.enter_character_special_active()
	player.reversal_elapsed = 0.2
	enemy.reversal_elapsed = 0.2
	var player_hp: int = player.current_hp
	var enemy_hp: int = enemy.current_hp
	player._on_character_special_hitbox_area_entered(enemy.get_node("HurtBox"))
	enemy._on_character_special_hitbox_area_entered(player.get_node("HurtBox"))
	await process_frame
	check(player.current_hp < player_hp and enemy.current_hp < enemy_hp, "same-step special trade")
	reset_pair()
	enemy.ai_enabled = true
	enemy.is_hit = true
	enemy.special_ai_use_chance = 10.0 # Guarantee the situational branch for this test.
	enemy.reversal_ai_checked = false
	enemy.reversal_ai_observation = 0.11
	enemy._try_observed_special_reversal()
	check(not enemy.is_character_special_busy(), "AI waits for visible-hit reaction delay")
	enemy.reversal_ai_observation = 0.13
	enemy._try_observed_special_reversal()
	check(enemy.is_character_special_busy(), "AI breaks observed hitstun without input reading")
	print("SPECIAL_REVERSAL_CHECK failures=%s" % [failures])
	await create_timer(1.5).timeout
	battle.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
