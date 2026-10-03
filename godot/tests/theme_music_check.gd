extends SceneTree

var failures: Array[String] = []
var audio: Node
var render := false
var missing := false

func _initialize() -> void:
	call_deferred("run_check")

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)
	print("[THEME_QA] %s %s" % ["PASS" if ok else "FAIL", label])

func capture(id: String) -> void:
	if not render: return
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../evidence/theme")
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path.path_join(id + ".png"))

func capture_ending_beat(beat: String) -> void:
	if not render or beat not in ["dawn", "credits"]: return
	if beat == "credits":
		await create_timer(0.7).timeout
		await capture("ending_credits_start")
		await create_timer(0.9).timeout
	else: await create_timer(0.4).timeout
	await capture("ending_" + beat)

func advance_intro(manager: Node) -> void:
	if not render: return
	for i in range(30):
		if manager._enemy_intro_panel == null or not manager._enemy_intro_panel.visible: break
		manager._enemy_intro_last_advance_msec = -1000
		manager._advance_enemy_intro()
		await process_frame

func wait_scene(path: String, seconds := 5.0) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while (current_scene == null or current_scene.scene_file_path != path) and Time.get_ticks_msec() < deadline:
		await process_frame
	check(current_scene != null and current_scene.scene_file_path == path, "scene " + path)

func run_check() -> void:
	render = DisplayServer.get_name() != "headless"
	missing = "--missing-theme" in OS.get_cmdline_user_args()
	audio = root.get_node("AudioManager")
	check(AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("SFX") >= 0, "separate Music/SFX buses")
	change_scene_to_file("res://scenes/Title.tscn")
	await wait_scene("res://scenes/Title.tscn")
	check(current_scene.TITLE_MAIN == "走れカミナリ" and current_scene.TITLE_ENGLISH == "HASHIRE KAMINARI", "correct Japanese/English title")
	check(ProjectSettings.get_setting("application/config/name") == "走れカミナリ 奪還の拳", "correct application/window title")
	if OS.get_name() == "Windows":
		check(ProjectSettings.globalize_path("user://").replace("\\", "/").ends_with("Godot/app_userdata/HashireIkazuchi/"), "existing Windows save directory retained")
	var credit_lines: Array[String] = []
	for line in FileAccess.get_file_as_string("res://data/story/credits.txt").split("\n"):
		if not line.strip_edges().is_empty(): credit_lines.append(line.strip_edges())
	check(credit_lines.slice(0, 14) == ["走れカミナリ", "奪還の拳", "STAFF", "企画・構成", "蒼大", "ディレクター", "PAPA", "音楽ディレクター", "蒼大", "Suno", "クリエイター", "chatGPT", "codex", "GAME ENGINE"], "exact requested staff names and order")
	await create_timer(1.5).timeout
	check(audio.current_bgm_id == ("title" if missing else audio.THEME_ID), "title theme or missing-file fallback")
	check(audio.bgm_player.playing, "title playback")
	if not missing:
		check(audio.bgm_player.stream is AudioStreamOggVorbis, "local Vorbis decoded")
		check(audio.bgm_player.stream.get_length() > 214.0 and audio.bgm_player.stream.get_length() < 216.0, "whole 3m35s song")
		var position: float = audio.bgm_player.get_playback_position()
		for i in range(8): audio.play_theme()
		await create_timer(0.1).timeout
		check(audio.bgm_player.get_playback_position() >= position, "repeated play does not restart or duplicate")
		var players := audio.get_children().filter(func(node): return node is AudioStreamPlayer and node.bus == &"Music")
		check(players.size() == 2 and not audio.crossfade_player.playing, "two fixed music slots; theme uses only one")
		audio.pause_music()
		position = audio.bgm_player.get_playback_position()
		await create_timer(0.2).timeout
		check(audio.bgm_player.stream_paused and absf(position - audio.bgm_player.get_playback_position()) < 0.08, "pause position retained within one audio buffer")
		audio.resume_music()
		await create_timer(0.15).timeout
		check(audio.bgm_player.get_playback_position() > position, "resume advances")
		# Exercise the actual finished signal without waiting another full song.
		audio.bgm_player.seek(audio.bgm_player.stream.get_length() - 0.15)
		await create_timer(2.3).timeout
		check(audio.bgm_player.playing and audio.bgm_player.get_playback_position() < 3.0, "title whole-song restart")
	await capture("title")
	current_scene.game_start_button.pressed.emit()
	await create_timer(0.45).timeout
	check(audio.current_bgm_id == ("title" if missing else audio.THEME_ID) and audio.music_envelope < 1.0, "START fades outgoing theme")
	await wait_scene("res://scenes/Opening.tscn")
	check(not audio.bgm_player.playing, "START finishes fade before opening")
	current_scene.skip()
	await wait_scene("res://scenes/Battle.tscn")
	var manager = current_scene.get_node("BattleManager")
	manager.select_player_by_id("player_01_akky")
	await advance_intro(manager)
	await create_timer(1.6).timeout
	check(audio.current_bgm_id != audio.THEME_ID and audio.bgm_player.playing, "Stage 1 keeps stage BGM")
	manager._set_battle_active(false)
	await capture("stage1")
	manager._mark_enemy_defeated()
	manager.current_enemy_index = manager.get_next_enemy_index()
	manager._flow_sequence_id += 1
	await manager.transition_to_next_enemy()
	manager.select_player_by_id("player_01_akky")
	await advance_intro(manager)
	await create_timer(1.6).timeout
	check(manager.current_enemy_index == 1 and audio.current_bgm_id == "battle" and audio.bgm_player.playing, "Stage 1 to Stage 2 preserves stage BGM")
	manager._set_battle_active(false)
	manager._switch_bgm("LoseBGM")
	manager._switch_bgm("WinBGM")
	await create_timer(0.6).timeout
	check(audio.current_bgm_id == "clear", "latest transition cancels stale fade")
	manager.current_enemy_index = 7
	manager._current_bgm_name = ""
	manager._switch_bgm("BattleBGM")
	await create_timer(0.6).timeout
	check(audio.current_bgm_id == "final_boss", "Stage 8 dedicated boss BGM retained")
	manager.restart_current_game()
	await create_timer(1.6).timeout
	check(audio.current_bgm_id != audio.THEME_ID, "retry retains combat music")
	manager.cleanup_battle_before_transition()
	change_scene_to_file("res://scenes/TrueBattle.tscn")
	await wait_scene("res://scenes/TrueBattle.tscn")
	await create_timer(1.6).timeout
	manager = current_scene.get_node("BattleManager")
	manager._set_battle_active(false)
	check(audio.current_bgm_id == "secret_boss", "TRUE boss dedicated BGM retained")
	await capture("true_boss")
	manager.enter_game_clear()
	await create_timer(0.25).timeout
	check(audio.music_envelope < 1.0, "TRUE clear fades combat BGM")
	await wait_scene("res://scenes/TrueEnding.tscn")
	# Start the actual film in an accelerated isolated QA instance.
	current_scene.queue_free()
	await process_frame
	var ending = load("res://scenes/TrueEnding.tscn").instantiate()
	ending.timing_scale = 0.14 if render else 0.02
	ending.auto_return = false
	ending.beat_started.connect(capture_ending_beat)
	root.add_child(ending)
	current_scene = ending
	var deadline := Time.get_ticks_msec() + 60000
	while ending.stage != "complete" and Time.get_ticks_msec() < deadline: await process_frame
	check(ending.stage == "complete", "TRUE ending reaches credits")
	await create_timer(1.5).timeout
	check(audio.current_bgm_id == ("true_ending" if missing else audio.THEME_ID), "ending uses main theme or original fallback")
	if not missing:
		check(not audio.theme_repeat and audio.bgm_player.playing, "ending does not loop or cut full song")
	await capture("ending")
	ending.queue_free()
	await process_frame
	change_scene_to_file("res://scenes/Title.tscn")
	await wait_scene("res://scenes/Title.tscn")
	await create_timer(2.5).timeout
	check(audio.current_bgm_id == ("title" if missing else audio.THEME_ID), "second title run starts cleanly")
	if not missing:
		audio.fade_to_theme(0.1, 5.0, false)
		await create_timer(1.6).timeout
		check(audio.bgm_player.get_playback_position() >= 5.0, "future boss cue API accepts explicit position")
		audio.play_bgm("battle")
		audio.fade_to_theme(0.3)
		audio.stop_music()
		await create_timer(0.6).timeout
		check(not audio.bgm_player.playing and audio.current_bgm_id.is_empty(), "stop cancels pending theme")
		audio.play_bgm("battle")
		audio.crossfade("clear", 0.3)
		await create_timer(0.15).timeout
		check(audio.bgm_player.playing and audio.crossfade_player.playing, "explicit non-theme crossfade mixes fixed slots")
		await create_timer(0.3).timeout
		check(audio.current_bgm_id == "clear" and not audio.crossfade_player.playing, "crossfade finishes with one track")
		audio.crossfade(audio.THEME_ID, 0.1)
		await create_timer(0.08).timeout
		check(not audio.crossfade_player.playing, "theme crossfade never overlaps stage music")
	current_scene.queue_free()
	await process_frame
	audio.stop_bgm()
	print("THEME_MUSIC_CHECK missing=%s rendered=%s failures=%s" % [missing, render, JSON.stringify(failures)])
	quit(0 if failures.is_empty() else 1)
