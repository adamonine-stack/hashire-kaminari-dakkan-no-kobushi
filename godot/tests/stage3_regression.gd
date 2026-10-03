extends "res://tests/stage2_regression.gd"

func start_selected() -> void:
	await manager.select_player_by_id(String(manager.player_team[0].fighter_id))
	for i in range(600):
		await physics_frame
		if manager.isRoundActive:
			return
	check(false, "round becomes active")

func clear_stage() -> void:
	await defeat_with_punches()
	for i in range(900):
		await physics_frame
		if manager.flow_state in [manager.BattleState.NEXT_PLAYER, manager.BattleState.CLEAR]:
			return
	check(false, "KO resolves stage")

func reset_grab_pair() -> void:
	manager.reset_active_fighter_state(player, Vector2(560, 520), 1.0)
	manager.reset_active_fighter_state(enemy, Vector2(610, 520), -1.0)
	for fighter in [player, enemy]:
		fighter.is_round_active = true
		fighter.throw_regrab_lock_timer = 0.0
		fighter.velocity = Vector2(0, 1)
		fighter.move_and_slide()

func run() -> void:
	seed(28)
	battle = load("res://scenes/Battle.tscn").instantiate()
	# Keep this regression scoped to the original three-stage slice even though
	# the published campaign now continues into Stage 4.
	battle.get_node("BattleManager").active_enemy_count_limit = 3
	root.add_child(battle)
	current_scene = battle
	await process_frame
	manager = battle.get_node("BattleManager")
	player = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	check(manager.enemy_team.size() == 3, "published campaign has three stages")
	check(manager.validate_enemy_definitions(), "unique roster order valid")
	check(manager.enemy_order[2] == &"enemy_07_teki_fighter", "Teki stage 3")
	check(manager.STAGE_DEFINITIONS[2].enemy_definition.fighter_id == &"enemy_07_teki_fighter", "intro uses Teki")
	check(manager.STAGE_DEFINITIONS[2].stage_number == 3, "stage number 3")
	await start_selected()
	await clear_stage()
	check(manager.current_enemy_index == 1, "Crusher KO advances to Rei")
	await start_selected()
	await clear_stage()
	check(manager.current_enemy_index == 2 and not manager.isBattleFinished, "Rei KO opens Teki selection")
	await start_selected()
	check(enemy.fighter_definition.fighter_id == &"enemy_07_teki_fighter", "Teki spawned")
	check(enemy.character_visual_controller.get_debug_source() == "motion_atlas", "Teki authored art")
	check(battle.get_node("UI/BattleUIRoot/BattleHUD").enemy_name_label.text == "テキ・ファイター", "Teki HUD")
	enemy.ai_enabled = false
	enemy.ai_profile = null
	enemy.reset_attack_state()
	enemy.clear_ai_action_state()
	enemy.set_physics_process(false)
	var sprite: AnimatedSprite2D = enemy.animated_character_sprite
	var atlas: Resource = enemy.fighter_definition.motion_atlas
	check(atlas.texture.get_width() <= 4096 and atlas.texture.get_height() <= 4096, "Web texture dimensions")
	for clip in atlas.clips:
		check(sprite.sprite_frames.has_animation(clip), "authored clip " + clip)
		for index in atlas.clips[clip].frames:
			check(index >= 0 and index < 52, "valid frame in " + clip)
	check(not sprite.sprite_frames.get_animation_loop("ko"), "KO holds final pose")
	for side in [-1, 1]:
		enemy.facing_direction = side
		enemy.character_visual_controller.set_facing(side)
		check(sprite.flip_h == (side < 0), "facing")
		for id in ["teki_straight", "teki_elbow", "teki_high_kick", "teki_sweep", "teki_air_punch", "teki_air_kick"]:
			enemy.reset_attack_state()
			enemy.start_attack(id)
			enemy._sync_attack_visual_phase()
			check(sprite.frame == 0 and not enemy.punch_hitbox_active and not enemy.kick_hitbox_active, "startup " + id)
			enemy.enter_attack_active()
			enemy._sync_attack_visual_phase()
			check(sprite.frame == 1 and (enemy.punch_hitbox_active or enemy.kick_hitbox_active), "contact " + id)
			enemy.enter_attack_recovery()
			enemy._sync_attack_visual_phase()
			check(sprite.frame == 2 and not enemy.punch_hitbox_active and not enemy.kick_hitbox_active, "recovery " + id)
			enemy.finish_attack()
	# Exercise actual target lock, single damage application and escape paths.
	player.set_physics_process(false)
	enemy.facing_direction = -1
	player.set_health(player.max_hp)
	for variant in range(4):
		reset_grab_pair()
		player.is_invincible = false
		player.throw_regrab_lock_timer = 0.0
		player.reset_attack_state()
		player._finish_throw()
		player.position = Vector2(560, 520)
		enemy.position = Vector2(610, 520)
		enemy._start_throw()
		enemy.teki_throw_variant = variant
		enemy._connect_throw(player)
		enemy._update_visual_state()
		player._update_visual_state()
		check(String(sprite.animation) == enemy._teki_throw_animation("throw_hold"), "grip pose survives runtime update %d" % variant)
		check(player._get_current_visual_animation() == &"grabbed", "opponent holds grabbed pose")
		check(enemy.throw_state == "THROW_HOLD" and player.is_throw_locked, "grab locks opponent %d" % variant)
		var hp: int = player.current_hp
		enemy._release_throw()
		check(player.current_hp == maxi(0, hp - enemy.throw_damage), "throw applies once %d" % variant)
		enemy._release_throw()
		check(player.current_hp == maxi(0, hp - enemy.throw_damage), "no duplicate throw damage")
		enemy._finish_throw()
		player.set_health(player.max_hp)
	reset_grab_pair()
	enemy._start_throw()
	enemy._connect_throw(player)
	var before_escape: int = player.current_hp
	player._complete_throw_escape()
	player._update_throw_recovery(1.0)
	check(player.current_hp == before_escape and not player.is_throw_locked, "escape prevents damage and unlocks")
	reset_grab_pair()
	enemy.ai_enabled = true
	enemy.ai_profile = enemy.fighter_definition.ai_profile
	enemy.set_special_gauge(100)
	check(enemy.request_character_special(true), "Deadly Hand spends gauge")
	check(sprite.animation == &"teki_deadly_startup", "special readable startup")
	enemy.enter_character_special_active()
	enemy.reversal_elapsed = 0.20
	player.throw_regrab_lock_timer = 0.0
	player.is_invincible = false
	player.invincibility_timer = 0.0
	var before_special: int = player.current_hp
	enemy._on_character_special_hitbox_area_entered(player.hurt_box)
	await process_frame
	await process_frame
	check(not enemy._is_throw_busy() and player.knockdown_state == &"KNOCKBACK", "special palm interrupts into dedicated knockback")
	check(player.current_hp == before_special-11,"special palm applies damage once")
	check(enemy.special_gauge == 0, "special consumes gauge")
	# Both clocks were paused for contact assertions; reset the completed
	# special rather than leaving its startup protection frozen during clear.
	manager.reset_active_fighter_state(player,Vector2(560,520),1,player.max_hp)
	manager.reset_active_fighter_state(enemy,Vector2(660,520),-1,enemy.current_hp)
	player.is_round_active = true
	enemy.is_round_active = true
	player.set_physics_process(true)
	await clear_stage()
	check(manager.flow_state == manager.BattleState.CLEAR, "Teki KO clears three-stage campaign")
	check(manager._end_title_label.text == "STAGE 3 CLEAR", "Stage 3 clear title")
	manager.debug_auto_select_player = true
	manager.restart_current_game()
	for i in range(600):
		await physics_frame
		if manager.isRoundActive and not manager.is_scene_transitioning:
			break
	check(manager.current_enemy_index == 0 and enemy.fighter_definition.fighter_id == &"enemy_01_crusher", "retry returns to Crusher")
	check(not enemy.attack_data_by_id.has("teki_straight"), "retry clears Teki attacks")
	manager.cleanup_battle_before_transition()
	root.get_node("AudioManager").stop_bgm()
	battle.queue_free()
	await process_frame
	print("STAGE3_REGRESSION failures=", failures)
	quit(0 if failures.is_empty() else 1)
