extends SceneTree

var failures: Array[String] = []
var actor: Node
var enemy: Node
var screenshot_count := 0
var output := ""

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	RenderingServer.force_draw(false)
	var result := root.get_texture().get_image().save_png(output.path_join(label + ".png"))
	check(result == OK, "screenshot " + label)
	screenshot_count += 1

func reset_actor() -> void:
	actor.reset_character_special_state(true)
	actor.reset_knockdown_state()
	actor._cancel_current_action()
	actor.is_hit = false
	actor.is_guard_hit = false
	actor.is_invincible = false
	actor.invincibility_timer = 0.0
	actor.hit_stop_timer = 0.0
	actor.current_hp = actor.max_hp
	actor.is_round_active = true
	actor.input_enabled = true
	actor.position = Vector2(580, 520)
	actor.facing_direction = 1.0
	actor.set_special_gauge(100)

func run() -> void:
	output = ProjectSettings.globalize_path("res://").path_join("../evidence/akky_reversal").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager._hide_player_selection()
	manager._set_battle_active(true)
	paused = false
	for i in range(90):
		await physics_frame
		if battle.get_node("Player").is_on_floor() and battle.get_node("Enemy").is_on_floor(): break
	actor = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	actor.set_physics_process(false)
	enemy.set_physics_process(false)
	actor.apply_character_data(load("res://data/fighters/ally_balance.tres"))
	enemy.apply_character_data(load("res://data/enemies/enemy_04_throw.tres"))
	enemy.position = Vector2(700,520)
	enemy.facing_direction = -1.0
	enemy.is_round_active = true
	reset_actor()
	var sprite: AnimatedSprite2D = actor.animated_character_sprite
	var fixed_scale := sprite.scale
	var fixed_pivot := sprite.position
	var atlas_paths: Array[String] = []
	var clips := {"akky_reversal_startup":2, "akky_reversal_elbow":1, "akky_reversal_finish":1,
		"special_hit":2, "special_knockback":2, "special_knockdown":1, "special_guard":2}
	for clip in clips:
		check(sprite.sprite_frames.has_animation(clip), "dedicated clip " + clip)
		check(sprite.sprite_frames.get_frame_count(clip) == clips[clip], "frame count " + clip)
		for frame_number in range(clips[clip]):
			var frame := sprite.sprite_frames.get_frame_texture(clip, frame_number) as AtlasTexture
			check(frame != null and frame.region.size == Vector2(320,224), "fixed cell " + clip)
			check(frame != null and String(frame.atlas.resource_path).contains("reversal_v1"), "authored source " + clip)
			if frame != null: atlas_paths.append(frame.atlas.resource_path)
			for facing in [1.0, -1.0]:
				actor.facing_direction = facing
				actor._set_visual_facing()
				sprite.play(clip)
				sprite.pause()
				sprite.frame = frame_number
				check(sprite.scale.is_equal_approx(fixed_scale), "scale invariant " + clip)
				check(sprite.position.is_equal_approx(fixed_pivot), "pivot invariant " + clip)
				await capture("%s_%d_%s" % [clip, frame_number, "R" if facing > 0 else "L"])
	# Check actual state transitions, not only direct SpriteFrames selection.
	reset_actor()
	actor.start_character_special()
	actor._update_visual_state()
	check(sprite.animation == &"akky_reversal_startup", "runtime startup")
	actor.enter_character_special_active()
	actor._update_visual_state()
	check(sprite.animation == &"akky_reversal_elbow", "runtime dedicated elbow")
	actor.enter_character_special_recovery()
	actor._update_visual_state()
	check(sprite.animation == &"akky_reversal_finish", "runtime finish")
	reset_actor()
	var packet: Dictionary = enemy._get_character_special_attack_dictionary()
	check(actor.receive_attack(packet, -1.0, actor.global_position, enemy), "runtime special damage")
	actor._update_visual_state()
	check(sprite.animation == &"special_hit", "runtime special hit reaction")
	reset_actor()
	packet.causes_knockdown = true
	check(actor.receive_attack(packet, -1.0, actor.global_position, enemy), "runtime special launch")
	actor._update_visual_state()
	check(sprite.animation == &"special_knockback", "airborne reaction before landing")
	actor.enter_knockdown()
	actor._update_visual_state()
	check(sprite.animation == &"special_knockdown", "ground reaction after landing")
	reset_actor()
	actor.is_guarding = true
	actor.guard_type = "high"
	check(not actor.receive_attack(packet, -1.0, actor.global_position, enemy), "runtime guard succeeds")
	actor._update_visual_state()
	check(sprite.animation == &"special_guard", "runtime special guard reaction")
	print("AKKY_REVERSAL_MOTION_CHECK failures=%s screenshots=%d scale=%s pivot=%s" % [failures,screenshot_count,fixed_scale,fixed_pivot])
	await create_timer(1.5).timeout
	# Fixed-FPS simulation can finish before the real audio mixer catches up.
	for audio in root.find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
	for audio in root.find_children("*", "AudioStreamPlayer2D", true, false):
		audio.stop()
	OS.delay_msec(200)
	battle.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures.is_empty() else 1)
