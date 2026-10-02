extends "res://tests/special_launch_reaction_check.gd"

var inspected_frames := 0
var captured_frames := {}

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var was_paused := paused
	paused = true
	await process_frame
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png(output.path_join(label+".png")) == OK,"save "+label)
	screenshots += 1
	print("LEON_CAPTURE "+label)
	paused = was_paused

func clean_reset(manager: Node, actor: Node, point: Vector2, facing: int) -> void:
	await reset(manager,actor,point,facing)
	actor._clear_guard_state()
	actor.is_guard_hit = false
	actor.is_hit = false
	actor.hit_reaction_timer = 0.0
	actor.guard_recoil_timer = 0.0
	actor.ai_enabled = false
	actor.input_enabled = false

func run() -> void:
	output = ProjectSettings.globalize_path("res://").path_join("../evidence/leon_runtime").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager._hide_player_selection()
	manager.current_enemy_index = 7
	manager._apply_current_stage_definition()
	manager._set_battle_active(true)
	paused = false
	var player: Node = battle.get_node("Player")
	var leon: Node = battle.get_node("Enemy")
	var definition: FighterDefinition = load("res://data/enemies/enemy_08_boss.tres")
	leon.apply_character_data(definition)
	player.apply_character_data(load("res://data/fighters/ally_balance.tres"))
	player.visible = true
	leon.visible = true
	manager._update_battle_hud_enemy()
	manager._update_battle_hud_player()
	await clean_reset(manager,player,Vector2(460,520),1)
	await clean_reset(manager,leon,Vector2(860,520),-1)
	player.set_physics_process(false)
	leon.set_physics_process(false)
	var sprite: AnimatedSprite2D = leon.animated_character_sprite
	var fixed_scale := sprite.scale
	var fixed_position := sprite.position
	var frames := sprite.sprite_frames
	var idle := frames.get_frame_texture(&"idle",0)
	var idle_height := idle.get_image().get_used_rect().size.y
	var idle_area := opaque_body_area(idle)
	check(idle_height == 296,"approved visible standing height preserved")
	check(is_equal_approx(definition.character_height_cm,188.0),"188cm design preserved")
	check(frames.has_animation(&"special_spin_kick") and frames.has_animation(&"special_charge"),"dedicated boss attacks exist")
	for clip in frames.get_animation_names():
		for frame in range(frames.get_frame_count(clip)):
			var texture := frames.get_frame_texture(clip,frame) as AtlasTexture
			check(texture != null,"authored texture "+clip)
			if texture == null: continue
			check(texture.atlas.resource_path.contains("leon_v2"),"all Leon motions use repaired originals "+clip)
			check(texture.get_size() == Vector2(512,448),"common complete cell "+clip)
			var used := texture.get_image().get_used_rect()
			check(used.position.x>=8 and used.position.y>=8 and used.end.x<=504 and used.end.y<=404,"no clipped hair limbs boots "+clip)
			check(used.end.y >= 403 and used.end.y <= 404,"common foot/prone contact baseline "+clip)
			var ratio := opaque_body_area(texture)/idle_area
			check(ratio>0.70 and ratio<1.70,"anatomical body mass "+clip+str(frame))
			for direction in [1,-1]:
				leon.facing_direction = direction
				leon._set_visual_facing()
				leon.character_visual_controller.play_animation(clip,true)
				sprite.pause()
				sprite.frame = frame
				check(sprite.scale.is_equal_approx(fixed_scale) and sprite.position.is_equal_approx(fixed_position),"no scale or pivot change "+clip)
				check_visible_art(sprite,"complete visible frame "+clip)
				var key := texture.atlas.resource_path+str(texture.region)+str(direction)
				if not captured_frames.has(key):
					captured_frames[key] = true
					await capture("frame_"+clip+"_"+str(frame)+("_R" if direction>0 else "_L"))
			inspected_frames += 1
	# Actual Area2D contact and state transitions in both directions.
	for direction in [1,-1]:
		await clean_reset(manager,player,Vector2(660-110*direction,520),direction)
		await clean_reset(manager,leon,Vector2(660,520),-direction)
		leon.set_physics_process(false)
		player.input_enabled = true
		var hp: int = leon.current_hp
		player.request_attack_input(&"Punch")
		var damaged := false
		for tick in range(75):
			await physics_frame
			if leon.current_hp<hp and not damaged:
				damaged = true
				leon._update_visual_state()
				check(String(sprite.animation).begins_with("damage"),"normal hit selects damage motion")
				await capture("contact_damage_"+str(direction))
		check(damaged,"player punch contacts Leon "+str(direction))
		await clean_reset(manager,player,Vector2(660-110*direction,520),direction)
		await clean_reset(manager,leon,Vector2(660,520),-direction)
		player.set_physics_process(false)
		leon.input_enabled = true
		hp = player.current_hp
		leon.request_attack_input(&"Kick",true)
		var attack_seen := false
		for tick in range(75):
			await physics_frame
			if leon.attack_phase == leon.AttackPhase.ACTIVE and not attack_seen:
				attack_seen = true
				check(sprite.frame == 1,"normal kick uses extended contact pose")
				await capture("contact_kick_"+str(direction))
		check(player.current_hp<hp,"Leon kick contacts player "+str(direction))
		check(attack_seen,"Leon kick contact pose was observed "+str(direction))
		await clean_reset(manager,player,Vector2(660-80*direction,520),direction)
		await clean_reset(manager,leon,Vector2(660,520),-direction)
		leon.set_physics_process(false)
		leon.is_guarding = true
		leon.guard_type = "high"
		hp = leon.current_hp
		var guard_packet := {"damage":5,"is_guardable":true,"attack_type":"punch","guard_damage_multiplier":0.0,"guard_hit_time":0.22}
		check(not leon.receive_attack(guard_packet,direction,leon.global_position,player),"Leon guard blocks attack")
		leon._update_visual_state()
		check(leon.current_hp==hp and sprite.animation==&"guard_hit","guard impact preserves HP and dedicated posture")
		await capture("contact_guard_"+str(direction))
		await clean_reset(manager,player,Vector2(660-55*direction,520),direction)
		await clean_reset(manager,leon,Vector2(660,520),-direction)
		manager.update_enemy_target()
		player.throw_escape_probability = 0.0 # Observe complete throw without random AI escape.
		hp = player.current_hp
		leon._start_throw()
		var throw_seen := {}
		for tick in range(140):
			await physics_frame
			leon._update_visual_state()
			var throw_phase: String = leon.throw_state
			if throw_phase.is_empty(): break
			var throw_clip := "throw_start" if throw_phase=="THROW_STARTUP" else ("throw_hold" if throw_phase=="THROW_HOLD" else "throw_release")
			check(String(sprite.animation)==throw_clip,"throw phase survives runtime update "+throw_phase)
			if not throw_seen.has(throw_phase):
				throw_seen[throw_phase] = true
				await capture("contact_"+throw_clip+"_"+str(direction))
		check(throw_seen.has("THROW_HOLD") and throw_seen.has("THROW_RECOVERY") and player.current_hp<hp,"throw connects holds releases and damages player")
		for attack_id in ["enemy8_charge_attack","enemy8_spin_kick","enemy8_ultimate_shockwave"]:
			await clean_reset(manager,player,Vector2(660-130*direction,520),direction)
			await clean_reset(manager,leon,Vector2(660,520),-direction)
			player.set_physics_process(false)
			hp = player.current_hp
			if attack_id == "enemy8_ultimate_shockwave":leon.start_ultimate_attack()
			else:leon.start_special_attack(attack_id)
			var seen := {}
			for tick in range(180):
				await physics_frame
				leon._update_visual_state()
				var state: int = leon.boss_attack_state
				if state == leon.BossAttackState.NONE: break
				var expected := ""
				if state == leon.BossAttackState.SPECIAL_STARTUP:expected = "special_startup"
				elif state == leon.BossAttackState.SPECIAL_ACTIVE:expected = "special_charge" if attack_id == "enemy8_charge_attack" else "special_spin_kick"
				elif state == leon.BossAttackState.SPECIAL_RECOVERY:expected = "special_recovery"
				elif state == leon.BossAttackState.ULTIMATE_STARTUP:expected = "ultimate_startup"
				elif state == leon.BossAttackState.ULTIMATE_ACTIVE:expected = "ultimate_attack"
				elif state == leon.BossAttackState.ULTIMATE_RECOVERY:expected = "ultimate_recovery"
				check(String(sprite.animation)==expected,"real boss phase keeps dedicated clip "+attack_id+expected)
				check(sprite.scale.is_equal_approx(fixed_scale),"boss phase constant size")
				if not seen.has(state):
					seen[state] = true
					await capture("boss_"+attack_id+"_"+expected+"_"+str(direction))
				if state == leon.BossAttackState.SPECIAL_ACTIVE and sprite.frame == 1 and not seen.has("peak"):
					seen["peak"] = true
					await capture("boss_"+attack_id+"_peak_"+str(direction))
			check(seen.has(leon.BossAttackState.ULTIMATE_ACTIVE) if attack_id == "enemy8_ultimate_shockwave" else seen.has("peak"),"boss visible contact frame "+attack_id)
			check(seen.size()>=3,"boss completes startup active recovery "+attack_id)
			check(player.current_hp<hp,"boss special makes real contact "+attack_id)
	print("LEON_MOTION_INTEGRITY_RESULT frames=%d unique_views=%d screenshots=%d failures=%s" % [inspected_frames,captured_frames.size(),screenshots,failures])
	quit(0 if failures.is_empty() else 1)
