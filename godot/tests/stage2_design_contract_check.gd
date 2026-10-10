extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func run() -> void:
	var definition: Resource = load("res://data/enemies/enemy_04_throw.tres")
	var before: Resource = load("res://tests/fixtures/stage2_design/rei_before.tres")
	for property in ["max_health","move_speed","jump_force","attack_speed_scale","punch_damage_scale","kick_damage_scale","throw_damage_scale","knockback_scale","combo_damage_scale","guard_damage_scale","sprite_body_height_px","character_height_cm","battle_sprite_height","visual_scale_adjustment"]:
		check(definition.get(property) == before.get(property),"preserved " + property)
	for property in ["attack_sequence","air_kick_attack","air_punch_down_attack","crouch_kick_sweep_attack","special_attack_sequence","special_damage_reactions"]:
		check(definition.get(property) == before.get(property),"preserved combat resource " + property)
	var actor: Node2D = load("res://scenes/Player.tscn").instantiate()
	root.add_child(actor)
	actor.set_physics_process(false)
	actor.apply_fighter_definition(definition)
	var sprite: AnimatedSprite2D = actor.animated_character_sprite
	var scale := sprite.scale
	var master: Texture2D = load("res://assets/characters/enemy04/animations/rei_v1/motion_atlas.png")
	var mapping := {"received_akky_elbow_hit":[24],"received_akky_elbow_air":[24,25],"received_akky_elbow_down":[26],"received_akky_elbow_wall":[25],"received_akky_elbow_fall":[24],"received_gou_breaker_hit":[24],"received_gou_breaker_air":[25],"received_gou_breaker_down":[26],"received_seiya_somersault_hit":[24],"received_seiya_somersault_air":[25],"received_seiya_somersault_fall":[25],"received_seiya_somersault_down":[26],"received_seiya_two_lift":[24],"received_seiya_two_fall":[25],"received_seiya_two_fly":[25],"received_seiya_two_down":[26]}
	var checked := 0
	for clip in sprite.sprite_frames.get_animation_names():
		for facing in [1,-1]:
			actor.facing_direction = facing
			actor._set_visual_facing()
			actor._play_visual_animation(clip,true)
			check(sprite.scale.is_equal_approx(scale),"fixed scale " + String(clip))
			for index in range(sprite.sprite_frames.get_frame_count(clip)):
				var texture := sprite.sprite_frames.get_frame_texture(clip,index) as AtlasTexture
				check(texture.get_size() == Vector2(768,640),"common canvas " + String(clip))
				if String(clip) in mapping:
					var source: int = mapping[String(clip)][index]
					var region := Rect2i((source%6)*320,(source/6)*300,320,300)
					check(texture.region == Rect2(region),"official source region " + String(clip))
					check(texture.get_image().get_data() == master.get_image().get_region(region).get_data(),"exact body/head/limb pixels " + String(clip))
				checked += 1
	check(sprite.sprite_frames.has_animation(&"jump_ascent"),"Rei opts into actual velocity air phase routing")
	actor.queue_free()
	await process_frame
	print("STAGE2_DESIGN_CONTRACT frames=",checked," failures=",failures)
	quit(0 if failures.is_empty() else 1)
