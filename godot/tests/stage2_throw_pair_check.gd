extends "res://tests/stage1_hero_throws_check.gd"

var rows: Array[Dictionary] = []
var output := ""

func run() -> void:
	output = ProjectSettings.globalize_path("res://../audit_evidence/stage2_design_20261010/throws")
	DirAccess.make_dir_recursive_absolute(output)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	battle.get_node("BattleManager").active_enemy_count_limit = 2
	root.add_child(battle)
	current_scene = battle
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager.select_player_by_id("player_01_akky")
	for tick in range(500):
		await physics_frame
		if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
		if manager.isRoundActive: break
	manager.current_enemy_index = 1
	manager.spawn_active_enemy()
	manager._apply_current_stage_definition()
	check(battle.get_node("Enemy").fighter_definition.fighter_id == &"enemy_04_rei_kageyama","actual Rei opponent")
	player = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	battle.set_process(false)
	battle.get_node("BattleCamera").position = Vector2(640,360)
	battle.get_node("BattleCamera").zoom = Vector2.ONE
	var cases := 0
	for entry in [["akky","ally_balance"],["gou","ally_power"],["seiya","ally_speed"]]:
		player.apply_character_data(load("res://data/fighters/"+entry[1]+".tres"))
		for actor in [player,enemy]:
			actor.ai_enabled = false
			actor.ai_profile = null
			actor.ai_guard_enabled = false
			actor.ai_throw_probability = 0.0
			actor.throw_escape_probability = 0.0
			actor.input_enabled = false
		for facing in ([1.0] if "--probe" in OS.get_cmdline_user_args() else [1.0,-1.0]):
			for reverse in ([true] if "--probe" in OS.get_cmdline_user_args() else [false,true]):
				for direction in (["normal"] if reverse else ["neutral","forward","down","back"]):
					reset_pair(facing)
					player.set_physics_process(true)
					enemy.set_physics_process(true)
					player.move_and_slide()
					enemy.move_and_slide()
					var attacker: Node = enemy if reverse else player
					var victim: Node = player if reverse else enemy
					var label: String = "%s_%s_%s_%d" % [entry[0],"rei_throws" if reverse else "hero_throws",direction,int(facing)]
					var scales := [player.animated_character_sprite.scale,enemy.animated_character_sprite.scale]
					var hp: int = victim.current_hp
					if reverse:
						print("REI_THROW_ACTOR ",attacker.fighter_definition.fighter_id," helper=",attacker._is_rei_thrower())
						attacker._start_throw()
					else: check(attacker._request_directional_move(entry[0]+"_"+direction+"_throw",true),label+" request starts")
					var held := false
					var changes := 0
					var sampled := {}
					var saw_air := false
					var saw_down := false
					for tick in range(240):
						await physics_frame
						held = held or victim.is_throw_locked
						check(player.animated_character_sprite.scale.is_equal_approx(scales[0]),label+" hero scale fixed")
						check(enemy.animated_character_sprite.scale.is_equal_approx(scales[1]),label+" Rei scale fixed")
						if victim.current_hp != hp:
							changes += 1
							hp = victim.current_hp
						var phase: String = attacker.throw_state if not attacker.throw_state.is_empty() else String(victim.knockdown_state)
						var sprite: AnimatedSprite2D = victim.animated_character_sprite
						saw_air = saw_air or victim.knockdown_state == &"KNOCKBACK"
						saw_down = saw_down or victim.knockdown_state == &"KNOCKDOWN"
						if victim.is_throw_locked and not reverse:
							var expected: StringName = victim._directional_throw_victim_animation()
							check(sprite.animation == expected and expected != &"",label+" configured held reaction")
						if not reverse and victim.knockdown_state == &"KNOCKBACK":
							check(sprite.animation == StringName("throw_victim_"+direction+"_air"),label+" dedicated flight reaction")
						if reverse and victim.is_throw_locked:
							check(sprite.animation == &"crusher_throw_held",label+" Rei held reaction")
						if reverse and victim.knockdown_state == &"KNOCKBACK":
							check(sprite.animation == &"crusher_throw_neutral_air",label+" Rei flight reaction")
						var key := phase+"/"+String(sprite.animation)+"/"+str(sprite.frame)
						if not sampled.has(key):
							sampled[key] = true
							var file := "%s_%03d.png" % [label,tick]
							if DisplayServer.get_name() != "headless":
								RenderingServer.force_draw(false)
								root.get_texture().get_image().save_png(output.path_join(file))
							rows.append({"case":label,"tick":tick,"phase":phase,"attacker_clip":attacker.animated_character_sprite.animation,"victim_clip":sprite.animation,"attacker_position":str(attacker.position),"victim_position":str(victim.position),"image":file})
					check(held,label+" actual hold contact")
					check(changes == 1,label+" exactly one damage application")
					check(saw_air and saw_down,label+" flight and landing observed")
					check(not victim.is_throw_locked and not attacker.is_throwing,label+" release clears both locks")
					check(victim.knockdown_state == &"" and victim.is_on_floor(),label+" victim wakes up")
					cases += 1
	FileAccess.open(output.path_join("inventory.json"),FileAccess.WRITE).store_string(JSON.stringify({"cases":cases,"rows":rows,"failures":failures},"  "))
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	print("STAGE2_THROW_PAIRS cases=",cases," failures=",failures)
	quit(0 if failures.is_empty() else 1)
