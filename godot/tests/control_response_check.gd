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
	var hero_id := "player_03_seiya" if "--seiya" in OS.get_cmdline_user_args() else ("player_02_gou" if "--gou" in OS.get_cmdline_user_args() else "player_01_akky")
	manager.select_player_by_id(hero_id)
	for i in range(420):
		await physics_frame
		if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible:
			manager.enemy_intro_finished.emit()
		if manager.isRoundActive:
			break
	check(manager.isRoundActive, "battle started")
	player = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	if String(player.fighter_definition.fighter_id) != hero_id:
		var temporary := player
		player = enemy
		enemy = temporary
	controls = manager.mobile_controls
	controls.show_touch_controls()
	player.attack_started.connect(record_start)

	var right := controls.left_controls.get_node("MoveRightButton") as Button
	var up := controls.left_controls.get_node("UpRightButton") as Button
	var punch := controls.right_controls.get_node("PunchButton") as Button
	var kick := controls.right_controls.get_node("KickButton") as Button
	var guard := controls.right_controls.get_node("GuardButton") as Button
	await reset_pair(1.0)
	touch(0, true, right)
	drag(0, Vector2(640, 100))
	check(not Input.is_action_pressed("move_right"), "leaving D-pad releases movement")
	drag(0, right.get_global_rect().get_center())
	check(Input.is_action_pressed("move_right"), "same finger can re-enter D-pad")
	var gap := (right.get_global_rect().get_center() + up.get_global_rect().get_center()) / 2.0
	drag(0, gap)
	check(Input.is_action_pressed("move_right"), "D-pad spacing does not cut shared direction")
	touch(0, false, right)
	check(not Input.is_action_pressed("move_right"), "D-pad final release clears direction")
	await reset_pair(1.0)
	# A guard stays down during thumb drift, and cancels on browser touch-cancel.
	touch(0, true, guard)
	drag(0, punch.get_global_rect().get_center())
	check(Input.is_action_pressed("guard"), "guard retains ownership while dragging")
	await ticks(3)
	check(started.is_empty(), "dragging guard never fires punch")
	var canceled := InputEventScreenTouch.new()
	canceled.index = 0
	canceled.pressed = false
	canceled.canceled = true
	controls._input(canceled)
	check(not Input.is_action_pressed("guard"), "touch cancel releases guard")
	await ticks(12)
	touch(1, true, punch)
	await ticks(3)
	touch(1, false, punch)
	check(started.size() == 1, "attack responds after guard release")
	await reset_pair(1.0)
	# Both press/release transitions are shorter than one physics sample.
	touch(1, true, punch)
	touch(1, false, punch)
	touch(1, true, punch)
	touch(1, false, punch)
	await ticks(3)
	check(started.size() == 1, "subframe taps start one attack immediately")
	await ticks(90)
	check(started.size() == 1, "subframe taps never replay a delayed attack")
	check(not Input.is_action_pressed("attack"), "rapid tap pulse fully released")
	# The next normal tap must still work after the rapid burst.
	touch(1, true, kick)
	await ticks(3)
	touch(1, false, kick)
	check(started.size() == 2, "kick works after rapid punch burst")
	await reset_pair(1.0)
	touch(1, true, punch)
	drag(1, kick.get_global_rect().get_center())
	await ticks(3)
	check(started.size() == 1 and player.current_attack_type == "Punch", "attack drag never changes to another button")
	touch(1, false, punch)
	await ticks(90)
	check(started.size() == 1, "attack drift produces no extra move")
	# Stale release tasks must not release a fresh press after pause/reset.
	await reset_pair(1.0)
	touch(1, true, punch)
	controls.set_paused_input_mode(true)
	check(player.combat_commands.pending.is_empty(), "pause clears pending touch commands")
	controls.set_paused_input_mode(false)
	touch(1, true, kick)
	await ticks(3)
	touch(1, false, kick)
	check(started.size() == 1 and player.current_attack_type == "Kick", "fresh input survives pause cleanup timers")
	# Inputs during a long knockdown must not wait until the player stands up.
	await reset_pair(1.0)
	player.knockdown_state = &"KNOCKDOWN"
	player.knockdown_timer = 0.4
	touch(1, true, punch)
	touch(1, false, punch)
	check(player.combat_commands.pending.is_empty(), "knockdown cannot freeze a fresh command")
	await ticks(100)
	check(started.is_empty(), "knockdown tap produces no attack after get-up")
	touch(1, true, punch)
	await ticks(3)
	touch(1, false, punch)
	check(started.size() == 1, "attack works after get-up")
	controls.release_all_touch_inputs()
	print("CONTROL_RESPONSE_CHECK hero=", hero_id, " failures=", failures)
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func drag(index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	controls._input(event)
