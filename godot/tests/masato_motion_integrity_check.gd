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
	print("MASATO_CAPTURE "+label)
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
	output = ProjectSettings.globalize_path("res://").path_join("../evidence/masato_runtime").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager._hide_player_selection()
	manager.current_enemy_index = 6
	manager._apply_current_stage_definition()
	manager._set_battle_active(true)
	paused = false
	var player: Node = battle.get_node("Player")
	var masato: Node = battle.get_node("Enemy")
	var definition: FighterDefinition = load("res://data/enemies/enemy_03_guard.tres")
	masato.apply_character_data(definition)
	player.apply_character_data(load("res://data/fighters/ally_balance.tres"))
	player.visible = true
	masato.visible = true
	manager._update_battle_hud_enemy()
	manager._update_battle_hud_player()
	await clean_reset(manager,player,Vector2(460,520),1)
	await clean_reset(manager,masato,Vector2(860,520),-1)
	player.set_physics_process(false)
	masato.set_physics_process(false)
	var sprite: AnimatedSprite2D = masato.animated_character_sprite
	var fixed_scale := sprite.scale
	var fixed_position := sprite.position
	var frames := sprite.sprite_frames
	var idle := frames.get_frame_texture(&"idle",0)
	var idle_height := idle.get_image().get_used_rect().size.y
	var idle_area := opaque_body_area(idle)
	check(idle_height == 295,"approved visible standing height preserved")
	check(is_equal_approx(definition.character_height_cm,168.0),"168cm design preserved")
	check(frames.has_animation(&"special_attack"),"dedicated palm reversal exists")
	for clip in frames.get_animation_names():
		for frame in range(frames.get_frame_count(clip)):
			var texture := frames.get_frame_texture(clip,frame) as AtlasTexture
			check(texture != null,"authored texture "+clip)
			if texture == null: continue
			var basic_source := texture.atlas.resource_path.contains("basic_moves_v2/masato/")
			check(basic_source or texture.atlas.resource_path.contains("masato_v3"),"all Masato motions use repaired originals "+clip)
			check((basic_source and texture.get_size() in [Vector2(512,448),Vector2(640,448)]) or texture.get_size() == Vector2(512,448),"common complete cell "+clip)
			var used := texture.get_image().get_used_rect()
			check((used.position.x>=1 and used.position.y>=1 and used.end.x<=texture.get_width()-1 and used.end.y<=404) if basic_source else (used.position.x>=8 and used.position.y>=8 and used.end.x<=504 and used.end.y<=404),"no clipped hair limbs boots "+clip)
			check((used.end.y>=403 and used.end.y<=404) if basic_source else (used.end.y >= 403 and used.end.y <= 404),"common foot/prone contact baseline "+clip)
			var ratio := opaque_body_area(texture)/idle_area
			check(ratio>0.70 and ratio<1.70,"anatomical body mass "+clip+str(frame))
			for direction in [1,-1]:
				masato.facing_direction = direction
				masato._set_visual_facing()
				masato.character_visual_controller.play_animation(clip,true)
				sprite.pause()
				sprite.frame = frame
				check(sprite.scale.is_equal_approx(fixed_scale) and sprite.position.is_equal_approx(fixed_position),"no scale or pivot change "+clip)
				check(not masato.character_visual_controller.fallback_sprite.visible,"no duplicate fallback body")
				check_visible_art(sprite,"complete visible frame "+clip)
				var key := texture.atlas.resource_path+str(texture.region)+str(direction)
				if not captured_frames.has(key):
					captured_frames[key] = true
					await capture("frame_"+clip+"_"+str(frame)+("_R" if direction>0 else "_L"))
			inspected_frames += 1
	# Actual Area2D contact and state transitions in both directions.
	for direction in [1,-1]:
		await clean_reset(manager,player,Vector2(660-110*direction,520),direction)
		await clean_reset(manager,masato,Vector2(660,520),-direction)
		masato.set_physics_process(false)
		player.input_enabled = true
		var hp: int = masato.current_hp
		player.request_attack_input(&"Punch")
		var damaged := false
		for tick in range(75):
			await physics_frame
			if masato.current_hp<hp and not damaged:
				damaged = true
				masato._update_visual_state()
				check(String(sprite.animation).begins_with("damage"),"normal hit selects damage motion")
				await capture("contact_damage_"+str(direction))
		check(damaged,"player punch contacts Masato "+str(direction))
		await clean_reset(manager,player,Vector2(660-110*direction,520),direction)
		await clean_reset(manager,masato,Vector2(660,520),-direction)
		player.set_physics_process(false)
		masato.input_enabled = true
		hp = player.current_hp
		masato.request_attack_input(&"Kick",true)
		var attack_seen := false
		for tick in range(75):
			await physics_frame
			if masato.attack_phase == masato.AttackPhase.ACTIVE and not attack_seen:
				attack_seen = true
				check(sprite.frame == masato.current_attack_data.contact_start_frame,"normal kick uses extended contact pose")
				await capture("contact_kick_"+str(direction))
		check(player.current_hp<hp,"Masato kick contacts player "+str(direction))
		check(attack_seen,"Masato kick contact pose was observed "+str(direction))
		await clean_reset(manager,player,Vector2(660-80*direction,520),direction)
		await clean_reset(manager,masato,Vector2(660,520),-direction)
		masato.set_physics_process(false)
		masato.is_guarding = true
		masato.guard_type = "high"
		hp = masato.current_hp
		var guard_packet := {"damage":5,"is_guardable":true,"attack_type":"punch","guard_damage_multiplier":0.0,"guard_hit_time":0.22}
		check(not masato.receive_attack(guard_packet,direction,masato.global_position,player),"Masato guard blocks attack")
		masato._update_visual_state()
		check(masato.current_hp==hp and sprite.animation==&"guard_hit","guard impact preserves HP and dedicated posture")
		await capture("contact_guard_"+str(direction))
		await clean_reset(manager,player,Vector2(660-55*direction,520),direction)
		await clean_reset(manager,masato,Vector2(660,520),-direction)
		manager.update_enemy_target()
		player.throw_escape_probability = 0.0 # Observe complete throw without random AI escape.
		hp = player.current_hp
		masato._start_throw()
		var throw_seen := {}
		for tick in range(140):
			await physics_frame
			masato._update_visual_state()
			var throw_phase: String = masato.throw_state
			if throw_phase.is_empty(): break
			var throw_clip := "throw_start" if throw_phase=="THROW_STARTUP" else ("throw_hold" if throw_phase=="THROW_HOLD" else "throw_release")
			check(String(sprite.animation)==throw_clip,"throw phase survives runtime update "+throw_phase)
			if not throw_seen.has(throw_phase):
				throw_seen[throw_phase] = true
				await capture("contact_"+throw_clip+"_"+str(direction))
		check(throw_seen.has("THROW_HOLD") and throw_seen.has("THROW_RECOVERY") and player.current_hp<hp,"throw connects holds releases and damages player")
		await clean_reset(manager,player,Vector2(660-100*direction,520),direction)
		await clean_reset(manager,masato,Vector2(660,520),-direction)
		player.set_physics_process(false)
		hp = player.current_hp
		masato.set_special_gauge(100)
		masato.start_character_special()
		var seen := {}
		for tick in range(120):
			await physics_frame
			masato._update_visual_state()
			var state: int = masato.character_special_state
			if state == masato.CharacterSpecialState.NONE: break
			var expected := "special_startup" if state == masato.CharacterSpecialState.STARTUP else ("special_attack" if state == masato.CharacterSpecialState.ACTIVE else "special_recovery")
			check(String(sprite.animation)==expected,"palm reversal dedicated phase "+expected)
			if not seen.has(state):
				seen[state] = true
				await capture("palm_"+expected+"_"+str(direction))
			if state == masato.CharacterSpecialState.ACTIVE and sprite.frame==1 and not seen.has("peak"):
				seen["peak"] = true
				await capture("palm_peak_"+str(direction))
		check(seen.has("peak") and seen.size()>=3 and player.current_hp<hp,"palm complete phases and real contact")
	print("MASATO_MOTION_INTEGRITY_RESULT frames=%d unique_views=%d screenshots=%d failures=%s" % [inspected_frames,captured_frames.size(),screenshots,failures])
	battle.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
