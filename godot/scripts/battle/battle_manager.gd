extends Node
class_name BattleManager

signal battle_started(player_id: StringName, enemy_id: StringName)
signal battle_finished(result: Dictionary)
signal player_selection_requested(available_fighters: Array)
signal active_fighter_changed(player_id: StringName, enemy_id: StringName)
signal team_progress_updated(remaining_players: int, remaining_enemies: int)
signal game_cleared()
signal game_over()
signal player_defeated(character_id)
signal player_select_opened
signal player_selected(character_id)
signal current_player_changed(new_player)
signal all_players_defeated
signal game_over_started
signal player_order_select_opened
signal player_order_changed(order)
signal player_order_confirmed(order)
signal battle_start_requested(first_player_id)
signal next_ordered_player_requested(character_id)
signal player_order_status_updated
signal hud_enemy_spawned(enemy: Node, enemy_index: int, enemy_data: Dictionary)
signal hud_enemy_defeated(enemy: Node, enemy_index: int)
signal hud_healing_applied(target: Node, applied_amount: int)
signal hud_message_requested(message: String, priority: int, duration: float)
signal hud_retry_started()
signal game_flow_state_changed(previous_state, new_state)
signal new_game_requested
signal restart_requested
signal return_to_title_requested
signal battle_paused
signal battle_resumed
signal scene_transition_started(scene_path)
signal scene_transition_finished(scene_path)
signal game_over_menu_opened
signal game_clear_menu_opened

enum BattleState {
	READY,
	FIGHT,
	BATTLE,
	ENEMY_DEAD,
	PLAYER_DEAD,
	NEXT_ENEMY,
	NEXT_PLAYER,
	CLEAR,
	GAME_OVER,
}

enum BattleOutcome {
	PLAYER_WIN,
	ENEMY_WIN,
	DOUBLE_KO,
}

enum Dev044DebugMode {
	NORMAL,
	FAST_VERIFY,
	AI_CHECK,
	HITBOX_CHECK,
	PERFORMANCE_CHECK,
}

const CHARACTER_SELECTION_SCENE := preload("res://ui/character_selection/character_selection_screen.tscn")
const ALLY_BALANCE := preload("res://data/fighters/ally_balance.tres")
const ALLY_POWER := preload("res://data/fighters/ally_power.tres")
const ALLY_SPEED := preload("res://data/fighters/ally_speed.tres")
const ENEMY_DEFINITIONS: Array[Resource] = [
	preload("res://data/enemies/enemy_01_standard.tres"),
	preload("res://data/enemies/enemy_02_speed.tres"),
	preload("res://data/enemies/enemy_03_guard.tres"),
	preload("res://data/enemies/enemy_04_throw.tres"),
	preload("res://data/enemies/enemy_05_power.tres"),
	preload("res://data/enemies/enemy_06_combo.tres"),
	preload("res://data/enemies/enemy_07_tricky.tres"),
	preload("res://data/enemies/enemy_08_boss.tres"),
]

@export var round_time_limit := 99
@export var ko_pause_duration := 1.5
@export var double_ko_check_window := 0.05
@export var result_display_duration := 1.2
@export var pre_battle_countdown := 3.0
@export var fight_message_duration := 0.6
@export var enemy_accepts_input := false
@export var debug_auto_select_player := false
@export var debug_flow_label_enabled := false
@export var player_change_invincible_time := 1.5
@export var player_defeat_display_time := 1.0
@export var next_player_display_time := 1.0
@export_group("DEV044 Debug")
@export var dev044_debug_tools_enabled := false
@export var dev044_debug_mode := Dev044DebugMode.NORMAL

var currentRound := 1
var playerWinCount := 0
var enemyWinCount := 0
var roundTime := 99
var isRoundActive := false
var isBattleFinished := false
var is_run_active := false
var is_battle_resolving := false
var battle_result: StringName = &""
var currentBattleState := BattleState.READY
var player_roster: Array = []
var current_player_id := ""
var current_player_instance: Node = null
var selected_player_ids: Array[StringName] = []
var defeated_player_ids: Array[StringName] = []
var enemy_order: Array[StringName] = []
var defeated_enemy_ids: Array[StringName] = []
var is_player_change_processing := false
var selected_player_order: Array[String] = []
var current_player_order_index := 0
var is_player_order_confirmed := false
var is_battle_starting := false
var is_ordered_player_change_processing := false
var is_game_paused := false
var is_scene_transitioning := false

var flow_state := BattleState.READY
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
var _last_recovery_enemy_index := -1
var _current_battle_start_time_msec := 0
var _current_battle_start_player_hp := 0
var _current_battle_start_enemy_hp := 0
var _current_battle_statistics_recorded := false
var battle_statistics: Array[Dictionary] = []

var _selection_panel: PanelContainer
var _selection_title: Label
var _selection_buttons: Array[Button] = []
var _progress_label: Label
var _debug_flow_label: Label
var _character_selection_screen: Control
var _selection_reason := "GAME_START"
var _enemy_intro_panel: PanelContainer
var _enemy_intro_label: Label
var _last_intro_enemy_index := -1
var _end_panel: PanelContainer
var _end_title_label: Label
var _end_body_label: Label
var _restart_button: Button
var _title_button: Button
var _fade_overlay: ColorRect
var _heal_effect_label: Label
var _bgm_player: AudioStreamPlayer
var _current_bgm_name := ""
var _player_order_panel: PanelContainer
var _player_order_title_label: Label
var _player_order_slots_label: Label
var _player_order_status_label: Label
var _player_order_confirm_button: Button
var _player_order_reset_button: Button
var _player_order_back_button: Button
var _player_order_character_buttons: Dictionary = {}
var _player_order_portrait_rects: Dictionary = {}
var _player_order_up_buttons: Dictionary = {}
var _player_order_down_buttons: Dictionary = {}
var _player_order_remove_buttons: Dictionary = {}
var _player_order_hud_label: Label
var _player_order_margin: MarginContainer
var _player_order_center: CenterContainer
var _player_order_root: VBoxContainer
var _player_order_header: HBoxContainer
var _player_order_header_center: VBoxContainer
var _player_order_character_list: HBoxContainer
var _player_order_footer: HBoxContainer
var _player_order_card_boxes: Dictionary = {}
var _player_order_control_rows: Dictionary = {}
var _player_order_order_badges: Dictionary = {}
var _last_spawned_player_id := ""
var _last_pause_toggle_frame := -1

@onready var player := $"../Player"
@onready var enemy := $"../Enemy"
@onready var battle_ui_root := $"../UI/BattleUIRoot"
@onready var mobile_controls := $"../UI/BattleUIRoot/MobileControls"
@onready var timer_label := $"../UI/BattleUIRoot/TimerLabel"
@onready var message_label := $"../UI/BattleUIRoot/KOLabel"
@onready var player_win_marks := $"../UI/BattleUIRoot/PlayerWinMarks"
@onready var enemy_win_marks := $"../UI/BattleUIRoot/EnemyWinMarks"
@onready var player_hp_bar := $"../UI/BattleUIRoot/PlayerHpBar"
@onready var enemy_hp_bar := $"../UI/BattleUIRoot/EnemyHpBar"
@onready var battle_hud := $"../UI/BattleUIRoot/BattleHUD"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	_player_start_position = player.position
	_enemy_start_position = enemy.position
	current_player_instance = player
	player.hp_depleted.connect(_on_player_hp_depleted)
	enemy.hp_depleted.connect(_on_enemy_hp_depleted)
	player.hp_changed.connect(_on_player_hp_changed)
	enemy.hp_changed.connect(_on_enemy_hp_changed)
	if player.has_signal("special_gauge_changed"):
		player.special_gauge_changed.connect(_on_player_special_gauge_changed)
	initialize_game_progress()
	_create_flow_ui()
	_initialize_battle_hud()
	if not get_viewport().size_changed.is_connected(_apply_player_order_responsive_layout):
		get_viewport().size_changed.connect(_apply_player_order_responsive_layout)
	if not get_viewport().size_changed.is_connected(_on_battle_viewport_size_changed):
		get_viewport().size_changed.connect(_on_battle_viewport_size_changed)
	_set_battle_active(false)
	_update_all_ui()
	call_deferred("refresh_mobile_controls_visibility")
	call_deferred("start_initial_player_selection")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause_from_input()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_poll_pause_action()
	_update_debug_flow_label()

	if flow_state != BattleState.BATTLE or not isRoundActive or isBattleFinished:
		return

	_time_accumulator += delta
	while _time_accumulator >= 1.0 and flow_state == BattleState.BATTLE:
		_time_accumulator -= 1.0
		roundTime = maxi(roundTime - 1, 0)
		_update_timer_ui()
		if roundTime == 0:
			_finish_battle_by_time_up()


func initialize_game_progress() -> void:
	_set_battle_state(BattleState.READY)
	currentRound = 1
	playerWinCount = 0
	enemyWinCount = 0
	roundTime = round_time_limit
	isRoundActive = false
	isBattleFinished = false
	is_run_active = true
	is_battle_resolving = false
	battle_result = &""
	battle_result_locked = false
	_pending_player_ko = false
	_pending_enemy_ko = false
	current_player_index = -1
	current_enemy_index = 0
	_last_intro_enemy_index = -1
	_last_recovery_enemy_index = -1
	_current_battle_start_time_msec = 0
	_current_battle_start_player_hp = 0
	_current_battle_start_enemy_hp = 0
	_current_battle_statistics_recorded = false
	battle_statistics.clear()
	selected_player_ids.clear()
	defeated_player_ids.clear()
	defeated_enemy_ids.clear()
	is_player_change_processing = false
	reset_player_order_data()
	_flow_sequence_id += 1

	reset_player_roster()

	initialize_enemy_team()

	print("Game progress initialized")
	_update_all_ui()


func initialize_enemy_team() -> void:
	enemy_team.clear()
	enemy_order.clear()
	if not validate_enemy_definitions():
		for index in range(8):
			var fallback_id := StringName("enemy_%02d" % (index + 1))
			enemy_order.append(fallback_id)
			enemy_team.append(_create_progress_entry(
				fallback_id,
				"Enemy %d" % (index + 1),
				index,
				enemy.max_hp
			))
		return

	for index in range(ENEMY_DEFINITIONS.size()):
		enemy_order.append(ENEMY_DEFINITIONS[index].fighter_id)
		enemy_team.append(_create_progress_entry_from_definition(ENEMY_DEFINITIONS[index], index))


func reset_player_roster() -> void:
	player_team = [
		_create_progress_entry_from_definition(ALLY_BALANCE, 0),
		_create_progress_entry_from_definition(ALLY_POWER, 1),
		_create_progress_entry_from_definition(ALLY_SPEED, 2),
	]
	player_roster = player_team
	current_player_id = ""


func reset_player_order_data() -> void:
	selected_player_order.clear()
	current_player_order_index = 0
	is_player_order_confirmed = false
	is_battle_starting = false
	is_ordered_player_change_processing = false


func validate_enemy_definitions() -> bool:
	var seen_ids := {}
	var expected_order := 1
	for definition in ENEMY_DEFINITIONS:
		if definition == null:
			push_warning("Enemy definition is missing.")
			return false
		if definition.fighter_id == &"" or seen_ids.has(definition.fighter_id):
			push_warning("Enemy definition has an empty or duplicated fighter_id.")
			return false
		seen_ids[definition.fighter_id] = true
		if int(definition.enemy_order) != expected_order:
			push_warning("Enemy order mismatch: %s" % definition.fighter_id)
			return false
		if definition.fighter_scene == null:
			push_warning("Enemy scene is missing: %s" % definition.fighter_id)
			return false
		if int(round(definition.max_health)) <= 0:
			push_warning("Enemy max health is invalid: %s" % definition.fighter_id)
			return false
		if definition.ai_profile == null:
			push_warning("Enemy AI profile is missing: %s" % definition.fighter_id)
			return false
		expected_order += 1
	return ENEMY_DEFINITIONS.size() == 8


func start_initial_player_selection() -> void:
	if flow_state == BattleState.CLEAR or flow_state == BattleState.GAME_OVER:
		return

	if not is_player_order_confirmed:
		open_player_order_select()
	else:
		open_player_select(_selection_reason == "GAME_START")


func open_player_select(is_initial_select: bool = false) -> void:
	if flow_state == BattleState.CLEAR or flow_state == BattleState.GAME_OVER:
		return
	_set_battle_state(BattleState.NEXT_PLAYER)
	_set_battle_active(false)
	_show_message("")
	_selection_reason = "GAME_START" if is_initial_select else "PLAYER_DEFEATED"
	_show_player_selection()
	player_select_opened.emit()
	print("[DEV033] Player select opened")


func close_player_select() -> void:
	_hide_player_selection()


func open_player_order_select() -> void:
	if flow_state == BattleState.CLEAR or flow_state == BattleState.GAME_OVER:
		return
	_set_battle_state(BattleState.READY)
	_set_battle_active(false)
	_clear_active_fighter_actions(player)
	_clear_active_fighter_actions(enemy)
	player.visible = false
	enemy.visible = false
	_show_message("")
	if _player_order_panel != null:
		_player_order_panel.visible = true
		_set_player_order_exclusive_ui(true)
		_apply_player_order_responsive_layout()
	update_order_select_ui()
	player_order_select_opened.emit()
	print("[DEV034] Player order select opened")


func close_player_order_select() -> void:
	if _player_order_panel != null:
		_player_order_panel.visible = false
	_set_player_order_exclusive_ui(false)
	player.visible = true
	enemy.visible = true


func select_order_character(character_id: String) -> void:
	if is_player_order_confirmed:
		return
	if not is_valid_player_id(character_id):
		return
	if selected_player_order.has(character_id):
		deselect_order_character(character_id)
		return
	if selected_player_order.size() >= 3:
		return
	selected_player_order.append(character_id)
	print("[DEV034] Player selected for order: %s" % character_id)
	_emit_player_order_changed()


func deselect_order_character(character_id: String) -> void:
	if is_player_order_confirmed:
		return
	var index := selected_player_order.find(character_id)
	if index == -1:
		return
	selected_player_order.remove_at(index)
	_emit_player_order_changed()


func move_order_up(character_id: String) -> void:
	var index := selected_player_order.find(character_id)
	if index <= 0:
		return
	var previous := selected_player_order[index - 1]
	selected_player_order[index - 1] = character_id
	selected_player_order[index] = previous
	_emit_player_order_changed()


func move_order_down(character_id: String) -> void:
	var index := selected_player_order.find(character_id)
	if index == -1 or index >= selected_player_order.size() - 1:
		return
	var next := selected_player_order[index + 1]
	selected_player_order[index + 1] = character_id
	selected_player_order[index] = next
	_emit_player_order_changed()


func reset_order_selection() -> void:
	if is_player_order_confirmed:
		return
	selected_player_order.clear()
	_emit_player_order_changed()


func confirm_player_order() -> void:
	if is_battle_starting:
		return
	if not is_valid_player_order(selected_player_order):
		push_warning("Invalid player order.")
		return
	is_battle_starting = true
	update_confirm_button_state()
	set_player_order(selected_player_order)
	player_order_confirmed.emit(selected_player_order.duplicate())
	print("[DEV034] Player order confirmed: %s" % ", ".join(selected_player_order))
	start_battle_with_first_player()


func set_player_order(order: Array[String]) -> void:
	if not is_valid_player_order(order):
		push_warning("Invalid player order.")
		return
	selected_player_order = order.duplicate()
	current_player_order_index = 0
	is_player_order_confirmed = true
	update_player_order_hud()


func get_player_order() -> Array[String]:
	return selected_player_order.duplicate()


func get_first_player_id() -> String:
	if selected_player_order.is_empty():
		return ""
	return selected_player_order[0]


func get_next_ordered_player_id() -> String:
	if current_player_order_index + 1 >= selected_player_order.size():
		return ""
	return selected_player_order[current_player_order_index + 1]


func get_next_available_ordered_player_id() -> String:
	for index in range(current_player_order_index + 1, selected_player_order.size()):
		var character_id := selected_player_order[index]
		if is_player_available(character_id):
			current_player_order_index = index
			return character_id
	return ""


func advance_player_order() -> void:
	current_player_order_index = mini(current_player_order_index + 1, selected_player_order.size())


func reset_player_order() -> void:
	reset_player_order_data()
	update_order_select_ui()
	update_player_order_hud()


func is_valid_player_order(order: Array[String]) -> bool:
	if order.size() != 3:
		return false
	var unique_ids := {}
	for character_id in order:
		if character_id == "":
			return false
		if not is_valid_player_id(character_id):
			return false
		if unique_ids.has(character_id):
			return false
		unique_ids[character_id] = true
	return true


func validate_player_order(order: Array[String]) -> bool:
	return is_valid_player_order(order)


func is_valid_player_id(character_id: String) -> bool:
	return _find_player_index_by_id(character_id) != -1


func is_player_available(character_id: String) -> bool:
	var player_index := _find_player_index_by_id(character_id)
	return player_index != -1 and _is_player_selectable(player_index)


func start_battle_with_first_player() -> void:
	var first_player_id := get_first_player_id()
	if first_player_id == "":
		is_battle_starting = false
		return
	close_player_order_select()
	battle_start_requested.emit(first_player_id)
	spawn_ordered_player(first_player_id)
	print("[DEV034] First player spawned: %s" % first_player_id)
	print("[DEV034] Battle started")
	is_battle_starting = false
	_set_battle_state(BattleState.READY)
	await prepare_battle()


func start_ordered_player_change() -> void:
	if is_ordered_player_change_processing:
		return
	is_ordered_player_change_processing = true
	var defeated_id := String(_active_player_id())
	print("[DEV034] Ordered player defeated: %s" % defeated_id)
	var next_player_id := get_next_available_ordered_player_id()
	if next_player_id == "":
		print("[DEV034] No ordered players remaining")
		print("[DEV034] GAME OVER")
		is_ordered_player_change_processing = false
		enter_game_over()
		return
	next_ordered_player_requested.emit(next_player_id)
	print("[DEV034] Next ordered player: %s" % next_player_id)
	print("[DEV034] Enemy HP retained: %d / %d" % [enemy.current_hp, enemy.max_hp])
	await show_next_player_message(next_player_id)
	spawn_ordered_player(next_player_id)
	print("[DEV034] Player spawned: %s" % next_player_id)
	is_ordered_player_change_processing = false
	await prepare_battle()


func show_next_player_message(character_id: String) -> void:
	_show_message("%s K.O." % _display_name_for_id(String(_active_player_id())))
	await get_tree().create_timer(player_defeat_display_time).timeout
	_show_message("NEXT FIGHTER\n%s" % _display_name_for_id(character_id))
	await get_tree().create_timer(next_player_display_time).timeout
	_show_message("")


func spawn_ordered_player(character_id: String) -> void:
	var player_index := _find_player_index_by_id(character_id)
	if player_index == -1:
		return
	current_player_order_index = selected_player_order.find(character_id)
	current_player_index = player_index
	current_player_id = character_id
	if not selected_player_ids.has(StringName(character_id)):
		selected_player_ids.append(StringName(character_id))
	spawn_active_player()
	update_enemy_target()
	update_camera_target()
	update_player_order_hud()


func select_player(selection) -> void:
	if flow_state != BattleState.NEXT_PLAYER:
		return
	var player_index := -1
	if selection is String or selection is StringName:
		player_index = _find_player_index_by_id(String(selection))
	else:
		player_index = int(selection)
	if not _is_player_selectable(player_index):
		return

	var selected_id := String(player_team[player_index]["character_id"])
	select_player_by_id(selected_id)


func select_player_by_id(character_id: String) -> void:
	var player_index := _find_player_index_by_id(character_id)
	if player_index == -1 or not _is_player_selectable(player_index):
		return

	current_player_index = player_index
	current_player_id = character_id
	var player_id := _active_player_id()
	if player_id != &"" and not selected_player_ids.has(player_id):
		selected_player_ids.append(player_id)
	close_player_select()
	player_selected.emit(character_id)
	print("[DEV033] Player selected: %s" % character_id)
	_set_battle_state(BattleState.READY)
	await prepare_battle()


func spawn_active_player() -> void:
	if current_player_index < 0 or current_player_index >= player_team.size():
		return

	var data := player_team[current_player_index]
	var definition: Resource = data["definition"]
	var previous_player_id := _last_spawned_player_id
	if previous_player_id != "":
		_store_player_special_gauge(previous_player_id)
	if player.has_method("apply_fighter_definition"):
		player.apply_fighter_definition(definition)
	if player.has_method("set_special_gauge"):
		player.set_special_gauge(float(data.get("special_gauge", 0.0)))
	var current_health := int(clampi(data["current_health"], 1, data["max_health"]))
	player.visible = true
	reset_active_fighter_state(player, _player_start_position, 1.0, current_health)
	current_player_instance = player
	current_player_id = String(data["character_id"])
	if previous_player_id != "" and previous_player_id != current_player_id:
		print("[DEV035] Character changed: %s -> %s" % [previous_player_id, current_player_id])
	print("[DEV035] %s stats applied" % current_player_id)
	print("[DEV035] HUD max HP updated: %d" % player.max_hp)
	_last_spawned_player_id = current_player_id
	current_player_changed.emit(current_player_instance)
	_update_battle_hud_player()
	update_player_hud()


func spawn_active_enemy(restore_full_health := true) -> void:
	if current_enemy_index < 0 or current_enemy_index >= enemy_team.size():
		return

	var data := enemy_team[current_enemy_index]
	var definition: Resource = data.get("definition", null)
	if definition != null and enemy.has_method("apply_fighter_definition"):
		enemy.apply_fighter_definition(definition)
	if definition != null and enemy.has_method("apply_ai_profile"):
		enemy.apply_ai_profile(definition.ai_profile)
	if definition != null and enemy.has_method("apply_temporary_color"):
		enemy.apply_temporary_color(definition.temporary_color)

	if restore_full_health:
		data["current_health"] = int(data["max_health"])
		data["is_defeated"] = false
	var current_health := int(clampi(data["current_health"], 1, data["max_health"]))
	reset_active_fighter_state(enemy, _enemy_start_position, -1.0, current_health)
	if enemy.has_method("set_special_gauge"):
		enemy.set_special_gauge(0.0)
	enemy.current_hp = enemy.max_hp if restore_full_health else enemy.current_hp
	if restore_full_health:
		data["current_health"] = enemy.current_hp
		enemy.hp_changed.emit(enemy.current_hp, enemy.max_hp)
	_update_battle_hud_enemy()
	hud_enemy_spawned.emit(enemy, current_enemy_index, data.duplicate(true))


func prepare_battle() -> void:
	if _should_finish_game():
		return

	_set_battle_state(BattleState.READY)
	_flow_sequence_id += 1
	var sequence_id := _flow_sequence_id
	_pending_player_ko = false
	_pending_enemy_ko = false
	battle_result_locked = false
	is_battle_resolving = false
	battle_result = &""
	_time_accumulator = 0.0
	roundTime = round_time_limit

	start_battle(_active_player_id(), _active_enemy_id())
	_set_battle_active(false)
	_update_all_ui()
	active_fighter_changed.emit(_active_player_id(), _active_enemy_id())
	update_enemy_target()
	update_camera_target()

	if _should_show_enemy_intro():
		_notify_hud_enemy_intro(enemy_team[current_enemy_index], current_enemy_index)
		await start_enemy_intro(enemy_team[current_enemy_index])

	await start_battle_countdown(sequence_id)


func start_battle(player_id: StringName = &"", enemy_id: StringName = &"") -> void:
	if player_id != &"" and player_id != _active_player_id():
		push_warning("start_battle player id mismatch: %s" % player_id)
	if enemy_id != &"" and enemy_id != _active_enemy_id():
		push_warning("start_battle enemy id mismatch: %s" % enemy_id)
	spawn_active_player()
	spawn_active_enemy(not is_player_change_processing)


func start_enemy_intro(enemy_data: Dictionary) -> void:
	if current_enemy_index < 0 or current_enemy_index >= enemy_team.size():
		return
	_last_intro_enemy_index = current_enemy_index
	_set_battle_active(false)
	_clear_active_fighter_actions(player)
	_clear_active_fighter_actions(enemy)
	_show_enemy_intro(enemy_data)
	await get_tree().create_timer(1.35).timeout
	finish_enemy_intro()


func finish_enemy_intro() -> void:
	if _enemy_intro_panel != null:
		_enemy_intro_panel.visible = false


func start_battle_countdown(sequence_id: int = -1) -> void:
	if sequence_id == -1:
		sequence_id = _flow_sequence_id

	if sequence_id != _flow_sequence_id or flow_state != BattleState.READY:
		return
	_show_message("ENEMY %d" % (current_enemy_index + 1))
	_notify_hud_message("ENEMY %d" % (current_enemy_index + 1), 1, 0.9)
	await get_tree().create_timer(1.0).timeout

	if sequence_id != _flow_sequence_id or flow_state != BattleState.READY:
		return

	_set_battle_state(BattleState.FIGHT)
	begin_battle(sequence_id)


func begin_battle(sequence_id: int = -1) -> void:
	if sequence_id != -1 and sequence_id != _flow_sequence_id:
		return

	_set_battle_state(BattleState.BATTLE)
	isBattleFinished = false
	isRoundActive = true
	_set_battle_active(true)
	if is_player_change_processing:
		start_change_invincibility()
	_switch_bgm("BattleBGM")
	_start_dev044_battle_statistics()
	_apply_dev044_debug_mode()
	_show_message("FIGHT")
	_notify_hud_fight()
	battle_started.emit(_active_player_id(), _active_enemy_id())
	print("Battle Start: %s VS %s" % [_active_player_id(), _active_enemy_id()])
	await get_tree().create_timer(fight_message_duration).timeout
	if flow_state == BattleState.BATTLE:
		_show_message("")
		resume_battle_after_player_change()


func on_fighter_ko(fighter: Node) -> void:
	if flow_state != BattleState.BATTLE and flow_state != BattleState.ENEMY_DEAD and flow_state != BattleState.PLAYER_DEAD:
		return
	if fighter == player and is_player_change_processing:
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
	is_battle_resolving = true
	_set_battle_state(BattleState.PLAYER_DEAD if fighter == player else BattleState.ENEMY_DEAD)
	_set_battle_active(false)
	_clear_active_fighter_actions(player)
	_clear_active_fighter_actions(enemy)
	_show_message("K.O.")
	_notify_hud_message("K.O.", 2, 0.9)
	print("KO detected")
	await _resolve_ko_after_pause()


func resolve_battle_result() -> void:
	var result := _get_pending_battle_result()
	battle_result = StringName(BattleOutcome.keys()[result])
	var result_data := {
		"outcome": result,
		"player_id": _active_player_id(),
		"enemy_id": _active_enemy_id(),
	}
	_record_dev044_battle_statistics(result)
	battle_finished.emit(result_data)

	match result:
		BattleOutcome.PLAYER_WIN:
			handle_player_victory()
			_show_message("PLAYER WIN")
			_notify_hud_message("PLAYER WIN", 2, 1.0)
		BattleOutcome.ENEMY_WIN:
			handle_player_defeat()
			_show_message("ENEMY WIN")
			_notify_hud_message("ENEMY WIN", 2, 1.0)
		BattleOutcome.DOUBLE_KO:
			handle_double_ko()
			_show_message("DOUBLE K.O.")
			_notify_hud_message("DOUBLE K.O.", 2, 1.0)

	_update_all_ui()
	await get_tree().create_timer(result_display_duration).timeout

	if _should_finish_game():
		return

	if result == BattleOutcome.PLAYER_WIN:
		current_enemy_index = get_next_enemy_index()
		if current_enemy_index == -1:
			enter_game_clear()
		else:
			_set_battle_state(BattleState.NEXT_ENEMY)
			await transition_to_next_enemy()
	else:
		await start_ordered_player_change()


func handle_player_victory() -> void:
	_mark_enemy_defeated()
	hud_enemy_defeated.emit(enemy, current_enemy_index)
	_notify_hud_enemy_defeated()
	_heal_active_player_after_enemy_defeat()
	playerWinCount += 1
	print("Enemy defeated: %s" % _active_enemy_id())


func handle_player_defeat() -> void:
	handle_player_defeated()


func handle_player_defeated() -> void:
	if is_player_change_processing:
		return
	is_player_change_processing = true
	_store_active_fighter_health()
	register_player_defeat(String(_active_player_id()))
	remove_current_player()
	enemyWinCount += 1
	_selection_reason = "PLAYER_DEFEATED"
	print("Player defeated: %s" % _active_player_id())
	print("[DEV033] Enemy HP retained: %d / %d" % [enemy.current_hp, enemy.max_hp])
	var available := get_available_players()
	if available.is_empty():
		print("[DEV033] No available players")
	else:
		print("[DEV033] Available players: %s" % ", ".join(available))


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


func get_available_players() -> Array[String]:
	var available: Array[String] = []
	for index in get_available_player_indices():
		available.append(String(player_team[index]["character_id"]))
	return available


func has_available_player() -> bool:
	return not get_available_players().is_empty()


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
	if flow_state == BattleState.CLEAR:
		return
	_set_battle_state(BattleState.CLEAR)
	isBattleFinished = true
	is_run_active = false
	_set_battle_active(false)
	_hide_player_selection()
	close_player_order_select()
	_switch_bgm("WinBGM")
	_show_message("GAME CLEAR")
	_notify_hud_game_clear()
	_show_end_panel("GAME CLEAR", "All 8 enemies defeated.\nORDER: %s\nDEFEATED: %d  SURVIVED: %d" % [
		_order_text(),
		defeated_player_ids.size(),
		maxi(0, selected_player_order.size() - defeated_player_ids.size()),
	])
	game_clear_menu_opened.emit()
	game_cleared.emit()
	print("GAME CLEAR")


func enter_game_over() -> void:
	if flow_state == BattleState.GAME_OVER:
		return
	_set_battle_state(BattleState.GAME_OVER)
	isBattleFinished = true
	is_run_active = false
	_set_battle_active(false)
	_hide_player_selection()
	close_player_order_select()
	_switch_bgm("LoseBGM")
	_show_message("GAME OVER")
	_notify_hud_game_over()
	_show_end_panel("GAME OVER", "All ally fighters defeated.")
	game_over_menu_opened.emit()
	all_players_defeated.emit()
	game_over_started.emit()
	game_over.emit()
	print("GAME OVER")
	print("[DEV033] GAME OVER")


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

	if fighter.has_method("clear_ai_action_state"):
		fighter.clear_ai_action_state()
	if fighter.has_method("_clear_pending_throw"):
		fighter._clear_pending_throw()
	if fighter.has_method("reset_combo"):
		fighter.reset_combo()
	if fighter.has_method("reset_knockdown_state"):
		fighter.reset_knockdown_state()
	if fighter.has_method("reset_character_special_state"):
		fighter.reset_character_special_state(false)
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
		"flow_state": BattleState.keys()[flow_state],
		"current_player_index": current_player_index,
		"current_enemy_index": current_enemy_index,
		"players": _serialize_team(player_team),
		"enemies": _serialize_team(enemy_team),
		"result_locked": battle_result_locked,
		"selected_player_ids": selected_player_ids.duplicate(),
		"defeated_player_ids": defeated_player_ids.duplicate(),
		"enemy_order": enemy_order.duplicate(),
		"defeated_enemy_ids": defeated_enemy_ids.duplicate(),
		"current_player_id": _active_player_id(),
		"current_enemy_id": _active_enemy_id(),
		"battle_result": battle_result,
		"is_run_active": is_run_active,
	}


func reset_game_progress() -> void:
	hud_retry_started.emit()
	if battle_hud != null and battle_hud.has_method("reset_battle_hud"):
		battle_hud.reset_battle_hud()
	_hide_end_panel()
	initialize_game_progress()
	start_initial_player_selection()


func initialize_new_run() -> void:
	initialize_game_progress()


func restart_current_game() -> void:
	if is_scene_transitioning:
		return
	is_scene_transitioning = true
	restart_requested.emit()
	print("[DEV041][GameFlow] Restart confirmed")
	var preserved_order := selected_player_order.duplicate()
	cleanup_battle_before_transition()
	hud_retry_started.emit()
	if battle_hud != null and battle_hud.has_method("reset_battle_hud"):
		battle_hud.reset_battle_hud()
	_hide_end_panel()
	initialize_game_progress()
	if preserved_order.size() == 3 and is_valid_player_order(preserved_order):
		set_player_order(preserved_order)
		await start_battle_with_first_player()
	else:
		start_initial_player_selection()
	is_scene_transitioning = false
	refresh_mobile_controls_visibility()
	scene_transition_finished.emit("restart")


func go_to_title() -> void:
	if is_scene_transitioning:
		return
	is_scene_transitioning = true
	return_to_title_requested.emit()
	print("[DEV041][GameFlow] Returning to title")
	cleanup_battle_before_transition()
	scene_transition_started.emit("res://scenes/Title.tscn")
	get_tree().change_scene_to_file("res://scenes/Title.tscn")


func return_to_battle() -> void:
	if not is_game_paused:
		return
	_release_touch_inputs()
	is_game_paused = false
	get_tree().paused = false
	if battle_hud != null and battle_hud.has_method("hide_pause_menu"):
		battle_hud.hide_pause_menu()
	if battle_hud != null and battle_hud.has_method("hide_confirm_dialog"):
		battle_hud.hide_confirm_dialog()
	_set_mobile_controls_paused(false)
	refresh_mobile_controls_visibility()
	battle_resumed.emit()
	print("[DEV041][Pause] Battle resumed")


func pause_battle() -> void:
	if not _can_pause_battle() or is_game_paused:
		return
	is_game_paused = true
	_release_touch_inputs()
	if battle_hud != null and battle_hud.has_method("show_pause_menu"):
		battle_hud.show_pause_menu()
	_set_mobile_controls_paused(true)
	refresh_mobile_controls_visibility()
	get_tree().paused = true
	battle_paused.emit()
	print("[DEV041][Pause] Battle paused")


func cleanup_battle_before_transition() -> void:
	is_game_paused = false
	get_tree().paused = false
	_release_touch_inputs()
	_set_mobile_controls_paused(false)
	_set_battle_active(false)
	_clear_active_fighter_actions(player)
	_clear_active_fighter_actions(enemy)
	if player.has_method("reset_special_attack_state"):
		player.reset_special_attack_state(false)
	if enemy.has_method("reset_special_attack_state"):
		enemy.reset_special_attack_state(false)
	if battle_hud != null:
		if battle_hud.has_method("hide_pause_menu"):
			battle_hud.hide_pause_menu()
		if battle_hud.has_method("hide_confirm_dialog"):
			battle_hud.hide_confirm_dialog()
		if battle_hud.has_method("hide_boss_warning"):
			battle_hud.hide_boss_warning()
	print("[DEV041][GameFlow] Battle cleanup completed")


func _can_pause_battle() -> bool:
	if is_scene_transitioning or isBattleFinished:
		return false
	if flow_state != BattleState.BATTLE:
		return false
	if not isRoundActive:
		return false
	if _end_panel != null and _end_panel.visible:
		return false
	return true


func _poll_pause_action() -> void:
	if Input.is_action_just_pressed("pause"):
		_toggle_pause_from_input()


func _toggle_pause_from_input() -> void:
	var frame := Engine.get_process_frames()
	if _last_pause_toggle_frame == frame:
		return
	_last_pause_toggle_frame = frame
	if is_game_paused:
		return_to_battle()
	elif _can_pause_battle():
		pause_battle()


func _release_touch_inputs() -> void:
	if mobile_controls != null and mobile_controls.has_method("release_all_touch_inputs"):
		mobile_controls.release_all_touch_inputs()


func _set_mobile_controls_paused(is_paused: bool) -> void:
	if mobile_controls != null and mobile_controls.has_method("set_paused_input_mode"):
		mobile_controls.set_paused_input_mode(is_paused)


func refresh_mobile_controls_visibility() -> void:
	if mobile_controls == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var is_portrait_orientation := viewport_size.y > viewport_size.x
	var is_player_order_open := _player_order_panel != null and _player_order_panel.visible
	var is_result_open := _end_panel != null and _end_panel.visible
	var should_show := (
		flow_state == BattleState.BATTLE
		and isRoundActive
		and not isBattleFinished
		and not is_scene_transitioning
		and not is_player_order_open
		and not is_result_open
		and not is_portrait_orientation
	)
	mobile_controls.process_mode = Node.PROCESS_MODE_ALWAYS if should_show else Node.PROCESS_MODE_DISABLED
	mobile_controls.visible = should_show
	mobile_controls.modulate.a = 1.0
	if should_show:
		if mobile_controls.has_method("set_paused_input_mode"):
			mobile_controls.set_paused_input_mode(is_game_paused)
		if mobile_controls.has_method("refresh_layout"):
			mobile_controls.call_deferred("refresh_layout")
	else:
		if mobile_controls.has_method("release_all_touch_inputs"):
			mobile_controls.release_all_touch_inputs()


func _on_battle_viewport_size_changed() -> void:
	refresh_mobile_controls_visibility()


func transition_to_next_enemy() -> void:
	_set_battle_active(false)
	_clear_active_fighter_actions(player)
	_clear_active_fighter_actions(enemy)
	enemy.visible = false
	await fade_out(0.4)
	enemy.visible = true
	await fade_in(0.4)
	await prepare_battle()


func spawn_selected_player(character_id: String) -> void:
	var player_index := _find_player_index_by_id(character_id)
	if player_index == -1:
		return
	current_player_index = player_index
	spawn_active_player()


func remove_current_player() -> void:
	_clear_active_fighter_actions(player)
	player.visible = false
	player.input_enabled = false


func update_enemy_target() -> void:
	if enemy.has_method("update_enemy_target"):
		enemy.update_enemy_target(current_player_instance)
	print("[DEV033] Enemy target updated: %s" % current_player_id)


func update_camera_target() -> void:
	pass


func update_player_hud() -> void:
	_update_hp_bar(player_hp_bar, player.current_hp, player.max_hp)
	_update_all_ui()


func start_change_invincibility() -> void:
	player.is_invincible = true
	player.invincibility_timer = player_change_invincible_time


func resume_battle_after_player_change() -> void:
	if not is_player_change_processing:
		return
	is_player_change_processing = false
	print("[DEV033] Battle resumed")


func start_game_over() -> void:
	enter_game_over()


func fade_out(duration := 0.4) -> void:
	if _fade_overlay == null:
		return
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "color", Color(0.0, 0.0, 0.0, 1.0), duration)
	await tween.finished


func fade_in(duration := 0.4) -> void:
	if _fade_overlay == null:
		return
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "color", Color(0.0, 0.0, 0.0, 0.0), duration)
	await tween.finished


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
	is_battle_resolving = true
	_set_battle_state(BattleState.PLAYER_DEAD if player.current_hp <= enemy.current_hp else BattleState.ENEMY_DEAD)
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
		var player_data := player_team[current_player_index]
		player_data["current_health"] = 0 if player_data["is_defeated"] else clampi(player.current_hp, 0, player.max_hp)
		if player.has_method("get_special_gauge"):
			player_data["special_gauge"] = float(player.get_special_gauge())
	if current_enemy_index >= 0 and current_enemy_index < enemy_team.size():
		var enemy_data := enemy_team[current_enemy_index]
		enemy_data["current_health"] = 0 if enemy_data["is_defeated"] else clampi(enemy.current_hp, 0, enemy.max_hp)


func _store_player_special_gauge(character_id: String) -> void:
	var player_index := _find_player_index_by_id(character_id)
	if player_index == -1 or player == null or not player.has_method("get_special_gauge"):
		return
	player_team[player_index]["special_gauge"] = float(player.get_special_gauge())


func _heal_active_player_after_enemy_defeat() -> void:
	var applied_heal := apply_enemy_defeat_recovery(String(_active_player_id()))
	if applied_heal <= 0:
		return
	print("[DEV035] Enemy defeated by: %s" % current_player_id)
	print("[DEV035] Recovery amount: %d" % applied_heal)
	print("[DEV035] HP after recovery: %d / %d" % [player.current_hp, player.max_hp])
	hud_healing_applied.emit(player, applied_heal)
	_show_heal_effect(applied_heal)


func apply_enemy_defeat_recovery(character_id: String) -> int:
	if current_player_index < 0 or current_player_index >= player_team.size():
		return 0
	if current_enemy_index < 0 or current_enemy_index >= enemy_team.size():
		return 0
	if _last_recovery_enemy_index == current_enemy_index:
		return 0
	if String(_active_player_id()) != character_id:
		return 0
	var player_data := player_team[current_player_index]
	var heal_amount := maxi(1, int(round(float(player.max_hp) * 0.2)))
	var previous_hp: int = player.current_hp
	var healed_hp := clampi(player.current_hp + heal_amount, 0, player.max_hp)
	var applied_heal: int = healed_hp - previous_hp
	_last_recovery_enemy_index = current_enemy_index
	player_data["current_health"] = healed_hp
	if player.has_method("set_health"):
		player.set_health(healed_hp)
	else:
		player.current_hp = healed_hp
		player.hp_changed.emit(player.current_hp, player.max_hp)
	return applied_heal


func _show_heal_effect(heal_amount: int) -> void:
	if _heal_effect_label == null:
		return
	_heal_effect_label.text = ""
	_heal_effect_label.visible = false
	return
	_heal_effect_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(_heal_effect_label, "modulate:a", 0.0, 0.2)
	await tween.finished
	_heal_effect_label.visible = false


func _start_dev044_battle_statistics() -> void:
	_current_battle_start_time_msec = Time.get_ticks_msec()
	_current_battle_start_player_hp = player.current_hp if player != null else 0
	_current_battle_start_enemy_hp = enemy.current_hp if enemy != null else 0
	_current_battle_statistics_recorded = false


func _record_dev044_battle_statistics(outcome: int) -> void:
	if _current_battle_statistics_recorded:
		return
	_current_battle_statistics_recorded = true
	var elapsed_sec := 0.0
	if _current_battle_start_time_msec > 0:
		elapsed_sec = float(Time.get_ticks_msec() - _current_battle_start_time_msec) / 1000.0
	var player_hp: int = player.current_hp if player != null else 0
	var enemy_hp: int = enemy.current_hp if enemy != null else 0
	var record := {
		"player_id": String(_active_player_id()),
		"enemy_id": String(_active_enemy_id()),
		"outcome": BattleOutcome.keys()[outcome],
		"battle_time": snappedf(elapsed_sec, 0.01),
		"player_remaining_hp": player_hp,
		"enemy_remaining_hp": enemy_hp,
		"damage_dealt": maxi(_current_battle_start_enemy_hp - enemy_hp, 0),
		"damage_taken": maxi(_current_battle_start_player_hp - player_hp, 0),
		"player_combo": _dev044_get_int_property(player, "combo_count"),
	}
	battle_statistics.append(record)
	if dev044_debug_tools_enabled:
		print("[DEV044][BattleStats] %s" % record)


func get_dev044_battle_statistics() -> Array[Dictionary]:
	return battle_statistics.duplicate(true)


func _apply_dev044_debug_mode() -> void:
	if not dev044_debug_tools_enabled:
		return
	match dev044_debug_mode:
		Dev044DebugMode.FAST_VERIFY:
			dev044_set_enemy_hp_to_one()
		Dev044DebugMode.AI_CHECK:
			_set_dev044_character_debug(enemy, "show_ai_debug", true)
		Dev044DebugMode.HITBOX_CHECK:
			_set_dev044_character_debug(player, "show_attack_hitboxes", true)
			_set_dev044_character_debug(enemy, "show_attack_hitboxes", true)
		Dev044DebugMode.PERFORMANCE_CHECK:
			_set_dev044_character_debug(player, "debug_state_label_enabled", false)
			_set_dev044_character_debug(enemy, "debug_state_label_enabled", false)


func _set_dev044_character_debug(character: Node, property_name: String, value: Variant) -> void:
	if character == null:
		return
	for property in character.get_property_list():
		if property.get("name", "") == property_name:
			character.set(property_name, value)
			return


func _dev044_get_int_property(character: Node, property_name: String) -> int:
	if character == null:
		return 0
	for property in character.get_property_list():
		if property.get("name", "") == property_name:
			return int(character.get(property_name))
	return 0


func _dev044_can_use_tools() -> bool:
	if not dev044_debug_tools_enabled:
		push_warning("DEV044 debug tools are disabled.")
		return false
	return true


func dev044_set_enemy_hp_to_one() -> void:
	if not _dev044_can_use_tools() or enemy == null:
		return
	if enemy.has_method("set_health"):
		enemy.set_health(1)
	else:
		enemy.current_hp = 1
		enemy.hp_changed.emit(enemy.current_hp, enemy.max_hp)
	if current_enemy_index >= 0 and current_enemy_index < enemy_team.size():
		enemy_team[current_enemy_index]["current_health"] = 1
	_update_all_ui()


func dev044_full_heal_player() -> void:
	if not _dev044_can_use_tools() or player == null:
		return
	if player.has_method("set_health"):
		player.set_health(player.max_hp)
	else:
		player.current_hp = player.max_hp
		player.hp_changed.emit(player.current_hp, player.max_hp)
	if current_player_index >= 0 and current_player_index < player_team.size():
		player_team[current_player_index]["current_health"] = player.max_hp
	_update_all_ui()


func dev044_reset_special_cooldowns() -> void:
	if not _dev044_can_use_tools():
		return
	for fighter in [player, enemy]:
		if fighter != null and fighter.has_method("reset_special_attack_state"):
			fighter.reset_special_attack_state()


func dev044_ko_current_enemy() -> void:
	if not _dev044_can_use_tools() or enemy == null:
		return
	if enemy.has_method("set_health"):
		enemy.set_health(0)
	else:
		enemy.current_hp = 0
		enemy.hp_changed.emit(enemy.current_hp, enemy.max_hp)
	on_fighter_ko(enemy)


func dev044_next_enemy() -> void:
	if not _dev044_can_use_tools():
		return
	var next_index := get_next_enemy_index()
	if next_index == -1:
		enter_game_clear()
		return
	current_enemy_index = next_index
	_flow_sequence_id += 1
	call_deferred("transition_to_next_enemy")


func dev044_toggle_player_defeated() -> void:
	if not _dev044_can_use_tools():
		return
	if current_player_index < 0 or current_player_index >= player_team.size():
		return
	var defeated: bool = not bool(player_team[current_player_index]["is_defeated"])
	player_team[current_player_index]["is_defeated"] = defeated
	player_team[current_player_index]["is_available"] = not defeated
	player_team[current_player_index]["current_health"] = 0 if defeated else player_team[current_player_index]["max_health"]
	_update_all_ui()


func dev044_go_to_clear_before_final() -> void:
	if not _dev044_can_use_tools():
		return
	for index in range(enemy_team.size()):
		enemy_team[index]["is_defeated"] = index < enemy_team.size() - 1
		enemy_team[index]["current_health"] = 0 if index < enemy_team.size() - 1 else enemy_team[index]["max_health"]
	current_enemy_index = maxi(enemy_team.size() - 1, 0)
	spawn_active_enemy()
	_update_all_ui()


func dev044_go_to_game_over_before_final_player() -> void:
	if not _dev044_can_use_tools():
		return
	for index in range(player_team.size()):
		var defeated := index < player_team.size() - 1
		player_team[index]["is_defeated"] = defeated
		player_team[index]["is_available"] = not defeated
		player_team[index]["current_health"] = 0 if defeated else player_team[index]["max_health"]
	current_player_index = maxi(player_team.size() - 1, 0)
	spawn_active_player()
	_update_all_ui()


func _switch_bgm(bgm_name: String) -> void:
	if _current_bgm_name == bgm_name:
		return
	_current_bgm_name = bgm_name
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("fade_bgm"):
		audio.call("fade_bgm", _bgm_id_for_name(bgm_name), 0.35)
	print("BGM: %s" % bgm_name)


func _bgm_id_for_name(bgm_name: String) -> String:
	match bgm_name:
		"BattleBGM":
			return "final_boss" if current_enemy_index >= 7 else "battle"
		"WinBGM":
			return "clear"
		"LoseBGM":
			return "game_over"
	return bgm_name.to_snake_case()


func _mark_player_defeated() -> void:
	if current_player_index < 0 or current_player_index >= player_team.size():
		return
	player_team[current_player_index]["current_health"] = 0
	player_team[current_player_index]["is_defeated"] = true
	player_team[current_player_index]["is_available"] = false
	var player_id := StringName(player_team[current_player_index]["fighter_id"])
	if not defeated_player_ids.has(player_id):
		defeated_player_ids.append(player_id)


func register_player_defeat(character_id: String) -> void:
	var player_index := _find_player_index_by_id(character_id)
	if player_index == -1:
		return
	current_player_index = player_index
	_mark_player_defeated()
	player_defeated.emit(character_id)
	print("[DEV033] Player defeated: %s" % character_id)


func _mark_enemy_defeated() -> void:
	if current_enemy_index < 0 or current_enemy_index >= enemy_team.size():
		return
	enemy_team[current_enemy_index]["current_health"] = 0
	enemy_team[current_enemy_index]["is_defeated"] = true
	var enemy_id := StringName(enemy_team[current_enemy_index]["fighter_id"])
	if not defeated_enemy_ids.has(enemy_id):
		defeated_enemy_ids.append(enemy_id)


func _set_battle_state(next_state: BattleState) -> void:
	var previous_state := flow_state
	flow_state = next_state
	currentBattleState = next_state
	if previous_state != next_state:
		game_flow_state_changed.emit(BattleState.keys()[previous_state], BattleState.keys()[next_state])
	refresh_mobile_controls_visibility()


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
	refresh_mobile_controls_visibility()


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
	if fighter.has_method("reset_character_special_state"):
		fighter.reset_character_special_state(false)


func _create_progress_entry_from_definition(definition: Resource, battle_order: int) -> Dictionary:
	var max_health := int(round(definition.max_health))
	return {
		"definition": definition,
		"character_id": definition.fighter_id,
		"fighter_id": definition.fighter_id,
		"display_name": definition.display_name,
		"fighter_type": String(definition.fighter_type),
		"scene_path": "",
		"max_health": max_health,
		"current_health": max_health,
		"special_gauge": 0.0,
		"is_defeated": false,
		"is_available": true,
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
		"character_id": fighter_id,
		"fighter_id": fighter_id,
		"display_name": display_name,
		"scene_path": "",
		"max_health": max_health,
		"current_health": max_health,
		"special_gauge": 0.0,
		"is_defeated": false,
		"is_available": true,
		"battle_order": battle_order,
	}


func _is_player_selectable(player_index: int) -> bool:
	if player_index < 0 or player_index >= player_team.size():
		return false
	var data := player_team[player_index]
	return bool(data.get("is_available", true)) and not data["is_defeated"] and data["current_health"] > 0


func _find_player_index_by_id(character_id: String) -> int:
	for index in range(player_team.size()):
		if String(player_team[index].get("character_id", player_team[index]["fighter_id"])) == character_id:
			return index
	return -1


func _display_name_for_id(character_id: String) -> String:
	var player_index := _find_player_index_by_id(character_id)
	if player_index == -1:
		return character_id
	return String(player_team[player_index]["display_name"])


func _short_order_name_for_id(character_id: String) -> String:
	var player_index := _find_player_index_by_id(character_id)
	if player_index == -1:
		return character_id
	return "P%d" % (player_index + 1)


func _definition_for_player_id(character_id: String) -> Resource:
	var player_index := _find_player_index_by_id(character_id)
	if player_index == -1:
		return null
	return player_team[player_index].get("definition", null)


func _type_for_player_id(character_id: String) -> String:
	var definition := _definition_for_player_id(character_id)
	if definition == null:
		return ""
	return String(definition.fighter_type).to_upper()


func _stats_text_for_definition(definition: Resource) -> String:
	if definition == null:
		return ""
	return "HP %d  SPD %d/%d\nP %d  K %d  GRD %.2f\n%s" % [
		int(round(definition.max_health)),
		int(round(definition.move_speed)),
		int(round(definition.air_move_speed)),
		int(round(definition.punch_damage)),
		int(round(definition.kick_damage)),
		float(definition.guard_damage_multiplier),
		_attack_trait_text_for_definition(definition),
	]


func _order_portrait_texture(data: Dictionary) -> Texture2D:
	var definition: Resource = data.get("definition", null)
	if definition == null:
		return null
	if definition.selection_portrait != null:
		return definition.selection_portrait
	if definition.portrait != null:
		return definition.portrait
	if definition.selection_icon != null:
		return definition.selection_icon
	return definition.icon


func _attack_trait_text_for_definition(definition: Resource) -> String:
	var combo_count := 0
	var max_reach := 0.0
	for attack_data in definition.attack_sequence:
		if attack_data == null:
			continue
		combo_count += 1
		max_reach = maxf(max_reach, absf(float(attack_data.hitbox_offset.x)) + float(attack_data.hitbox_size.x) * 0.5)
	if int(definition.max_attack_chain_count) > 0:
		combo_count = int(definition.max_attack_chain_count)
	var type_text := "STANDARD"
	match String(definition.fighter_type):
		"power":
			type_text = "HEAVY"
		"speed":
			type_text = "RUSH"
	return "ATK %s  COMBO %d  RANGE %d" % [type_text, combo_count, int(round(max_reach))]


func _order_slot_text(index: int) -> String:
	if index < selected_player_order.size():
		return _short_order_name_for_id(selected_player_order[index])
	return "--"


func _order_status_text(character_id: String, order_index: int) -> String:
	if defeated_player_ids.has(StringName(character_id)):
		return "DEFEATED"
	if order_index == current_player_order_index and String(_active_player_id()) == character_id and flow_state == BattleState.BATTLE:
		return "ACTIVE"
	return "WAIT"


func _order_text() -> String:
	if selected_player_order.is_empty():
		return "NONE"
	var names: Array[String] = []
	for character_id in selected_player_order:
		names.append(_display_name_for_id(character_id))
	return ", ".join(names)


func _emit_player_order_changed() -> void:
	player_order_changed.emit(selected_player_order.duplicate())
	print("[DEV034] Current order: %s" % ", ".join(selected_player_order))
	update_order_select_ui()


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


func get_battle_hud_snapshot() -> Dictionary:
	return {
		"player": player,
		"enemy": enemy,
		"player_team": _serialize_team(player_team),
		"enemy_team": _serialize_team(enemy_team),
		"current_player_index": current_player_index,
		"current_enemy_index": current_enemy_index,
		"flow_state": BattleState.keys()[flow_state],
	}


func _initialize_battle_hud() -> void:
	if battle_hud == null:
		return
	if battle_hud.has_method("initialize_hud"):
		battle_hud.initialize_hud(self)


func _update_battle_hud_player() -> void:
	if battle_hud == null:
		return
	if battle_hud.has_method("update_player_status"):
		battle_hud.update_player_status(player)
	if battle_hud.has_method("update_team_status"):
		battle_hud.update_team_status(player_team, current_player_index)


func _update_battle_hud_enemy() -> void:
	if battle_hud == null:
		return
	if battle_hud.has_method("update_enemy_status"):
		battle_hud.update_enemy_status(enemy)
	if battle_hud.has_method("update_enemy_information") and current_enemy_index >= 0 and current_enemy_index < enemy_team.size():
		battle_hud.update_enemy_information(enemy_team[current_enemy_index], current_enemy_index)


func _notify_hud_enemy_intro(enemy_data: Dictionary, enemy_index: int) -> void:
	if battle_hud != null and battle_hud.has_method("show_enemy_intro"):
		battle_hud.show_enemy_intro(enemy_data, enemy_index)


func _notify_hud_enemy_defeated() -> void:
	pass


func _notify_hud_fight() -> void:
	_notify_hud_message("FIGHT", 2, fight_message_duration)


func _notify_hud_message(message: String, priority: int, duration: float) -> void:
	hud_message_requested.emit(message, priority, duration)


func _notify_hud_game_over() -> void:
	pass


func _notify_hud_game_clear() -> void:
	pass


func _create_flow_ui() -> void:
	_progress_label = Label.new()
	_progress_label.name = "ProgressLabel"
	_progress_label.visible = false
	_progress_label.text = ""
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

	_enemy_intro_panel = PanelContainer.new()
	_enemy_intro_panel.name = "EnemyIntroPanel"
	_enemy_intro_panel.visible = false
	_enemy_intro_panel.set_anchors_preset(Control.PRESET_CENTER)
	_enemy_intro_panel.offset_left = -220.0
	_enemy_intro_panel.offset_top = -90.0
	_enemy_intro_panel.offset_right = 220.0
	_enemy_intro_panel.offset_bottom = 90.0
	battle_ui_root.add_child(_enemy_intro_panel)

	_enemy_intro_label = Label.new()
	_enemy_intro_label.name = "EnemyIntroLabel"
	_enemy_intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_intro_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_enemy_intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_enemy_intro_label.add_theme_font_size_override("font_size", 22)
	_enemy_intro_panel.add_child(_enemy_intro_label)

	_end_panel = PanelContainer.new()
	_end_panel.name = "RunEndPanel"
	_end_panel.visible = false
	_end_panel.set_anchors_preset(Control.PRESET_CENTER)
	_end_panel.offset_left = -190.0
	_end_panel.offset_top = -120.0
	_end_panel.offset_right = 190.0
	_end_panel.offset_bottom = 120.0
	battle_ui_root.add_child(_end_panel)

	var end_box := VBoxContainer.new()
	end_box.add_theme_constant_override("separation", 14)
	_end_panel.add_child(end_box)

	_end_title_label = Label.new()
	_end_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_title_label.add_theme_font_size_override("font_size", 30)
	end_box.add_child(_end_title_label)

	_end_body_label = Label.new()
	_end_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_box.add_child(_end_body_label)

	_restart_button = Button.new()
	_restart_button.text = "RESTART"
	_restart_button.custom_minimum_size = Vector2(260.0, 42.0)
	_restart_button.pressed.connect(reset_game_progress)
	end_box.add_child(_restart_button)

	_title_button = Button.new()
	_title_button.text = "TITLE"
	_title_button.disabled = false
	_title_button.custom_minimum_size = Vector2(260.0, 42.0)
	_title_button.pressed.connect(go_to_title)
	end_box.add_child(_title_button)

	_heal_effect_label = Label.new()
	_heal_effect_label.name = "HealEffectLabel"
	_heal_effect_label.visible = false
	_heal_effect_label.set_anchors_preset(Control.PRESET_CENTER)
	_heal_effect_label.offset_left = -100.0
	_heal_effect_label.offset_top = 110.0
	_heal_effect_label.offset_right = 100.0
	_heal_effect_label.offset_bottom = 150.0
	_heal_effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heal_effect_label.add_theme_font_size_override("font_size", 28)
	_heal_effect_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55, 1.0))
	battle_ui_root.add_child(_heal_effect_label)

	_fade_overlay = ColorRect.new()
	_fade_overlay.name = "FadeOverlay"
	_fade_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_ui_root.add_child(_fade_overlay)

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BattleBGMPlayer"
	add_child(_bgm_player)

	_create_player_order_ui()

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


func _create_player_order_ui() -> void:
	_player_order_hud_label = Label.new()
	_player_order_hud_label.name = "PlayerOrderHudLabel"
	_player_order_hud_label.visible = false
	_player_order_hud_label.text = ""
	_player_order_hud_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_player_order_hud_label.offset_left = 24.0
	_player_order_hud_label.offset_top = 114.0
	_player_order_hud_label.offset_right = -24.0
	_player_order_hud_label.offset_bottom = 170.0
	_player_order_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_order_hud_label.add_theme_font_size_override("font_size", 15)
	battle_ui_root.add_child(_player_order_hud_label)

	_player_order_panel = PanelContainer.new()
	_player_order_panel.name = "PlayerOrderSelectUI"
	_player_order_panel.visible = false
	_player_order_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_player_order_panel.offset_left = 0.0
	_player_order_panel.offset_top = 0.0
	_player_order_panel.offset_right = 0.0
	_player_order_panel.offset_bottom = 0.0
	battle_ui_root.add_child(_player_order_panel)

	_player_order_margin = MarginContainer.new()
	_player_order_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_order_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_player_order_panel.add_child(_player_order_margin)

	_player_order_root = VBoxContainer.new()
	_player_order_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_order_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_player_order_root.add_theme_constant_override("separation", 6)
	_player_order_margin.add_child(_player_order_root)

	_player_order_header = HBoxContainer.new()
	_player_order_header.alignment = BoxContainer.ALIGNMENT_CENTER
	_player_order_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_order_header.add_theme_constant_override("separation", 8)
	_player_order_root.add_child(_player_order_header)

	_player_order_back_button = Button.new()
	_player_order_back_button.text = "< BACK"
	_player_order_back_button.custom_minimum_size = Vector2(140.0, 48.0)
	_player_order_back_button.pressed.connect(go_to_title)
	_player_order_header.add_child(_player_order_back_button)

	_player_order_header_center = VBoxContainer.new()
	_player_order_header_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_order_header_center.add_theme_constant_override("separation", 2)
	_player_order_header.add_child(_player_order_header_center)

	_player_order_title_label = Label.new()
	_player_order_title_label.text = "PLAYER ORDER"
	_player_order_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_order_title_label.add_theme_font_size_override("font_size", 22)
	_player_order_header_center.add_child(_player_order_title_label)

	_player_order_slots_label = Label.new()
	_player_order_slots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_order_slots_label.add_theme_font_size_override("font_size", 15)
	_player_order_header_center.add_child(_player_order_slots_label)

	var header_right_spacer := Control.new()
	header_right_spacer.custom_minimum_size = Vector2(140.0, 1.0)
	_player_order_header.add_child(header_right_spacer)

	_player_order_character_list = HBoxContainer.new()
	_player_order_character_list.alignment = BoxContainer.ALIGNMENT_CENTER
	_player_order_character_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_order_character_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_player_order_character_list.add_theme_constant_override("separation", 10)
	_player_order_root.add_child(_player_order_character_list)

	for data in player_team:
		var character_id := String(data["character_id"])
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(0.0, 0.0)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation", 4)
		_player_order_character_list.add_child(box)
		_player_order_card_boxes[character_id] = box

		var badge := Label.new()
		badge.text = ""
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.custom_minimum_size = Vector2(32.0, 28.0)
		badge.add_theme_font_size_override("font_size", 16)
		badge.visible = false
		box.add_child(badge)
		_player_order_order_badges[character_id] = badge

		var portrait_rect := TextureRect.new()
		portrait_rect.custom_minimum_size = Vector2(120.0, 120.0)
		portrait_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		portrait_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait_rect.texture = _order_portrait_texture(data)
		portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(portrait_rect)
		_player_order_portrait_rects[character_id] = portrait_rect

		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 46.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(select_order_character.bind(character_id))
		box.add_child(button)
		_player_order_character_buttons[character_id] = button

		var controls := HBoxContainer.new()
		controls.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_child(controls)
		_player_order_control_rows[character_id] = controls

		var up_button := Button.new()
		up_button.text = "UP"
		up_button.pressed.connect(move_order_up.bind(character_id))
		controls.add_child(up_button)
		_player_order_up_buttons[character_id] = up_button

		var down_button := Button.new()
		down_button.text = "DOWN"
		down_button.pressed.connect(move_order_down.bind(character_id))
		controls.add_child(down_button)
		_player_order_down_buttons[character_id] = down_button

		var remove_button := Button.new()
		remove_button.text = "REMOVE"
		remove_button.custom_minimum_size = Vector2(0.0, 28.0)
		remove_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		remove_button.pressed.connect(deselect_order_character.bind(character_id))
		box.add_child(remove_button)
		_player_order_remove_buttons[character_id] = remove_button

	_player_order_footer = HBoxContainer.new()
	_player_order_footer.alignment = BoxContainer.ALIGNMENT_END
	_player_order_footer.custom_minimum_size = Vector2(0.0, 50.0)
	_player_order_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_order_footer.add_theme_constant_override("separation", 10)
	_player_order_root.add_child(_player_order_footer)

	_player_order_status_label = Label.new()
	_player_order_status_label.text = "Select sortie order"
	_player_order_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_player_order_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_player_order_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_order_footer.add_child(_player_order_status_label)

	_player_order_reset_button = Button.new()
	_player_order_reset_button.text = "RESET"
	_player_order_reset_button.custom_minimum_size = Vector2(140.0, 48.0)
	_player_order_reset_button.pressed.connect(reset_order_selection)
	_player_order_footer.add_child(_player_order_reset_button)

	_player_order_confirm_button = Button.new()
	_player_order_confirm_button.text = "CONFIRM"
	_player_order_confirm_button.visible = true
	_player_order_confirm_button.custom_minimum_size = Vector2(160.0, 48.0)
	_player_order_confirm_button.pressed.connect(confirm_player_order)
	_player_order_footer.add_child(_player_order_confirm_button)

	_apply_player_order_responsive_layout()
	update_order_select_ui()


func update_order_select_ui() -> void:
	if _player_order_slots_label == null:
		return
	_player_order_slots_label.text = "1:%s   2:%s   3:%s" % [
		_order_slot_text(0),
		_order_slot_text(1),
		_order_slot_text(2),
	]

	for data in player_team:
		var character_id := String(data["character_id"])
		var order_index := selected_player_order.find(character_id)
		var selected := order_index != -1
		var button: Button = _player_order_character_buttons.get(character_id)
		if button != null:
			button.text = "ORDER %d" % (order_index + 1) if selected else "SELECT"
			button.disabled = is_player_order_confirmed
			button.modulate = Color(0.65, 0.85, 1.0, 1.0) if selected else Color.WHITE

		var portrait_rect: TextureRect = _player_order_portrait_rects.get(character_id)
		if portrait_rect != null:
			portrait_rect.texture = _order_portrait_texture(data)
			portrait_rect.modulate = Color(1.0, 1.0, 1.0, 1.0) if selected else Color(0.9, 0.9, 0.9, 1.0)

		var badge := _player_order_order_badges.get(character_id) as Label
		if badge != null:
			badge.text = "%d" % (order_index + 1) if selected else ""
			badge.visible = selected

		var up_button: Button = _player_order_up_buttons.get(character_id)
		if up_button != null:
			up_button.disabled = not selected or order_index <= 0 or is_player_order_confirmed
		var down_button: Button = _player_order_down_buttons.get(character_id)
		if down_button != null:
			down_button.disabled = not selected or order_index >= selected_player_order.size() - 1 or is_player_order_confirmed
		var remove_button: Button = _player_order_remove_buttons.get(character_id)
		if remove_button != null:
			remove_button.disabled = not selected or is_player_order_confirmed

	if _player_order_status_label != null:
		_player_order_status_label.text = "Ready to start" if is_valid_player_order(selected_player_order) else "Select sortie order"
	update_confirm_button_state()
	update_player_order_hud()


func update_confirm_button_state() -> void:
	if _player_order_confirm_button == null:
		return
	_player_order_confirm_button.visible = true
	_player_order_confirm_button.disabled = not is_valid_player_order(selected_player_order) or is_battle_starting


func _set_player_order_exclusive_ui(is_open: bool) -> void:
	if battle_hud != null:
		battle_hud.visible = not is_open
	for legacy_battle_control in [player_hp_bar, enemy_hp_bar, timer_label, message_label, player_win_marks, enemy_win_marks]:
		if legacy_battle_control != null:
			legacy_battle_control.visible = not is_open and legacy_battle_control in [player_hp_bar, enemy_hp_bar]
	if _enemy_intro_panel != null:
		_enemy_intro_panel.visible = false
	if _progress_label != null:
		_progress_label.visible = false
	if _heal_effect_label != null:
		_heal_effect_label.visible = false
	refresh_mobile_controls_visibility()


func _apply_player_order_responsive_layout() -> void:
	if _player_order_panel == null or _player_order_root == null:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var is_mobile_landscape := _is_mobile_landscape_viewport(viewport_size)
	var safe_margin := _player_order_safe_margin(is_mobile_landscape)
	_player_order_panel.offset_left = safe_margin.x
	_player_order_panel.offset_top = safe_margin.y
	_player_order_panel.offset_right = -safe_margin.z
	_player_order_panel.offset_bottom = -safe_margin.w

	if _player_order_margin != null:
		var inner_margin := 0 if is_mobile_landscape else 8
		_player_order_margin.add_theme_constant_override("margin_left", inner_margin)
		_player_order_margin.add_theme_constant_override("margin_top", inner_margin)
		_player_order_margin.add_theme_constant_override("margin_right", inner_margin)
		_player_order_margin.add_theme_constant_override("margin_bottom", inner_margin)

	var usable_width := maxf(360.0, viewport_size.x - safe_margin.x - safe_margin.z)
	var usable_height := maxf(260.0, viewport_size.y - safe_margin.y - safe_margin.w)
	var card_gap := 6.0 if is_mobile_landscape else 12.0
	var root_width := usable_width
	var root_height := usable_height
	var header_height := clampf(usable_height * 0.13, 40.0, 58.0) if is_mobile_landscape else 76.0
	var footer_button_height := clampf(usable_height * 0.13, 42.0, 52.0) if is_mobile_landscape else 48.0
	var select_button_height := clampf(usable_height * 0.11, 38.0, 46.0) if is_mobile_landscape else 46.0
	var order_control_height := clampf(usable_height * 0.095, 32.0, 40.0) if is_mobile_landscape else 32.0
	var root_separation := 2.0 if is_mobile_landscape else 6.0
	var card_width := (usable_width - card_gap * 2.0) / 3.0 if is_mobile_landscape else 250.0
	var cards_area_height := maxf(120.0, usable_height - header_height - footer_button_height - root_separation * 2.0)
	var portrait_height := maxf(86.0, cards_area_height - select_button_height - order_control_height - 10.0) if is_mobile_landscape else 250.0
	var footer_button_width := clampf(usable_width * 0.34, 160.0, 260.0) if is_mobile_landscape else 160.0
	var reset_button_width := clampf(usable_width * 0.16, 88.0, 130.0) if is_mobile_landscape else 140.0

	_player_order_root.custom_minimum_size = Vector2(root_width, root_height)
	_player_order_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_order_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_player_order_root.add_theme_constant_override("separation", int(root_separation))

	if _player_order_header != null:
		_player_order_header.custom_minimum_size = Vector2(root_width, header_height)
		_player_order_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_player_order_header.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	if _player_order_character_list != null:
		_player_order_character_list.add_theme_constant_override("separation", int(card_gap))
		_player_order_character_list.custom_minimum_size = Vector2(root_width, cards_area_height)
		_player_order_character_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_player_order_character_list.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if _player_order_footer != null:
		_player_order_footer.add_theme_constant_override("separation", 8 if is_mobile_landscape else 10)
		_player_order_footer.custom_minimum_size = Vector2(root_width, footer_button_height)
		_player_order_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_player_order_footer.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	if _player_order_title_label != null:
		_player_order_title_label.add_theme_font_size_override("font_size", 17 if is_mobile_landscape else 22)
	if _player_order_slots_label != null:
		_player_order_slots_label.add_theme_font_size_override("font_size", 12 if is_mobile_landscape else 15)
	if _player_order_back_button != null:
		_player_order_back_button.custom_minimum_size = Vector2(104.0 if is_mobile_landscape else 140.0, 40.0 if is_mobile_landscape else 48.0)
		_player_order_back_button.add_theme_font_size_override("font_size", 12 if is_mobile_landscape else 15)

	for data in player_team:
		var character_id := String(data["character_id"])
		var box := _player_order_card_boxes.get(character_id) as VBoxContainer
		if box != null:
			box.custom_minimum_size = Vector2(card_width, 0.0)
			box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.size_flags_vertical = Control.SIZE_EXPAND_FILL
			box.add_theme_constant_override("separation", 2 if is_mobile_landscape else 4)

		var portrait_rect := _player_order_portrait_rects.get(character_id) as TextureRect
		if portrait_rect != null:
			portrait_rect.custom_minimum_size = Vector2(card_width, portrait_height)
			portrait_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			portrait_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL if is_mobile_landscape else Control.SIZE_EXPAND_FILL
			portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		var button := _player_order_character_buttons.get(character_id) as Button
		if button != null:
			button.custom_minimum_size = Vector2(card_width, select_button_height)
			button.add_theme_font_size_override("font_size", 13 if is_mobile_landscape else 15)

		var controls := _player_order_control_rows.get(character_id) as HBoxContainer
		if controls != null:
			controls.visible = true
			controls.custom_minimum_size = Vector2(card_width, order_control_height)
		var remove_button := _player_order_remove_buttons.get(character_id) as Button
		if remove_button != null:
			remove_button.visible = not is_mobile_landscape
		var up_button := _player_order_up_buttons.get(character_id) as Button
		if up_button != null:
			up_button.custom_minimum_size = Vector2((card_width - 4.0) * 0.5, order_control_height)
			up_button.add_theme_font_size_override("font_size", 11 if is_mobile_landscape else 13)
		var down_button := _player_order_down_buttons.get(character_id) as Button
		if down_button != null:
			down_button.custom_minimum_size = Vector2((card_width - 4.0) * 0.5, order_control_height)
			down_button.add_theme_font_size_override("font_size", 11 if is_mobile_landscape else 13)
		var badge := _player_order_order_badges.get(character_id) as Label
		if badge != null:
			badge.custom_minimum_size = Vector2(30.0, 24.0 if is_mobile_landscape else 28.0)
			badge.add_theme_font_size_override("font_size", 14 if is_mobile_landscape else 16)

	var footer_buttons := [_player_order_confirm_button, _player_order_reset_button]
	for footer_button_variant in footer_buttons:
		var footer_button := footer_button_variant as Button
		if footer_button != null:
			footer_button.custom_minimum_size = Vector2(footer_button_width, footer_button_height)
			footer_button.add_theme_font_size_override("font_size", 13 if is_mobile_landscape else 15)
	if _player_order_reset_button != null:
		_player_order_reset_button.custom_minimum_size = Vector2(reset_button_width, footer_button_height)
	if _player_order_status_label != null:
		_player_order_status_label.add_theme_font_size_override("font_size", 12 if is_mobile_landscape else 14)


func _is_mobile_landscape_viewport(viewport_size: Vector2) -> bool:
	return viewport_size.x > viewport_size.y and viewport_size.y <= 560.0


func _player_order_safe_margin(is_mobile_landscape: bool) -> Vector4:
	if is_mobile_landscape:
		return Vector4(24.0, 14.0, 24.0, 22.0)
	return Vector4(20.0, 16.0, 20.0, 18.0)


func update_player_order_hud() -> void:
	if _player_order_hud_label == null:
		return
	_player_order_hud_label.visible = false
	_player_order_hud_label.text = ""
	return
	if selected_player_order.is_empty():
		_player_order_hud_label.text = ""
		return
	var lines: Array[String] = []
	for index in range(selected_player_order.size()):
		var character_id := selected_player_order[index]
		var definition := _definition_for_player_id(character_id)
		var max_health := int(round(definition.max_health)) if definition != null else 0
		lines.append("%d %s [%s] HP %d  %s" % [
			index + 1,
			_display_name_for_id(character_id),
			_type_for_player_id(character_id),
			max_health,
			_order_status_text(character_id, index),
		])
	_player_order_hud_label.text = "\n".join(lines)


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
	update_player_order_hud()
	_update_debug_flow_label()


func _update_timer_ui() -> void:
	timer_label.visible = false


func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
	_update_hp_bar(player_hp_bar, current_hp, max_hp)
	if current_player_index >= 0 and current_player_index < player_team.size() and not player_team[current_player_index]["is_defeated"]:
		player_team[current_player_index]["current_health"] = clampi(current_hp, 0, max_hp)
	if battle_hud != null and battle_hud.has_method("update_player_hp"):
		battle_hud.update_player_hp(current_hp, max_hp, true)
	if battle_hud != null and battle_hud.has_method("update_team_status"):
		battle_hud.update_team_status(player_team, current_player_index)


func _on_player_special_gauge_changed(current_value: float, max_value: float) -> void:
	if current_player_index >= 0 and current_player_index < player_team.size():
		player_team[current_player_index]["special_gauge"] = clampf(current_value, 0.0, maxf(max_value, 1.0))
	if battle_hud != null and battle_hud.has_method("update_player_special_gauge"):
		battle_hud.update_player_special_gauge(current_value, max_value)


func _on_enemy_hp_changed(current_hp: int, max_hp: int) -> void:
	_update_hp_bar(enemy_hp_bar, current_hp, max_hp)
	if current_enemy_index >= 0 and current_enemy_index < enemy_team.size() and not enemy_team[current_enemy_index]["is_defeated"]:
		enemy_team[current_enemy_index]["current_health"] = clampi(current_hp, 0, max_hp)
	if battle_hud != null and battle_hud.has_method("update_enemy_hp"):
		battle_hud.update_enemy_hp(current_hp, max_hp, true)


func _update_hp_bar(bar: ProgressBar, current_hp: int, max_hp: int) -> void:
	if bar == null:
		return
	bar.max_value = max_hp
	bar.value = current_hp


func _update_win_marks() -> void:
	player_win_marks.visible = false
	enemy_win_marks.visible = false


func _update_progress_ui() -> void:
	if _progress_label == null:
		return
	_progress_label.visible = false
	_progress_label.text = ""
	team_progress_updated.emit(_remaining_count(player_team), _remaining_count(enemy_team))


func _update_debug_flow_label() -> void:
	if _debug_flow_label == null:
		return
	_debug_flow_label.visible = debug_flow_label_enabled
	if not debug_flow_label_enabled:
		return

	_debug_flow_label.text = "\n".join([
		"FLOW STATE: %s" % [BattleState.keys()[flow_state]],
		"CURRENT PLAYER: %s" % [_active_player_id()],
		"CURRENT ENEMY: %s" % [_active_enemy_id()],
		"ENEMY NAME: %s" % [_active_enemy_name()],
		"ENEMY TYPE: %s" % [_active_enemy_type()],
		"ENEMY ORDER: %s" % [_active_enemy_order_text()],
		"RUN ACTIVE: %s" % [str(is_run_active).to_upper()],
		"BATTLE RESULT: %s" % [String(battle_result)],
		"ACTIVE TYPE: %s" % [_type_for_player_id(String(_active_player_id()))],
		"ACTIVE MOVE SPEED: %.1f" % [player.move_speed],
		"ACTIVE AIR SPEED: %.1f" % [player.air_move_speed],
		"ACTIVE MAX HEALTH: %d" % [player.max_hp],
		"ACTIVE PUNCH DAMAGE: %d" % [player.punch_damage],
		"ACTIVE KICK DAMAGE: %d" % [player.kick_damage],
		"ACTIVE GUARD RATE: %.2f" % [player.guard_damage_rate],
		"ENEMY MOVE SPEED: %.1f" % [enemy.move_speed],
		"ENEMY MAX HEALTH: %d" % [enemy.max_hp],
		"ENEMY PUNCH DAMAGE: %d" % [enemy.punch_damage],
		"ENEMY KICK DAMAGE: %d" % [enemy.kick_damage],
		"ENEMY THROW DAMAGE: %d" % [enemy.throw_damage],
		"PLAYER HP: %d" % [player.current_hp],
		"ENEMY HP: %d" % [enemy.current_hp],
		"ALLY REMAINING: %d" % [_remaining_count(player_team)],
		"ENEMY REMAINING: %d" % [_remaining_count(enemy_team)],
		"SELECTED ALLIES: %s" % [_ids_to_text(selected_player_ids)],
		"DEFEATED ALLIES: %s" % [_ids_to_text(defeated_player_ids)],
		"DEFEATED ENEMIES: %s" % [_ids_to_text(defeated_enemy_ids)],
		"RESULT LOCKED: %s" % [str(battle_result_locked).to_upper()],
		"RESOLVING: %s" % [str(is_battle_resolving).to_upper()],
	] + _enemy_ai_debug_lines())


func _show_message(message: String) -> void:
	message_label.text = ""
	message_label.visible = false


func _on_player_hp_depleted() -> void:
	on_fighter_ko(player)


func _on_enemy_hp_depleted() -> void:
	on_fighter_ko(enemy)


func _active_player_name() -> String:
	if current_player_index < 0 or current_player_index >= player_team.size():
		return ""
	return player_team[current_player_index]["display_name"]


func _active_enemy_name() -> String:
	if current_enemy_index < 0 or current_enemy_index >= enemy_team.size():
		return ""
	return enemy_team[current_enemy_index]["display_name"]


func _active_enemy_type() -> String:
	if current_enemy_index < 0 or current_enemy_index >= enemy_team.size():
		return ""
	var definition: Resource = enemy_team[current_enemy_index].get("definition", null)
	if definition == null:
		return ""
	return String(definition.fighter_type)


func _active_enemy_order_text() -> String:
	if current_enemy_index < 0 or current_enemy_index >= enemy_team.size():
		return "- / 8"
	var definition: Resource = enemy_team[current_enemy_index].get("definition", null)
	if definition == null:
		return "%d / 8" % (current_enemy_index + 1)
	return "%d / 8" % int(definition.enemy_order)


func _should_show_enemy_intro() -> bool:
	if current_enemy_index < 0 or current_enemy_index >= enemy_team.size():
		return false
	return _last_intro_enemy_index != current_enemy_index


func _show_enemy_intro(enemy_data: Dictionary) -> void:
	if _enemy_intro_panel == null or _enemy_intro_label == null:
		return
	_enemy_intro_label.text = ""
	_enemy_intro_panel.visible = false
	return
	var definition: Resource = enemy_data.get("definition", null)
	var intro_title := "ENEMY"
	var intro_description := ""
	var enemy_type := ""
	var order_text := "%d / 8" % (current_enemy_index + 1)
	if definition != null:
		intro_title = definition.intro_title
		intro_description = definition.intro_description
		enemy_type = String(definition.fighter_type)
		order_text = "%d / 8" % int(definition.enemy_order)
	_enemy_intro_label.text = "ENEMY %s\n%s\nTYPE: %s\n%s\n%s" % [
		order_text,
		enemy_data["display_name"],
		enemy_type,
		intro_title,
		intro_description,
	]
	_enemy_intro_panel.visible = true


func _enemy_ai_debug_lines() -> Array[String]:
	if enemy == null or not enemy.has_method("get_ai_debug_lines"):
		return []
	return enemy.get_ai_debug_lines()


func _show_end_panel(title: String, body: String) -> void:
	if _end_panel == null:
		return
	_end_title_label.text = title
	_end_body_label.text = body
	_end_panel.visible = true
	_restart_button.grab_focus()


func _hide_end_panel() -> void:
	if _end_panel != null:
		_end_panel.visible = false


func _ids_to_text(ids: Array[StringName]) -> String:
	if ids.is_empty():
		return "NONE"
	var text_ids: Array[String] = []
	for id in ids:
		text_ids.append(String(id))
	return ", ".join(text_ids)
