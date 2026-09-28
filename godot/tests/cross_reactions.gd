extends "res://tests/stage3_regression.gd"

const MOVES := ["cross_punch", "cross_chop", "cross_wrist_finish", "cross_kick", "cross_knee", "cross_joint_finish"]
const REACTIONS := ["cross_react_pull", "cross_react_shoulder", "cross_react_joint", "cross_react_reap", "cross_react_reap", "cross_react_joint"]
var rendered := false
var output := ""

func start_selected() -> void:
	manager.select_player_by_id(String(manager.player_team[0].fighter_id))
	for i in range(1200):
		await physics_frame
		if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible:
			manager._advance_enemy_intro()
		if manager.isRoundActive:
			return
	check(false, "reaction review reaches battle")

func capture(label: String) -> void:
	if not rendered:
		return
	player.animated_character_sprite.pause()
	enemy.animated_character_sprite.pause()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))

func pair(side: int) -> void:
	manager.reset_active_fighter_state(player, Vector2(640 + side * 42, 520), -side)
	manager.reset_active_fighter_state(enemy, Vector2(640 - side * 42, 520), side)
	for fighter in [player, enemy]:
		fighter.is_round_active = true
		fighter.ai_enabled = false
		fighter.ai_profile = null
		fighter.set_physics_process(false)
		fighter.is_invincible = false
		fighter.set_health(fighter.max_hp)
		fighter.velocity = Vector2(0, 1)
		fighter.move_and_slide()
		fighter._update_visual_state()

func run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	output = ProjectSettings.globalize_path("res://../audit_evidence/cross_pairs")
	if rendered:
		DirAccess.make_dir_recursive_absolute(output)
	battle = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	current_scene = battle
	await process_frame
	manager = battle.get_node("BattleManager")
	player = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	await start_selected()
	manager.current_enemy_index = 3
	manager.spawn_active_enemy()
	battle.get_node("BattleCamera").position = Vector2(640, 360)
	battle.get_node("BattleCamera").zoom = Vector2.ONE
	for actor in ["ally_balance", "ally_power", "ally_speed"]:
		player.apply_fighter_definition(load("res://data/fighters/" + actor + ".tres"))
		for side in [-1, 1]:
			for i in range(MOVES.size()):
				pair(side)
				var id: String = MOVES[i]
				enemy.start_attack(id)
				enemy.enter_attack_active()
				enemy._sync_attack_visual_phase()
				var attack: Dictionary = enemy._get_attack_data_dictionary("Punch")
				attack["damage"] = 1
				attack["combo_hit_index"] = 1
				attack["combo_hit_max"] = 3
				check(player.receive_attack(attack, side, player.position, enemy), actor + " receives " + id)
				check(String(player.last_damage_animation) == REACTIONS[i], actor + " reaction " + id)
				player._update_visual_state()
				check(String(player.animated_character_sprite.animation) == REACTIONS[i], "reaction survives update")
				check(not player.is_throw_locked and not enemy.is_throwing, "normal move has no throw lock")
				await capture("%s_%s_%d" % [actor, id, side])
				pair(side)
				player.is_guarding = true
				player.guard_type = "stand"
				check(not player.receive_attack(attack, side, player.position, enemy), "guard blocks " + id)
				player._update_visual_state()
				check(not String(player.animated_character_sprite.animation).begins_with("cross_react"), "guard never uses victim pose")
				pair(side)
				enemy.start_attack(id)
				enemy.enter_attack_active()
				enemy.enter_attack_recovery()
				check(not player.is_hit and not player.is_throw_locked, "whiff leaves target free")
			for variant in range(6):
				pair(side)
				enemy._start_throw()
				enemy.cross_throw_variant = variant
				enemy._connect_throw(player)
				player._update_visual_state()
				enemy._update_visual_state()
				check(player.animated_character_sprite.animation == &"cross_react_pull", "held victim pose")
				await capture("%s_throw%d_hold_%d" % [actor, variant, side])
				enemy._release_throw()
				player._update_visual_state()
				check(String(player.last_knockdown_animation).begins_with("cross_react"), "matching thrown pose")
				await capture("%s_throw%d_release_%d" % [actor, variant, side])
				player.start_get_up()
				player.finish_get_up()
				check(not player.is_throw_locked and not player._is_knockdown_busy(), "throw recovery unlocks")
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	print("CROSS_REACTIONS failures=", failures, " rendered=", rendered)
	quit(0 if failures.is_empty() else 1)
