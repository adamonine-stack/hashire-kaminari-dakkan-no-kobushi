extends SceneTree

const ENDING := preload("res://scripts/ui/stage8_ending.gd")
var failures: Array[String] = []
var render := false

func _initialize() -> void:
	call_deferred("run_check")

func check(condition: bool, detail: String) -> void:
	if not condition: failures.append(detail)

func capture(filename: String) -> void:
	if not render: return
	for frame in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("user://evidence")
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path.path_join(filename + ".png"))

func run_check() -> void:
	render = DisplayServer.get_name() != "headless"
	if render: DisplayServer.window_set_title("ST_action Stage8 Ending QA")
	var cases := {"A":[0], "B":[1], "C":[2], "D":[0,1], "E":[0,2], "F":[1,2], "G":[0,1,2]}
	for expected_route in cases:
		change_scene_to_file("res://scenes/Battle.tscn")
		for frame in range(5): await process_frame
		var manager = current_scene.get_node("BattleManager")
		manager._hide_player_selection()
		manager.current_enemy_index = 7
		for i in range(3):
			manager.player_team[i]["is_defeated"] = not cases[expected_route].has(i)
			manager.player_team[i]["current_health"] = 30 if cases[expected_route].has(i) else 0
		for data in manager.enemy_team:
			data["is_defeated"] = true
			data["current_health"] = 0
		manager._should_finish_game()
		manager.enter_game_clear() # A duplicate clear must not restart the delay.
		check(not manager.isRoundActive, "combat stopped " + expected_route)
		check(not manager._end_panel.visible, "no result overlay " + expected_route)
		await create_timer(2.7).timeout
		check(current_scene.scene_file_path == "res://scenes/Stage8Ending.tscn", "stage8 connection " + expected_route)
		if current_scene.scene_file_path != "res://scenes/Stage8Ending.tscn": continue
		var ui = current_scene
		check(ui.route == expected_route, "route " + expected_route)
		check(ui.actors.has("ミオ") == cases[expected_route].has(0), "Mio visibility " + expected_route)
		check(ui.actors.has("レン") == cases[expected_route].has(1), "Ren visibility " + expected_route)
		check(not ui.actors.has("ユイ"), "Yui never appears")
		for actor_name in ui.actors:
			check(is_equal_approx(ui.actors[actor_name].position.y, 478), "feet " + actor_name)
		ui.visible_elapsed = 1000.0
		ui.story_label.visible_characters = -1
		await capture(expected_route + "_rescue")
		root.size = Vector2i(844,390)
		for frame in range(3): await process_frame
		check(ui.safe_content.position.x >= 0 and ui.safe_content.position.y >= 0, "phone fit " + expected_route)
		await capture(expected_route + "_phone")
		root.size = Vector2i(1280,720)
		for frame in range(3): await process_frame
		if expected_route == "C":
			var spoken: Array = ui.pages.filter(func(p): return p.speaker != "@").map(func(p): return p.text)
			check(spoken == ["……残ったのは俺だけか……。", "……くくく。", "くはは……。", "あはははははー！"], "exact short BAD END")
		var guard := 0
		while is_instance_valid(ui) and not ui.finished and not ui.terminal_card and guard < 220:
			guard += 1
			if ui.input_locked:
				if ui.script_events.back() == "true_pause":
					check(ui.veil.color.a == 0, "TRUE no fade at black mastermind line")
					await capture("G_no_fade")
				await create_timer(0.2).timeout
				guard -= 1
				continue
			ui.visible_elapsed = 1000.0
			ui.story_label.visible_characters = -1
			if ui.story_label.text == "その真のボスは――俺だ。": await capture("G_reveal")
			ui.last_input_msec = -1000
			ui.advance()
			await process_frame
		if expected_route != "G":
			check(ui.terminal_card, "terminal card " + expected_route)
			check(ui.end_card.text == ("BAD END" if expected_route == "C" else "TO BE CONTINUED…"), "correct ending card " + expected_route)
			await capture(expected_route + "_end")
			ui.last_input_msec = -1000
			ui.advance()
			# Returning now waits for the ending music's 1-second fade.
			await create_timer(1.2).timeout
			check(current_scene.scene_file_path == "res://scenes/Title.tscn", "title return " + expected_route)
		else:
			await capture("G_true_boss_card")
			await create_timer(3.1).timeout
			check(current_scene.scene_file_path == "res://scenes/TrueBattle.tscn", "TRUE battle transition")
			await create_timer(1.8).timeout
			var boss_manager = current_scene.get_node("BattleManager")
			check(boss_manager.enemy.fighter_definition.fighter_id == &"enemy_09_seiya", "boss identity")
			check(boss_manager.get_available_players() == ["player_01_akky", "player_02_gou"], "Seiya not selectable")
			check(boss_manager.isRoundActive and boss_manager.player.input_enabled, "TRUE battle controllable")
			check(boss_manager.enemy.uses_animated_character_art, "TRUE uses Seiya atlas")
			await capture("G_true_battle")
			check(boss_manager.save_run_progress(), "TRUE save")
			var cfg := ConfigFile.new()
			cfg.load("user://save.cfg")
			check(cfg.get_value("run", "scene", "") == "res://scenes/TrueBattle.tscn", "TRUE save scene")
			boss_manager._set_battle_active(false)
			boss_manager.player.current_hp = 0
			boss_manager.handle_player_defeated()
			check(boss_manager.get_available_players() == ["player_02_gou"], "Gou survives Akky defeat")
			boss_manager.select_player_by_id("player_02_gou")
			await create_timer(1.5).timeout
			check(boss_manager.player.fighter_definition.fighter_id == &"player_02_gou", "Gou replacement")
			boss_manager.restart_current_game()
			await create_timer(1.5).timeout
			check(boss_manager.enemy.current_hp > 0 and boss_manager.player.current_hp > 0 and boss_manager.isRoundActive, "TRUE retry")
			boss_manager._set_battle_active(false)
			boss_manager._mark_enemy_defeated()
			boss_manager._should_finish_game()
			check(boss_manager.flow_state == boss_manager.BattleState.CLEAR, "TRUE win")
			await create_timer(2.2).timeout
			check(current_scene.scene_file_path == "res://scenes/TrueEnding.tscn", "TRUE win enters ending")
			change_scene_to_file("res://scenes/TrueBattle.tscn")
			await create_timer(1.8).timeout
			boss_manager = current_scene.get_node("BattleManager")
			boss_manager._set_battle_active(false)
			for data in boss_manager.player_team:
				data["is_defeated"] = true
				data["current_health"] = 0
			boss_manager._should_finish_game()
			check(boss_manager.flow_state == boss_manager.BattleState.GAME_OVER, "TRUE loss")
		print("STAGE8_ROUTE_CHECK route=%s done" % expected_route)
	print("STAGE8_ENDING_CHECK failures=%s" % JSON.stringify(failures))
	if current_scene != null:
		current_scene.queue_free()
		for frame in range(3): await process_frame
	get_root().get_node("AudioManager").stop_bgm()
	var audio = get_root().get_node("AudioManager")
	for sound in audio.se_players:
		sound.stop()
		sound.stream = null
	audio.bgm_player.stream = null
	await create_timer(0.3).timeout
	quit(0 if failures.is_empty() else 1)
