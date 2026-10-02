extends "res://tests/crusher_web_qa_base.gd"

func _initialize() -> void:
	attacker_definition = "enemy_01_standard"
	attacker_definition_folder = "enemies"
	victim_definition_folder = "fighters"
	attacker_node_name = "Enemy"
	victim_node_name = "Player"
	victim_definitions = ["ally_balance","ally_power","ally_speed"]
	reaction_prefix = "received_crusher_hammer"
	evidence_folder = "crusher_reversal_final"
	dedicated_attack_clips = ["crusher_hammer_startup","crusher_hammer_active","crusher_hammer_finish"]
	attack_original_folder = "reversal_v1"
	minimum_contact_height = 40.0
	super._initialize()

func reset(manager: Node, actor: Node, point: Vector2, facing: int) -> void:
	await super.reset(manager,actor,point,facing)
	actor._clear_guard_state()
	actor.is_guard_hit = false
	actor.guard_recoil_timer = 0.0
	actor.is_hit = false
	actor.hit_reaction_timer = 0.0
	actor.ai_enabled = false
	actor.input_enabled = false

func capture(label: String) -> void:
	await super.capture(label)
	print("CRUSHER_CAPTURE "+label)

func extra_checks(manager: Node, attacker: Node, target: Node) -> void:
	for definition in victim_definitions:
		target.apply_character_data(load("res://data/fighters/%s.tres" % definition))
		var sprite: AnimatedSprite2D = target.animated_character_sprite
		var idle_area := opaque_body_area(sprite.sprite_frames.get_frame_texture(&"idle",0))
		for clip in ["received_crusher_hammer_hit","received_crusher_hammer_air","received_crusher_hammer_down","received_crusher_hammer_guard"]:
			for frame in range(sprite.sprite_frames.get_frame_count(clip)):
				var ratio := opaque_body_area(sprite.sprite_frames.get_frame_texture(clip,frame))/idle_area
				check(ratio > 0.90 and ratio < 1.10,definition+" retains anatomical body mass "+clip)
		for direction in [1,-1]:
			await reset(manager,attacker,Vector2(640-180*direction,520),direction)
			attacker.set_physics_process(false)
			await reset(manager,target,Vector2(640,520),-direction)
			target.set_physics_process(false)
			target.is_guarding = true
			target.guard_type = "high"
			var hp: float = target.current_hp
			var packet: Dictionary = attacker._get_character_special_attack_dictionary()
			check(not target.receive_attack(packet,direction,target.global_position,attacker),definition+" blocks hammer")
			check(target.current_hp == hp,definition+" guard has zero chip damage")
			target._update_visual_state()
			check(sprite.animation == &"received_crusher_hammer_guard",definition+" dedicated hammer guard")
			check_visible_art(sprite,definition+" guard")
			await capture(definition+"_guard_"+str(direction))
	await reset(manager,attacker,Vector2(600,520),1)
	await reset(manager,target,Vector2(660,520),-1)
	attacker.set_physics_process(false)
	target.set_physics_process(false)
	attacker.set_special_gauge(100)
	attacker.reversal_cooldown = 0.0
	attacker.ai_enabled = true
	attacker.is_hit = true
	attacker.special_ai_use_chance = 10.0 # Deterministic exercise of the real situational AI branch.
	attacker.reversal_ai_checked = false
	attacker.reversal_ai_observation = 0.11
	attacker._try_observed_special_reversal()
	check(not attacker.is_character_special_busy(),"Crusher AI waits for observed hit delay")
	attacker.reversal_ai_observation = 0.13
	attacker._try_observed_special_reversal()
	check(attacker.is_character_special_busy(),"Crusher AI reverses observed hitstun")
	attacker._update_visual_state()
	check(attacker.animated_character_sprite.animation == &"crusher_hammer_startup","Crusher AI uses authored windup")
	await capture("crusher_ai_reversal")
	attacker.ai_enabled = false
