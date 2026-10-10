extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var checked := 0
	for fighter in ["ally_power", "ally_speed"]:
		var actors: Array[Node2D] = []
		for canvas in [Vector2i.ZERO,Vector2i(768,640)]:
			var definition: Resource = load("res://data/fighters/"+fighter+".tres").duplicate()
			definition.motion_display_canvas_size = canvas
			var actor: Node2D = load("res://scenes/Player.tscn").instantiate()
			root.add_child(actor)
			actor.set_physics_process(false)
			actor.apply_fighter_definition(definition)
			actors.append(actor)
		var frames: SpriteFrames = actors[1].animated_character_sprite.sprite_frames
		for clip in frames.get_animation_names():
			for facing in [1,-1]:
				var edges: Array[Vector2] = []
				for actor in actors:
					actor.facing_direction = facing
					actor._set_visual_facing()
					actor.last_special_knockback_animation = clip
					actor.last_knockdown_animation = &"down"
					actor._cache_special_reaction_edge_padding()
					edges.append(actor.special_reaction_edge_padding)
				if not edges[0].is_equal_approx(edges[1]):
					failures.append("display margin changes stage clamp: %s/%s/%d" % [fighter,clip,facing])
				for index in range(frames.get_frame_count(clip)):
					var centers: Array[Vector2] = []
					for actor in actors:
						var sprite: AnimatedSprite2D = actor.animated_character_sprite
						var texture: Texture2D = sprite.sprite_frames.get_frame_texture(clip,index)
						var center: Vector2 = Vector2(texture.get_image().get_used_rect().get_center())+actor._texture_display_offset(texture)-texture.get_size()*0.5
						if sprite.flip_h: center.x = -center.x
						centers.append(sprite.global_transform*(center+sprite.offset))
					if not centers[0].is_equal_approx(centers[1]):
						failures.append("display margin changes rotation center: %s/%s/%d/%d" % [fighter,clip,index,facing])
					checked += 1
		for actor in actors: actor.queue_free()
		await process_frame
	print("HERO_MARGIN_PHYSICS_CHECK frames=",checked," failures=",failures)
	quit(0 if failures.is_empty() else 1)
