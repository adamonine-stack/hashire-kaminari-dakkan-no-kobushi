extends SceneTree

var failures: Array[String] = []
var output := ""
var screenshots := 0

func check_visible_art(sprite: AnimatedSprite2D, label: String) -> void:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	var used := texture.get_image().get_used_rect()
	var left := float(used.position.x)-texture.get_width()*0.5
	var right := float(used.end.x)-texture.get_width()*0.5
	if sprite.flip_h:
		var old_left := left
		left = -right
		right = -old_left
	var top := float(used.position.y)-texture.get_height()*0.5
	var bottom := float(used.end.y)-texture.get_height()*0.5
	var transform := sprite.get_global_transform_with_canvas()
	var screen := root.get_visible_rect().size
	for point in [Vector2(left,top),Vector2(right,top),Vector2(left,bottom),Vector2(right,bottom)]:
		var actual: Vector2 = transform * point
		check(actual.x >= 0 and actual.x <= screen.x and actual.y >= 0 and actual.y <= screen.y,label + " art inside rendered viewport")

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png(output.path_join(label + ".png")) == OK, "capture " + label)
	screenshots += 1

func reset(manager: Node, actor: Node, point: Vector2, facing: int) -> void:
	manager.reset_active_fighter_state(actor, point, facing, actor.max_hp)
	actor.ai_enabled = false
	actor.input_enabled = false
	actor.is_round_active = true
	actor.current_hp = actor.max_hp
	actor.is_invincible = false
	actor.invincibility_timer = 0.0
	actor.hit_stop_timer = 0.0
	actor.set_physics_process(true)
	for i in range(3): await physics_frame

func run() -> void:
	output = ProjectSettings.globalize_path("res://").path_join("../evidence/special_launch").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager._hide_player_selection()
	manager._set_battle_active(true)
	paused = false
	var attacker: Node = battle.get_node("Player")
	var target: Node = battle.get_node("Enemy")
	attacker.apply_character_data(load("res://data/fighters/ally_balance.tres"))
	var definitions := ["enemy_01_standard","enemy_02_speed","enemy_03_guard","enemy_04_throw",
		"enemy_05_power","enemy_06_combo","enemy_07_tricky","enemy_08_boss","enemy_09_seiya"]
	for definition in definitions:
		target.apply_character_data(load("res://data/enemies/%s.tres" % definition))
		for direction in [1,-1]:
			var label: String = definition + ("_R" if direction == 1 else "_L")
			await reset(manager, attacker, Vector2(640 - 120 * direction,520), direction)
			await reset(manager, target, Vector2(640,520), -direction)
			attacker.set_physics_process(false)
			var sprite: AnimatedSprite2D = target.animated_character_sprite
			var scale_before := sprite.scale
			var pivot_before := sprite.position
			var packet: Dictionary = attacker._get_character_special_attack_dictionary()
			check(packet.causes_knockdown, label + " special always launches on hit")
			check(target._get_damage_animation_from_attack(packet) == &"received_akky_elbow_hit", label + " attack-specific victim hit")
			check(target._get_knockdown_animation_from_attack(packet) == &"received_akky_elbow_down", label + " attack-specific victim down")
			var ordinary := packet.duplicate()
			ordinary.is_special = false
			ordinary.attack_id = "ordinary_punch"
			check(target._get_damage_animation_from_attack(ordinary) != &"received_akky_elbow_hit", label + " ordinary hit remains ordinary")
			attacker.set_special_gauge(100)
			attacker.input_enabled = true
			attacker.start_character_special()
			attacker._update_visual_state()
			await capture(label + "_startup")
			attacker.enter_character_special_active()
			attacker._update_visual_state()
			attacker.input_enabled = false
			attacker.set_physics_process(true)
			var start: Vector2 = target.position
			check(attacker._get_character_special_hit_position(target).y < start.y-80.0,label + " effect at special contact height")
			attacker._on_character_special_hitbox_area_entered(target.get_node("HurtBox"))
			await process_frame
			await process_frame
			check(target.knockdown_state == &"KNOCKBACK", label + " actual contact enters flight")
			check(target.last_special_knockback_animation == &"received_akky_elbow_air", label + " victim airborne selection")
			check(target.velocity.x * direction > 500, label + " large outward velocity")
			await capture(label + "_impact")
			var apex := start.y
			var distance := 0.0
			var captured_air := false
			for frame in range(150):
				await physics_frame
				if definition == "enemy_01_standard" and direction == 1 and frame % 4 == 0:
					await capture("preview_%03d" % frame)
				apex = minf(apex,target.position.y)
				distance = maxf(distance,(target.position.x - start.x) * direction)
				check(sprite.scale.is_equal_approx(scale_before), label + " constant sprite scale")
				check(sprite.position.is_equal_approx(pivot_before), label + " constant sprite pivot")
				if not captured_air and start.y-target.position.y > 55:
					check_visible_art(sprite,label + " airborne")
					await capture(label + "_air")
					captured_air = true
				if target.knockdown_state == &"KNOCKDOWN": break
			check(captured_air and start.y-apex > 55, label + " visible upward arc")
			check(distance > 200, label + " flies over 200 pixels")
			check(target.knockdown_state == &"KNOCKDOWN", label + " lands in down state")
			target._update_visual_state()
			check(sprite.animation == &"received_akky_elbow_down", label + " grounded victim pose")
			check_visible_art(sprite,label + " down")
			await capture(label + "_down")
			print("SPECIAL_FLIGHT %s distance=%.1f height=%.1f" % [label,distance,start.y-apex])
			attacker.finish_character_special()
			await reset(manager, target, Vector2(640,520), -direction)
			target.set_physics_process(false)
			target.is_guarding = true
			target.guard_type = "high"
			check(not target.receive_attack(packet,direction,target.global_position,attacker),label + " guard succeeds")
			check(target.knockdown_state == &"" and target.is_guard_hit,label + " guard never launches")
	# A lethal special must still fly, land, and remain defeated without getting up.
	await reset(manager, attacker, Vector2(520,520),1)
	await reset(manager, target, Vector2(640,520),-1)
	attacker.set_physics_process(false)
	target.current_hp = 1
	var lethal: Dictionary = attacker._get_character_special_attack_dictionary()
	check(target.receive_attack(lethal,1,target.global_position,attacker),"lethal special connects")
	check(target.current_hp == 0 and target.special_ko_flight,"lethal special retains KO and launch")
	for frame in range(180):
		await physics_frame
		if target.knockdown_state == &"KNOCKDOWN": break
	check(target.knockdown_state == &"KNOCKDOWN","lethal special lands")
	target.update_knockdown(2.0)
	check(target.current_hp == 0 and target.knockdown_state == &"KNOCKDOWN","KO never gets up")
	Engine.time_scale = 1.0
	print("SPECIAL_LAUNCH_REACTION_CHECK failures=%s screenshots=%d" % [failures,screenshots])
	for audio in root.find_children("*","AudioStreamPlayer",true,false): audio.stop()
	for audio in root.find_children("*","AudioStreamPlayer2D",true,false): audio.stop()
	OS.delay_msec(200)
	battle.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures.is_empty() else 1)
