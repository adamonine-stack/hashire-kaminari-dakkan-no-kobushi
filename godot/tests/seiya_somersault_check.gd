extends "res://tests/special_launch_reaction_check.gd"

func _initialize() -> void:
	attacker_definition = "ally_speed"
	reaction_prefix = "received_seiya_somersault"
	evidence_folder = "seiya_somersault_head_contact_final"
	dedicated_attack_clips = ["seiya_somersault_startup","seiya_somersault_kick","seiya_somersault_landing"]
	attack_original_folder = "somersault_v1"
	minimum_launch_velocity = 100.0
	minimum_flight_distance = 20.0
	maximum_flight_distance = 420.0
	minimum_flight_height = 160.0
	maximum_flight_height = 210.0
	super._initialize()

func extra_checks(manager: Node,attacker: Node,target: Node) -> void:
	await reset(manager,attacker,Vector2(520,520),1)
	await reset(manager,target,Vector2(950,520),-1)
	target.set_physics_process(false)
	attacker.input_enabled = true
	Input.action_press("move_right")
	attacker.set_special_gauge(100.0)
	attacker.start_character_special()
	attacker.enter_character_special_active()
	var sprite: AnimatedSprite2D = attacker.animated_character_sprite
	var scale_before := sprite.scale
	var anchor: Vector2 = attacker.position
	var idle_area := opaque_body_area(sprite.sprite_frames.get_frame_texture(&"idle",0))
	for clip in dedicated_attack_clips:
		for index in range(sprite.sprite_frames.get_frame_count(clip)):
			var area := opaque_body_area(sprite.sprite_frames.get_frame_texture(clip,index))
			print("SEIYA_BODY_AREA %s%d idle=%.0f pose=%.0f ratio=%.3f" % [clip,index,idle_area,area,area/idle_area])
			check(area/idle_area>0.97 and area/idle_area<1.03,"size-corrected Seiya body preserved "+clip+str(index))
	var previous_turn := 0.0
	var saw_inverted := false
	var saw_return := false
	for frame in range(55):
		await physics_frame
		check(absf(attacker.position.x-anchor.x)<0.5,"in-place somersault never travels horizontally")
		check(sprite.scale.is_equal_approx(scale_before),"somersault keeps corrected Sprite scale")
		if attacker.character_special_state == attacker.CharacterSpecialState.ACTIVE:
			check(attacker.seiya_somersault_turn>=previous_turn,"continuous backward somersault")
			previous_turn = attacker.seiya_somersault_turn
			if sprite.frame == 1: saw_inverted = true
			if sprite.frame == 2: saw_return = true
			if frame%3==0: await capture("attacker_flip_%03d" % frame)
		else: break
	print("SEIYA_TURN inverted=%s return=%s last=%.3f" % [saw_inverted,saw_return,previous_turn])
	Input.action_release("move_right")
	check(saw_inverted and saw_return and previous_turn>TAU-0.25,"somersault passes approved inverted frame and completes one turn")
	check(is_zero_approx(sprite.rotation) and sprite.offset.is_zero_approx(),"attacker landing restores normal corrected transform")
