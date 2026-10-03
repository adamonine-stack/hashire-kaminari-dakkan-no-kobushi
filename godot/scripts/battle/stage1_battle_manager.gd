extends BattleManager
class_name Stage1BattleManager

## Published campaign slice (one or two stages).
## Enemy scoping is configured by BattleManager.active_enemy_count_limit on
## Battle.tscn. This script keeps Stage 1's unlimited timer and clear presentation.

const BATTLE_HP_SCALE := 1.5
const BATTLE_HP_SCALE_META := &"st_action_hp_scale_applied_1_5"
const BATTLE_HP_SAVE_VERSION := 2
const BATTLE_RUN_SAVE_PATH := "user://save.cfg"


func _create_progress_entry_from_definition(definition: Resource, battle_order: int) -> Dictionary:
	_apply_battle_hp_scale_once(definition)
	return super._create_progress_entry_from_definition(definition, battle_order)


func _apply_battle_hp_scale_once(definition: Resource) -> void:
	if definition == null or definition.has_meta(BATTLE_HP_SCALE_META):
		return
	var current_max_health := float(definition.get("max_health"))
	if current_max_health <= 0.0:
		return
	definition.set("max_health", current_max_health * BATTLE_HP_SCALE)
	definition.set_meta(BATTLE_HP_SCALE_META, true)


func save_run_progress() -> bool:
	if not super.save_run_progress():
		return false
	var config := ConfigFile.new()
	if config.load(BATTLE_RUN_SAVE_PATH) != OK:
		return false
	config.set_value("run", "version", BATTLE_HP_SAVE_VERSION)
	return config.save(BATTLE_RUN_SAVE_PATH) == OK


func load_run_progress() -> bool:
	var saved_version := 1
	if FileAccess.file_exists(BATTLE_RUN_SAVE_PATH):
		var version_config := ConfigFile.new()
		if version_config.load(BATTLE_RUN_SAVE_PATH) == OK:
			saved_version = int(version_config.get_value("run", "version", 1))

	if not super.load_run_progress():
		return false

	if saved_version < BATTLE_HP_SAVE_VERSION:
		_migrate_loaded_health_to_scaled_values()
		save_run_progress()
	return true


func _migrate_loaded_health_to_scaled_values() -> void:
	for data in player_team:
		if bool(data.get("is_defeated", false)):
			continue
		data["current_health"] = clampi(
			int(round(float(data["current_health"]) * BATTLE_HP_SCALE)),
			1,
			int(data["max_health"])
		)
	for data in enemy_team:
		if bool(data.get("is_defeated", false)):
			continue
		data["current_health"] = clampi(
			int(round(float(data["current_health"]) * BATTLE_HP_SCALE)),
			1,
			int(data["max_health"])
		)
	_update_all_ui()


func _ready() -> void:
	super._ready()
	# The Stage 1 flow owns its result panel. The generic HUD otherwise opens a
	# second, eight-enemy result on top and steals the restart button's focus.
	if battle_hud != null:
		for binding in [["game_cleared", "show_game_clear"], ["game_over", "show_game_over"]]:
			var callback := Callable(battle_hud, binding[1])
			if is_connected(binding[0], callback):
				disconnect(binding[0], callback)
		battle_hud.hide_result_layer()


func _process(_delta: float) -> void:
	# The game design uses an unlimited timer. Keep pause/debug polling from the
	# base manager, but deliberately skip BattleManager's countdown/time-up path.
	_poll_pause_action()
	_update_debug_flow_label()


func enter_game_clear() -> void:
	if flow_state == BattleState.CLEAR:
		return
	_set_battle_state(BattleState.CLEAR)
	isBattleFinished = true
	is_run_active = false
	_set_battle_active(false)
	_hide_player_selection()
	close_player_order_select()
	if enemy_team.size() == 8:
		_clear_active_fighter_actions(player)
		_clear_active_fighter_actions(enemy)
		_hide_end_panel()
		if battle_hud != null: battle_hud.hide_result_layer()
		var snapshot: Array = []
		for data in player_team:
			snapshot.append({"character_id":String(data["character_id"]), "current_health":int(data["current_health"]), "max_health":int(data["max_health"]), "is_defeated":bool(data["is_defeated"]), "special_gauge":float(data.get("special_gauge", 0.0))})
		get_tree().root.set_meta(&"stage8_ending_snapshot", snapshot)
		clear_run_save()
		_show_message("STAGE 8 CLEAR")
		_switch_bgm("WinBGM")
		_flow_sequence_id += 1
		var sequence := _flow_sequence_id
		await get_tree().create_timer(2.5).timeout
		if sequence != _flow_sequence_id or not is_inside_tree(): return
		get_tree().change_scene_to_file("res://scenes/Stage8Ending.tscn")
		return
	_switch_bgm("WinBGM")
	var title := "STAGE %d CLEAR" % enemy_team.size()
	_show_message(title)
	_notify_hud_game_clear()
	clear_run_save()
	_show_end_panel(title, "All opponents in this published slice defeated.\nDEFEATED: %d  SURVIVED: %d" % [
		defeated_player_ids.size(),
		maxi(0, player_team.size() - defeated_player_ids.size()),
	])
	game_clear_menu_opened.emit()
	game_cleared.emit()
	print(title)
