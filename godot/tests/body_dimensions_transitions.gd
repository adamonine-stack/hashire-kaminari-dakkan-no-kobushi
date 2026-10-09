extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	var stage := "transitions_after" if "--after" in args else "transitions"
	if "--remaining" in args:
		stage = "transitions_remaining"
	if "--unique-captures" in args:
		stage += "_unique"
	if "--upper-lower" in args:
		stage = "transitions_upper_lower"
	if "--hold-air" in args:
		stage = "air_gui_review"
	if "--hold-back" in args:
		stage = "back_throw_gui_review"
	if "--live-review" in args:
		stage = "transitions_live_review"
	if "--realtime" in args:
		stage = "transitions_realtime_review"
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/body_dimensions/" + stage)
	if "--special-guard" in args: stage = "special_guard_transitions"
	if "--special-guard" in args and "--realtime" in args: stage = "special_guard_realtime"
	if "--ground-bounce" in args: stage = "ground_bounce_transitions"
	if "--ground-bounce" in args and "--realtime" in args: stage = "ground_bounce_realtime"
	if "--wall" in args: stage = "wall_transitions"
	if "--wall" in args and "--realtime" in args: stage = "wall_realtime"
	folder = ProjectSettings.globalize_path("res://../audit_evidence/body_dimensions/" + stage)
	DirAccess.make_dir_recursive_absolute(folder)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager.select_player_by_id(String(manager.player_team[0].fighter_id))
	for tick in range(360):
		await physics_frame
		if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible:
			manager.enemy_intro_finished.emit()
		if manager.isRoundActive:
			break
	var player: Node2D = battle.get_node("Player")
	var enemy: Node2D = battle.get_node("Enemy")
	if not manager.isRoundActive:
		push_error("Battle did not start")
		quit(1)
		return
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	player.set_process(false)
	enemy.set_process(false)
	manager.set_process(false)
	manager.set_physics_process(false)
	# Keep comparison captures at the same camera scale throughout the sequence.
	battle.set_process(false)
	player.position = Vector2(470, 520)
	enemy.position = Vector2(810, 520)
	battle.get_node("BattleCamera").position = Vector2(640, 360)
	battle.get_node("BattleCamera").zoom = Vector2.ONE
	var sequences := [["idle","punch_1","idle"], ["idle","kick_1","idle"], ["idle","damage_light","idle"],
		["walk_forward","jump_up","jump_fall","jump_land","walk_forward"], ["walk_forward","punch_1","damage_heavy","idle"], ["special","idle"]]
	if "--hit-only" in args:
		sequences = [["idle","damage_light","idle"], ["idle","damage_heavy","idle"]]
	if "--remaining" in args:
		sequences.append(["idle","damage_high","idle","damage_low","idle"])
	if "--live-review" in args:
		sequences.append(["idle","akky_throw_back_start","akky_throw_back_release","idle"])
		sequences.append(["walk_forward","jump_up","akky_air_punch","jump_fall","jump_land","idle"])
		sequences.append(["idle","special_guard","idle"])
	if "--upper-lower" in args:
		sequences = [["idle","damage_high","idle"], ["idle","damage_low","idle"]]
	if "--hold-heavy" in args or "--hold-upper-lower" in args or "--hold-air" in args or "--hold-back" in args:
		sequences = []
	var rows: Array[Dictionary] = []
	if "--special-guard" in args: sequences = [["idle", "special_guard", "idle"], ["walk_forward", "special_guard", "idle"]]
	if "--special-guard" in args and "--hold" in args: sequences = []
	if "--ground-bounce" in args: sequences = [["idle", "ground_impact", "ground_bounce", "down", "stand_up", "idle"]]
	if "--ground-bounce" in args and "--hold" in args: sequences = []
	if "--wall" in args: sequences = [["idle", "wall_hit", "wall_fall", "down", "stand_up", "idle"]]
	if "--wall" in args and "--hold" in args: sequences = []
	for target in [player, enemy]:
		if "--akky-only" in args and target != player:
			continue
		var sprite: AnimatedSprite2D = target.animated_character_sprite
		for facing in [1,-1]:
			target.facing_direction = facing
			target._set_visual_facing()
			for sequence_index in range(sequences.size()):
				for clip in sequences[sequence_index]:
					if not sprite.sprite_frames.has_animation(clip):
						rows.append({"actor": target.name, "clip": clip, "status":"unverified_missing_clip"})
						continue
					var actor_folder := folder.path_join("%s_%d_%d" % [target.name, facing, sequence_index])
					DirAccess.make_dir_recursive_absolute(actor_folder)
					target._play_visual_animation(StringName(clip), true)
					var count := sprite.sprite_frames.get_frame_count(clip)
					var seconds := float(count) / sprite.sprite_frames.get_animation_speed(clip)
					var captured_frames: Array[int] = []
					var observed_frames: Array[int] = []
					var start_usec := Time.get_ticks_usec()
					var timeline: Array[Dictionary] = []
					for tick in range(maxi(1, ceili(seconds * 60))):
						await physics_frame
						timeline.append({"tick":tick,"frame":sprite.frame})
						if sprite.frame not in observed_frames: observed_frames.append(sprite.frame)
						if "--realtime" not in args and ("--unique-captures" not in args or sprite.frame not in captured_frames):
							RenderingServer.force_draw(true)
							root.get_texture().get_image().save_png(actor_folder.path_join("%s_%03d.png" % [clip,tick]))
							captured_frames.append(sprite.frame)
					rows.append({"actor":target.name,"fighter_id":target.fighter_definition.fighter_id,"clip":clip,"facing":facing,"sequence":sequence_index,"captured_frames":captured_frames,"observed_frames":observed_frames,"expected_frames":count,"elapsed_usec":Time.get_ticks_usec()-start_usec,"timeline":timeline,"status":"live_realtime_anatomy_unverified" if "--realtime" in args else "rendered_anatomy_unverified"})
	if not rows.is_empty():
		var output := FileAccess.open(folder.path_join("inventory.json"),FileAccess.WRITE)
		output.store_string(JSON.stringify(rows,"  "))
	if "--hold-heavy" in args or "--hold-upper-lower" in args or "--hold-air" in args or "--hold-back" in args:
		player.facing_direction = -1 if "--left" in args else 1
		player._set_visual_facing()
		var hold_clip := &"akky_air_punch" if "--hold-air" in args else (&"damage_low" if "--hold-upper-lower" in args else &"damage_heavy")
		if "--hold-back" in args: hold_clip = &"akky_throw_back_release"
		player._play_visual_animation(hold_clip, true)
		player.animated_character_sprite.pause()
		player.animated_character_sprite.frame = 0 if "--hold-back" in args else (2 if "--hold-air" in args else 1)
		print("BODY_HOLD_REVIEW clip=",hold_clip," frame=",player.animated_character_sprite.frame)
		await create_timer(60.0 if "--hold-air" in args or "--hold-back" in args else 30.0).timeout
	if "--special-guard" in args and "--hold" in args:
		player.facing_direction = -1 if "--left" in args else 1
		player._set_visual_facing()
		player._play_visual_animation(&"special_guard", true)
		player.animated_character_sprite.pause()
		player.animated_character_sprite.frame = 1
		print("SPECIAL_GUARD_GUI_HOLD")
		await create_timer(45).timeout
	if "--ground-bounce" in args and "--hold" in args:
		player.facing_direction = -1 if "--left" in args else 1
		player._set_visual_facing()
		player._play_visual_animation(&"ground_impact", true)
		player.animated_character_sprite.pause()
		player.animated_character_sprite.frame = 0
		print("GROUND_BOUNCE_GUI_HOLD")
		await create_timer(60).timeout
	if "--wall" in args and "--hold" in args:
		player.facing_direction = -1 if "--left" in args else 1
		player._set_visual_facing()
		player._play_visual_animation(&"wall_fall" if "--fall" in args else &"wall_hit",true)
		player.animated_character_sprite.pause()
		print("WALL_GUI_HOLD")
		await create_timer(60).timeout
	manager.cleanup_battle_before_transition()
	print("BODY_TRANSITIONS rendered_segments=", rows.size())
	quit()
