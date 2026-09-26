extends BattleManager
class_name Stage1BattleManager

## Published campaign slice (one or two stages).
## Enemy scoping is configured by BattleManager.active_enemy_count_limit on
## Battle.tscn. This script keeps Stage 1's unlimited timer and clear presentation.


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