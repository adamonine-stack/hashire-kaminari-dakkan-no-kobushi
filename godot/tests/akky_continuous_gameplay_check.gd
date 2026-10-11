extends "res://tests/directional_throws_check.gd"

var rows: Array[Dictionary] = []
var folder := ""
var capture := false
var label: Label
var facing := 1.0
var case_index := 0
var tick_index := 0
var previous := ""
var baseline := Vector2.ZERO
var iteration := 0
var camera: Camera2D

func selected_fighter_id() -> String:
	return "player_01_akky"

func qa_name() -> String:
	return "Akky"

func special_clips() -> Array:
	return ["akky_reversal_startup","akky_reversal_elbow","akky_reversal_finish"]

func battle_stage_index() -> int:
	return 0

func controlled_actor_name() -> String:
	return "Player"

func step(count: int) -> void:
	for tick in range(count):
		await physics_frame
		var sprite: AnimatedSprite2D = player.animated_character_sprite
		var key := "%s/%d" % [sprite.animation,sprite.frame]
		check(sprite.scale.is_equal_approx(baseline),"runtime scale case %d facing %s tick %d" % [case_index,facing,tick_index])
		label.text = "QA %s | run %d facing %d | sequence %d | %s frame %d" % [qa_name(),iteration,int(facing),case_index,String(sprite.animation),sprite.frame]
		var row := {"iteration":iteration,"facing":facing,"sequence":case_index,"tick":tick_index,"clip":sprite.animation,"frame":sprite.frame,"position":str(player.position),"on_floor":player.is_on_floor(),"scale":str(sprite.scale),"camera_zoom":str(camera.zoom),"hp":player.current_hp,"image":""}
		if "--fixed-camera" in OS.get_cmdline_user_args(): check(camera.zoom.is_equal_approx(Vector2.ONE),"fixed comparison camera")
		if capture and key != previous:
			RenderingServer.force_draw(true)
			row.image = "%d_%d_%d_%03d.png" % [iteration,int(facing),case_index,tick_index]
			root.get_texture().get_image().save_png(folder.path_join(row.image))
		previous = key
		rows.append(row)
		tick_index += 1

func tap(action: String) -> void:
	Input.action_press(action)
	await step(2)
	Input.action_release(action)

func incoming_hit() -> void:
	var packet: Dictionary = enemy._get_punch_attack_data().duplicate(true)
	packet.merge({"damage":1,"base_damage":1,"knockback_x":0.0,"knockback_y":0.0,"launch_velocity":Vector2.ZERO,"causes_knockdown":false,"combo_hit_max":0,"hitstun_time":0.4,"attack_height":"middle","hit_stop_frames":0,"hitstop_defender":0.0,"hitstop_attacker":0.0},true)
	packet.erase("hit_reaction")
	check(player.receive_attack(packet,-facing,player.global_position,enemy),"hit fixture accepted")

func run() -> void:
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	battle.get_node("BattleManager").active_enemy_count_limit = battle_stage_index() + 1
	root.add_child(battle)
	current_scene = battle
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager.select_player_by_id(selected_fighter_id())
	for tick in range(360):
		await physics_frame
		if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
		if manager.isRoundActive: break
	check(manager.isRoundActive,"round ready")
	if battle_stage_index() != 0:
		manager.current_enemy_index = battle_stage_index()
		manager.spawn_active_enemy()
		manager._apply_current_stage_definition()
		manager._update_battle_hud_enemy()
		check(battle.get_node("Enemy").fighter_definition.fighter_id == &"enemy_04_rei_kageyama","actual Stage 2 actor is Rei")
	player = battle.get_node(controlled_actor_name())
	enemy = battle.get_node("Enemy" if controlled_actor_name() == "Player" else "Player")
	player.ai_enabled = false
	player.ai_profile = null
	enemy.ai_enabled = false
	enemy.ai_profile = null
	enemy.ai_guard_enabled = false
	enemy.set_physics_process(false)
	player.input_enabled = true
	baseline = player.animated_character_sprite.scale
	camera = battle.get_node("BattleCamera")
	if "--fixed-camera" in OS.get_cmdline_user_args():
		battle.set_process(false)
		camera.position = Vector2(640,360)
		camera.zoom = Vector2.ONE
		camera.offset = Vector2.ZERO
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	folder = ProjectSettings.globalize_path("res://../audit_evidence/body_dimensions/continuous_gameplay/" + ("capture" if capture else ("headless" if DisplayServer.get_name() == "headless" else "realtime")))
	if "--fixed-camera" in OS.get_cmdline_user_args(): folder += "_fixed_camera"
	if selected_fighter_id() != "player_01_akky":
		folder = ProjectSettings.globalize_path("res://../audit_evidence/hero_design_20261010/continuous/" + qa_name().to_lower() + ("_native" if DisplayServer.get_name() != "headless" else "_headless") + ("_fixed" if "--fixed-camera" in OS.get_cmdline_user_args() else ""))
	if battle_stage_index() == 1:
		folder = ProjectSettings.globalize_path("res://../audit_evidence/stage2_design_20261010/continuous/" + qa_name().to_lower())
	DirAccess.make_dir_recursive_absolute(folder)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	label = Label.new()
	label.position = Vector2(400,630)
	label.add_theme_color_override("font_color",Color.YELLOW)
	layer.add_child(label)
	for direction in ([1.0,-1.0,1.0,-1.0,1.0,-1.0] if "--repeat" in OS.get_cmdline_user_args() else [1.0,-1.0]):
		iteration += 1
		facing = direction
		for sequence in range(6):
			case_index = sequence
			tick_index = 0
			previous = ""
			player.set_physics_process(false)
			reset_pair(facing)
			player.position = Vector2(400 if facing>0 else 880,520)
			enemy.position = Vector2(1150 if facing>0 else 100,520)
			player.velocity.y = 40
			player.move_and_slide()
			player.set_physics_process(true)
			player.input_enabled = true
			await step(30)
			match sequence:
				0:
					await tap("attack")
					await step(70)
				1:
					await tap("kick")
					await step(70)
				2:
					incoming_hit()
					await step(90)
				3:
					var move := "move_right" if facing>0 else "move_left"
					Input.action_press(move)
					await step(25)
					await tap("jump")
					await step(40)
					Input.action_release(move)
					await step(50)
					Input.action_press(move)
					await step(30)
					Input.action_release(move)
					await step(30)
				4:
					var move := "move_right" if facing>0 else "move_left"
					Input.action_press(move)
					await step(25)
					Input.action_release(move)
					await tap("attack")
					await step(10)
					incoming_hit()
					await step(90)
				5:
					player.set_special_gauge(100)
					await tap("special_attack")
					await step(150)
			# Slower fighters finish at their production recovery duration.
			for settle_tick in range(60):
				if not player.is_hit and player.is_on_floor() and player.current_attack_type == "": break
				await step(1)
			var observed: Array[String] = []
			for row in rows:
				if row.iteration == iteration and row.sequence == case_index and String(row.clip) not in observed: observed.append(String(row.clip))
			var required: Array = [["normal_punch_1"],["normal_kick_1"],["damage_light"],["walk_forward","jump_start","jump_fall","jump_land"],["walk_forward","normal_punch_1","damage_light"],special_clips()][case_index]
			for clip in required: check(clip in observed,"required clip %s sequence %d facing %s" % [clip,case_index,facing])
			if case_index == 3:
				var landing_frames: Array[int] = []
				for row in rows:
					if row.iteration == iteration and row.sequence == case_index and row.clip == &"jump_land" and row.frame not in landing_frames: landing_frames.append(row.frame)
				check(landing_frames.size() == player.animated_character_sprite.sprite_frames.get_frame_count(&"jump_land"),"all landing frames observed")
			check(not player.is_hit and player.is_on_floor() and player.current_attack_type == "","sequence returns ground control")
			check(String(player.animated_character_sprite.animation) in ["idle","idle_ready"],"sequence returns idle")
			print("CONTINUOUS_GAMEPLAY sequence=",case_index," facing=",facing," observed=",observed)
	var output := FileAccess.open(folder.path_join("inventory.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify({"frames":rows,"failures":failures,"renderer":DisplayServer.get_name(),"physics_enabled":true,"input_actions":true,"hit_fixture":true,"manual_play":false},"  "))
	print(qa_name().to_upper(),"_CONTINUOUS_GAMEPLAY_CHECK failures=",failures)
	root.get_node("AudioManager").stop_bgm()
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	layer.queue_free()
	await process_frame
	await create_timer(1).timeout
	quit(0 if failures.is_empty() else 1)
