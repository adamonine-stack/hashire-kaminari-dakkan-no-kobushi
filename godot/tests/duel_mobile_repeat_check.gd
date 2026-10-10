extends SceneTree

var failures: Array[String] = []
var battle: Node
var manager: Node
var player: Node
var enemy: Node
var controls: Node
var started: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)


func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame


func record_start(move_id: String) -> void:
	started.append(move_id)


func touch(index: int, pressed: bool, button: Button) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = button.get_global_rect().get_center()
	controls._input(event)


func reset_pair(facing: float) -> void:
	controls.release_all_touch_inputs()
	for actor in [player, enemy]:
		actor._cancel_current_action()
		actor.reset_attack_state()
		manager.reset_active_fighter_state(actor, Vector2(500 if actor == player else 500 + 300 * facing, 520), facing if actor == player else -facing, actor.max_hp)
		actor.ai_enabled = false
		actor.ai_profile = null
		actor.input_enabled = actor == player
		actor.is_round_active = true
		actor.hit_stop_timer = 0
		actor.combat_commands.clear()
	await ticks(4)
	started.clear()


func run() -> void:
	battle = load("res://scenes/Battle.tscn").instantiate()
	battle.get_node("BattleManager").active_enemy_count_limit = 1
	root.add_child(battle)
	current_scene = battle
	await process_frame
	manager = battle.get_node("BattleManager")
	manager.select_player_by_id("player_01_akky")
	for i in range(420):
		await physics_frame
		if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible:
			manager.enemy_intro_finished.emit()
		if manager.isRoundActive:
			break
	check(manager.isRoundActive, "battle started")
	player = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	if String(player.fighter_definition.fighter_id) != "player_01_akky":
		var temporary := player
		player = enemy
		enemy = temporary
	controls = manager.mobile_controls
	controls.show_touch_controls()
	player.attack_started.connect(record_start)

	for facing in [1.0, -1.0]:
		for direction in ["down", "forward", "back"]:
			for action in ["punch", "kick"]:
				await reset_pair(facing)
				var direction_button_name := "CrouchButton" if direction == "down" else ("MoveRightButton" if (direction == "forward") == (facing > 0.0) else "MoveLeftButton")
				var direction_button := controls.left_controls.get_node(direction_button_name) as Button
				var attack_button := controls.right_controls.get_node("PunchButton" if action == "punch" else "KickButton") as Button
				var expected := "basic_akky_%s_%s" % [direction, action]
				var held_action := "down" if direction == "down" else ("move_right" if direction_button_name == "MoveRightButton" else "move_left")
				# First test: an early repeat must NOT create a delayed ghost move.
				touch(0, true, direction_button)
				await ticks(3)
				check(Input.is_action_pressed(held_action), "D-pad held %s %s" % [direction, action])
				touch(1, true, attack_button)
				await ticks(3)
				touch(1, false, attack_button)
				check(started.size() == 1 and started[0] == expected, "first attack %s / facing %s / got %s" % [expected, facing, started])
				touch(1, true, attack_button)
				await ticks(3)
				touch(1, false, attack_button)
				await ticks(90)
				check(started.size() == 1, "early repeat discarded %s facing %s got %s" % [expected, facing, started])
				touch(0, false, direction_button)
				await ticks(3)
				check(not Input.is_action_pressed(held_action), "D-pad released early case %s" % direction)

				# Second test: one new press in the last 120ms of recovery
				# must start exactly one new full animation after the old one.
				await reset_pair(facing)
				touch(0, true, direction_button)
				await ticks(3)
				touch(1, true, attack_button)
				await ticks(3)
				touch(1, false, attack_button)
				check(started.size() == 1 and started[0] == expected, "late case starts first %s" % expected)
				var waited := 0
				while player.current_attack_type != "" and (player.attack_phase != player.AttackPhase.RECOVERY or player.attack_phase_timer > 0.08) and waited < 180:
					await ticks(1)
					waited += 1
				check(player.current_attack_type != "" and player.attack_phase == player.AttackPhase.RECOVERY and player.attack_phase_timer > 0.0, "recovery window reached %s" % expected)
				touch(1, true, attack_button)
				await ticks(2)
				touch(1, false, attack_button)
				check(started.size() == 1, "no animation self-cancel %s" % expected)
				await ticks(15)
				check(started.size() == 2 and started[0] == expected and started[1] == expected, "late repeat starts after recovery %s facing %s got %s" % [expected, facing, started])
				touch(0, false, direction_button)
				await ticks(90)
				check(started.size() == 2, "no late phantom repeat %s got %s" % [expected, started])
				check(not Input.is_action_pressed(held_action), "D-pad releases %s" % direction)
	# Regression: a synthetic/emulated duplicate press cannot latch the D-pad.
	await reset_pair(1.0)
	var down_button := controls.left_controls.get_node("CrouchButton") as Button
	var punch_button := controls.right_controls.get_node("PunchButton") as Button
	down_button.button_down.emit()
	down_button.button_down.emit()
	check(Input.is_action_pressed("down"), "duplicate down starts one hold")
	down_button.button_up.emit()
	check(not Input.is_action_pressed("down"), "single release cancels duplicate down")
	await ticks(2)
	check(player.combat_commands.command_direction(player.facing_direction) == "neutral", "duplicate down does not survive as buffered command")
	touch(1, true, punch_button)
	await ticks(3)
	touch(1, false, punch_button)
	check(player.last_combat_command.get("direction", "") == "neutral", "punch after released down is neutral")
	await reset_pair(1.0)
	# Two real touch identifiers on the same D-pad button share one hold;
	# releasing the final finger must clear the virtual direction immediately.
	touch(0, true, down_button)
	touch(2, true, down_button)
	check(Input.is_action_pressed("down"), "two touches share D-pad hold")
	touch(0, false, down_button)
	check(Input.is_action_pressed("down"), "first finger release retains second hold")
	touch(2, false, down_button)
	check(not Input.is_action_pressed("down"), "final finger release clears D-pad")
	check(player.combat_commands.command_direction(player.facing_direction) == "neutral", "last touch removes direction history")
	controls.release_all_touch_inputs()
	print("DUEL_MOBILE_REPEAT_CHECK failures=", failures)
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
