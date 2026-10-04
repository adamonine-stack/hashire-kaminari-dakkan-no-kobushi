extends "res://tests/special_launch_reaction_check.gd"

func _initialize() -> void:
	attacker_definition = "enemy_07_tricky"
	attacker_definition_folder = "enemies"
	victim_definition_folder = "fighters"
	attacker_node_name = "Enemy"
	victim_node_name = "Player"
	victim_definitions = ["ally_balance","ally_power","ally_speed"]
	reaction_prefix = "received_teki_palm"
	evidence_folder = "teki_reversal_final"
	dedicated_attack_clips = ["teki_deadly_startup","teki_deadly_hand","teki_deadly_finish"]
	attack_original_folder = "teki_reversal_v1"
	minimum_launch_velocity = 350.0
	minimum_flight_distance = 100.0
	minimum_contact_height = 100.0
	minimum_flight_height = 20.0
	maximum_flight_height = 80.0
	super._initialize()

func reset(manager: Node, actor: Node, point: Vector2, facing: int) -> void:
	if manager.current_enemy_index != 2:
		manager.current_enemy_index = 2
		manager._apply_current_stage_definition()
		manager._update_battle_hud_enemy()
	if actor.name == "Enemy":actor.max_hp = int(manager.enemy_team[2].max_health)
	if actor.name == "Player" and actor.fighter_definition != null:
		var index := victim_definitions.find(actor.fighter_definition.resource_path.get_file().get_basename())
		if index >= 0:
			manager.current_player_index = index
			actor.max_hp = int(manager.player_team[index].max_health)
			manager._update_battle_hud_player()
	for member in manager.player_team:
		member.current_health = mini(int(member.current_health),int(member.max_health))
	var controller: Node = manager.get_parent()
	if controller != null:
		for label in controller.damage_number_pool:
			controller._stop_damage_number_tween(label)
			controller._recycle_damage_number_label(label)
	for effect in root.find_children("*","Node2D",true,false):
		if effect.get_script() == load("res://scripts/combat/reversal_effect.gd"): effect.queue_free()
	await super.reset(manager,actor,point,facing)
	actor._clear_guard_state()
	actor.is_guard_hit = false
	actor.guard_recoil_timer = 0.0
	actor.is_hit = false
	actor.hit_reaction_timer = 0.0
	actor.ai_enabled = false
	actor.input_enabled = false
	actor.hp_changed.emit(actor.current_hp,actor.max_hp)

func extra_checks(manager: Node, attacker: Node, target: Node) -> void:
	var attack_sprite: AnimatedSprite2D = attacker.animated_character_sprite
	var idle_area := opaque_body_area(attack_sprite.sprite_frames.get_frame_texture(&"idle",0))
	for clip in dedicated_attack_clips:
		for frame in range(attack_sprite.sprite_frames.get_frame_count(clip)):
			var ratio := opaque_body_area(attack_sprite.sprite_frames.get_frame_texture(clip,frame))/idle_area
			check(ratio > 0.9 and ratio < 1.1,"Teki maintains body mass "+clip)
	for definition in victim_definitions:
		target.apply_character_data(load("res://data/fighters/%s.tres" % definition))
		var sprite: AnimatedSprite2D = target.animated_character_sprite
		idle_area = opaque_body_area(sprite.sprite_frames.get_frame_texture(&"idle",0))
		for clip in ["received_teki_palm_hit","received_teki_palm_air","received_teki_palm_down","received_teki_palm_guard"]:
			for frame in range(sprite.sprite_frames.get_frame_count(clip)):
				var ratio := opaque_body_area(sprite.sprite_frames.get_frame_texture(clip,frame))/idle_area
				check(ratio > 0.9 and ratio < 1.1,definition+" body mass "+clip)
		for direction in [1,-1]:
			var label: String = definition+"_"+str(direction)
			# Run startup -> area overlap -> interruption -> recovery on physics clocks.
			await reset(manager,attacker,Vector2(640-75*direction,520),direction)
			await reset(manager,target,Vector2(640,520),-direction)
			attacker.set_special_gauge(100)
			attacker.reversal_cooldown = 0.0
			target.request_punch_attack()
			target.set_physics_process(false) # Hold attack until palm interrupts it.
			var hp: int = target.current_hp
			attacker.start_character_special()
			check(attacker.special_gauge == 0,"Teki consumes MAX meter")
			var impact_captured := false
			var observed_frames := {}
			for frame in range(80):
				await physics_frame
				var clip: String = attack_sprite.animation
				if clip in dedicated_attack_clips:
					observed_frames[clip] = maxi(int(observed_frames.get(clip,0)),attack_sprite.frame)
					var key := clip+"_"+str(attack_sprite.frame)
					if direction == 1 and not observed_frames.has(key):
						observed_frames[key] = true
						await capture(label+"_sequence_"+key)
				if target.current_hp < hp and not impact_captured:
					check(target.current_hp == hp-11,label+" actual collision damage 11")
					check(target.current_attack_type.is_empty(),label+" cancels normal attack")
					check(target.knockdown_state == &"KNOCKBACK",label+" actual collision launches")
					target._update_visual_state()
					await capture(label+"_natural_interrupt")
					target.set_physics_process(true)
					impact_captured = true
				if impact_captured and not attacker.is_character_special_busy(): break
			for clip in dedicated_attack_clips:
				check(observed_frames.get(clip,-1) == attack_sprite.sprite_frames.get_frame_count(clip)-1,label+" naturally reaches last frame "+clip)
			check(impact_captured,label+" physical area contact from natural startup")
			check(not attacker.is_character_special_busy(),label+" actual recovery completes")
			await capture(label+"_natural_recovered")
			# Real blocked contact, then full attacker recovery longer than guard hit.
			await reset(manager,attacker,Vector2(640-75*direction,520),direction)
			await reset(manager,target,Vector2(640,520),-direction)
			target.is_guarding = true
			target.guard_type = "high"
			target.set_physics_process(false)
			attacker.set_special_gauge(100)
			attacker.start_character_special()
			hp = target.current_hp
			var guard_seen := false
			for frame in range(65):
				await physics_frame
				if target.is_guard_hit and not guard_seen:
					target._update_visual_state()
					check(sprite.animation == &"received_teki_palm_guard",label+" dedicated guard")
					check(target.current_hp == hp-2,label+" existing 15 percent chip rounds to 2")
					check(target.knockdown_state == &"",label+" guard never launches")
					check(attacker.reversal_connected,label+" guard registers contact")
					await capture(label+"_natural_guard")
					guard_seen = true
				if guard_seen and attacker.character_special_state == attacker.CharacterSpecialState.RECOVERY:
					check(attacker.character_special_timer > attacker.character_special_data.guard_hit_time,label+" guard recovers before attacker")
					break
			check(guard_seen,label+" natural guard contact")
			# Natural whiff cannot hit a distant defender and has extra recovery.
			await reset(manager,attacker,Vector2(320,520),1)
			await reset(manager,target,Vector2(1000,520),-1)
			attacker.set_special_gauge(100)
			attacker.start_character_special()
			hp = target.current_hp
			for frame in range(60):
				await physics_frame
				if attacker.character_special_state == attacker.CharacterSpecialState.RECOVERY: break
			check(not attacker.reversal_connected and target.current_hp == hp,label+" whiff stays whiff")
			check(attacker.character_special_timer > 0.65,label+" whiff recovery about 0.6875s")
			await capture(label+"_whiff")
			# The full silhouette stays visible when launched near either wall.
			await reset(manager,attacker,Vector2(640,520),direction)
			await reset(manager,target,Vector2(1050 if direction > 0 else 230,520),-direction)
			attacker.set_physics_process(false)
			var wall_packet: Dictionary = attacker._get_character_special_attack_dictionary()
			check(target.receive_attack(wall_packet,direction,target.global_position,attacker),label+" wall hit accepted")
			for frame in range(130):
				await physics_frame
				check_visible_art(sprite,label+" wall flight")
				if target.knockdown_state == &"KNOCKDOWN": break
			check(target.knockdown_state == &"KNOCKDOWN",label+" wall flight lands safely")
			await capture(label+"_wall_down")
	# Real situational AI is permitted to reverse only after observing hitstun.
	await reset(manager,attacker,Vector2(600,520),1)
	await reset(manager,target,Vector2(660,520),-1)
	attacker.set_physics_process(false)
	target.set_physics_process(false)
	attacker.set_special_gauge(100)
	attacker.reversal_cooldown = 0.0
	attacker.ai_enabled = true
	attacker.is_hit = true
	attacker.special_ai_use_chance = 10.0
	attacker.reversal_ai_checked = false
	attacker.reversal_ai_observation = 0.11
	attacker._try_observed_special_reversal()
	check(not attacker.is_character_special_busy(),"Teki AI cannot read immediate input")
	attacker.reversal_ai_observation = 0.13
	attacker._try_observed_special_reversal()
	check(attacker.is_character_special_busy(),"Teki AI reverses observed hitstun")
	attacker._update_visual_state()
	check(attack_sprite.animation == &"teki_deadly_startup","AI uses dedicated palm startup")
	await capture("teki_ai_reversal")
	attacker.ai_enabled = false
	# Both contacts are snapshotted before either special interrupts the other.
	for definition in victim_definitions:
		target.apply_character_data(load("res://data/fighters/%s.tres" % definition))
		await reset(manager,attacker,Vector2(570,520),1)
		await reset(manager,target,Vector2(640,520),-1)
		attacker.set_physics_process(false)
		target.set_physics_process(false)
		attacker.set_special_gauge(100)
		target.set_special_gauge(100)
		attacker.start_character_special()
		target.start_character_special()
		attacker.enter_character_special_active()
		target.enter_character_special_active()
		attacker.reversal_elapsed = 0.20
		target.reversal_elapsed = 0.20
		var enemy_hp: int = attacker.current_hp
		var player_hp: int = target.current_hp
		attacker._on_character_special_hitbox_area_entered(target.get_node("HurtBox"))
		target._on_character_special_hitbox_area_entered(attacker.get_node("HurtBox"))
		await process_frame
		await process_frame
		check(attacker.current_hp<enemy_hp and target.current_hp<player_hp,definition+" simultaneous special trades without player priority")
		await capture(definition+"_special_trade")
	# Airborne jumpers remain eligible; grounded knockdown is not a free hit.
	await reset(manager,attacker,Vector2(570,520),1)
	await reset(manager,target,Vector2(640,390),-1)
	attacker.set_physics_process(false)
	target.set_physics_process(false)
	var airborne_packet: Dictionary = attacker._get_character_special_attack_dictionary()
	check(target.receive_attack(airborne_packet,1,target.global_position,attacker),"airborne jumper receives palm")
	target._update_visual_state()
	await capture("airborne_palm_hit")
	await reset(manager,target,Vector2(640,520),-1)
	target.enter_knockdown()
	var down_hp: int = target.current_hp
	check(not target.receive_attack(airborne_packet,1,target.global_position,attacker) and target.current_hp==down_hp,"down victim rejects another palm")
	check(not target.request_character_special(),"down victim cannot reverse")
	print("TEKI_REVERSAL_EXTRA_OK natural_contact guard whiff ai body_mass special_trade airborne down")
