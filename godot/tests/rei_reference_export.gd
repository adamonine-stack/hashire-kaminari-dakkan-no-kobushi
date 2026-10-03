extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var actor: Node=load("res://scenes/Player.tscn").instantiate()
	root.add_child(actor)
	await process_frame
	actor.set_physics_process(false)
	var base := ProjectSettings.globalize_path("res://").path_join("../art_sources/rei_reversal_v1/references").simplify_path()
	for pair in [["rei","enemies/enemy_04_throw"],["akky","fighters/ally_balance"],["gou","fighters/ally_power"],["seiya","fighters/ally_speed"]]:
		actor.apply_character_data(load("res://data/%s.tres" % pair[1]))
		var texture: Texture2D=actor.animated_character_sprite.sprite_frames.get_frame_texture(&"idle",0)
		assert(texture.get_image().save_png(base.path_join(pair[0]+".png"))==OK)
		print("REI_REFERENCE ",pair[0]," texture=",texture.get_size()," scale=",actor.animated_character_sprite.scale," pivot=",actor.animated_character_sprite.position)
	actor.queue_free()
	await process_frame
	quit()
