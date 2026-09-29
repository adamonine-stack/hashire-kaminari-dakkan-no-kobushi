extends SceneTree

var failures: Array[String] = []


func check(ok: bool, label: String) -> void:
	if ok:
		return
	failures.append(label)
	push_error(label)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fighter_scene := load("res://scenes/Player.tscn") as PackedScene
	check(fighter_scene != null, "Player scene loads")
	if fighter_scene == null:
		quit(1)
		return

	var player := fighter_scene.instantiate()
	player.name = "Player"
	get_root().add_child(player)
	await process_frame
	player.set_physics_process(false)

	var fighter_definition := load("res://data/fighters/ally_balance.tres")
	check(fighter_definition != null, "Akky definition loads")
	if fighter_definition == null:
		player.queue_free()
		quit(1)
		return
	player.apply_character_data(fighter_definition)
	player.input_enabled = true
	player.is_round_active = true
	player.current_hp = player.max_hp

	var frames: SpriteFrames = player.animated_character_sprite.sprite_frames
	check(frames != null, "Akky authored SpriteFrames load")
	if frames != null:
		check(frames.has_animation("dash"), "dash clip exists")
		check(frames.has_animation("backstep"), "backstep clip exists")
		if frames.has_animation("backstep"):
			check(frames.get_frame_count("backstep") == 4, "backstep has four authored frames")
			check(not frames.get_animation_loop("backstep"), "backstep does not loop")

	player.facing_direction = 1.0
	check(player._consume_horizontal_tap(1.0, 1000) == &"", "first forward tap only arms dash")
	check(player._consume_horizontal_tap(1.0, 1200) == &"dash", "second forward tap within window requests dash")
	check(player._consume_horizontal_tap(-1.0, 2000) == &"", "first back tap only arms backstep")
	check(player._consume_horizontal_tap(-1.0, 2200) == &"backstep", "second back tap within window requests backstep")
	check(player._consume_horizontal_tap(1.0, 3000) == &"", "timeout test first tap")
	check(player._consume_horizontal_tap(1.0, 3300) == &"", "tap outside window does not dash")
	check(player._consume_horizontal_tap(-1.0, 4000) == &"", "direction-change first tap")
	check(player._consume_horizontal_tap(1.0, 4100) == &"", "different directions never form a double tap")

	player.facing_direction = -1.0
	check(player._consume_horizontal_tap(-1.0, 5000) == &"", "left-facing first forward tap")
	check(player._consume_horizontal_tap(-1.0, 5200) == &"dash", "left-facing forward double tap dashes")
	check(player._consume_horizontal_tap(1.0, 6000) == &"", "left-facing first back tap")
	check(player._consume_horizontal_tap(1.0, 6200) == &"backstep", "left-facing back double tap backsteps")

	player.facing_direction = 1.0
	player._start_backstep(-1.0)
	check(player.is_backstepping, "backstep state starts")
	check(not player.is_dashing, "backstep excludes dash state")
	check(player.backstep_direction == -1.0, "backstep preserves rear direction")
	check(player.velocity.x < 0.0, "backstep launches away from opponent")
	check(String(player.animated_character_sprite.animation) == "backstep", "backstep animation starts")
	player._cancel_current_action()
	check(not player.is_backstepping, "action cancellation clears backstep")

	player._start_dash(1.0)
	check(player.is_dashing, "dash state starts")
	check(player.dash_direction == 1.0, "dash preserves forward direction")
	check(String(player.animated_character_sprite.animation) == "dash", "dash animation starts")
	player._cancel_current_action()
	check(not player.is_dashing, "action cancellation clears dash")

	print("DEV065_DOUBLE_TAP_MOBILITY_OK failures=%s" % failures)
	player.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
