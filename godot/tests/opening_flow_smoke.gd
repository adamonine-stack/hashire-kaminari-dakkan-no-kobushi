extends SceneTree

const TITLE_SCENE := "res://scenes/Title.tscn"
const OPENING_SCENE := "res://scenes/Opening.tscn"
const BATTLE_SCENE := "res://scenes/Battle.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var title_packed := load(TITLE_SCENE) as PackedScene
	if title_packed == null:
		_fail("could not load title scene")
		return
	var title := title_packed.instantiate()
	root.add_child(title)
	await process_frame
	var requested_scenes: Array[String] = []
	title.connect("scene_transition_started", func(scene_path: String) -> void: requested_scenes.append(scene_path))
	var start_button := title.get("game_start_button") as Button
	if start_button == null:
		_fail("title game-start button was not created")
		return
	var save_path := ProjectSettings.globalize_path("user://save.cfg")
	var save_existed := FileAccess.file_exists(save_path)
	var previous_save := FileAccess.get_file_as_bytes(save_path) if save_existed else PackedByteArray()
	start_button.pressed.emit()
	if save_existed:
		var save_file := FileAccess.open(save_path, FileAccess.WRITE)
		if save_file != null:
			save_file.store_buffer(previous_save)
	await process_frame
	if requested_scenes.is_empty() or requested_scenes[0] != OPENING_SCENE:
		_fail("new game did not request the opening scene")
		return
	var opening_packed := load(OPENING_SCENE) as PackedScene
	if opening_packed == null:
		_fail("opening scene resource is missing")
		return
	var opening := opening_packed.instantiate()
	root.add_child(opening)
	await process_frame
	var pages: Array = opening.get_script().get_script_constant_map().get("PAGES", [])
	if pages.size() < 5:
		_fail("opening dialogue pages are missing")
		return
	for _page in range(pages.size()):
		opening.call("advance")
		await process_frame
	if not bool(opening.get("is_transitioning")):
		_fail("opening did not continue to fighter selection")
		return
	print("OPENING_FLOW_OK pages=%d next=%s" % [pages.size(), BATTLE_SCENE])
	quit(0)


func _fail(message: String) -> void:
	push_error("OPENING_FLOW_FAIL %s" % message)
	quit(1)
