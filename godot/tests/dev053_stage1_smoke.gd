extends SceneTree


var _last_checkpoint := "initialize"
var _completed := false


func _initialize() -> void:
	call_deferred("_watchdog")
	call_deferred("_run_stage1_smoke")


func _checkpoint(label: String) -> void:
	_last_checkpoint = label
	print("DEV053_CHECKPOINT ", label)


func _watchdog() -> void:
	await create_timer(20.0).timeout
	if _completed:
		return
	push_error("DEV053_STAGE1_WATCHDOG_TIMEOUT last_checkpoint=" + _last_checkpoint)
	quit(1)


func _run_stage1_smoke() -> void:
	_checkpoint("load_battle_scene")
	var battle_scene := load("res://scenes/Battle.tscn") as PackedScene
	assert(battle_scene != null)

	_checkpoint("instantiate_battle")
	var battle := battle_scene.instantiate()
	battle.get_node("BattleManager").active_enemy_count_limit = 1
	get_root().add_child(battle)
	await process_frame
	_checkpoint("battle_ready")

	var manager := battle.get_node("BattleManager") as Stage1BattleManager
	assert(manager != null)
	assert(manager.enemy_team.size() == 1)
	assert(manager.enemy_order.size() == 1)
	assert(String(manager.enemy_team[0]["fighter_id"]) == "enemy_01_crusher")
	assert(manager.enemy_team[0].get("definition", null) == null)
	assert(manager.current_enemy_index == 0)
	_checkpoint("lightweight_enemy_team_verified")

	_checkpoint("select_player_begin")
	await manager.select_player_by_id(String(manager.player_team[0]["fighter_id"]))
	_checkpoint("select_player_returned")
	print("DEV053_STAGE1_OK diagnostic=select_player_returned")
	_completed = true
	battle.queue_free()
	quit()
