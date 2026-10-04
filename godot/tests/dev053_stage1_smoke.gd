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
	# SceneTree._initialize runs before child _ready callbacks are guaranteed to
	# complete. Wait one frame so BattleManager has initialized teams and UI.
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

	# Stage 1 uses an unlimited timer: the Stage1 manager must not decrement it.
	var initial_round_time: int = int(manager.roundTime)
	manager.flow_state = BattleManager.BattleState.BATTLE
	manager.currentBattleState = BattleManager.BattleState.BATTLE
	manager.isRoundActive = true
	manager.isBattleFinished = false
	manager._process(120.0)
	assert(manager.roundTime == initial_round_time)
	_checkpoint("unlimited_timer_verified")

	# Crusher is the POWER archetype. While already attacking, an ordinary hit
	# must damage him without cancelling the attack or entering normal hitstun.
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

	# Defeating Crusher through the normal player-win result path must show the
	# active fighter's victory pose before resolving the one-enemy slice as clear.
	manager._pending_player_ko = false
	manager._pending_enemy_ko = true
	manager.battle_result_locked = true
	manager.result_display_duration = 0.01
	_checkpoint("resolve_battle_result_begin")
	await manager.resolve_battle_result()
	_checkpoint("resolve_battle_result_returned")
	assert(manager.are_all_enemies_defeated())
	assert(manager.flow_state == BattleManager.BattleState.CLEAR)
	assert(manager.isBattleFinished)
	assert(manager.player.victory_pose_active)
	assert(manager.player._get_current_visual_animation() == &"victory")
	if manager.player.uses_animated_character_art:
		assert(String(manager.player.animated_character_sprite.animation) == "victory")
	# The legacy KO/message label is intentionally hidden by BattleManager.
	# Verify the result UI that players actually see instead.
	assert(manager._end_panel != null)
	assert(manager._end_panel.visible)
	assert(manager._end_title_label != null)
	assert(manager._end_title_label.text == "STAGE 1 CLEAR")
	assert(not manager.battle_hud.result_panel.visible)
	_checkpoint("clear_ui_verified")

	print("DEV053_STAGE1_OK enemy=", manager.enemy_team[0]["fighter_id"], " round_time=", manager.roundTime)
	manager.cleanup_battle_before_transition()
	get_root().get_node("AudioManager").stop_bgm()
	battle.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	_completed = true
	_checkpoint("completed")
	quit()
