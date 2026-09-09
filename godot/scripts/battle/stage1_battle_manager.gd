extends BattleManager
class_name Stage1BattleManager

## Stage 1 completion slice.
## Enemy scoping is configured by BattleManager.active_enemy_count_limit on
## Battle.tscn. This script keeps Stage 1's unlimited timer and clear presentation.


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
