extends SceneTree

const CHECKPOINT := preload("res://scripts/ui/true_ending_checkpoint.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func run() -> void:
	check(CHECKPOINT.save_pending() == OK, "pending ending saved")
	change_scene_to_file("res://scenes/Title.tscn")
	await create_timer(0.1).timeout
	current_scene.continue_game()
	await create_timer(1.8).timeout
	check(current_scene != null and current_scene.scene_file_path == CHECKPOINT.SCENE, "continue restores film without boss replay")
	if current_scene != null and current_scene.scene_file_path == CHECKPOINT.SCENE:
		check(not ResourceLoader.has_cached("res://scenes/Player.tscn"), "continue has no combat load")
		check(not root.get_meta(&"st_action_continue_run", false), "continue flag consumed")
	CHECKPOINT.clear()
	check(not FileAccess.file_exists(CHECKPOINT.SAVE_PATH), "completion clears pending film")
	var cfg := ConfigFile.new()
	cfg.set_value("run", "scene", "res://scenes/TrueBattle.tscn")
	cfg.save(CHECKPOINT.SAVE_PATH)
	CHECKPOINT.clear()
	check(FileAccess.file_exists(CHECKPOINT.SAVE_PATH), "other save preserved")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CHECKPOINT.SAVE_PATH))
	print("TRUE_ENDING_CHECKPOINT_CHECK failures=", JSON.stringify(failures))
	current_scene.queue_free()
	for i in range(3): await process_frame
	var audio := root.get_node("AudioManager")
	audio.stop_bgm()
	audio.bgm_player.stream = null
	await create_timer(0.2).timeout
	quit(0 if failures.is_empty() else 1)
