extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var flow := root.get_node("StoryFlow")
	flow.call("start_new_game")
	var expected := [
		["player_01_akky", "player_02_gou", "player_03_seiya"],
		["player_01_akky", "player_02_gou"],
		["player_01_akky", "player_03_seiya"],
		["player_02_gou", "player_03_seiya"],
		["player_01_akky"],
		["player_02_gou"],
		["player_03_seiya"],
	]
	var failures: Array[String] = []
	for survivors in expected:
		flow.call("prepare_ending", survivors)
		var lines: Array = flow.get("ending_lines")
		var joined := " ".join(lines.map(func(line: Dictionary) -> String: return String(line.get("text", ""))))
		var missing_count: int = 3 - survivors.size()
		if bool(flow.get("all_survivors_clear")) != (missing_count == 0): failures.append("all_survivors flag %s" % str(survivors))
		var rescued_text := ""
		for line in lines:
			if String(line.get("text", "")).begins_with("救出できた：") or String(line.get("text", "")).begins_with("救出した："):
				rescued_text = String(line.get("text", ""))
		for hero in survivors:
			var target_name: String = {"player_01_akky":"アッキーの恋人", "player_02_gou":"ごうの弟", "player_03_seiya":"せいやの妹"}[hero]
			if not rescued_text.contains(target_name): failures.append("wrong rescued target %s" % target_name)
		if missing_count == 0:
			if not joined.contains("全員そろってる") or not joined.contains("TO BE CONTINUED"):
				failures.append("full rescue %s" % str(survivors))
		else:
			if not joined.contains("邪悪なオーラを纏った男") or not joined.contains("一体誰が") or not joined.contains("TO BE CONTINUED"):
				failures.append("mystery ending %s" % str(survivors))
			if bool(lines.any(func(line: Dictionary) -> bool: return bool(line.get("silhouette", false)))) != true:
				failures.append("silhouette %s" % str(survivors))
	flow.call("start_new_game")
	if (flow.get("opening_lines") as Array).size() < 20:
		failures.append("opening dialogue missing")
	var opening_scene := load("res://scenes/StoryEvent.tscn") as PackedScene
	var scene_error := change_scene_to_packed(opening_scene)
	for _frame in range(3): await process_frame
	var opening_ui := root.get_node_or_null("StoryEvent")
	if scene_error != OK: failures.append("opening change scene error %d" % scene_error)
	if opening_ui == null or opening_ui.get("lines").size() < 20:
		failures.append("opening scene did not load")
	else:
		opening_ui.call("_skip")
		await create_timer(0.8).timeout
		if current_scene == null or current_scene.scene_file_path != "res://scenes/Battle.tscn":
			failures.append("opening skip did not reach battle")
		flow.call("prepare_ending", ["player_01_akky"])
		change_scene_to_packed(opening_scene)
		for _frame in range(3): await process_frame
		var ending_ui := root.get_node_or_null("StoryEvent")
		if ending_ui == null or ending_ui.get("lines").is_empty():
			failures.append("ending scene did not load")
		else:
			ending_ui.call("_skip")
			await create_timer(1.5).timeout
			if current_scene == null or current_scene.scene_file_path != "res://scenes/Title.tscn":
				failures.append("ending did not return to title: %s" % ("null" if current_scene == null else current_scene.scene_file_path))
	print("STORY_BRANCH_CHECK failures=%s" % JSON.stringify(failures))
	quit(1 if not failures.is_empty() else 0)
