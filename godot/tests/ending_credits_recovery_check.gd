extends SceneTree

const CHECKPOINT := preload("res://scripts/ui/ending_credits_checkpoint.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run_check")

func check(condition: bool, detail: String) -> void:
	if not condition: failures.append(detail)

func wait_for_scene(scene_path: String, maximum := 4.0) -> void:
	var until := Time.get_ticks_msec() + int(maximum * 1000)
	while (current_scene == null or current_scene.scene_file_path != scene_path) and Time.get_ticks_msec() < until:
		await process_frame
	check(current_scene != null and current_scene.scene_file_path == scene_path, "scene " + scene_path)

func run_check() -> void:
	# Simulate a browser being terminated while end-roll is active:
	# the next launch starts at Title, and CONTINUE must bring it back.
	for route in [CHECKPOINT.NORMAL, CHECKPOINT.BAD, CHECKPOINT.TRUE]:
		check(CHECKPOINT.save_pending(route) == OK, "checkpoint saved " + route)
		change_scene_to_file("res://scenes/Title.tscn")
		await wait_for_scene("res://scenes/Title.tscn")
		check(not current_scene.continue_button.disabled, "CONTINUE enabled " + route)
		root.set_meta(&"ending_credits_qa_scale", 0.006)
		current_scene.continue_game()
		await wait_for_scene(CHECKPOINT.SCENE)
		if current_scene == null or current_scene.scene_file_path != CHECKPOINT.SCENE: continue
		var credits = current_scene
		check(credits.ending_route == route, "recovered route " + route)
		check(credits.credits_started, "roll restarted " + route)
		check(not credits.credits_complete, "roll is not skipped on recovery " + route)
		check(credits.get_children().size() == 2, "credits scene has no CG or fighters " + route)
		check(CHECKPOINT.load_route() == route, "checkpoint retained during roll " + route)
		await create_timer(0.48).timeout
		check(credits.credits_complete, "roll completed " + route)
		check(current_scene == credits, "roll stays on screen " + route)
		check(CHECKPOINT.load_route() == route, "checkpoint remains after roll " + route)
		if route == CHECKPOINT.BAD:
			check(credits.header.text == "BAD END", "bad ending heading")
		elif route == CHECKPOINT.TRUE:
			check(credits.header.text == "TRUE ENDING", "true ending heading")
		else:
			check(credits.header.text == "TO BE CONTINUED…", "normal heading")
		var tap := InputEventScreenTouch.new()
		tap.pressed = true
		tap.index = 0
		tap.position = Vector2(422, 195)
		Input.parse_input_event(tap)
		await wait_for_scene("res://scenes/Title.tscn", 4.0)
		check(not CHECKPOINT.is_pending(), "only explicit title exit clears checkpoint " + route)
		check(current_scene != null and current_scene.continue_button.disabled, "CONTINUE disabled after exit " + route)
	print("ENDING_CREDITS_RECOVERY_CHECK failures=%s" % JSON.stringify(failures))
	if current_scene != null: current_scene.queue_free()
	await process_frame
	var audio = root.get_node("AudioManager")
	audio.stop_bgm()
	audio.bgm_player.stream = null
	await create_timer(0.3).timeout
	quit(0 if failures.is_empty() else 1)
