extends SceneTree

var failures: Array[String] = []
var theme_started := 0
var theme_finished := 0

func _initialize() -> void:
	call_deferred("run_check")

func run_check() -> void:
	var audio := root.get_node("AudioManager")
	audio.music_finished.connect(func(id: String):
		if id == audio.THEME_ID: theme_finished = Time.get_ticks_msec()
	)
	var ending = load("res://scenes/TrueEnding.tscn").instantiate()
	ending.timing_scale = 0.14
	ending.beat_started.connect(func(beat: String):
		print("[FULL_THEME_QA] beat=%s" % beat)
		if beat == "dawn": theme_started = Time.get_ticks_msec()
		if beat == "complete" and theme_finished == 0: failures.append("ending cut theme before finished signal")
	)
	root.add_child(ending)
	current_scene = ending
	var deadline := Time.get_ticks_msec() + 290000
	while (current_scene == null or current_scene.scene_file_path != "res://scenes/Title.tscn") and Time.get_ticks_msec() < deadline:
		await process_frame
	if theme_finished == 0: failures.append("full song did not finish")
	var elapsed := float(theme_finished - theme_started) / 1000.0
	# Dummy audio and busy machines may deliver completion later than wall-clock
	# track length. Natural finished plus no early completion proves no cut.
	if elapsed < 213.5: failures.append("full song ended before its duration")
	if current_scene == null or current_scene.scene_file_path != "res://scenes/Title.tscn": failures.append("ending did not return to title")
	print("THEME_FULL_ENDING_CHECK elapsed=%.3f failures=%s" % [elapsed, JSON.stringify(failures)])
	if current_scene != null: current_scene.queue_free()
	await process_frame
	audio.stop_bgm()
	audio.bgm_player.stream = null
	await create_timer(0.3).timeout
	quit(0 if failures.is_empty() else 1)
