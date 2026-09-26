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
	preload("res://data/enemies/enemy_04_throw.tres"),
	preload("res://data/enemies/enemy_03_guard.tres"),
	preload("res://data/enemies/enemy_02_speed.tres"),
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
@export_range(0, 8, 1) var active_enemy_count_limit := 0
@export_group("Stage Bounds")
@export var stage_left_limit := 0.0
@export var stage_right_limit := 1280.0
@export var stage_floor_y := 520.0
@export var fighter_body_half_width := 43.0
@export var minimum_fighter_distance := 42.0
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
	_configure_fighter_stage_constraints()
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
	var active_enemy_count := _active_enemy_definition_count()
	if not validate_enemy_definitions(active_enemy_count):
		for index in range(active_enemy_count):
			var fallback_id := StringName("enemy_%02d" % (index + 1))
			enemy_order.append(fallback_id)
			enemy_team.append(_create_progress_entry(
				fallback_id,
				"Enemy %d" % (index + 1),
				index,
				enemy.max_hp
			))
		return

	for index in range(active_enemy_count):
		enemy_order.append(ENEMY_DEFINITIONS[index].fighter_id)
		enemy_team.append(_create_progress_entry_from_definition(ENEMY_DEFINITIONS[index], index))


func _active_enemy_definition_count() -> int:
	if active_enemy_count_limit <= 0:
		return ENEMY_DEFINITIONS.size()
	return clampi(active_enemy_count_limit, 1, ENEMY_DEFINITIONS.size())


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


func validate_enemy_definitions(required_count: int = -1) -> bool:
	var count := ENEMY_DEFINITIONS.size() if required_count < 0 else clampi(required_count, 0, ENEMY_DEFINITIONS.size())
	if count <= 0:
		push_warning("No enemy definitions are enabled for this battle.")
		return false

	var seen_ids := {}
	for index in range(count):
		var definition: Resource = ENEMY_DEFINITIONS[index]
		var expected_order := index + 1
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
	return true


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