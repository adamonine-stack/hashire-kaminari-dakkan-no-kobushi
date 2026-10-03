extends SceneTree

const Attack := preload("res://scripts/data/player_attack_data.gd")
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	battle.get_node("BattleManager").active_enemy_count_limit = 1
	root.add_child(battle)
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	await manager.select_player_by_id("player_01_akky")
	for i in range(360):
		await physics_frame
		if manager.isRoundActive:
			break
	check(manager.isRoundActive, "stage startup")
	var player: Node = battle.get_node("Player")
	var enemy: Node = battle.get_node("Enemy")
	enemy.ai_enabled = false
	enemy.ai_profile = null
	for i in range(3):
		await physics_frame
	var move := Attack.new()
	move.attack_id = "test_back_punch"
	move.attack_type = "punch"
	move.command_direction = "back"
	move.animation_name = "punch_1"
	move.cancel_start = 0.10
	move.cancel_end = 0.25
	move.cancel_targets.assign(["test_back_punch"])
	player.attack_data_sequence.append(move)
	player.attack_data_by_id[move.attack_id] = move
	for facing in [1.0, -1.0]:
		player.reset_attack_state()
		player.attack_cooldown_timer = 0.0
		player.kick_cooldown_timer = 0.0
		player.facing_direction = facing
		player.combat_commands.clear()
		var direction := "left" if facing > 0.0 else "right"
		player.combat_commands.record(direction, true, facing)
		player.combat_commands.record(direction, false, facing)
		player.combat_commands.advance(0.12)
		player.combat_commands.record("punch", true, facing)
		player._dispatch_combat_command()
		check(player.current_attack_id == move.attack_id, "direction wins over P / facing %s" % facing)
		check(player.attack_phase == player.AttackPhase.STARTUP, "startup has no active hit")
		check(not player.punch_hitbox_active, "hitbox disabled during startup")
		player.combat_commands.record("punch", false, facing)
		player.combat_commands.record("punch", true, facing)
		player.command_attack_elapsed = 0.05
		player._dispatch_combat_command()
		check(not player.combat_commands.peek().is_empty(), "early request retained")
		player.command_attack_elapsed = 0.15
		player._dispatch_combat_command()
		check(not player.combat_commands.peek().is_empty(), "whiff cancel forbidden")
		player.dev_current_attack_connected = true
		player._dispatch_combat_command()
		check(player.combat_commands.peek().is_empty(), "hit confirm cancel accepted")
		check(player.command_attack_elapsed == 0.0, "cancel begins new move")
	player.reset_attack_state()
	player.combat_commands.clear()
	player.is_hit = true
	player.combat_commands.record("punch", true, 1.0)
	player._dispatch_combat_command()
	check(player.current_attack_id.is_empty(), "hitstun forbids normal attack")
	player.combat_commands.advance(0.151)
	check(player.combat_commands.peek().is_empty(), "hitstun request expires")
	player.input_enabled = false
	player._sample_combat_commands(0.01)
	check(player.combat_commands.history.is_empty(), "disabled input clears commands")
	print("COMBAT_COMMAND_INTEGRATION_CHECK failures=%s" % [failures])
	battle.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
