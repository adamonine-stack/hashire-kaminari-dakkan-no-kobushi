extends SceneTree

const CHECKPOINT := preload("res://scripts/ui/stage8_ending_checkpoint.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func run() -> void:
	for mask in range(1, 8):
		var snapshot: Array = []
		for index in range(3):
			var alive := (mask & (1 << index)) != 0
			snapshot.append({"character_id": CHECKPOINT.IDS[index], "current_health": 27 if alive else 0, "max_health": 100, "is_defeated": not alive, "special_gauge": 42.0})
		check(CHECKPOINT.save_snapshot(snapshot) == OK, "save %d" % mask)
		root.remove_meta(CHECKPOINT.META) if root.has_meta(CHECKPOINT.META) else null
		change_scene_to_file("res://scenes/Title.tscn")
		await create_timer(0.1).timeout
		current_scene.continue_game()
		await create_timer(1.8).timeout
		check(current_scene.scene_file_path == CHECKPOINT.SCENE, "continue ending %d" % mask)
		if current_scene.scene_file_path != CHECKPOINT.SCENE: continue
		check(current_scene.stage8_snapshot == snapshot, "health and survivors restored %d" % mask)
		check(not root.get_meta(&"st_action_continue_run", false), "consume continue request")
		check(current_scene.route == {1:"A",2:"B",3:"D",4:"C",5:"E",6:"F",7:"G"}[mask], "restored route %d" % mask)
		print("STAGE8_CHECKPOINT_ROUTE ", mask)
	CHECKPOINT.clear()
	check(not FileAccess.file_exists(CHECKPOINT.SAVE_PATH), "completion clears checkpoint")
	# A newly written true-battle save must not be deleted by ending completion.
	var cfg := ConfigFile.new()
	cfg.set_value("run", "scene", "res://scenes/TrueBattle.tscn")
	cfg.save(CHECKPOINT.SAVE_PATH)
	CHECKPOINT.clear()
	check(FileAccess.file_exists(CHECKPOINT.SAVE_PATH), "preserve true-battle save")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CHECKPOINT.SAVE_PATH))
	print("STAGE8_CHECKPOINT_CHECK failures=", JSON.stringify(failures))
	current_scene.queue_free()
	for frame in range(3): await process_frame
	var audio = root.get_node("AudioManager")
	audio.stop_bgm()
	for sound in audio.se_players:
		sound.stop()
		sound.stream = null
	audio.bgm_player.stream = null
	await create_timer(0.3).timeout
	quit(0 if failures.is_empty() else 1)
