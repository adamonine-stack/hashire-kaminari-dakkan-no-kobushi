extends "res://tests/hero_continuous_gameplay_check.gd"

func battle_stage_index() -> int:
	return 1

func tap(action: String) -> void:
	if controlled_actor_name() == "Enemy" and action == "special_attack":
		# Enemy specials are AI requests, not the player's special input binding.
		player.start_character_special()
		check(player.is_character_special_busy(),"Rei special request starts")
		await step(2)
	else:
		await super.tap(action)

func controlled_actor_name() -> String:
	return "Enemy" if "--rei" in OS.get_cmdline_user_args() else "Player"

func selected_fighter_id() -> String:
	if "--rei" in OS.get_cmdline_user_args() or "--akky" in OS.get_cmdline_user_args():
		return "player_01_akky"
	return super.selected_fighter_id()

func qa_name() -> String:
	if "--rei" in OS.get_cmdline_user_args(): return "Rei"
	if "--akky" in OS.get_cmdline_user_args(): return "Akky"
	return super.qa_name()

func special_clips() -> Array:
	if "--rei" in OS.get_cmdline_user_args():
		return ["rei_uppercut_startup","rei_dragon_uppercut","rei_uppercut_finish"]
	if "--akky" in OS.get_cmdline_user_args():
		return ["akky_reversal_startup","akky_reversal_elbow","akky_reversal_finish"]
	return super.special_clips()
