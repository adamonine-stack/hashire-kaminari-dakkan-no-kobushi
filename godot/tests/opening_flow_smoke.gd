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
	title.free()
	await process_frame
	var opening_packed := load(OPENING_SCENE) as PackedScene
	if opening_packed == null:
		_fail("opening scene resource is missing")
		return
	var opening := opening_packed.instantiate()
	root.add_child(opening)
	await process_frame
	var backdrop := opening.get_child(0) as ColorRect
	if backdrop == null or backdrop.color == Color.BLACK:
		_fail("opening night backdrop was not created")
		return
	var pages: Array = opening.get_script().get_script_constant_map().get("PAGES", [])
	if pages.size() != 26:
		_fail("opening dialogue must contain the original 26 lines")
		return
	if pages[0].get("text") != "来てくれたか。二人とも、話がある。" or pages[11].get("text") != "ブラックスパロウだ。" or pages[25].get("text") != "行こう。":
		_fail("opening dialogue does not match the planned story")
		return
	var portraits: Array = opening.get("character_portraits")
	if portraits.size() != 3:
		_fail("opening character portraits are missing")
		return
	for portrait in portraits:
		if portrait.texture == null:
			_fail("an opening character portrait did not load")
			return
	var safe_content := opening.get("safe_content") as Control
	if safe_content == null or safe_content.offset_left < 72.0 or safe_content.offset_top < 80.0:
		_fail("opening controls are not inset from mobile camera cutouts")
		return
	for _page in range(pages.size() - 1):
		opening.call("advance")
		await process_frame
	if int(opening.get("page_index")) != pages.size() - 1 or opening.get("story_label").text != "行こう。":
		_fail("the final planned dialogue line was not displayed")
		return
	if opening.get("next_button").text != "ゲームを始める":
		_fail("the final opening action was not presented")
		return
	# The final key event changes scenes synchronously. Handling that input must
	# happen before the opening leaves the tree, while its viewport still exists.
	current_scene = opening
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	opening.call("_unhandled_input", accept)
	await process_frame
	await process_frame
	if current_scene == null or current_scene.scene_file_path != BATTLE_SCENE:
		_fail("final opening key did not enter fighter selection")
		return
	var manager := current_scene.get_node_or_null("BattleManager")
	if manager != null:
		manager.cleanup_battle_before_transition()
	print("OPENING_FLOW_OK pages=%d next=%s" % [pages.size(), BATTLE_SCENE])
	quit(0)


func _fail(message: String) -> void:
	push_error("OPENING_FLOW_FAIL %s" % message)
	quit(1)
