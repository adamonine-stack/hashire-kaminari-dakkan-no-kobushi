extends SceneTree

var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fighter = load("res://data/fighters/ally_power.tres")
	var controller = load("res://scripts/characters/character_visual_controller.gd").new()
	var sprite := AnimatedSprite2D.new()
	var fallback := Sprite2D.new()
	root.add_child(controller)
	root.add_child(sprite)
	root.add_child(fallback)
	check(controller.setup(fighter, sprite, fallback), "Gou atlas loads through production controller")
	var frames := sprite.sprite_frames
	var scale_before := sprite.scale
	var position_before := sprite.position
	var checked := 0
	for clip in frames.get_animation_names():
		controller.play_animation(StringName(clip), true)
		check(sprite.scale.is_equal_approx(scale_before), clip + ": fixed body scale")
		check(sprite.position.is_equal_approx(position_before), clip + ": fixed origin")
		for index in range(frames.get_frame_count(clip)):
			var texture := frames.get_frame_texture(clip, index)
			check(texture is AtlasTexture and texture.atlas == fighter.motion_atlas.texture, clip + ": uses new art")
			check(texture.get_size() == Vector2(384, 288), clip + ": cell size")
			var rect := texture.get_image().get_used_rect()
			check(rect.has_area() and rect.position.x >= 2 and rect.position.y >= 2 and rect.end.x < 382 and rect.end.y <= 270, clip + ": unclipped body and baseline")
			checked += 1
	for required in ["idle_prebattle", "walk_forward", "walk_backward", "dash", "jump_start", "jump_air", "jump_fall", "jump_land", "guard", "crouch_guard", "punch_1", "punch_2", "kick_1", "crouch_punch", "crouch_kick_sweep", "jump_punch_down", "jump_kick", "throw", "special_iron_breaker", "victory", "stand_up", "ko"]:
		check(frames.has_animation(required), required + ": explicit motion")
	check(not frames.get_animation_loop("ko"), "KO does not loop")
	check(frames.get_frame_texture("ko", 2).region == frames.get_frame_texture("down", 0).region, "KO holds prone pose")
	check(frames.get_frame_count("walk") == 6 and frames.get_frame_count("dash") == 6, "complete movement cycles")
	check(fighter.character_height_cm == 170.0, "reference stature")
	check(fighter.max_health == 130.0 and fighter.move_speed == 175.0 and fighter.punch_damage == 18.0 and fighter.kick_damage == 25.0, "combat balance preserved")
	controller.queue_free()
	sprite.queue_free()
	fallback.queue_free()
	await process_frame
	# Use the real battle and selected fighter, including the existing HP ledger.
	var battle = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var manager = battle.get_node("BattleManager")
	await manager.select_player_by_id("player_02_gou")
	for i in range(480):
		await physics_frame
		if manager.isRoundActive:
			break
	check(manager.isRoundActive, "Gou starts through player selection")
	var player = battle.get_node("Player")
	var enemy = battle.get_node("Enemy")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	check(player.fighter_definition.fighter_id == &"player_02_gou", "selected fighter ID preserved")
	check(player.max_hp == 65, "published campaign HP preserved")
	for facing in [-1, 1]:
		player.facing_direction = facing
		player.character_visual_controller.set_facing(facing)
		check(player.animated_character_sprite.flip_h == (facing < 0), "both facings")
		for id in ["player2_punch_1", "player2_punch_2", "player2_kick_finish"]:
			player.start_attack(id)
			player.enter_attack_active()
			player._sync_attack_visual_phase()
			check(player.animated_character_sprite.frame == 3, id + ": active contact frame")
			var area: Area2D = player.kick_area if id.contains("kick") else player.punch_area
			check(signf(area.position.x) == float(facing) and area.position.y < -100, id + ": hitbox follows limb/facing")
			player.enter_attack_recovery()
			player._sync_attack_visual_phase()
			check(player.animated_character_sprite.frame >= 4, id + ": recovery retracts")
			player.finish_attack()
		for action in ["crouch_punch", "crouch_kick", "jump_punch", "jump_kick"]:
			player.is_crouching = action.begins_with("crouch")
			var id := "player2_punch_1"
			if action == "crouch_kick":
				id = player._ensure_crouch_kick_sweep_attack_data()
			elif action == "jump_punch":
				id = player._ensure_air_punch_down_attack_data()
			elif action == "jump_kick":
				id = player._ensure_air_kick_attack_data()
			player.start_attack(id)
			if action == "crouch_punch":
				player._play_visual_animation(&"crouch_punch", true)
			player.enter_attack_active()
			player._sync_attack_visual_phase()
			check(player.animated_character_sprite.frame == (3 if action.begins_with("crouch") else 1), action + ": contact frame")
			var area: Area2D = player.kick_area if action.ends_with("kick") else player.punch_area
			check(signf(area.position.x) == float(facing) and area.position.y < 0, action + ": hitbox stays above ground")
			player.finish_attack()
			player.is_crouching = false
	player.set_special_gauge(100)
	check(player.request_character_special(false), "Gou special starts through real gauge path")
	check(player.animated_character_sprite.animation == &"special_startup", "Iron Breaker windup")
	player.enter_character_special_active()
	check(player.animated_character_sprite.animation == &"special_iron_breaker", "Iron Breaker contact")
	player.enter_character_special_recovery()
	check(player.animated_character_sprite.animation == &"special_recovery", "Iron Breaker recovery")
	player.finish_character_special()
	print("GOU_MOTION_ATLAS_OK clips=%d frames=%d failures=%s" % [frames.get_animation_names().size(), checked, failures])
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
