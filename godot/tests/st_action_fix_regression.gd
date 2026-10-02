extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func run() -> void:
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	var hud: Node = manager.battle_hud
	var player: Node = battle.get_node("Player")
	var enemy: Node = battle.get_node("Enemy")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	manager.select_player_by_id(String(manager.player_team[0].fighter_id))
	var child_count: int = hud.get_child_count()
	player.set_special_gauge(35.0)
	check(not hud.special_gauge_is_full and hud.player_special_fill.bg_color == Color("26ceef"), "partial gauge is cyan")
	player.set_special_gauge(100.0)
	check(hud.special_gauge_is_full and hud.special_flash_remaining > 0.0, "MAX edge starts flash")
	hud._process(0.2)
	var flash: float = hud.special_flash_remaining
	for i in range(40): player.set_special_gauge(100.0)
	check(is_equal_approx(hud.special_flash_remaining, flash), "repeated MAX signals do not restart flash")
	check(hud.get_child_count() == child_count, "repeated MAX signals create no extra effect nodes")
	hud._process(1.0)
	check(hud.special_gauge_is_full and hud.special_flash_remaining == 0.0 and hud.player_special_background.shadow_size > 0, "MAX maintains glow after single flash")
	player.is_round_active = true
	player.input_enabled = true
	player.start_character_special()
	check(player.get_special_gauge() < 100.0, "real special startup consumes gauge")
	check(not hud.special_gauge_is_full and hud.special_flash_remaining == 0.0 and hud.player_special_background.shadow_size == 0, "special consumption immediately stops glow and flash")
	check(hud.player_special_fill.bg_color == Color("26ceef"), "consumption restores cyan")
	player.reset_character_special_state(true)
	var initial_floor_size: Vector2 = battle.get_node("Floor/CollisionShape2D").shape.size
	var previous_frames: SpriteFrames
	for stage in range(8):
		manager.current_enemy_index = stage
		manager.spawn_active_enemy()
		manager._apply_current_stage_definition()
		manager._show_enemy_intro(manager.enemy_team[stage])
		check(manager._enemy_intro_pages[0].begins_with("STAGE %d  " % (stage + 1)), "stage %d starts with its number" % (stage + 1))
		for page in manager._enemy_intro_pages:
			check(not "/ 9" in page and not "/9" in page, "stage %d intro hides total" % (stage + 1))
		check(battle.get_node("Floor/CollisionShape2D").shape.size == initial_floor_size, "stage %d keeps collision floor" % (stage + 1))
		var sprite: AnimatedSprite2D = enemy.animated_character_sprite
		check(sprite.sprite_frames != previous_frames, "stage %d installs separate SpriteFrames" % (stage + 1))
		previous_frames = sprite.sprite_frames
		check(sprite.offset == Vector2.ZERO and sprite.centered and sprite.z_index == 2, "stage %d resets sprite pivot and draw order" % (stage + 1))
		var fixed_scale := sprite.scale
		var fixed_position := sprite.position
		for clip in sprite.sprite_frames.get_animation_names():
			enemy._play_visual_animation(clip, true)
			check(sprite.scale.is_equal_approx(fixed_scale), "stage %d %s retains scale" % [stage + 1, clip])
			check(sprite.position.is_equal_approx(fixed_position), "stage %d %s retains pivot" % [stage + 1, clip])
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	print("ST_ACTION_FIX_REGRESSION failures=", failures)
	quit(0 if failures.is_empty() else 1)
