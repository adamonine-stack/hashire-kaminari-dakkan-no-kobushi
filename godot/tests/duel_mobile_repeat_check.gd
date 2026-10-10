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
				var expected := "akky_%s_%s" % [direction, action]
				# Independent screen-touch identifiers: the direction finger never lifts.
				touch(0, true, direction_button)
				await ticks(3)
				check(Input.is_action_pressed("down" if direction == "down" else ("move_right" if direction_button_name == "MoveRightButton" else "move_left")), "D-pad held %s %s" % [direction, action])
				touch(1, true, attack_button)
				await ticks(3)
				touch(1, false, attack_button)
				check(started.size() == 1 and started[0] == expected, "first attack %s / facing %s / got %s" % [expected, facing, started])
				# A rapid second tap occurs during the first attack animation.
				touch(1, true, attack_button)
				await ticks(3)
				touch(1, false, attack_button)
				await ticks(8)
				check(started.size() == 1, "animation not cancelled %s / facing %s" % [expected, facing])
				await ticks(90)
				check(started.size() == 2 and started[0] == expected and started[1] == expected, "two full directional attacks %s / facing %s / got %s" % [expected, facing, started])
				touch(0, false, direction_button)
				await ticks(3)
				check(not Input.is_action_pressed("down" if direction == "down" else ("move_right" if direction_button_name == "MoveRightButton" else "move_left")), "D-pad releases %s" % direction)
	controls.release_all_touch_inputs()
	print("DUEL_MOBILE_REPEAT_CHECK failures=", failures)
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
