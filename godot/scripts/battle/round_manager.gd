extends Node

signal battle_started(player_id: StringName, enemy_id: StringName)
signal battle_finished(result: Dictionary)
signal player_selection_requested(available_fighters: Array)
signal active_fighter_changed(player_id: StringName, enemy_id: StringName)
signal team_progress_updated(remaining_players: int, remaining_enemies: int)
signal game_cleared()
signal game_over()

enum FlowState {
	INITIALIZING,
	PLAYER_SELECTION,
	PRE_BATTLE,
	BATTLE,
	KO_PAUSE,
	RESULT,
	TRANSITION,
	GAME_CLEAR,
	GAME_OVER,
}

enum BattleOutcome {
	PLAYER_WIN,
	ENEMY_WIN,
	DOUBLE_KO,
}

const CHARACTER_SELECTION_SCENE := preload("res://ui/character_selection/character_selection_screen.tscn")
const ALLY_BALANCE := preload("res://data/fighters/ally_balance.tres")
const ALLY_POWER := preload("res://data/fighters/ally_power.tres")
const ALLY_SPEED := preload("res://data/fighters/ally_speed.tres")

@export var round_time_limit := 99
@export var ko_pause_duration := 1.5
@export var double_ko_check_window := 0.05
@export var result_display_duration := 1.2
@export var pre_battle_countdown := 3.0
@export var fight_message_duration := 0.6
@export var enemy_accepts_input := false
@export var debug_auto_select_player := false
@export var debug_flow_label_enabled := true

var currentRound := 1
var playerWinCount := 0
var enemyWinCount := 0
var roundTime := 99
var isRoundActive := false
var isBattleFinished := false

var flow_state := FlowState.INITIALIZING
var player_team: Array[Dictionary] = []
var enemy_team: Array[Dictionary] = []
var current_player_index := -1
var current_enemy_index := 0
var battle_result_locked := false

var _time_accumulator := 0.0
var _player_start_position := Vector2.ZERO
var _enemy_start_position := Vector2.ZERO
var _pending_player_ko := false
var _pending_enemy_ko := false
var _flow_sequence_id := 0

var _selection_panel: PanelContainer
var _selection_title: Label
var _selection_buttons: Array[Button] = []
var _progress_label: Label
var _debug_flow_label: Label
var _character_selection_screen: Control
var _selection_reason := "GAME_START"

@onready var player := $"../Player"
@onready var enemy := $"../Enemy"
@onready var battle_ui_root := $"../UI/BattleUIRoot"
@onready var timer_label := $"../UI/BattleUIRoot/TimerLabel"
@onready var message_label := $"../UI/BattleUIRoot/KOLabel"
@onready var player_win_marks := $"../UI/BattleUIRoot/PlayerWinMarks"
@onready var enemy_win_marks := $"../UI/BattleUIRoot/EnemyWinMarks"


func _ready() -> void:
	_player_start_position = player.position
	_enemy_start_position = enemy.position
	player.hp_depleted.connect(_on_player_hp_depleted)
	enemy.hp_depleted.connect(_on_enemy_hp_depleted)
	_create_flow_ui()
	initialize_game_progress()
	_set_battle_active(false)
	_update_all_ui()
	call_deferred("start_initial_player_selection")


func _process(delta: float) -> void:
	_update_debug_flow_label()

	if flow_state != FlowState.BATTLE or not isRoundActive or isBattleFinished:
		return

	_time_accumulator += delta
	while _time_accumulator >= 1.0 and flow_state == FlowState.BATTLE:
		_time_accumulator -= 1.0
		roundTime = maxi(roundTime - 1, 0)
		_update_timer_ui()
		if roundTime == 0:
			_finish_battle_by_time_up()


func initialize_game_progress() -> void:
	flow_state = FlowState.INITIALIZING
	currentRound = 1
	playerWinCount = 0
	enemyWinCount = 0
	roundTime = round_time_limit
	isRoundActive = false
	isBattleFinished = false
	battle_result_locked = false
	_pending_player_ko = false
	_pending_enemy_ko = false
	current_player_index = -1
	current_enemy_index = 0
	_flow_sequence_id += 1

	player_team = [
		_create_progress_entry_from_definition(ALLY_BALANCE, 0),
		_create_progress_entry_from_definition(ALLY_POWER, 1),
		_create_progress_entry_from_definition(ALLY_SPEED, 2),
	]

	enemy_team.clear()
	for index in range(8):
		enemy_team.append(_create_progress_entry(
			StringName("enemy_%02d" % (index + 1)),
			"Enemy %d" % (index + 1),
			index,
			enemy.max_hp
		))

	print("Game progress initialized")
	_update_all_ui()


func start_initial_player_selection() -> void:
	if flow_state == FlowState.GAME_CLEAR or flow_state == FlowState.GAME_OVER:
		return

	flow_state = FlowState.PLAYER_SELECTION
	_set_battle_active(false)
	_show_message("")
	_show_player_selection()


func select_player(player_index: int) -> void:
	if flow_state != FlowState.PLAYER_SELECTION:
		return
	if not _is_player_selectable(player_index):
		return

	current_player_index = player_index
	_hide_player_selection()
	flow_state = FlowState.TRANSITION
	await prepare_battle()


func spawn_active_player() -> void:
	if current_player_index < 0 or current_player_index >= player_team.size():
		return

	var data := player_team[current_player_index]
	var definition: Resource = data["definition"]
	if player.has_method("apply_fighter_definition"):
		player.apply_fighter_definition(definition)
	var current_health := int(clampi(data["current_health"], 1, definition.max_health))
	reset_active_fighter_state(player, _player_start_position, 1.0, current_health)


func spawn_active_enemy() -> void:
	if current_enemy_index < 0 or current_enemy_index >= enemy_team.size():
		return

	var data := enemy_team[current_enemy_index]
	var current_health := int(clampi(data["current_health"], 1, data["max_health"]))
	reset_active_fighter_state(enemy, _enemy_start_position, -1.0, current_health)


func prepare_battle() -> void:
	if _should_finish_game():
		return

	flow_state = FlowState.PRE_BATTLE
	_flow_sequence_id += 1
	var sequence_id := _flow_sequence_id
	_pending_player_ko = false
	_pending_enemy_ko = false
	battle_result_locked = false
	_time_accumulator = 0.0
	roundTime = round_time_limit

	spawn_active_player()
	spawn_active_enemy()
	_set_battle_active(false)
	_update_all_ui()
	active_fighter_changed.emit(_active_player_id(), _active_enemy_id())

	await start_battle_countdown(sequence_id)


func start_battle_countdown(sequence_id: int = -1) -> void:
	if sequence_id == -1:
		sequence_id = _flow_sequence_id

	var count := int(ceil(pre_battle_countdown))
	while count > 0:
		if sequence_id != _flow_sequence_id or flow_state != FlowState.PRE_BATTLE:
			return
		_show_message(str(count))
		await get_tree().create_timer(1.0).timeout
		count -= 1

	if sequence_id != _flow_sequence_id or flow_state != FlowState.PRE_BATTLE:
		return

	begin_battle(sequence_id)


func begin_battle(sequence_id: int = -1) -> void:
	if sequence_id != -1 and sequence_id != _flow_sequence_id:
		return

	flow_state = FlowState.BATTLE
	isBattleFinished = false
	isRoundActive = true
	_set_battle_active(true)
	_show_message("FIGHT")
	battle_started.emit(_active_player_id(), _active_enemy_id())
	print("Battle Start: %s VS %s" % [_active_player_id(), _active_enemy_id()])
	await get_tree().create_timer(fight_message_duration).timeout
	if flow_state == FlowState.BATTLE:
		_show_message("")


func on_fighter_ko(fighter: Node) -> void:
	if flow_state != FlowState.BATTLE and flow_state != FlowState.KO_PAUSE:
		return

	if fighter == player:
		_pending_player_ko = true
	elif fighter == enemy:
		_pending_enemy_ko = true
	else:
		return

	if battle_result_locked:
		return

	battle_result_locked = true
	flow_state = FlowState.KO_PAUSE
	_set_battle_active(false)
	_clear_active_fighter_actions(player)
	_clear_active_fighter_actions(enemy)
	_show_message("K.O.")
	print("KO detected")
	await _resolve_ko_after_pause()


func resolve_battle_result() -> void:
	flow_state = FlowState.RESULT
	var result := _get_pending_battle_result()
	var result_data := {
		"outcome": result,
		"player_id": _active_player_id(),
		"enemy_id": _active_enemy_id(),
	}
	battle_finished.emit(result_data)

	match result:
		BattleOutcome.PLAYER_WIN:
			handle_player_victory()
			_show_message("PLAYER WIN")
		BattleOutcome.ENEMY_WIN:
			handle_player_defeat()
			_show_message("ENEMY WIN")
		BattleOutcome.DOUBLE_KO:
			handle_double_ko()
			_show_message("DOUBLE K.O.")

	_update_all_ui()
	await get_tree().create_timer(result_display_duration).timeout

	if _should_finish_game():
		return

	if result == BattleOutcome.PLAYER_WIN:
		current_enemy_index = get_next_enemy_index()
		if current_enemy_index == -1:
			enter_game_clear()
		else:
			flow_state = FlowState.TRANSITION
			await prepare_battle()
	else:
		start_initial_player_selection()


func handle_player_victory() -> void:
	_store_active_fighter_health()
	_mark_enemy_defeated()
	playerWinCount += 1
	print("Enemy defeated: %s" % _active_enemy_id())


func handle_player_defeat() -> void:
	_store_active_fighter_health()
	_mark_player_defeated()
	enemyWinCount += 1
	_selection_reason = "PLAYER_DEFEATED"
	print("Player defeated: %s" % _active_player_id())


func handle_double_ko() -> void:
	_store_active_fighter_health()
	_mark_player_defeated()
	_mark_enemy_defeated()
	playerWinCount += 1
	enemyWinCount += 1
	print("Double KO")


func store_active_fighter_health() -> void:
	_store_active_fighter_health()


func get_available_player_indices() -> Array[int]:
	var indices: Array[int] = []
	for index in range(player_team.size()):
		if _is_player_selectable(index):
			indices.append(index)
	return indices


func get_next_enemy_index() -> int:
	for index in range(current_enemy_index + 1, enemy_team.size()):
		if not enemy_team[index]["is_defeated"]:
			return index
	return -1


func are_all_players_defeated() -> bool:
	for data in player_team:
		if not data["is_defeated"] and data["current_health"] > 0:
			return false
	return true


func are_all_enemies_defeated() -> bool:
	for data in enemy_team:
		if not data["is_defeated"] and data["current_health"] > 0:
			return false
	return true


func enter_game_clear() -> void:
	if flow_state == FlowState.GAME_CLEAR:
		return
	flow_state = FlowState.GAME_CLEAR
	isBattleFinished = true
	_set_battle_active(false)
	_hide_player_selection()
	_show_message("GAME CLEAR")
	game_cleared.emit()
	print("GAME CLEAR")


func enter_game_over() -> void:
	if flow_state == FlowState.GAME_OVER:
		return
	flow_state = FlowState.GAME_OVER
	isBattleFinished = true
	_set_battle_active(false)
	_hide_player_selection()
	_show_message("GAME OVER")
	game_over.emit()
	print("GAME OVER")


func reset_active_fighter_state(
	fighter: CharacterBody2D,
	start_position := Vector2.ZERO,
	start_facing_direction := 1.0,
	health := -1
) -> void:
	fighter.position = start_position
	fighter.velocity = Vector2.ZERO
	if fighter.has_method("set_health"):
		fighter.set_health(fighter.max_hp if health < 0 else health)
	else:
		fighter.current_hp = fighter.max_hp if health < 0 else clampi(health, 0, fighter.max_hp)
	fighter.facing_direction = start_facing_direction
	fighter.visual_root.scale.x = start_facing_direction
	fighter.attack_active_timer = 0.0
	fighter.attack_cooldown_timer = 0.0
	fighter.kick_active_timer = 0.0
	fighter.kick_cooldown_timer = 0.0
	fighter.is_guarding = false
	fighter.is_crouching = false
	fighter.is_crouch_guarding = false
	fighter.guard_type = "none"
	fighter.is_hit = false
	fighter.is_invincible = false
	fighter.is_guard_hit = false
	fighter.is_throwing = false
	fighter.is_throw_locked = false
	fighter.is_throw_escape_pending = false
	fighter.is_throw_escaping = false
	fighter.is_round_active = false
	fighter.hit_reaction_timer = 0.0
	fighter.invincibility_timer = 0.0
	fighter.hit_stop_timer = 0.0
	fighter.guard_hit_timer = 0.0
	fighter.throw_startup_timer = 0.0
	fighter.throw_hold_timer = 0.0
	fighter.throw_recovery_timer = 0.0
	fighter.throw_escape_timer = 0.0
	fighter.throw_state = ""
	fighter.current_throw_target = null
	fighter.has_throw_connected = false
	fighter.has_throw_damage_applied = false
	fighter.combo_count = 0
	fighter.combo_timer = 0.0
	fighter.can_cancel = false
	fighter.cancel_window_timer = 0.0
	fighter.current_attack_type = ""
	fighter.ai_guard_check_timer = 0.0
	fighter.ai_guard_timer = 0.0
	fighter.ai_throw_check_timer = 0.0
	fighter.ai_throw_cooldown_timer = 0.0

	if fighter.has_method("_clear_pending_throw"):
		fighter._clear_pending_throw()
	if fighter.has_method("reset_combo"):
		fighter.reset_combo()
	if fighter.has_method("reset_knockdown_state"):
		fighter.reset_knockdown_state()
	if fighter.has_method("_set_punch_hitbox_active"):
		fighter._set_punch_hitbox_active(false, false)
	if fighter.has_method("_set_kick_hitbox_active"):
		fighter._set_kick_hitbox_active(false, false)

	if fighter.hurt_box != null:
		fighter.hurt_box.set_deferred("monitorable", fighter.current_hp > 0)
	fighter.punch_hit_targets.clear()
	fighter.kick_hit_targets.clear()
	fighter.hp_changed.emit(fighter.current_hp, fighter.max_hp)
	fighter._update_visual_state()


func create_progress_snapshot() -> Dictionary:
	return {
		"flow_state": FlowState.keys()[flow_state],
		"current_player_index": current_player_index,
		"current_enemy_index": current_enemy_index,
		"players": _serialize_team(player_team),
		"enemies": _serialize_team(enemy_team),
		"result_locked": battle_result_locked,
	}


func reset_game_progress() -> void:
	initialize_game_progress()
	start_initial_player_selection()


func _resolve_ko_after_pause() -> void:
	await get_tree().create_timer(double_ko_check_window).timeout
	if _pending_player_ko and _pending_enemy_ko:
		_show_message("DOUBLE K.O.")
	await get_tree().create_timer(ko_pause_duration).timeout
	resolve_battle_result()


func _finish_battle_by_time_up() -> void:
	if battle_result_locked:
		return

	battle_result_locked = true
	flow_state = FlowState.KO_PAUSE
	_set_battle_active(false)
	_show_message("TIME UP")

	if player.current_hp > enemy.current_hp:
		_pending_enemy_ko = true
	elif enemy.current_hp > player.current_hp:
		_pending_player_ko = true
	else:
		_pending_player_ko = true
		_pending_enemy_ko = true

	await get_tree().create_timer(ko_pause_duration).timeout
	resolve_battle_result()


func _get_pending_battle_result() -> BattleOutcome:
	if _pending_player_ko and _pending_enemy_ko:
		return BattleOutcome.DOUBLE_KO
	if _pending_enemy_ko:
		return BattleOutcome.PLAYER_WIN
	return BattleOutcome.ENEMY_WIN


func _store_active_fighter_health() -> void:
	if current_player_index >= 0 and current_player_index < player_team.size():
		player_team[current_player_index]["current_health"] = clampi(player.current_hp, 0, player.max_hp)
	if current_enemy_index >= 0 and current_enemy_index < enemy_team.size():
		enemy_team[current_enemy_index]["current_health"] = clampi(enemy.current_hp, 0, enemy.max_hp)


func _mark_player_defeated() -> void:
	if current_player_index < 0 or current_player_index >= player_team.size():
		return
	player_team[current_player_index]["current_health"] = 0
	player_team[current_player_index]["is_defeated"] = true


func _mark_enemy_defeated() -> void:
	if current_enemy_index < 0 or current_enemy_index >= enemy_team.size():
		return
	enemy_team[current_enemy_index]["current_health"] = 0
	enemy_team[current_enemy_index]["is_defeated"] = true


func _should_finish_game() -> bool:
	if are_all_players_defeated():
		enter_game_over()
		return true
	if are_all_enemies_defeated():
		enter_game_clear()
		return true
	return false


func _set_battle_active(is_enabled: bool) -> void:
	isRoundActive = is_enabled
	player.is_round_active = is_enabled
	enemy.is_round_active = is_enabled
	player.input_enabled = is_enabled
	enemy.input_enabled = is_enabled and enemy_accepts_input


func _clear_active_fighter_actions(fighter: CharacterBody2D) -> void:
	fighter.attack_active_timer = 0.0
	fighter.kick_active_timer = 0.0
	fighter.attack_cooldown_timer = 0.0
	fighter.kick_cooldown_timer = 0.0
	fighter.velocity.x = 0.0
	if fighter.has_method("_set_punch_hitbox_active"):
		fighter._set_punch_hitbox_active(false, false)
	if fighter.has_method("_set_kick_hitbox_active"):
		fighter._set_kick_hitbox_active(false, false)
	if fighter.has_method("_clear_pending_throw"):
		fighter._clear_pending_throw()
	if fighter.has_method("reset_combo"):
		fighter.reset_combo()


func _create_progress_entry_from_definition(definition: Resource, battle_order: int) -> Dictionary:
	return {
		"definition": definition,
		"fighter_id": definition.fighter_id,
		"display_name": definition.display_name,
		"max_health": int(round(definition.max_health)),
		"current_health": int(round(definition.max_health)),
		"is_defeated": false,
		"battle_order": battle_order,
		"has_been_selected": false,
	}


func _create_progress_entry(
	fighter_id: StringName,
	display_name: String,
	battle_order: int,
	max_health: int
) -> Dictionary:
	return {
		"definition": null,
		"fighter_id": fighter_id,
		"display_name": display_name,
		"max_health": max_health,
		"current_health": max_health,
		"is_defeated": false,
		"battle_order": battle_order,
	}


func _is_player_selectable(player_index: int) -> bool:
	if player_index < 0 or player_index >= player_team.size():
		return false
	var data := player_team[player_index]
	return not data["is_defeated"] and data["current_health"] > 0


func _active_player_id() -> StringName:
	if current_player_index < 0 or current_player_index >= player_team.size():
		return &""
	return player_team[current_player_index]["fighter_id"]


func _active_enemy_id() -> StringName:
	if current_enemy_index < 0 or current_enemy_index >= enemy_team.size():
		return &""
	return enemy_team[current_enemy_index]["fighter_id"]


func _remaining_count(team: Array[Dictionary]) -> int:
	var count := 0
	for data in team:
		if not data["is_defeated"] and data["current_health"] > 0:
			count += 1
	return count


func _serialize_team(team: Array[Dictionary]) -> Array:
	var serialized := []
	for data in team:
		serialized.append(data.duplicate(true))
	return serialized


func _create_flow_ui() -> void:
	_progress_label = Label.new()
	_progress_label.name = "ProgressLabel"
	_progress_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_progress_label.offset_left = 24.0
	_progress_label.offset_top = 86.0
	_progress_label.offset_right = -24.0
	_progress_label.offset_bottom = 114.0
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 18)
	battle_ui_root.add_child(_progress_label)

	_debug_flow_label = Label.new()
	_debug_flow_label.name = "DebugFlowLabel"
	_debug_flow_label.visible = debug_flow_label_enabled
	_debug_flow_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_debug_flow_label.offset_left = 24.0
	_debug_flow_label.offset_top = 120.0
	_debug_flow_label.offset_right = 360.0
	_debug_flow_label.offset_bottom = 260.0
	_debug_flow_label.add_theme_font_size_override("font_size", 14)
	battle_ui_root.add_child(_debug_flow_label)
	_character_selection_screen = CHARACTER_SELECTION_SCENE.instantiate()
	battle_ui_root.add_child(_character_selection_screen)
	_character_selection_screen.fighter_selected.connect(select_player)


func _show_player_selection() -> void:
	if get_available_player_indices().is_empty():
		enter_game_over()
		return
	_character_selection_screen.open_selection(player_team, _selection_reason)
	player_selection_requested.emit(get_available_player_indices())

	if debug_auto_select_player:
		var indices := get_available_player_indices()
		if not indices.is_empty():
			call_deferred("select_player", indices[0])


func _hide_player_selection() -> void:
	if _character_selection_screen != null:
		_character_selection_screen.close_selection()


func _update_selection_buttons() -> void:
	pass


func _update_all_ui() -> void:
	_update_timer_ui()
	_update_win_marks()
	_update_progress_ui()
	_update_selection_buttons()
	_update_debug_flow_label()


func _update_timer_ui() -> void:
	timer_label.text = str(roundTime)


func _update_win_marks() -> void:
	player_win_marks.text = "ALLY %d/3" % _remaining_count(player_team)
	enemy_win_marks.text = "ENEMY %d/8" % _remaining_count(enemy_team)


func _update_progress_ui() -> void:
	if _progress_label == null:
		return
	_progress_label.text = "PLAYER %s  VS  %s" % [_active_player_name(), _active_enemy_id()]
	team_progress_updated.emit(_remaining_count(player_team), _remaining_count(enemy_team))


func _update_debug_flow_label() -> void:
	if _debug_flow_label == null:
		return
	_debug_flow_label.visible = debug_flow_label_enabled
	if not debug_flow_label_enabled:
		return

	_debug_flow_label.text = "\n".join([
		"FLOW STATE: %s" % FlowState.keys()[flow_state],
		"CURRENT PLAYER: %s" % _active_player_id(),
		"CURRENT ENEMY: %s" % _active_enemy_id(),
		"ACTIVE MOVE SPEED: %.1f" % player.move_speed,
		"ACTIVE MAX HEALTH: %d" % player.max_hp,
		"ACTIVE PUNCH DAMAGE: %d" % player.punch_damage,
		"PLAYER HP: %d" % player.current_hp,
		"ENEMY HP: %d" % enemy.current_hp,
		"PLAYERS REMAINING: %d" % _remaining_count(player_team),
		"ENEMIES REMAINING: %d" % _remaining_count(enemy_team),
		"RESULT LOCKED: %s" % str(battle_result_locked).to_upper(),
	])


func _show_message(message: String) -> void:
	message_label.text = message
	message_label.visible = message != ""


func _on_player_hp_depleted() -> void:
	on_fighter_ko(player)


func _on_enemy_hp_depleted() -> void:
	on_fighter_ko(enemy)


func _active_player_name() -> String:
	if current_player_index < 0 or current_player_index >= player_team.size():
		return ""
	return player_team[current_player_index]["display_name"]
