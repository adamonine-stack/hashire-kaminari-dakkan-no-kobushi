extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var actors: Array[Node2D] = []
	for canvas in [Vector2i(512,448),Vector2i(768,640)]:
		var definition: Resource = load("res://data/fighters/ally_speed.tres").duplicate()
		definition.motion_display_canvas_size = canvas
		var actor: Node2D = load("res://scenes/Player.tscn").instantiate()
		root.add_child(actor)
		actor.set_physics_process(false)
		actor.apply_fighter_definition(definition)
		actors.append(actor)
	var reference: AnimatedSprite2D = actors[0].animated_character_sprite
	var padded: AnimatedSprite2D = actors[1].animated_character_sprite
	var checked := 0
	for clip in padded.sprite_frames.get_animation_names():
		for frame in range(padded.sprite_frames.get_frame_count(clip)):
			for actor in actors:
				actor._play_visual_animation(clip,true)
				actor.animated_character_sprite.pause()
				actor.animated_character_sprite.frame = frame
				actor.get_node("SeiyaProportions").update_head()
			if reference.material.get_shader_parameter("neck_direction") != padded.material.get_shader_parameter("neck_direction"):
				failures.append("neck direction changed by display margin: %s/%d" % [clip,frame])
			if reference.material.get_shader_parameter("head_rect") != padded.material.get_shader_parameter("head_rect"):
				failures.append("head UV changed by display margin: %s/%d" % [clip,frame])
			if reference.material.get_shader_parameter("head_anchor") != padded.material.get_shader_parameter("head_anchor"):
				failures.append("head anchor changed by display margin: %s/%d" % [clip,frame])
			if reference.scale != padded.scale or reference.position != padded.position:
				failures.append("body transform changed by display margin: %s/%d" % [clip,frame])
			checked += 1
	print("SEIYA_SOURCE_BASIS_CHECK frames=",checked," failures=",failures)
	for actor in actors: actor.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
