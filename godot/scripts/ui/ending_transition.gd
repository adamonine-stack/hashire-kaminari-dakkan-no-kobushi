extends Node

# Lives outside the battle so its coroutine survives freeing the old scene.
func start(tree: SceneTree, target: String) -> void:
	tree.root.add_child(self)
	call_deferred("_run", tree, target)

func _run(tree: SceneTree, target: String) -> void:
	var old_scene := tree.current_scene
	tree.current_scene = null
	if is_instance_valid(old_scene): old_scene.queue_free()
	# Give deferred deletion and rendering a frame before loading ending art.
	await tree.process_frame
	await tree.process_frame
	var error := tree.change_scene_to_file(target)
	if error != OK: push_error("Could not load ending: %s" % error)
	queue_free()
