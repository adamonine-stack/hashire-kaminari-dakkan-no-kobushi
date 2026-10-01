extends SceneTree

const TITLE_SCENE := "res://scenes/Title.tscn"
const OPENING_SCENE := "res://scenes/Opening.tscn"
const BATTLE_SCENE := "res://scenes/Battle.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var title_error := change_scene_to_file(TITLE_SCENE)
	if title_error != OK:
		_fail("could not load title scene")
		return
	await process_frame
	var title := current_scene
	if title == null:
		_fail("title scene did not become current")
		return
	var start_button := title.get("game_start_button") as Button
	if start_button == null:
		_fail("title game-start button was not created")
		return
	start_button.pressed.emit()
	await create_timer(0.7).timeout
	if current_scene == null or current_scene.scene_file_path != OPENING_SCENE:
		_fail("new game did not open the opening scene")
		return
	var opening := current_scene
	var pages: Array = opening.get_script().get_script_constant_map().get("PAGES", [])
	if pages.size() < 5:
		_fail("opening dialogue pages are missing")
		return
	for _page in range(pages.size()):
		opening.call("advance")
		await process_frame
	await create_timer(0.3).timeout
	if current_scene == null or current_scene.scene_file_path != BATTLE_SCENE:
		_fail("opening did not continue to fighter selection")
		return
	print("OPENING_FLOW_OK pages=%d next=%s" % [pages.size(), BATTLE_SCENE])
	quit(0)


func _fail(message: String) -> void:
	push_error("OPENING_FLOW_FAIL %s" % message)
	quit(1)
