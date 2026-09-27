extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fighter_scene := load("res://scenes/Player.tscn") as PackedScene
	assert(fighter_scene != null)

	var arena := Node2D.new()
	arena.name = "GuardCounterArena"
	get_root().add_child(arena)

	var player := fighter_scene.instantiate()
	player.name = "Player"
	arena.add_child(player)

	var enemy := fighter_scene.instantiate()
	enemy.name = "Enemy"
	arena.add_child(enemy)
	await process_frame

	var enemy_definition := load("res://data/enemies/enemy_01_standard.tres")
	assert(enemy_definition != null)
	enemy.apply_character_data(enemy_definition)
	enemy.input_enabled = false
	enemy.is_round_active = true

	# Normal attacks do zero chip damage when correctly guarded.
	assert(enemy._get_guard_damage_from_attack_data({
		"damage": 12,
		"base_damage": 12,
		"attack_type": "punch",
		"guard_damage_multiplier": 0.50,
	}) == 0)
	assert(enemy._get_guard_damage_from_attack_data({
		"damage": 14,
		"base_damage": 14,
		"attack_type": "kick",
	}) == 0)

	# Specials/ultimates retain authored guard chip damage.
	assert(enemy._get_guard_damage_from_attack_data({
		"damage": 20,
		"base_damage": 20,
		"attack_type": "special",
		"guard_damage_multiplier": 0.20,
	}) == 4)
	assert(enemy._get_guard_damage_from_attack_data({
		"damage": 30,
		"base_damage": 30,
		"attack_type": "ultimate",
		"guard_damage_multiplier": 0.10,
	}) == 3)

	# Standing guard blocks overheads but loses to lows.
	enemy.guard_type = "high"
	assert(enemy._is_attack_height_guardable("overhead"))
	assert(not enemy._is_attack_height_guardable("low"))

	# Crouch guard blocks lows but loses to jump/overhead attacks.
	enemy.guard_type = "low"
	assert(enemy._is_attack_height_guardable("low"))
	assert(not enemy._is_attack_height_guardable("overhead"))

	# AI reads air attacks as standing-guard threats and crouch attacks as lows.
	player.current_attack_data = load("res://data/attacks/player1_jump_kick.tres")
	player.current_attack_type = "Kick"
	assert(enemy._choose_ai_guard_type_against_player() == "high")

	player.current_attack_data = load("res://data/attacks/player1_crouch_kick_sweep.tres")
	player.current_attack_type = "Kick"
	assert(enemy._choose_ai_guard_type_against_player() == "low")

	# A crouching punch is also a low even when its normal resource is authored high.
	player.current_attack_data = load("res://data/attacks/player1_punch_1.tres")
	player.current_attack_id = "player1_punch_1"
	player.current_attack_type = "Punch"
	player.is_crouching = true
	var crouch_punch_data: Dictionary = player._get_attack_data_dictionary("Punch")
	assert(String(crouch_punch_data["attack_height"]) == "low")
	assert(enemy._choose_ai_guard_type_against_player() == "low")
	player.is_crouching = false

	# Guard success arms the dedicated retaliation path.
	enemy.ai_profile.guard_counter_rate = 1.0
	enemy.ai_guard_counter_pending = false
	enemy._on_successful_guard({"attack_type": "punch"}, player)
	assert(enemy.ai_guard_counter_pending)

	print("DEV062_GUARD_COUNTERPLAY_OK")
	arena.queue_free()
	await process_frame
	quit()
