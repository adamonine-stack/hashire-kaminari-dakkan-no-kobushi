extends SceneTree

var failures: Array[String] = []
var battle: Node
var manager: Node
var player: Node
var enemy: Node

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	seed(53)
	battle = load("res://scenes/Battle.tscn").instantiate()
	battle.get_node("BattleManager").active_enemy_count_limit = 1
	root.add_child(battle)
	await process_frame
	manager = battle.get_node("BattleManager")
	for entry in manager.player_team:
		manager.select_order_character(String(entry.fighter_id))
	manager.confirm_player_order()
	for i in range(360):
		await physics_frame
		if manager.isRoundActive:
			break
	check(manager.isRoundActive, "order selection must reach battle")
	player = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	enemy.ai_enabled = false
	enemy.ai_profile = null
	# Keep hitstun, invincibility and floor recovery running while AI is disabled.
	await ticks(2)
	var sprite: AnimatedSprite2D = player.animated_character_sprite
	check(player.default_hurt_box_size.y > 180, "player upper body hurt region")
	check(enemy.default_hurt_box_size.y > player.default_hurt_box_size.y * 1.08, "Crusher upper body hurt region")
	check(enemy.default_hurt_box_size.x > 100, "Crusher broad shoulder hurt region")
	# Verify the enemy's real fallback attacks follow the contact frames.
	for action in [&"Punch", &"Kick"]:
		if action == &"Punch":
			enemy.request_punch_attack()
		else:
			enemy.request_kick_attack()
		check(enemy.attack_phase == enemy.AttackPhase.STARTUP, "Crusher %s startup" % action)
		check(not enemy.punch_hitbox_active and not enemy.kick_hitbox_active, "Crusher %s startup has no hitbox" % action)
		enemy._sync_attack_visual_phase()
		check(enemy.animated_character_sprite.frame == 0, "Crusher %s startup frame" % action)
		enemy.enter_attack_active()
		enemy._sync_attack_visual_phase()
		check(enemy.animated_character_sprite.frame == 1, "Crusher %s contact frame" % action)
		check(enemy.kick_hitbox_active if action == &"Kick" else enemy.punch_hitbox_active, "Crusher %s contact hitbox" % action)
		enemy.enter_attack_recovery()
		enemy._sync_attack_visual_phase()
		check(enemy.animated_character_sprite.frame == 2, "Crusher %s recovery frame" % action)
		check(not enemy.punch_hitbox_active and not enemy.kick_hitbox_active, "Crusher %s recovery has no hitbox" % action)
		enemy.finish_attack()
	check(sprite.sprite_frames.get_frame_count("jump_land") == 2, "landing contains only ground poses")
	check(sprite.sprite_frames.get_frame_count("jump_fall") == 2, "descent has dedicated airborne poses")
	# Use the real input path and floor, not a manually assigned airborne flag.
	Input.action_press("jump")
	await ticks(2)
	Input.action_release("jump")
	var saw_up := false
	var saw_fall := false
	var saw_land := false
	for i in range(100):
		await physics_frame
		saw_up = saw_up or sprite.animation == &"jump_start"
		saw_fall = saw_fall or sprite.animation == &"jump_fall"
		saw_land = saw_land or sprite.animation == &"jump_land"
	check(saw_up and saw_fall and saw_land, "jump must traverse rise, descent and landing")
	check(player.is_on_floor(), "jump returns to floor")
	# A repeated attack must reset its visual even if requested before idle.
	player._play_visual_animation(&"punch_1", true)
	sprite.set_frame_and_progress(4, 0.5)
	player._play_visual_animation(&"punch_1", true)
	check(sprite.frame == 0, "forced repeat resets frame")
	player.start_hit_stop_seconds(0.1)
	player._update_hit_stop(0.016)
	check(sprite.speed_scale == 0.0, "hitstop freezes sprite clock")
	await ticks(15)
	check(sprite.speed_scale == 1.0, "hitstop restores sprite clock")
	# Real Area2D collision must cause damage during ACTIVE only, on both facings.
	enemy.set_physics_process(true)
	enemy.input_enabled = true
	for side in [1, -1]:
		manager.reset_active_fighter_state(enemy, Vector2(640 + side * 100, 520), -side, enemy.current_hp)
		enemy.is_round_active = true
		enemy.input_enabled = true
		player.position = Vector2(640, 520)
		enemy.position = Vector2(640 + side * 100, 520)
		enemy.is_invincible = false
		enemy.hurt_box.monitorable = true
		player.facing_direction = side
		player.start_attack("player1_punch_1")
		player._update_visual_state()
		var initial_hp: int = enemy.current_hp
		await ticks(8)
		check(enemy.current_hp == initial_hp, "startup cannot deal damage")
		var saw_contact := false
		for i in range(45):
			await physics_frame
			if player.current_attack_id == "player1_punch_1" and player.attack_phase == player.AttackPhase.ACTIVE:
				saw_contact = true
				check(sprite.frame == 2, "active hitbox holds contact frame")
		check(saw_contact and enemy.current_hp < initial_hp, "actual punch overlap hits on each facing")
		check(enemy.current_hp == initial_hp - 11, "single punch cannot damage twice")
		check(player._get_hit_position(enemy).y < 420, "contact feedback is above the floor")
		await ticks(20)
	# Defeat through the collision/HP/KO path; do not call _mark_enemy_defeated.
	for attempt in range(35):
		if manager.isBattleFinished:
			break
		player.position = Vector2(560, 520)
		enemy.position = Vector2(660, 520)
		enemy.is_invincible = false
		enemy.hurt_box.monitorable = true
		player.facing_direction = 1
		player.request_attack_input(&"Punch")
		await ticks(70)
	await ticks(180)
	check(manager.flow_state == manager.BattleState.CLEAR, "real damage path reaches Stage 1 clear")
	check(manager._end_panel.visible, "clear panel is visible")
	check(not manager.battle_hud.result_panel.visible, "clear result must not overlap legacy HUD result")
	check(manager._end_title_label.text == "STAGE 1 CLEAR", "clear panel names Stage 1")
	check(not player.is_round_active, "combat is disabled after clear")
	manager.restart_current_game()
	for i in range(480):
		await physics_frame
		if manager.isRoundActive and not manager.is_scene_transitioning:
			break
	check(manager.isRoundActive and enemy.current_hp == enemy.max_hp, "retry restores enemy HP and combat")
	check(not manager._end_panel.visible, "retry closes result panel")
	enemy.set_physics_process(true)
	# With no player input the real AI must defeat the three ordered fighters.
	for i in range(24000):
		await physics_frame
		if manager.isBattleFinished:
			break
	check(manager.flow_state == manager.BattleState.GAME_OVER, "real AI damage and substitutions reach game over")
	check(manager._end_panel.visible, "game over panel is visible")
	check(not manager.battle_hud.result_panel.visible, "game over result must not overlap legacy HUD result")
	manager.cleanup_battle_before_transition()
	root.get_node("AudioManager").stop_bgm()
	battle.queue_free()
	await process_frame
	await create_timer(1.0).timeout
	print("STAGE1_REGRESSION failures=", failures)
	quit(0 if failures.is_empty() else 1)