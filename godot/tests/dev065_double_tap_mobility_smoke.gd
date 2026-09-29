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

	var playable_definitions := [
		load("res://data/fighters/ally_balance.tres"),
		load("res://data/fighters/ally_power.tres"),
		load("res://data/fighters/ally_speed.tres"),
	]
	var backstep_signatures: Array[String] = []
	for definition in playable_definitions:
		check(definition != null, "playable fighter definition loads")
		if definition == null:
			continue
		var probe := fighter_scene.instantiate()
		probe.name = "Probe"
		get_root().add_child(probe)
		await process_frame
		probe.set_physics_process(false)
		probe.apply_character_data(definition)
		var frames: SpriteFrames = probe.animated_character_sprite.sprite_frames
		var fighter_id := String(definition.fighter_id)
		check(frames != null, fighter_id + ": authored SpriteFrames load")
		if frames != null:
			check(frames.has_animation("dash"), fighter_id + ": dash clip exists")
			check(frames.has_animation("backstep"), fighter_id + ": dedicated backstep clip exists")
			if frames.has_animation("backstep"):
				check(frames.get_frame_count("backstep") >= 4, fighter_id + ": backstep has multi-pose motion")
				check(not frames.get_animation_loop("backstep"), fighter_id + ": backstep does not loop")
				if fighter_id == "player_01_akky":
					check(frames.get_frame_count("backstep") == 6, "player_01_akky: dedicated six-frame backstep loads")
					for frame_index in range(frames.get_frame_count("backstep")):
						var backstep_texture := frames.get_frame_texture("backstep", frame_index)
						check(backstep_texture != null and backstep_texture.get_width() == 320 and backstep_texture.get_height() == 224, "player_01_akky: backstep frame uses 320x224 authored cell")
				var backstep_regions: Array[String] = []
				for index in range(frames.get_frame_count("backstep")):
					var texture := frames.get_frame_texture("backstep", index)
					if texture is AtlasTexture:
						backstep_regions.append(str((texture as AtlasTexture).region))
				var dash_regions: Array[String] = []
				for index in range(frames.get_frame_count("dash")):
					var texture := frames.get_frame_texture("dash", index)
					if texture is AtlasTexture:
						dash_regions.append(str((texture as AtlasTexture).region))
				var reversed_dash_regions: Array[String] = dash_regions.duplicate()
				reversed_dash_regions.reverse()
				check(backstep_regions != reversed_dash_regions, fighter_id + ": backstep is not reversed dash playback")
				backstep_signatures.append(fighter_id + ":" + str(backstep_regions))
		probe.queue_free()
		await process_frame
	check(backstep_signatures.size() == 3, "all three playable fighters expose backstep signatures")
	if backstep_signatures.size() == 3:
		check(backstep_signatures[0] != backstep_signatures[1], "Akky and Gou use different backstep poses")
		check(backstep_signatures[0] != backstep_signatures[2], "Akky and Seiya use different backstep poses")
		check(backstep_signatures[1] != backstep_signatures[2], "Gou and Seiya use different backstep poses")

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

	print("DEV065_DOUBLE_TAP_MOBILITY_OK failures=%s" % [failures])
	player.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
