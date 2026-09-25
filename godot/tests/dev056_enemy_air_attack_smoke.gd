extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fighter_scene := load("res://scenes/Player.tscn") as PackedScene
	assert(fighter_scene != null)
	var enemy := fighter_scene.instantiate()
	enemy.name = "Enemy"
	get_root().add_child(enemy)
	await process_frame

	var definition := load("res://data/enemies/enemy_01_standard.tres")
	assert(definition != null)
	assert(definition.supplemental_motion_atlas != null)
	enemy.apply_character_data(definition)
	enemy.input_enabled = false
	enemy.is_round_active = true
	enemy.current_hp = enemy.max_hp
	enemy.has_used_air_attack = false
	enemy.position = Vector2(500.0, 300.0)
	enemy.velocity = Vector2(120.0, -120.0)
	assert(not enemy.is_on_floor())

	assert(enemy.request_attack_input(&"Kick", true))
	assert(enemy.current_attack_id == "fallback_jump_kick")
	assert(enemy.current_attack_type == "Kick")
	assert(enemy.has_used_air_attack)
	enemy._update_visual_state()
	assert(enemy.animated_character_sprite.animation == &"jump_kick")
	assert(enemy.animated_character_sprite.sprite_frames.get_frame_count(&"jump_kick") == 4)
	enemy.finish_attack()

	enemy.has_used_air_attack = false
	enemy.velocity = Vector2(80.0, 40.0)
	assert(enemy.request_attack_input(&"Punch", true))
	assert(enemy.current_attack_id == "player1_jump_punch_down")
	assert(enemy.current_attack_type == "Punch")
	assert(enemy.has_used_air_attack)
	enemy._update_visual_state()
	assert(enemy.animated_character_sprite.animation == &"jump_punch_down")
	assert(enemy.animated_character_sprite.sprite_frames.get_frame_count(&"jump_punch_down") == 4)
	enemy.finish_attack()

	print("DEV056_ENEMY_AIR_ATTACK_OK")
	enemy.queue_free()
	await process_frame
	quit()
