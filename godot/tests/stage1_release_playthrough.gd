extends SceneTree

var enemy_attacks := 0
var player_was_hit := false
var active_frames := 0

func count_enemy_attack(_attack_id: String) -> void:
	enemy_attacks += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	seed(53)
	var battle = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	current_scene = battle
	await process_frame
	var manager = battle.get_node("BattleManager")
	var hero = "player_02_gou" if "--gou" in OS.get_cmdline_user_args() else ("player_03_seiya" if "--seiya" in OS.get_cmdline_user_args() else "player_01_akky")
	manager.select_player_by_id(hero)
	var player = battle.get_node("Player")
	var enemy = battle.get_node("Enemy")
	enemy.attack_started.connect(count_enemy_attack)
	var started := false
	var output = ProjectSettings.globalize_path("res://../audit_evidence/stage1_release_playthrough/" + hero + "")
	DirAccess.make_dir_recursive_absolute(output)
	# A small deterministic input player. HP, AI and hitboxes remain unmodified.
	for frame in range(12000):
		await physics_frame
		if manager.isBattleFinished or bool(manager.enemy_team[0].get("is_defeated",false)):
			break
		if not manager.isRoundActive:
			if manager._enemy_intro_panel!=null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
			continue
		started = true
		active_frames += 1
		player_was_hit = player_was_hit or player.current_hp < player.max_hp
		# Let the live AI approach and land attacks before the input player fights.
		if not player_was_hit and active_frames < 360:
			if active_frames % 120 == 0:
				print("AI_PROBE distance=", enemy.evaluate_distance(), " state=", enemy.ai_state, " floor=", enemy.is_on_floor(), " active=", enemy.is_round_active, " input=", enemy.input_enabled, " action=", enemy.can_ai_act(), " cooldown=", enemy.ai_attack_cooldown_timer)
			continue
		for action in ["move_left", "move_right", "attack", "kick", "guard", "special_attack", "down"]:
			Input.action_release(action)
		var gap: float = enemy.position.x - player.position.x
		if absf(gap) > 98:
			Input.action_press("move_right" if gap > 0 else "move_left")
		if player.special_gauge>=player.special_gauge_cost and absf(gap)<170 and frame%12==0:
			Input.action_press("special_attack")
		elif enemy.current_attack_data!=null and enemy.attack_phase in [enemy.AttackPhase.STARTUP,enemy.AttackPhase.ACTIVE] :
			Input.action_press("guard")
			if String(enemy.current_attack_data.attack_height)=="low": Input.action_press("down")
		elif frame % 12 == 0:
			Input.action_press("attack" if frame % 36 != 0 else "kick")
		if frame % 300 == 0:
			print("PLAYTHROUGH frame=", frame, " player_hp=", player.current_hp, " enemy_hp=", enemy.current_hp)
			if DisplayServer.get_name() != "headless":
				RenderingServer.force_draw(false)
				root.get_texture().get_image().save_png(output.path_join("play_%05d.png" % frame))
	for action in ["move_left", "move_right", "attack", "kick", "guard", "special_attack", "down"]:
		Input.action_release(action)
	for i in range(180):
		await physics_frame
	var cleared: bool = bool(manager.enemy_team[0].get("is_defeated",false)) and enemy.current_hp==0
	print("STAGE1_RELEASE_PLAYTHROUGH hero=",hero," started=", started, " cleared=", cleared, " player_hp=", player.current_hp, " enemy_hp=", enemy.current_hp, " enemy_attacks=", enemy_attacks, " player_was_hit=", player_was_hit)
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png(output.path_join("play_result.png"))
	manager.cleanup_battle_before_transition()
	root.get_node("AudioManager").stop_bgm()
	battle.queue_free()
	await process_frame
	await create_timer(1.0).timeout
	quit(0 if cleared and enemy_attacks > 0 and player_was_hit else 1)
