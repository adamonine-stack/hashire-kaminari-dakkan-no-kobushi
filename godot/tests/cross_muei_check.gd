extends "res://tests/cross_motion_integrity_check.gd"

var cases_checked := 0

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var was_paused := paused
	paused = true
	await process_frame
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png(output.path_join(label+".png")) == OK,"save "+label)
	screenshots += 1
	print("MUEI_CAPTURE "+label)
	paused = was_paused

func clean_reset(manager: Node, actor: Node, point: Vector2, facing: int) -> void:
	# Production auto-enables profile AI each physics update; isolate this contact fixture.
	actor.ai_profile = null
	await super.clean_reset(manager,actor,point,facing)
	actor.throw_regrab_lock_timer = 0.0
	actor.throw_escape_timer = 0.0

func run() -> void:
	output = ProjectSettings.globalize_path("res://").path_join("../evidence/cross_muei").simplify_path()
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
	for stage in [3]:
		manager.current_enemy_index = stage
		manager._apply_current_stage_definition()
		manager._set_battle_active(true)
		actor.apply_character_data(load("res://data/enemies/enemy_05_power.tres"))
		manager._update_battle_hud_enemy()
		for hero in ["ally_balance","ally_power","ally_speed"]:
			victim.apply_character_data(load("res://data/fighters/"+hero+".tres"))
			victim.visible = true
			actor.visible = true
			manager._update_battle_hud_player()
			for direction in [1,-1]:
				for variant in range(8):
					var special: bool = variant >= 6
					var near_wall: bool = variant == 7
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
					var prefix := "stage%d_%s_%d_%s_%d" % [stage+1,hero,direction,"wall" if near_wall else "center",variant]
					if special:
						actor.set_special_gauge(100)
						actor.start_character_special()
					else:
						actor._start_throw()
						actor.cross_throw_variant = variant
					for tick in range(180):
						await physics_frame
						actor._update_visual_state()
						victim._update_visual_state()
						check(actor.animated_character_sprite.scale.is_equal_approx(fixed_actor_scale) and victim.animated_character_sprite.scale.is_equal_approx(fixed_victim_scale),"both fighters retain body size "+prefix)
						check(not actor.character_visual_controller.fallback_sprite.visible and not victim.character_visual_controller.fallback_sprite.visible,"one rendered sprite per fighter "+prefix)
						if special and actor.character_special_state == actor.CharacterSpecialState.ACTIVE:
							await capture(prefix+"_special_active")
							actor._on_character_special_hitbox_area_entered(victim.hurt_box)
						var state: String = actor.throw_state
						if state=="THROW_HOLD":
							held_frames += 1
							check(victim.animated_character_sprite.animation==(&"cross_muei_held" if special else &"cross_react_pull"),"recipient never plays two-person/down pose while held "+prefix)
							check(is_equal_approx(absf(actor.global_position.x-victim.global_position.x),76.0),"no compressed body overlap at wall "+prefix)
							check(victim.facing_direction==-actor.facing_direction,"both face actual grip "+prefix)
							check_visible_art(actor.animated_character_sprite,prefix+" complete thrower")
							check_visible_art(victim.animated_character_sprite,prefix+" complete held recipient")
							if held_frames in [1,4,8]: await capture(prefix+"_hold_"+str(held_frames))
						if not state.is_empty() and not seen.has(state):
							seen[state] = true
							await capture(prefix+"_"+state)
						for reaction in [&"cross_muei_air",&"cross_muei_down",&"cross_react_shoulder",&"cross_react_shoulder_down",&"cross_react_reap",&"cross_react_reap_down",&"stand_up"]:
							if victim.animated_character_sprite.animation==reaction and not seen.has(reaction):
								seen[reaction] = true
								await capture(prefix+"_"+String(reaction))
						if tick>30 and actor.throw_state.is_empty() and victim.knockdown_state==&"" and not victim.is_hit: break
					check(held_frames>0 and seen.has("THROW_RECOVERY") and (seen.has(&"cross_muei_air") and seen.has(&"cross_muei_down") if special else seen.has(&"cross_react_shoulder") or seen.has(&"cross_react_reap")),"grip release flight landing sequence "+prefix)
					var expected_damage: int = roundi(maxi(actor.punch_damage,actor.kick_damage)*1.5) if special else actor.throw_damage
					check(victim.current_hp==hp-expected_damage,"special 1.5x or unchanged ordinary throw damage "+prefix)
					check(not actor.cross_muei_throw_active,"dedicated flag clears "+prefix)
					if special: check(actor.special_gauge<100,"special consumes gauge "+prefix)
					cases_checked += 1
		# Failed grip, escape and KO must restore ordinary rendering as well.
		victim.apply_character_data(load("res://data/fighters/ally_balance.tres"))
		for direction in [1,-1]:
			for mode in ["whiff","escape","ko"]:
				await clean_reset(manager,actor,Vector2(660,520),direction)
				await clean_reset(manager,victim,Vector2(660+(340 if mode=="whiff" else 55)*direction,520),-direction)
				victim.throw_escape_probability = 0.0
				if mode=="ko": victim.current_hp = 1
				var hp: int = victim.current_hp
				manager.update_enemy_target()
				actor.set_special_gauge(100)
				actor.start_character_special()
				var escaped := false
				for tick in range(90):
					await physics_frame
					if mode!="whiff" and actor.character_special_state==actor.CharacterSpecialState.ACTIVE:
						actor._on_character_special_hitbox_area_entered(victim.hurt_box)
					if mode=="escape" and actor.throw_state=="THROW_HOLD" and not escaped:
						victim._complete_throw_escape()
						escaped = true
						await capture("stage%d_escape_%d" % [stage+1,direction])
					if mode=="ko" and victim.current_hp<=0:
						await capture("stage%d_throw_ko_%d" % [stage+1,direction])
						break
					if tick>60 and actor.throw_state.is_empty(): break
				check(victim.current_hp==0 if mode=="ko" else victim.current_hp==hp,"special throw outcome "+mode)
				check(escaped if mode=="escape" else true,"actual throw escape executes")
				check(not victim.character_visual_controller.fallback_sprite.visible,"no duplicate body after "+mode)
				if mode!="ko":
					check(not victim.is_throw_locked and not victim.is_throw_escape_pending,"grip lock clears after "+mode)
					await capture("stage%d_%s_%d_complete" % [stage+1,mode,direction])
				cases_checked += 1
	await extra_reversal_checks(manager,actor,victim)
	print("CROSS_MUEI_RESULT cases=%d screenshots=%d failures=%s" % [cases_checked,screenshots,failures])
	for audio in root.find_children("*","AudioStreamPlayer",true,false):audio.stop()
	for audio in root.find_children("*","AudioStreamPlayer2D",true,false):audio.stop()
	OS.delay_msec(200)
	battle.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures.is_empty() else 1)

func extra_reversal_checks(_manager: Node,_actor: Node,_victim: Node) -> void:
	pass
