extends "res://tests/special_launch_reaction_check.gd"

func _initialize() -> void:
	evidence_folder = "akky_wall_launch_final"
	super._initialize()

func extra_checks(manager: Node, attacker: Node, target: Node) -> void:
	for definition in victim_definitions:
		target.apply_character_data(load("res://data/enemies/%s.tres" % definition))
		for direction in [1,-1]:
			for distance_case in ["far","near"]:
				await reset(manager,target,Vector2(640,520),-direction)
				target._cache_special_reaction_edge_padding()
				# Use the same full-art limits as runtime, with room for the attack.
				var packet: Dictionary = attacker._get_character_special_attack_dictionary()
				target.last_special_knockback_animation = target._get_special_received_animation(packet,"airborne")
				target.last_knockdown_animation = target._get_special_received_animation(packet,"down")
				target._cache_special_reaction_edge_padding()
				var left: float = target.stage_left_limit + maxf(target.fighter_body_half_width,target.special_reaction_edge_padding.x)+8
				var right: float = target.stage_right_limit - maxf(target.fighter_body_half_width,target.special_reaction_edge_padding.y)-8
				var x: float = (left+20 if direction > 0 else right-20) if distance_case == "far" else (right-20 if direction > 0 else left+20)
				await reset(manager,target,Vector2(x,520),-direction)
				await reset(manager,attacker,Vector2(x-120*direction,520),direction)
				attacker.set_physics_process(false)
				var hp_before: int = target.current_hp
				check(target.receive_attack(packet,direction,target.global_position,attacker),definition + distance_case + " wall launch connects")
				left = target.special_wall_screen_limits.x + maxf(target.fighter_body_half_width,target.special_reaction_edge_padding.x)+8
				right = target.special_wall_screen_limits.y - maxf(target.fighter_body_half_width,target.special_reaction_edge_padding.y)-8
				var impact_seen := false
				for frame in range(240):
					await physics_frame
					if target.special_wall_phase == "impact":
						impact_seen = true
						check(absf(target.position.x-(right if direction>0 else left))<1.0,definition + distance_case + " reaches opposite wall")
					if target.knockdown_state == &"KNOCKDOWN": break
				check(impact_seen and target.special_wall_contacts == 1 and target.knockdown_state == &"KNOCKDOWN",definition + distance_case + " complete wall/drop sequence")
				check(target.current_hp == hp_before-int(packet.damage),definition + distance_case + " no extra wall damage")
				check_visible_art(target.animated_character_sprite,definition + distance_case + " grounded art")
	print("AKKY_WALL_RANGE_CHECK cases=36 failures=%s" % [failures])
