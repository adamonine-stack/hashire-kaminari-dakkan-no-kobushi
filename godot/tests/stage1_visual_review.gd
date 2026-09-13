extends SceneTree

var output: String

func _initialize() -> void:
	call_deferred("run")

func snap(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Visual review requires a rendering display; use stage1_regression.gd for headless checks.")
		quit(1)
		return
	output = ProjectSettings.globalize_path("res://../audit_evidence")
	DirAccess.make_dir_recursive_absolute(output)
	var battle = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var manager = battle.get_node("BattleManager")
	for entry in manager.player_team:
		manager.select_order_character(String(entry.fighter_id))
	manager.confirm_player_order()
	for i in range(360):
		await physics_frame
		if manager.isRoundActive:
			break
	var player = battle.get_node("Player")
	var enemy = battle.get_node("Enemy")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	battle.set_process(false)
	player.position = Vector2(470, 520)
	enemy.position = Vector2(810, 520)
	battle.get_node("BattleCamera").position = Vector2(640, 360)
	battle.get_node("BattleCamera").zoom = Vector2.ONE
	player._play_visual_animation(&"idle_ready", true)
	enemy._play_visual_animation(&"idle", true)
	var sprite: AnimatedSprite2D = player.animated_character_sprite
	sprite.pause()
	enemy.animated_character_sprite.pause()
	var baseline_scale := sprite.scale / float(player.fighter_definition.visual_scale_adjustment)
	var baseline_position := sprite.position / float(player.fighter_definition.visual_scale_adjustment)
	for percent in [95, 100, 105, 110]:
		sprite.scale = baseline_scale * float(percent) / 100.0
		sprite.position = baseline_position * float(percent) / 100.0
		await snap("size_%d" % percent)
	sprite.scale = baseline_scale * float(player.fighter_definition.visual_scale_adjustment)
	sprite.position = baseline_position * float(player.fighter_definition.visual_scale_adjustment)
	for clip in ["walk_forward", "walk_backward", "dash", "jump_start", "jump_fall", "jump_land", "punch_1", "punch_2", "kick_1", "kick_2", "crouch_idle", "crouch_guard", "crouch_punch", "crouch_sweep_kick", "jump_kick", "jump_punch_down", "damage_high", "damage_low", "knockdown_high", "knockdown_low", "stand_up", "ko"]:
		if not sprite.sprite_frames.has_animation(clip):
			continue
		player._play_visual_animation(StringName(clip), true)
		sprite.pause()
		for frame in range(sprite.sprite_frames.get_frame_count(clip)):
			sprite.set_frame_and_progress(frame, 0.0)
			await snap("review_%s_%02d" % [clip, frame])
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	await create_timer(1.0).timeout
	print("STAGE1_VISUAL_EXPORT_OK ", output)
	quit()
