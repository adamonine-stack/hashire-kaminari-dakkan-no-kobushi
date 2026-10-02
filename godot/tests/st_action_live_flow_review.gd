extends SceneTree

var output: String
var failures: Array[String] = []

func attack_data(damage: int) -> Dictionary:
	return {"damage":damage,"knockback_x":0.0,"knockback_y":0.0,"knockback":0.0,"knockback_force":Vector2.ZERO,"effect_size":1.0,"se_type":"normal","screen_shake":0.0,"attack_type":"punch","combo_hit_index":1,"combo_hit_max":1}

func _initialize() -> void:
	call_deferred("run")

func snap(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		print("LIVE_CAPTURE ", name)
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(output.path_join(name + ".png"))

func ticks(count: int) -> void:
	for i in range(count): await physics_frame

func run() -> void:
	output = ProjectSettings.globalize_path("res://../evidence/live")
	DirAccess.make_dir_recursive_absolute(output)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	var manager: Node = battle.get_node("BattleManager")
	manager.debug_auto_select_player = true
	root.add_child(battle)
	current_scene = battle
	await process_frame
	var player: Node = battle.get_node("Player")
	var enemy: Node = battle.get_node("Enemy")
	for stage in range(8):
		var reached := false
		for i in range(1800):
			await physics_frame
			enemy.set_physics_process(false)
			if manager._enemy_intro_panel.visible:
				manager._enemy_intro_label.visible_characters = -1
				await snap("stage%02d_intro" % (stage + 1))
				manager._advance_enemy_intro()
			if manager.isRoundActive and manager.current_enemy_index == stage:
				reached = true
				break
		if not reached:
			failures.append("did not reach stage %d via progression" % (stage + 1))
			break
		player.set_physics_process(false)
		player.position = Vector2(450,520)
		enemy.position = Vector2(810,520)
		enemy.input_enabled = true
		enemy.is_round_active = true
		enemy.set_physics_process(true)
		await ticks(3)
		await snap("stage%02d_idle" % (stage + 1))
		Input.action_press("move_right")
		await ticks(12)
		await snap("stage%02d_walk" % (stage + 1))
		Input.action_release("move_right")
		await ticks(4)
		Input.action_press("jump")
		await ticks(2)
		Input.action_release("jump")
		await ticks(12)
		if enemy.is_on_floor(): failures.append("stage %d jump did not leave ground" % (stage + 1))
		await snap("stage%02d_jump" % (stage + 1))
		await ticks(65)
		Input.action_press("attack")
		await ticks(4)
		Input.action_release("attack")
		await snap("stage%02d_attack" % (stage + 1))
		await ticks(50)
		enemy.is_invincible = false
		enemy.receive_attack(attack_data(1),1.0,enemy.global_position + Vector2(0,-100),player)
		await ticks(2)
		await snap("stage%02d_hit" % (stage + 1))
		await ticks(50)
		enemy.is_invincible = false
		var connected: bool = enemy.receive_attack(attack_data(enemy.current_hp+1),1.0,enemy.global_position + Vector2(0,-100),player)
		if not connected: failures.append("stage %d finishing hit did not connect" % (stage + 1))
		await ticks(12)
		await snap("stage%02d_ko" % (stage + 1))
		print("LIVE_STAGE_REVIEW stage=",stage+1," hp=",enemy.current_hp," motions=Idle,Walk,Jump,Attack,Hit,KO")
		for i in range(900):
			await physics_frame
			if manager.current_enemy_index != stage or manager.isBattleFinished: break
		player.set_physics_process(true)
	for action in ["move_right","jump","attack"]: Input.action_release(action)
	if manager.flow_state != manager.BattleState.CLEAR: failures.append("eight-stage progression did not reach clear")
	await snap("campaign_clear")
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	print("ST_ACTION_LIVE_FLOW_REVIEW failures=", failures)
	quit(0 if failures.is_empty() else 1)
