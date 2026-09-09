extends SceneTree


func _initialize() -> void:
	call_deferred("_run_stage1_smoke")


func _run_stage1_smoke() -> void:
	var battle_scene := load("res://scenes/Battle.tscn") as PackedScene
	assert(battle_scene != null)

	var battle := battle_scene.instantiate()
	get_root().add_child(battle)
	# SceneTree._initialize runs before child _ready callbacks are guaranteed to
	# complete. Wait one frame so BattleManager has initialized teams and UI.
	await process_frame

	var manager := battle.get_node("BattleManager") as Stage1BattleManager
	assert(manager != null)
	assert(manager.enemy_team.size() == 1)
	assert(manager.enemy_order.size() == 1)
	assert(String(manager.enemy_team[0]["fighter_id"]) == "enemy_01_crusher")
	assert(manager.current_enemy_index == 0)

	# Stage 1 uses an unlimited timer: the Stage1 manager must not decrement it.
	var initial_round_time := manager.roundTime
	manager.flow_state = BattleManager.BattleState.BATTLE
	manager.currentBattleState = BattleManager.BattleState.BATTLE
	manager.isRoundActive = true
	manager.isBattleFinished = false
	manager._process(120.0)
	assert(manager.roundTime == initial_round_time)

	# Defeating Crusher must immediately resolve the one-enemy slice as Stage 1 clear.
	manager._mark_enemy_defeated()
	assert(manager.are_all_enemies_defeated())
	assert(manager._should_finish_game())
	assert(manager.flow_state == BattleManager.BattleState.CLEAR)
	assert(manager.isBattleFinished)
	# The legacy KO/message label is intentionally hidden by BattleManager.
	# Verify the result UI that players actually see instead.
	assert(manager._end_panel != null)
	assert(manager._end_panel.visible)
	assert(manager._end_title_label != null)
	assert(manager._end_title_label.text == "STAGE 1 CLEAR")

	print("DEV053_STAGE1_OK enemy=", manager.enemy_team[0]["fighter_id"], " round_time=", manager.roundTime)
	quit()
