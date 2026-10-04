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
	for i in range(360):
		await physics_frame
		if manager.isRoundActive:
			break
	_checkpoint("round_wait_finished active=" + str(manager.isRoundActive))

	var hud := battle.get_node("UI/BattleUIRoot/BattleHUD")
	assert(hud.player_name_label.visible)
	assert(hud.player_name_label.text == "アッキー")
	assert(hud.player_icon_rect.texture != null)
	assert(hud.enemy_name_label.visible)
	assert(hud.enemy_name_label.text == "クラッシャー")
	assert(hud.enemy_icon_rect.texture != null)
	assert(manager._current_enemy_definition != null)
	assert(manager._current_enemy_definition_index == 0)
	_checkpoint("hud_and_enemy_definition_verified")

	var stage_1: Resource = manager._stage_definition_for_enemy_index(0)
	assert(stage_1 != null)
	assert(manager._current_stage_definition_index == 0)
	assert(manager.STAGE_DEFINITION_PATHS.size() >= 2)
	var stage_2: Resource = ResourceLoader.load(manager.STAGE_DEFINITION_PATHS[1])
	assert(stage_2 != null)
	assert(stage_1.backdrop_id == &"downtown_street")
	assert(stage_2.backdrop_id == &"back_alley")
	_checkpoint("stage_definitions_verified")

	var backdrop := battle.get_node("Stage1Backdrop")
	assert(backdrop != null)
	assert(backdrop.get_backdrop_id() == &"downtown_street")
	backdrop.set_backdrop_id(&"back_alley")
	assert(backdrop.get_backdrop_id() == &"back_alley")
	backdrop.set_backdrop_id(stage_1.backdrop_id)
	assert(String(stage_1.player_dialogues.get("player_01_akky", "")) != "")
	assert(String(stage_1.player_dialogues.get("player_02_gou", "")) != "")
	assert(String(stage_1.player_dialogues.get("player_03_seiya", "")) != "")
	assert(String(stage_1.enemy_dialogues.get("player_01_akky", "")) != "")
	assert(String(stage_1.enemy_dialogues.get("player_02_gou", "")) != "")
	assert(String(stage_1.enemy_dialogues.get("player_03_seiya", "")) != "")
	_checkpoint("backdrop_and_dialogues_verified")

	var initial_round_time: int = int(manager.roundTime)
	manager.flow_state = BattleManager.BattleState.BATTLE
	manager.currentBattleState = BattleManager.BattleState.BATTLE
	manager.isRoundActive = true
	manager.isBattleFinished = false
	manager._process(120.0)
	assert(manager.roundTime == initial_round_time)
	_checkpoint("unlimited_timer_verified")

	var enemy := battle.get_node("Enemy")
	enemy.disable_ai()
	enemy.reset_attack_state(false)
	enemy.reset_knockdown_state()
	enemy._clear_guard_state()
	enemy.is_hit = false
	enemy.is_guard_hit = false
	assert(enemy._is_power_fighter())
	assert(enemy.ai_profile.pressure_attack_rate >= 0.50)
	assert(enemy.ai_profile.counter_attack_rate >= 0.75)
	var armor_hp: int = enemy.current_hp
	enemy.current_attack_type = "Punch"
	var armor_test_hit := {
		"damage": 5,
		"combo_hit_index": 1,
		"combo_hit_max": 0,
		"attack_type": "punch",
		"causes_knockdown": false,
		"hitstun_time": 0.30,
		"effect_size": 1.0,
		"se_type": "strong",
		"screen_shake": 0.0,
	}
	assert(enemy._has_active_power_armor(armor_test_hit, null))
	assert(not enemy._has_active_power_armor({"attack_type": "throw"}, null))
	assert(enemy.receive_attack(armor_test_hit, 1.0, enemy.global_position, null))
	assert(enemy.current_hp == armor_hp - 5)
	assert(enemy.current_attack_type == "Punch")
	assert(not enemy.is_hit)
	enemy.reset_attack_state(false)
	enemy.hit_stop_timer = 0.0
	enemy.set_health(enemy.max_hp)
	_checkpoint("crusher_power_armor_verified")

	print("DEV053_STAGE1_OK diagnostic=through_crusher_power_armor")
	_completed = true
	battle.queue_free()
	quit()
