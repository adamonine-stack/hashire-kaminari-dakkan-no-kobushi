extends "res://tests/akky_continuous_gameplay_check.gd"

func selected_fighter_id() -> String:
	return "player_03_seiya" if "--seiya" in OS.get_cmdline_user_args() else "player_02_gou"

func qa_name() -> String:
	return "Seiya" if "--seiya" in OS.get_cmdline_user_args() else "Gou"

func special_clips() -> Array:
	return ["seiya_two_start","seiya_two_somersault","seiya_two_finish"] if "--seiya" in OS.get_cmdline_user_args() else ["gou_reversal_startup","gou_reversal_breaker","gou_reversal_finish"]
