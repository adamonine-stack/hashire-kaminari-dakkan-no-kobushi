extends BattleManager
class_name Stage1BattleManager

## Stage 1 completion slice.
## Keeps the existing battle systems intact while limiting the current playable
## build to Crusher and using an unlimited round timer.


func _process(_delta: float) -> void:
	# The game design uses an unlimited timer. Keep pause/debug polling from the
	# base manager, but deliberately skip BattleManager's countdown/time-up path.
	_poll_pause_action()
	_update_debug_flow_label()


func initialize_enemy_team() -> void:
	# Stage 1 must be independent from unfinished Stage 2-8 definitions.
	# Validate and register Crusher only instead of validating the full gauntlet.
	enemy_team.clear()
	enemy_order.clear()

	if ENEMY_DEFINITIONS.is_empty():
		push_error("[Stage1] Crusher definition is missing.")
		return

	var definition: Resource = ENEMY_DEFINITIONS[0]
	if definition == null:
		push_error("[Stage1] Crusher definition is null.")
		return
	if definition.fighter_id != &"enemy_01_crusher":
		push_error("[Stage1] Unexpected fighter id: %s" % definition.fighter_id)
		return
	if int(definition.enemy_order) != 1:
		push_error("[Stage1] Crusher enemy_order must be 1.")
		return
	if definition.fighter_scene == null:
		push_error("[Stage1] Crusher fighter scene is missing.")
		return
	if int(round(definition.max_health)) <= 0:
		push_error("[Stage1] Crusher max health is invalid.")
		return
	if definition.ai_profile == null:
		push_error("[Stage1] Crusher AI profile is missing.")
		return

	enemy_order.append(definition.fighter_id)
	enemy_team.append(_create_progress_entry_from_definition(definition, 0))


func enter_game_clear() -> void:
	if flow_state == BattleState.CLEAR:
		return
	_set_battle_state(BattleState.CLEAR)
	isBattleFinished = true
	is_run_active = false
	_set_battle_active(false)
	_hide_player_selection()
	close_player_order_select()
	_switch_bgm("WinBGM")
	_show_message("STAGE 1 CLEAR")
	_notify_hud_game_clear()
	_show_end_panel("STAGE 1 CLEAR", "Crusher defeated.\nORDER: %s\nDEFEATED: %d  SURVIVED: %d" % [
		_order_text(),
		defeated_player_ids.size(),
		maxi(0, selected_player_order.size() - defeated_player_ids.size()),
	])
	game_clear_menu_opened.emit()
	game_cleared.emit()
	print("STAGE 1 CLEAR")
