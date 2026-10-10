extends "res://tests/crusher_web_qa_base.gd"

var cases := 0
var motions := 0
var contact_events: Array[Dictionary] = []
var include_motion_audit := true
var include_boss_cases := true
var include_cleanup_cases := false
var hero_enemies := ["enemy_01_standard","enemy_02_speed","enemy_03_guard","enemy_04_throw","enemy_05_power","enemy_06_combo","enemy_07_tricky","enemy_08_boss","enemy_09_seiya"]

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var old_pause := paused
	paused = true
	if OS.has_feature("web"):
		await RenderingServer.frame_post_draw
		JavaScriptBridge.eval("window.stage9CaptureDone = ''",true)
		print("STAGE9_CAPTURE "+label)
		var deadline := Time.get_ticks_msec()+20000
		while JavaScriptBridge.eval("window.stage9CaptureDone",true) != label:
			if Time.get_ticks_msec()>deadline:
				check(false,"capture acknowledgement "+label)
				break
			await get_tree().create_timer(0.05,true,false,true).timeout
	else:
		await process_frame
		RenderingServer.force_draw(false)
		check(root.get_texture().get_image().save_png(output.path_join(label+".png"))==OK,"save "+label)
	screenshots += 1
	paused = old_pause

func clean(manager: Node, actor: Node, point: Vector2, direction: int) -> void:
	actor.ai_profile = null
	actor.ai_throw_probability = -1.0
	actor.ai_guard_enabled = false
	actor._finish_throw()
	await reset(manager,actor,point,direction)
	actor._clear_guard_state()
	actor.is_guard_hit = false
	actor.guard_recoil_timer = 0.0
	actor.throw_regrab_lock_timer = 0.0
	actor.input_enabled = false
	actor.ai_profile = null
	actor.ai_enabled = false
	actor.current_hp = 999
	actor.is_round_active = true
	if is_instance_valid(actor.aura_controller): actor.aura_controller.cancel()

func ticks(n: int) -> void:
	for i in range(n): await physics_frame

func on_contact(actor: Node, amount: int, guarded: bool, _point: Vector2) -> void:
	contact_events.append({"target":actor,"damage":amount,"guard":guarded,"y":actor.global_position.y,"vy":actor.velocity.y,"time":Time.get_ticks_msec()})

func expected_two_hit_damage(attacker: Node) -> int:
	var definition: Resource = attacker.get("fighter_definition")
	if definition != null:
		var fighter_id := String(definition.get("fighter_id"))
		if fighter_id == "enemy_09_seiya": return 24
		if fighter_id == "player_03_seiya": return 13
	return maxi(attacker.punch_damage,attacker.kick_damage)

func audit_motions(actor: Node) -> void:
	actor.set_physics_process(false)
	actor.position = Vector2(750,520)
	var sprite: AnimatedSprite2D = actor.animated_character_sprite
	var original_scale := sprite.scale
	var seen := {}
	for clip in sprite.sprite_frames.get_animation_names():
		for frame in range(sprite.sprite_frames.get_frame_count(clip)):
			actor._play_visual_animation(clip,true)
			sprite.pause()
			sprite.frame = frame
			motions += 1
			check(sprite.scale.is_equal_approx(original_scale),"fixed scale "+String(clip)+str(frame))
			var tex := sprite.sprite_frames.get_frame_texture(clip,frame) as AtlasTexture
			check(tex!=null,"authored single body "+String(clip))
			var key := tex.atlas.resource_path+str(tex.region)
			if seen.has(key): continue
			seen[key] = true
			for direction in [-1,1]:
				actor.facing_direction = direction
				actor._set_visual_facing()
				check_visible_art(sprite,"single body "+String(clip))
				await capture("motion_%s_%d_%d" % [clip,frame,direction])
	actor.set_physics_process(true)

func run_case(manager: Node, attacker: Node, target: Node, direction: int, mode: String, label: String) -> void:
	var start_x := 600.0
	if mode == "wall": start_x = 1040.0 if direction>0 else 240.0
	await clean(manager,attacker,Vector2(start_x,520),direction)
	await clean(manager,target,Vector2(start_x+95*direction,520),-direction)
	manager._set_battle_active(true)
	manager.isRoundActive = true
	if mode in ["side_only","whiff"]: target.position.x = start_x+390*direction
	if mode == "ko_second": target.current_hp = expected_two_hit_damage(attacker)+1
	if mode in ["guard_both","guard_first"]:
		target.is_guarding = true
		target.guard_type = "high"
		# Autonomous guard update reads the configured test state.
		target.set_physics_process(false)
	contact_events.clear()
	attacker.set_special_gauge(100.0)
	attacker.start_character_special()
	var saw_second := false
	var target_start: Vector2 = target.position
	var scale_before: Vector2 = attacker.animated_character_sprite.scale
	var moved_for_second := false
	var cap_done := {}
	for frame in range(150):
		await physics_frame
		var elapsed: float = attacker.character_special_data.active_time-attacker.character_special_timer
		if attacker.character_special_state == attacker.CharacterSpecialState.ACTIVE:
			if target.seiya_followup_owner != null:
				check(not target.can_receive_attack(),label+" ordinary attacks cannot juggle this lift")
			if mode == "confirmed_guard_displaced" and elapsed>0.45 and not moved_for_second:
				target.position.x = start_x+390*direction
				target.is_guarding = true
				target.guard_type = "high"
				target.is_invincible = true
				var wrong_sequence: Dictionary = attacker._get_character_special_attack_dictionary()
				wrong_sequence["seiya_two_hit_stage"] = 1
				wrong_sequence["seiya_two_hit_sequence"] -= 1
				check(not target.can_receive_seiya_followup(wrong_sequence,attacker),label+" rejects another activation")
				moved_for_second = true
			if mode == "guard_both" and elapsed>0.40:
				target.is_guard_hit = false
				target.guard_recoil_timer = 0.0
				target.is_guarding = true
				target.guard_type = "high"
			if mode == "side_only" and elapsed>0.45 and not moved_for_second:
				target.position = Vector2(start_x+95*direction,520)
				moved_for_second = true
			if mode == "guard_first" and elapsed>0.38:
				target._clear_guard_state()
				target.is_guard_hit = false
				target.guard_recoil_timer = 0.0
				target.set_physics_process(true)
			if attacker.seiya_two_hit_stage==1: saw_second=true
			check(attacker.animated_character_sprite.scale.is_equal_approx(scale_before),label+" actor size")
			if frame%5==0: check_visible_art(attacker.animated_character_sprite,label+" actor viewport")
			for moment in [0.12,0.36,0.70,0.77]:
				if elapsed>=moment and not cap_done.has(moment):
					cap_done[moment]=true
					await capture("%s_%s" % [label,str(moment).replace('.','_')])
		if target.special_wall_phase == "impact" and not cap_done.has("wall"):
			cap_done["wall"]=true
			await capture(label+"_wall")
		if not attacker.is_character_special_busy() and target.knockdown_state in [&"KNOCKDOWN",&""] and frame>75: break
	check(saw_second,label+" always executes sidekick")
	var hits := contact_events.filter(func(e):return not e.guard)
	var guards := contact_events.filter(func(e):return e.guard)
	var base := expected_two_hit_damage(attacker)
	for hit in hits: check(hit.damage==base,label+" preserved per-hit special damage")
	if mode in ["both","wall","ko_second","confirmed_guard_displaced"]:
		check(hits.size()==2,label+" two separate hits")
		if hits.size()==2:
			check(hits[1].y < target_start.y-8,label+" second contact airborne")
			check(hits[1].vy>0,label+" second contact while descending")
		check(cap_done.has("wall"),label+" reaches screen edge")
		if mode=="ko_second": check(target.current_hp==0,label+" second hit KO retains visible flight")
		if mode=="confirmed_guard_displaced":
			check(guards.is_empty(),label+" confirmed second hit cannot be guarded")
			check(moved_for_second,label+" confirmed hit tracks displaced target")
	elif mode=="side_only": check(hits.size()==1,label+" sidekick only uses preserved special damage")
	elif mode=="guard_first": check(guards.size()==1 and hits.size()==1,label+" first guard does not stop second hit")
	elif mode=="guard_both": check(guards.size()==2 and hits.is_empty(),label+" independently guard both")
	elif mode=="whiff": check(hits.is_empty() and guards.is_empty(),label+" both misses recover without damage")
	check(not attacker.special_area.monitoring,label+" hitbox cleans after move")
	check(attacker.seiya_confirmed_targets.is_empty(),label+" confirmed target cleans after move")
	check(attacker.animated_character_sprite.rotation==0 and attacker.animated_character_sprite.offset==Vector2.ZERO,label+" restores transform")
	print("STAGE9_CASE ",label," contacts=",contact_events)
	cases+=1

func run() -> void:
	output=ProjectSettings.globalize_path("res://../evidence/stage9/runtime")
	DirAccess.make_dir_recursive_absolute(output)
	var battle: Node=load("res://scenes/TrueBattle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var manager: Node=battle.get_node("BattleManager")
	# TrueBattle now waits for the user to choose a surviving hero.
	# Initialize both real combat actors before the isolated hitbox suite.
	check(manager._character_selection_screen.is_open, "TRUE boss selection opens before Stage 9 QA")
	manager.select_player_by_id("player_01_akky")
	await create_timer(1.35).timeout
	check(manager.current_player_id == "player_01_akky" and manager.enemy.fighter_definition != null, "Stage 9 test actors initialized")
	manager._flow_sequence_id+=1
	manager.set_process(false)
	manager.set_physics_process(false)
	manager._hide_player_selection()
	manager.flow_state=manager.BattleState.FIGHT
	manager._set_battle_active(true)
	var hero: Node=battle.get_node("Player")
	var boss: Node=battle.get_node("Enemy")
	paused = false
	hero.damage_feedback_requested.connect(on_contact)
	boss.damage_feedback_requested.connect(on_contact)
	await clean(manager,hero,Vector2(430,520),1)
	await clean(manager,boss,Vector2(750,520),-1)
	if include_motion_audit: await audit_motions(boss)
	for character in (["ally_balance","ally_power","ally_speed"] if include_boss_cases else []):
		hero.apply_character_data(load("res://data/fighters/%s.tres" % character))
		for direction in [-1,1]:
			for mode in ["both","side_only","guard_first","guard_both","wall"]:
				await run_case(manager,boss,hero,direction,mode,character+"_"+mode+"_"+str(direction))
	if include_boss_cases or include_cleanup_cases:
		hero.apply_character_data(load("res://data/fighters/ally_speed.tres"))
		for direction in [-1,1]:
			for mode in ["whiff","confirmed_guard_displaced","ko_second"]:
				await run_case(manager,boss,hero,direction,mode,"cleanup_"+mode+"_"+str(direction))
	hero.apply_character_data(load("res://data/fighters/ally_speed.tres"))
	for enemy in hero_enemies:
		boss.apply_character_data(load("res://data/enemies/%s.tres" % enemy))
		for direction in [-1,1]: await run_case(manager,hero,boss,direction,"both",enemy+"_hero_"+str(direction))
	boss.apply_character_data(load("res://data/enemies/enemy_09_seiya.tres"))
	await clean(manager,hero,Vector2(340,520),1)
	await clean(manager,boss,Vector2(900,520),-1)
	var aura: Node=boss.aura_controller
	aura.cooldown=0
	var gauge: float=boss.special_gauge
	check(aura.start_normal(),"pillar is normal move")
	var start:=Engine.get_physics_frames()
	while aura.phase!=aura.Phase.ACTIVE: await physics_frame
	check(Engine.get_physics_frames()-start<40,"pillar starts within 40 physics ticks")
	check(is_equal_approx(aura.data.charge_time+aura.data.slam_time+aura.data.warning_time,0.38),"pillar authored startup 0.38s")
	check(boss.special_gauge>=gauge,"pillar consumes no special gauge")
	await capture("normal_pillar_active")
	while aura.busy(): await physics_frame
	check(not aura.strike_area.monitoring,"normal pillar cleanup")
	print("STAGE9_TWO_HIT_RESULT cases=%d frames=%d screenshots=%d failures=%s" % [cases,motions,screenshots,str(failures)])
	print("SPECIAL_LAUNCH_REACTION_CHECK failures="+str(failures))
	contact_events.clear()
	for audio in root.find_children("*","AudioStreamPlayer",true,false): audio.stop()
	for audio in root.find_children("*","AudioStreamPlayer2D",true,false): audio.stop()
	OS.delay_msec(200)
	battle.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures.is_empty() else 1)
