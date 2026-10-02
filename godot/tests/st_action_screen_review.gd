extends SceneTree

var output: String
var captured_files: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func snap(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))
	captured_files.append(label + ".png")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	DisplayServer.window_set_title("ST_action four-item review")
	output = ProjectSettings.globalize_path("res://../evidence/before" if "--before" in OS.get_cmdline_user_args() else "res://../evidence/final")
	DirAccess.make_dir_recursive_absolute(output)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	current_scene = battle
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager.select_player_by_id(String(manager.player_team[0].fighter_id))
	for i in range(1200):
		await physics_frame
		if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible:
			manager._advance_enemy_intro()
		if manager.isRoundActive: break
	var player: Node = battle.get_node("Player")
	var enemy: Node = battle.get_node("Enemy")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	battle.set_process(false)
	manager.set_process(false)
	manager.set_physics_process(false)
	for stage in range(manager.enemy_team.size()):
		# Clean this tool's previous stage captures, never game assets.
		for filename in DirAccess.get_files_at(output):
			if filename.begins_with("stage%02d_" % (stage + 1)) and filename.ends_with(".png"):
				DirAccess.remove_absolute(output.path_join(filename))
		manager.current_enemy_index = stage
		manager.spawn_active_enemy()
		manager._apply_current_stage_definition()
		player.position = Vector2(470, 520)
		enemy.position = Vector2(810, 520)
		battle.get_node("BattleCamera").position = Vector2(640, 360)
		battle.get_node("BattleCamera").zoom = Vector2.ONE
		manager._show_enemy_intro(manager.enemy_team[stage])
		manager._enemy_intro_label.visible_characters = -1
		await snap("stage%02d_intro" % (stage + 1))
		manager._enemy_intro_panel.hide()
		player._play_visual_animation(&"idle", true)
		player.animated_character_sprite.pause()
		var sprite: AnimatedSprite2D = enemy.animated_character_sprite
		var clips: Array = ["idle", "walk", "dash", "jump_start", "jump_air", "jump_fall", "jump_land", "punch", "kick", "special", "guard", "crouch", "damage", "down", "getup", "ko"]
		if "--all-clips" in OS.get_cmdline_user_args():
			clips = Array(sprite.sprite_frames.get_animation_names())
		var captured := {}
		for clip in clips:
			if not sprite.sprite_frames.has_animation(clip): continue
			enemy._play_visual_animation(StringName(clip), true)
			sprite.pause()
			for frame in range(sprite.sprite_frames.get_frame_count(clip)):
				sprite.set_frame_and_progress(frame, 0.0)
				var texture: Texture2D = sprite.sprite_frames.get_frame_texture(clip, frame)
				var key := str(texture.get_rid()) + str(sprite.position) + str(sprite.scale)
				if texture is AtlasTexture: key = str(texture.atlas.get_rid()) + str(texture.region) + str(sprite.position) + str(sprite.scale)
				if captured.has(key): continue
				captured[key] = true
				await snap("stage%02d_%s_%02d" % [stage + 1, clip, frame])
		print("SCREEN_STAGE ", stage + 1, " ", enemy.fighter_definition.fighter_id, " clips=", clips.size(), " unique_frames=", captured.size(), " scale=", sprite.scale, " position=", sprite.position)
	manager.current_enemy_index = 4
	manager.spawn_active_enemy()
	manager._apply_current_stage_definition()
	enemy._play_visual_animation(&"idle", true)
	enemy.animated_character_sprite.pause()
	for value in [0.0, 35.0, 75.0]:
		player.set_special_gauge(value)
		await snap("gauge_%03d" % value)
		await create_timer(0.4).timeout
	player.set_special_gauge(100.0)
	await snap("gauge_max_arrival")
	await create_timer(0.8).timeout
	await snap("gauge_max_hold")
	for i in range(40): player.set_special_gauge(100.0)
	await snap("gauge_max_repeated")
	manager.reset_active_fighter_state(player, Vector2(470,520), 1.0)
	player.is_round_active = true
	player.input_enabled = true
	player.velocity = Vector2(0,1)
	player.move_and_slide()
	player.set_special_gauge(100.0)
	var started: bool = player.request_character_special()
	assert(started, "real special request must start")
	await snap("gauge_special_used")
	assert(player.get_special_gauge() < 100.0)
	assert(not manager.battle_hud.special_gauge_is_full)
	player.enter_character_special_active()
	await snap("gauge_special_active")
	player.finish_character_special()
	await snap("gauge_after_special")
	var manifest := FileAccess.open(output.path_join("capture-manifest.json"), FileAccess.WRITE)
	manifest.store_string(JSON.stringify(captured_files, "\t"))
	manifest.close()
	print("SCREEN_REVIEW_EXPORTED ", output)
	if "--hold" in OS.get_cmdline_user_args():
		await create_timer(240.0).timeout
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	quit()
