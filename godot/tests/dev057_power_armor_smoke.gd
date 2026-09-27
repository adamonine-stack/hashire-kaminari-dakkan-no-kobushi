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
	enemy.apply_character_data(definition)
	enemy.input_enabled = false
	enemy.is_round_active = true
	enemy.current_hp = enemy.max_hp

	assert(enemy.power_armor_enabled)
	assert(enemy.power_armor_damage_threshold == 24)
	assert(enemy.power_armor_damage_accumulated == 0)

	var light_hit := _attack(10)
	assert(enemy.receive_attack(light_hit, -1.0, enemy.global_position, null))
	assert(enemy.current_hp == enemy.max_hp - 10)
	assert(not enemy.is_hit)
	assert(enemy.power_armor_damage_accumulated == 10)

	assert(enemy.receive_attack(light_hit, -1.0, enemy.global_position, null))
	assert(enemy.current_hp == enemy.max_hp - 20)
	assert(not enemy.is_hit)
	assert(enemy.power_armor_damage_accumulated == 20)

	var breaking_hit := _attack(5)
	assert(enemy.receive_attack(breaking_hit, -1.0, enemy.global_position, null))
	assert(enemy.current_hp == enemy.max_hp - 25)
	assert(enemy.is_hit)
	assert(enemy.power_armor_damage_accumulated == 0)

	print("DEV057_POWER_ARMOR_OK")
	enemy.queue_free()
	await process_frame
	quit()


func _attack(damage: int) -> Dictionary:
	return {
		"damage": damage,
		"attack_height": "high",
		"knockback_x": 120.0,
		"knockback_y": 80.0,
		"hit_stop_frames": 3,
		"hitstun_time": 0.20,
		"effect_size": 1.0,
		"screen_shake": 2.0,
		"se_type": "weak",
		"combo_hit_index": 1,
		"combo_hit_max": 1,
		"allows_combo_followup": true,
	}
