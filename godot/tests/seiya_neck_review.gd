extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var actor=load("res://scenes/Player.tscn").instantiate()
	root.add_child(actor)
	actor.set_physics_process(false)
	actor.position=Vector2(640,540)
	actor.apply_character_data(load("res://data/enemies/enemy_09_seiya.tres"))
	actor.aura_controller.queue_free()
	var sprite: AnimatedSprite2D=actor.animated_character_sprite
	for sample in [["seiya_two_somersault",1,"inverted"],["received_seiya_two_fly",0,"horizontal"],["received_seiya_two_down",0,"prone"],["idle",0,"idle"]]:
		actor._play_visual_animation(StringName(sample[0]),true)
		sprite.pause()
		sprite.frame=sample[1]
		await process_frame
		await process_frame
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/stage9/neck_fixed_"+sample[2]+".png"))
		print("SEIYA_NECK_REVIEW ",sample[2]," rect=",actor.get_node("SeiyaProportions").head_bounds," neck=",sprite.material.get_shader_parameter("neck_direction"))
	actor.queue_free()
	await process_frame
	quit()
