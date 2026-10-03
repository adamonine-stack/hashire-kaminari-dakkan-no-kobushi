extends "res://tests/special_launch_reaction_check.gd"

func run() -> void:
	output = ProjectSettings.globalize_path("res://").path_join("../evidence/combat_pose_flow").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager._hide_player_selection()
	manager._set_battle_active(true)
	paused = false
	var actor: Node = battle.get_node("Enemy")
	var definitions := ["fighters/ally_balance","fighters/ally_power","fighters/ally_speed",
		"enemies/enemy_01_standard","enemies/enemy_02_speed","enemies/enemy_03_guard",
		"enemies/enemy_04_throw","enemies/enemy_05_power","enemies/enemy_06_combo",
		"enemies/enemy_07_tricky","enemies/enemy_08_boss","enemies/enemy_09_seiya"]
	for definition in definitions:
		actor.apply_character_data(load("res://data/%s.tres" % definition))
		await reset(manager,actor,Vector2(640,520),1)
		actor.set_physics_process(false)
		actor.input_enabled = false
		actor.reset_special_attack_state()
		actor.reset_character_special_state(false)
		actor._cancel_current_action()
		actor._clear_guard_state()
		actor.is_hit = false
		actor.is_guard_hit = false
		actor.guard_recoil_timer = 0.0
		actor.cancel_current_ai_action()
		actor.jump_landing_visual_timer = 0.0
		actor.crouch_motion_state = 'none'
		actor.velocity = Vector2.ZERO
		actor._update_visual_state()
		check(actor._get_current_visual_animation() == &"idle_ready",definition+" active AI uses normal stance")
		check(actor.animated_character_sprite.animation != &"idle_prebattle",definition+" active AI never uses front-facing introduction pose")
		if definition == "enemies/enemy_04_throw":
			var sprite: AnimatedSprite2D = actor.animated_character_sprite
			var ordinary_area := opaque_body_area(sprite.sprite_frames.get_frame_texture(&"idle",0))
			actor.is_round_active = false
			actor._update_visual_state()
			var ratio := opaque_body_area(sprite.sprite_frames.get_frame_texture(&"idle_prebattle",0))/ordinary_area
			check(ratio > 0.9 and ratio < 1.1,"Rei intro keeps normal body mass")
			var texture := sprite.sprite_frames.get_frame_texture(&"idle_prebattle",0) as AtlasTexture
			check(texture.atlas.resource_path.contains("rei_reversal_v1"),"Rei intro uses normalized pose")
			await capture("rei_intro_normal_size")
			actor.is_round_active = true
			actor._update_visual_state()
			await capture("rei_combat_stance")
	print("COMBAT_POSE_FLOW_CHECK failures=%s screenshots=%d" % [failures,screenshots])
	for audio in root.find_children("*","AudioStreamPlayer",true,false): audio.stop()
	for audio in root.find_children("*","AudioStreamPlayer2D",true,false): audio.stop()
	OS.delay_msec(200)
	battle.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures.is_empty() else 1)
