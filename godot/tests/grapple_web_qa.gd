extends "res://tests/crusher_web_qa_base.gd"
func base_clean_reset(manager: Node, actor: Node, point: Vector2, facing: int) -> void:
	await reset(manager,actor,point,facing)
	actor._clear_guard_state()
	actor.is_guard_hit = false
	actor.is_hit = false
	actor.hit_reaction_timer = 0.0
	actor.guard_recoil_timer = 0.0
	actor.ai_enabled = false
	actor.input_enabled = false


var cases_checked := 0

func capture(label: String) -> void:
	if OS.has_feature("web"):
		var was_paused := paused
		paused = true
		await RenderingServer.frame_post_draw
		JavaScriptBridge.eval("window.grappleQACaptureDone = ''", true)
		print("GRAPPLE_CAPTURE "+label)
		var deadline := Time.get_ticks_msec()+20000
		while JavaScriptBridge.eval("window.grappleQACaptureDone", true) != label:
			if Time.get_ticks_msec() > deadline:
				check(false, "browser capture acknowledgement "+label)
				break
			await get_tree().create_timer(0.05, true, false, true).timeout
		screenshots += 1
		paused = was_paused
		return
	if DisplayServer.get_name() == "headless": return
	var was_paused := paused
	paused = true
	await process_frame
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png(output.path_join(label+".png")) == OK,"save "+label)
	screenshots += 1
	print("GRAPPLE_CAPTURE "+label)
	paused = was_paused

func clean_reset(manager: Node, actor: Node, point: Vector2, facing: int) -> void:
	# Production auto-enables profile AI each physics update; isolate this contact fixture.
	actor.ai_profile = null
	await base_clean_reset(manager,actor,point,facing)
	actor.throw_regrab_lock_timer = 0.0
	actor.throw_escape_timer = 0.0

func run() -> void:
	output = ProjectSettings.globalize_path("res://").path_join("../evidence/readable_grapple").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.get_tree().current_scene = battle
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager._hide_player_selection()
	# Isolate motion checks from asynchronous round intro and automatic ally replacement.
	manager._flow_sequence_id += 1
	manager.flow_state = manager.BattleState.FIGHT
	var actor: Node = battle.get_node("Enemy")
	var victim: Node = battle.get_node("Player")
	for stage in [5,6]:
		manager.current_enemy_index = stage
		manager._apply_current_stage_definition()
		manager._set_battle_active(true)
		actor.apply_character_data(load("res://data/enemies/enemy_06_combo.tres" if stage==5 else "res://data/enemies/enemy_03_guard.tres"))
		manager._update_battle_hud_enemy()
		for hero in ["ally_balance","ally_power","ally_speed"]:
			victim.apply_character_data(load("res://data/fighters/"+hero+".tres"))
			victim.visible = true
			actor.visible = true
			manager._update_battle_hud_player()
			for direction in [1,-1]:
				for near_wall in [false,true]:
					var x: float = 660.0
					if near_wall: x = actor._stage_min_x()+40.0 if direction<0 else actor._stage_max_x()-40.0
					await clean_reset(manager,actor,Vector2(x,520),direction)
					await clean_reset(manager,victim,Vector2(clampf(x+55*direction,actor._stage_min_x()+4,actor._stage_max_x()-4),520),-direction)
					victim.throw_escape_probability = 0.0
					manager.update_enemy_target()
					var fixed_actor_scale: Vector2 = actor.animated_character_sprite.scale
					var fixed_victim_scale: Vector2 = victim.animated_character_sprite.scale
					var hp: int = victim.current_hp
					var seen := {}
					var held_frames := 0
					var prefix := "stage%d_%s_%d_%s" % [stage+1,hero,direction,"wall" if near_wall else "center"]
					actor._start_throw()
					for tick in range(180):
						await physics_frame
						actor._update_visual_state()
						victim._update_visual_state()
						check(actor.animated_character_sprite.scale.is_equal_approx(fixed_actor_scale) and victim.animated_character_sprite.scale.is_equal_approx(fixed_victim_scale),"both fighters retain body size "+prefix)
						check(not actor.character_visual_controller.fallback_sprite.visible and not victim.character_visual_controller.fallback_sprite.visible,"one rendered sprite per fighter "+prefix)
						var state: String = actor.throw_state
						if state=="THROW_HOLD":
							held_frames += 1
							check(victim.animated_character_sprite.animation==&"grapple_held","recipient never plays two-person/down pose while held "+prefix)
							check(is_equal_approx(absf(actor.global_position.x-victim.global_position.x),76.0),"no compressed body overlap at wall "+prefix)
							check(victim.facing_direction==-actor.facing_direction,"both face actual grip "+prefix)
							check_visible_art(actor.animated_character_sprite,prefix+" complete thrower")
							check_visible_art(victim.animated_character_sprite,prefix+" complete held recipient")
							if held_frames in [1,4,8]: await capture(prefix+"_hold_"+str(held_frames))
						if not state.is_empty() and not seen.has(state):
							seen[state] = true
							await capture(prefix+"_"+state)
						for reaction in [&"grapple_air",&"grapple_down",&"stand_up"]:
							if victim.animated_character_sprite.animation==reaction and not seen.has(reaction):
								seen[reaction] = true
								await capture(prefix+"_"+String(reaction))
						if tick>30 and actor.throw_state.is_empty() and victim.knockdown_state==&"" and not victim.is_hit: break
					check(held_frames>0 and seen.has("THROW_RECOVERY") and seen.has(&"grapple_air") and seen.has(&"grapple_down"),"grip release flight landing sequence "+prefix)
					check(victim.current_hp==hp-actor.throw_damage,"unchanged throw damage "+prefix)
					cases_checked += 1
		# Failed grip, escape and KO must restore ordinary rendering as well.
		victim.apply_character_data(load("res://data/fighters/ally_balance.tres"))
		for mode in ["whiff","escape","ko"]:
			await clean_reset(manager,actor,Vector2(660,520),1)
			await clean_reset(manager,victim,Vector2(1000 if mode=="whiff" else 715,520),-1)
			victim.throw_escape_probability = 0.0
			if mode=="ko": victim.current_hp = 1
			var hp: int = victim.current_hp
			manager.update_enemy_target()
			actor._start_throw()
			var escaped := false
			for tick in range(90):
				await physics_frame
				if mode=="escape" and actor.throw_state=="THROW_HOLD" and not escaped:
					victim._complete_throw_escape()
					escaped = true
					await capture("stage%d_escape" % [stage+1])
				if mode=="ko" and victim.current_hp<=0:
					await capture("stage%d_throw_ko" % [stage+1])
					break
				if tick>20 and actor.throw_state.is_empty(): break
			check(victim.current_hp==0 if mode=="ko" else victim.current_hp==hp,"special throw outcome "+mode)
			check(escaped if mode=="escape" else true,"actual throw escape executes")
			check(not victim.character_visual_controller.fallback_sprite.visible,"no duplicate body after "+mode)
			if mode!="ko":
				check(not victim.is_throw_locked and not victim.is_throw_escape_pending,"grip lock clears after "+mode)
				await capture("stage%d_%s_complete" % [stage+1,mode])
			cases_checked += 1
	print("GRAPPLE_MOTION_INTEGRITY_RESULT cases=%d screenshots=%d failures=%s" % [cases_checked,screenshots,failures])
	battle.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
