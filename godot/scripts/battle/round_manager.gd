extends Node

enum RoundResult {
	PLAYER,
	ENEMY,
	DRAW,
}

@export var round_time_limit := 99
@export var ready_duration := 1.0
@export var fight_message_duration := 0.5
@export var ko_display_duration := 2.0
@export var round_result_duration := 2.0
@export var final_display_duration := 4.0
@export var enemy_accepts_input := false

var currentRound := 1
var playerWinCount := 0
var enemyWinCount := 0
var roundTime := 99
var isRoundActive := false
var isBattleFinished := false

var _time_accumulator := 0.0
var _player_start_position := Vector2.ZERO
var _enemy_start_position := Vector2.ZERO

@onready var player := $"../Player"
@onready var enemy := $"../Enemy"
@onready var timer_label := $"../UI/BattleUIRoot/TimerLabel"
@onready var message_label := $"../UI/BattleUIRoot/KOLabel"
@onready var player_win_marks := $"../UI/BattleUIRoot/PlayerWinMarks"
@onready var enemy_win_marks := $"../UI/BattleUIRoot/EnemyWinMarks"


func _ready() -> void:
	_player_start_position = player.position
	_enemy_start_position = enemy.position
	player.hp_depleted.connect(_on_player_hp_depleted)
	enemy.hp_depleted.connect(_on_enemy_hp_depleted)
	_set_round_input_enabled(false)
	_update_timer_ui()
	_update_win_marks()
	call_deferred("start_battle")


func _process(delta: float) -> void:
	if not isRoundActive or isBattleFinished:
		return

	_time_accumulator += delta
	while _time_accumulator >= 1.0 and isRoundActive:
		_time_accumulator -= 1.0
		roundTime = maxi(roundTime - 1, 0)
		_update_timer_ui()
		if roundTime == 0:
			_finish_round_by_time_up()


func start_battle() -> void:
	currentRound = 1
	playerWinCount = 0
	enemyWinCount = 0
	isBattleFinished = false
	_update_win_marks()
	await _start_round()


func _start_round() -> void:
	if isBattleFinished:
		return

	isRoundActive = false
	_time_accumulator = 0.0
	roundTime = round_time_limit
	_reset_fighters()
	_update_timer_ui()
	_update_win_marks()
	_set_round_input_enabled(false)
	_show_message("Round %d" % currentRound)
	await get_tree().create_timer(0.4).timeout
	_show_message("READY")
	await get_tree().create_timer(ready_duration).timeout
	_show_message("FIGHT")
	isRoundActive = true
	_set_round_input_enabled(true)
	await get_tree().create_timer(fight_message_duration).timeout
	if isRoundActive:
		_show_message("")


func _finish_round_by_ko(winner: RoundResult) -> void:
	if not isRoundActive:
		return

	isRoundActive = false
	_set_round_input_enabled(false)
	_show_message("KO")
	await get_tree().create_timer(ko_display_duration).timeout
	await _complete_round(winner)


func _finish_round_by_time_up() -> void:
	if not isRoundActive:
		return

	isRoundActive = false
	_set_round_input_enabled(false)
	_show_message("TIME UP")
	await get_tree().create_timer(round_result_duration).timeout
	await _complete_round(_get_time_up_result())


func _complete_round(result: RoundResult) -> void:
	match result:
		RoundResult.PLAYER:
			playerWinCount += 1
			_show_message("PLAYER WIN")
		RoundResult.ENEMY:
			enemyWinCount += 1
			_show_message("ENEMY WIN")
		RoundResult.DRAW:
			_show_message("DRAW")

	_update_win_marks()
	await get_tree().create_timer(round_result_duration).timeout

	if playerWinCount >= 2:
		await _finish_battle(true)
	elif enemyWinCount >= 2:
		await _finish_battle(false)
	else:
		currentRound += 1
		await _start_round()


func _finish_battle(player_won: bool) -> void:
	isBattleFinished = true
	isRoundActive = false
	_set_round_input_enabled(false)
	_show_message("YOU WIN" if player_won else "YOU LOSE")
	await get_tree().create_timer(final_display_duration).timeout
	get_tree().change_scene_to_file("res://scenes/Title.tscn")


func _get_time_up_result() -> RoundResult:
	if player.current_hp > enemy.current_hp:
		return RoundResult.PLAYER
	if enemy.current_hp > player.current_hp:
		return RoundResult.ENEMY
	return RoundResult.DRAW


func _reset_fighters() -> void:
	_reset_fighter(player, _player_start_position, 1.0)
	_reset_fighter(enemy, _enemy_start_position, -1.0)


func _reset_fighter(fighter: CharacterBody2D, start_position: Vector2, start_facing_direction: float) -> void:
	fighter.position = start_position
	fighter.velocity = Vector2.ZERO
	fighter.current_hp = fighter.max_hp
	fighter.facing_direction = start_facing_direction
	fighter.visual_root.scale.x = start_facing_direction
	fighter.attack_active_timer = 0.0
	fighter.attack_cooldown_timer = 0.0
	fighter.kick_active_timer = 0.0
	fighter.kick_cooldown_timer = 0.0
	fighter.is_guarding = false
	fighter.is_crouching = false
	fighter.is_crouch_guarding = false
	fighter.is_hit = false
	fighter.is_invincible = false
	fighter.hit_reaction_timer = 0.0
	fighter.invincibility_timer = 0.0
	fighter.hit_stop_timer = 0.0
	fighter.hurt_box.set_deferred("monitorable", true)
	fighter._set_punch_hitbox_active(false, false)
	fighter._set_kick_hitbox_active(false, false)
	fighter.punch_hit_targets.clear()
	fighter.kick_hit_targets.clear()
	fighter.hp_changed.emit(fighter.current_hp, fighter.max_hp)
	fighter._update_visual_state()


func _set_round_input_enabled(is_enabled: bool) -> void:
	player.input_enabled = is_enabled
	enemy.input_enabled = is_enabled and enemy_accepts_input


func _show_message(message: String) -> void:
	message_label.text = message
	message_label.visible = message != ""


func _update_timer_ui() -> void:
	timer_label.text = str(roundTime)


func _update_win_marks() -> void:
	player_win_marks.text = _format_win_marks(playerWinCount)
	enemy_win_marks.text = _format_win_marks(enemyWinCount)


func _format_win_marks(win_count: int) -> String:
	var filled_count := clampi(win_count, 0, 2)
	var empty_count := 2 - filled_count
	return String.chr(0x25CF).repeat(filled_count) + String.chr(0x25CB).repeat(empty_count)


func _on_player_hp_depleted() -> void:
	_finish_round_by_ko(RoundResult.ENEMY)


func _on_enemy_hp_depleted() -> void:
	_finish_round_by_ko(RoundResult.PLAYER)
