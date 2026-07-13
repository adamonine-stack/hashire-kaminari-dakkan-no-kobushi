extends Control

enum MessagePriority {
	LOW,
	NORMAL,
	HIGH,
	CRITICAL,
}

@export var show_normal_battle_hud := true
@export var show_debug_overlay := false
@export var show_damage_numbers := false
@export var show_battle_messages := false
@export var show_battle_hp_bars := true

var battle_manager: Node
var current_player: Node
var current_enemy: Node
var message_queue: Array[Dictionary] = []
var is_message_showing := false
var current_message_priority := MessagePriority.LOW
var player_display_hp := 0.0
var player_delay_hp := 0.0
var enemy_display_hp := 0.0
var enemy_delay_hp := 0.0
var _hud_tweens: Array[Tween] = []

var player_panel: PanelContainer
var player_icon_rect: TextureRect
var player_name_label: Label
var player_hp_label: Label
var player_hp_bar: ProgressBar
var player_delay_hp_bar: ProgressBar
var player_state_label: Label
var player_special_label: Label
var player_low_hp_label: Label
var team_panel: PanelContainer
var team_labels: Array[Label] = []
var enemy_panel: PanelContainer
var enemy_icon_rect: TextureRect
var enemy_name_label: Label
var enemy_type_label: Label
var enemy_progress_label: Label
var enemy_hp_label: Label
var enemy_hp_bar: ProgressBar
var enemy_delay_hp_bar: ProgressBar
var enemy_low_hp_label: Label
var message_label: Label
var boss_warning_label: Label
var result_panel: PanelContainer
var result_title_label: Label
var result_body_label: Label
var result_retry_button: Button
var result_title_button: Button
var pause_panel: PanelContainer
var pause_continue_button: Button
var pause_how_to_button: Button
var pause_options_button: Button
var pause_restart_button: Button
var pause_title_button: Button
var confirm_panel: PanelContainer
var confirm_label: Label
var confirm_yes_button: Button
var confirm_no_button: Button
var pending_confirm_action := ""
var debug_overlay_label: Label
var floating_layer: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_hud()
	_apply_minimal_battle_text_visibility()
	reset_battle_hud()


func _process(_delta: float) -> void:
	_update_live_state_labels()


func _unhandled_input(event: InputEvent) -> void:
	if confirm_panel != null and confirm_panel.visible and event.is_action_pressed("ui_cancel"):
		_cancel_confirm()
		get_viewport().set_input_as_handled()
	elif pause_panel != null and pause_panel.visible and event.is_action_pressed("ui_cancel"):
		_request_continue()
		get_viewport().set_input_as_handled()


func initialize_hud(manager: Node) -> void:
	battle_manager = manager
	_hide_legacy_battle_labels()
	connect_battle_signals()
	reset_battle_hud()
	if battle_manager != null:
		if battle_manager.has_method("get_battle_hud_snapshot"):
			apply_battle_snapshot(battle_manager.get_battle_hud_snapshot())
		else:
			refresh_from_manager()


func connect_battle_signals() -> void:
	if battle_manager == null:
		return
	_connect_signal_once(battle_manager, "current_player_changed", Callable(self, "_on_current_player_changed"))
	_connect_signal_once(battle_manager, "active_fighter_changed", Callable(self, "_on_active_fighter_changed"))
	_connect_signal_once(battle_manager, "team_progress_updated", Callable(self, "_on_team_progress_updated"))
	_connect_signal_once(battle_manager, "player_defeated", Callable(self, "_on_player_defeated"))
	_connect_signal_once(battle_manager, "battle_started", Callable(self, "_on_battle_started"))
	_connect_signal_once(battle_manager, "battle_finished", Callable(self, "_on_battle_finished"))
	_connect_signal_once(battle_manager, "game_over", Callable(self, "show_game_over"))
	_connect_signal_once(battle_manager, "game_cleared", Callable(self, "show_game_clear"))
	_connect_signal_once(battle_manager, "hud_enemy_spawned", Callable(self, "_on_hud_enemy_spawned"))
	_connect_signal_once(battle_manager, "hud_enemy_defeated", Callable(self, "_on_hud_enemy_defeated"))
	_connect_signal_once(battle_manager, "hud_healing_applied", Callable(self, "_on_hud_healing_applied"))
	_connect_signal_once(battle_manager, "hud_message_requested", Callable(self, "show_battle_message"))
	_connect_signal_once(battle_manager, "hud_retry_started", Callable(self, "_on_hud_retry_started"))


func disconnect_battle_signals() -> void:
	if battle_manager == null:
		return
	for signal_name in [
		"current_player_changed",
		"active_fighter_changed",
		"team_progress_updated",
		"player_defeated",
		"battle_started",
		"battle_finished",
		"game_over",
		"game_cleared",
		"hud_enemy_spawned",
		"hud_enemy_defeated",
		"hud_healing_applied",
		"hud_message_requested",
		"hud_retry_started",
	]:
		var callable := _callable_for_signal(signal_name)
		if battle_manager.is_connected(signal_name, callable):
			battle_manager.disconnect(signal_name, callable)


func show_battle_hud() -> void:
	visible = show_normal_battle_hud


func hide_battle_hud() -> void:
	visible = false


func reset_battle_hud() -> void:
	cancel_all_hud_tweens()
	clear_message_queue()
	_clear_floating_labels()
	show_battle_hud()
	disable_boss_hud()
	hide_boss_warning()
	hide_result_layer()
	hide_pause_menu()
	hide_confirm_dialog()
	message_label.visible = false
	player_state_label.visible = false
	player_special_label.visible = false
	player_special_label.text = ""
	player_low_hp_label.visible = false
	player_name_label.visible = false
	player_name_label.text = ""
	player_hp_label.visible = false
	player_hp_label.text = ""
	enemy_name_label.visible = false
	enemy_name_label.text = ""
	enemy_type_label.visible = false
	enemy_type_label.text = ""
	enemy_progress_label.visible = false
	enemy_progress_label.text = ""
	enemy_hp_label.visible = false
	enemy_hp_label.text = ""
	enemy_low_hp_label.visible = false
	update_player_hp(0, 1, false)
	update_enemy_hp(0, 1, false)
	for label in team_labels:
		label.text = ""
		label.visible = false
	team_panel.visible = false
	debug_overlay_label.visible = show_debug_overlay
	_apply_minimal_battle_text_visibility()


func show_normal_enemy_hud() -> void:
	enemy_panel.custom_minimum_size = Vector2(360.0, 118.0)
	enemy_name_label.text = enemy_name_label.text.replace("BOSS - ", "")


func show_boss_hud() -> void:
	enemy_panel.custom_minimum_size = Vector2(430.0, 136.0)
	boss_warning_label.visible = false
	boss_warning_label.text = ""


func update_player_status(player_node: Node) -> void:
	current_player = player_node
	_connect_fighter_signals(current_player)
	if current_player == null:
		return
	player_name_label.text = ""
	player_name_label.visible = false
	if player_icon_rect != null:
		player_icon_rect.texture = _fighter_icon_from_node(current_player, true)
	update_player_hp(int(current_player.get("current_hp")), int(current_player.get("max_hp")), false)


func update_team_status(team_data: Array, active_index: int = -1) -> void:
	while team_labels.size() < team_data.size():
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 14)
		team_panel.get_node("Margin/VBox").add_child(label)
		team_labels.append(label)

	for index in range(team_labels.size()):
		if index >= team_data.size():
			team_labels[index].visible = false
			continue
		team_labels[index].visible = false
		var data: Dictionary = team_data[index]
		var status := "READY"
		if bool(data.get("is_defeated", false)) or int(data.get("current_health", 0)) <= 0:
			status = "KO"
		elif index == active_index:
			status = "ACTIVE"
		var hp_text := "%d/%d" % [int(data.get("current_health", 0)), int(data.get("max_health", 0))]
		team_labels[index].text = ""
		team_labels[index].modulate = Color(1.0, 0.95, 0.55, 1.0) if status == "ACTIVE" else Color.WHITE
		if status == "KO":
			team_labels[index].modulate = Color(0.8, 0.35, 0.35, 1.0)


func update_enemy_status(enemy_node: Node) -> void:
	current_enemy = enemy_node
	_connect_fighter_signals(current_enemy)
	if current_enemy == null:
		return
	update_enemy_hp(int(current_enemy.get("current_hp")), int(current_enemy.get("max_hp")), false)


func update_enemy_information(enemy_data: Dictionary, enemy_index: int) -> void:
	var enemy_name := String(enemy_data.get("display_name", "ENEMY %d" % (enemy_index + 1)))
	var enemy_type := _enemy_type_label(enemy_data)
	enemy_name_label.text = ""
	enemy_name_label.visible = false
	enemy_type_label.text = ""
	enemy_type_label.visible = false
	if enemy_icon_rect != null:
		enemy_icon_rect.texture = _definition_texture(enemy_data.get("definition", null), "icon", "selection_icon")
	update_enemy_progress(enemy_index + 1, _enemy_total_count())
	if _is_boss_enemy(enemy_data, enemy_index):
		show_boss_hud()
	else:
		hide_boss_warning()
		show_normal_enemy_hud()


func update_enemy_progress(current_index: int, total_count: int) -> void:
	if total_count <= 0:
		total_count = 8
	enemy_progress_label.text = ""
	enemy_progress_label.visible = false


func update_player_hp(current_hp: float, max_hp: float, animate := true) -> void:
	var safe_max := maxf(max_hp, 1.0)
	var safe_current := clampf(current_hp, 0.0, safe_max)
	player_hp_bar.max_value = safe_max
	player_delay_hp_bar.max_value = safe_max
	player_hp_label.text = ""
	player_hp_label.visible = false
	player_hp_bar.visible = show_battle_hp_bars
	player_delay_hp_bar.visible = show_battle_hp_bars
	_update_low_hp_label(player_low_hp_label, safe_current, safe_max)
	_animate_hp_bar(player_hp_bar, player_delay_hp_bar, player_display_hp, player_delay_hp, safe_current, animate)
	player_display_hp = safe_current
	player_delay_hp = safe_current


func update_enemy_hp(current_hp: float, max_hp: float, animate := true) -> void:
	var safe_max := maxf(max_hp, 1.0)
	var safe_current := clampf(current_hp, 0.0, safe_max)
	enemy_hp_bar.max_value = safe_max
	enemy_delay_hp_bar.max_value = safe_max
	enemy_hp_label.text = ""
	enemy_hp_label.visible = false
	enemy_hp_bar.visible = show_battle_hp_bars
	enemy_delay_hp_bar.visible = show_battle_hp_bars
	_update_low_hp_label(enemy_low_hp_label, safe_current, safe_max)
	_animate_hp_bar(enemy_hp_bar, enemy_delay_hp_bar, enemy_display_hp, enemy_delay_hp, safe_current, animate)
	enemy_display_hp = safe_current
	enemy_delay_hp = safe_current


func show_invincibility_state(duration: float = 0.0) -> void:
	player_state_label.text = ""
	player_state_label.visible = false
	if duration > 0.0:
		var tween := create_tween()
		_track_tween(tween)
		tween.tween_interval(duration)
		tween.tween_callback(hide_invincibility_state)


func hide_invincibility_state() -> void:
	if player_state_label.text == "INVINCIBLE":
		player_state_label.visible = false


func show_guard_state(_character: Node = null) -> void:
	player_state_label.text = ""
	player_state_label.visible = false


func hide_guard_state(_character: Node = null) -> void:
	if player_state_label.text == "GUARD":
		player_state_label.visible = false


func show_damage_number(target: Node, damage: int, guarded := false, hit_position := Vector2.ZERO) -> void:
	if not show_damage_numbers:
		return
	var label := Label.new()
	label.text = "GUARD -%d" % damage if guarded else str(damage)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0, 1.0) if guarded else Color(1.0, 0.35, 0.25, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating_layer.add_child(label)
	label.position = _screen_position_for_target(target, hit_position) + Vector2(-28.0, -76.0)
	var tween := create_tween()
	_track_tween(tween)
	tween.tween_property(label, "position:y", label.position.y - 28.0, 0.55)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.55)
	tween.tween_callback(label.queue_free)


func show_heal_number(target: Node, heal_amount: int) -> void:
	if heal_amount <= 0 or not show_damage_numbers:
		return
	var label := Label.new()
	label.text = "HP +%d" % heal_amount
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating_layer.add_child(label)
	label.position = _screen_position_for_target(target, Vector2.ZERO) + Vector2(-44.0, -108.0)
	var tween := create_tween()
	_track_tween(tween)
	tween.tween_property(label, "position:y", label.position.y - 24.0, 0.75)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.75)
	tween.tween_callback(label.queue_free)
	show_battle_message("RECOVER +%d" % heal_amount, MessagePriority.LOW, 0.8)


func show_enemy_intro(enemy_data: Dictionary, enemy_index: int) -> void:
	update_enemy_information(enemy_data, enemy_index)


func show_enemy_defeated(_enemy: Node = null) -> void:
	update_enemy_hp(0, maxf(enemy_hp_bar.max_value, 1.0), true)


func show_fight_message() -> void:
	pass


func enable_boss_hud(enemy_node: Node) -> void:
	current_enemy = enemy_node
	show_boss_hud()


func disable_boss_hud() -> void:
	show_normal_enemy_hud()


func show_special_attack_warning(attack_id: String) -> void:
	boss_warning_label.visible = false
	boss_warning_label.modulate.a = 1.0
	boss_warning_label.text = ""


func show_ultimate_warning() -> void:
	boss_warning_label.visible = false
	boss_warning_label.modulate.a = 1.0
	boss_warning_label.text = ""


func hide_boss_warning(_attack_id: String = "") -> void:
	boss_warning_label.visible = false
	boss_warning_label.text = ""


func show_game_over() -> void:
	hide_boss_warning()
	clear_message_queue()
	result_title_label.text = "GAME OVER"
	result_body_label.text = "All ally fighters defeated.\nRETRY or RETURN TO TITLE."
	result_panel.visible = true
	result_retry_button.text = "RETRY"
	result_retry_button.grab_focus()
	_play_ui_se("defeat")


func show_game_clear() -> void:
	hide_boss_warning()
	clear_message_queue()
	result_title_label.text = "GAME CLEAR"
	result_body_label.text = "All 8 enemies defeated.\nBattle run complete."
	result_panel.visible = true
	result_retry_button.text = "PLAY AGAIN"
	result_retry_button.grab_focus()
	_play_ui_se("clear")


func hide_result_layer() -> void:
	result_panel.visible = false


func show_pause_menu() -> void:
	pause_panel.visible = true
	_play_ui_se("pause")
	pause_continue_button.grab_focus()


func hide_pause_menu() -> void:
	if pause_panel != null:
		pause_panel.visible = false


func show_restart_confirm() -> void:
	_play_ui_se("confirm")
	_show_confirm_dialog("Restart current run?", "restart")


func show_return_title_confirm() -> void:
	_play_ui_se("confirm")
	_show_confirm_dialog("Return to title?", "title")


func hide_confirm_dialog() -> void:
	if confirm_panel != null:
		confirm_panel.visible = false
	pending_confirm_action = ""


func _show_confirm_dialog(message: String, action: String) -> void:
	pending_confirm_action = action
	confirm_label.text = message
	confirm_panel.visible = true
	confirm_yes_button.grab_focus()


func _confirm_current_action() -> void:
	var action := pending_confirm_action
	hide_confirm_dialog()
	if action == "restart":
		_request_restart()
	elif action == "title":
		_request_return_to_title()


func _cancel_confirm() -> void:
	hide_confirm_dialog()
	if pause_panel != null and pause_panel.visible:
		pause_restart_button.grab_focus()


func _request_continue() -> void:
	_play_ui_se("confirm")
	if battle_manager != null and battle_manager.has_method("return_to_battle"):
		battle_manager.return_to_battle()


func _request_restart() -> void:
	_play_ui_se("confirm")
	if battle_manager != null and battle_manager.has_method("restart_current_game"):
		battle_manager.restart_current_game()


func _request_return_to_title() -> void:
	_play_ui_se("confirm")
	if battle_manager != null and battle_manager.has_method("go_to_title"):
		battle_manager.go_to_title()


func _show_pause_how_to_play() -> void:
	_play_ui_se("confirm")


func _show_pause_options_hint() -> void:
	_play_ui_se("confirm")
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null:
		return
	else:
		return


func show_battle_message(message: String, priority: int = MessagePriority.NORMAL, duration: float = 0.8) -> void:
	if not show_battle_messages or message.is_empty():
		return
	var data := {
		"message": message,
		"priority": priority,
		"duration": duration,
	}
	if priority >= MessagePriority.CRITICAL or not is_message_showing or priority >= current_message_priority:
		_display_message(data)
	else:
		enqueue_message(data)


func enqueue_message(data: Dictionary) -> void:
	message_queue.append(data)


func process_message_queue() -> void:
	if is_message_showing or message_queue.is_empty():
		return
	var next_message: Dictionary = message_queue.pop_front()
	_display_message(next_message)


func clear_message_queue() -> void:
	message_queue.clear()
	is_message_showing = false
	current_message_priority = MessagePriority.LOW
	message_label.visible = false


func cancel_all_hud_tweens() -> void:
	for tween in _hud_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_hud_tweens.clear()


func apply_battle_snapshot(snapshot: Dictionary) -> void:
	if snapshot.has("player"):
		update_player_status(snapshot["player"])
	if snapshot.has("enemy"):
		update_enemy_status(snapshot["enemy"])
	if snapshot.has("player_team"):
		update_team_status(snapshot["player_team"], int(snapshot.get("current_player_index", -1)))
	if snapshot.has("enemy_team"):
		var enemy_index := int(snapshot.get("current_enemy_index", 0))
		var enemy_team: Array = snapshot["enemy_team"]
		if enemy_index >= 0 and enemy_index < enemy_team.size():
			update_enemy_information(enemy_team[enemy_index], enemy_index)


func refresh_from_manager() -> void:
	if battle_manager == null:
		return
	var manager_player: Node = battle_manager.get("player")
	var manager_enemy: Node = battle_manager.get("enemy")
	var player_team_data: Array = battle_manager.get("player_team")
	var enemy_team_data: Array = battle_manager.get("enemy_team")
	var player_index := int(battle_manager.get("current_player_index"))
	var enemy_index := int(battle_manager.get("current_enemy_index"))
	if manager_player != null:
		update_player_status(manager_player)
	if manager_enemy != null:
		update_enemy_status(manager_enemy)
	if not player_team_data.is_empty():
		update_team_status(player_team_data, player_index)
	if not enemy_team_data.is_empty() and enemy_index >= 0:
		if enemy_index < enemy_team_data.size():
			update_enemy_information(enemy_team_data[enemy_index], enemy_index)


func _build_hud() -> void:
	player_panel = _make_panel("PlayerStatusPanel", Control.PRESET_TOP_LEFT, Vector2(24.0, 18.0), Vector2(386.0, 132.0))
	var player_box := _make_margin_vbox(player_panel)
	player_icon_rect = _make_icon_rect(player_box)
	player_name_label = _make_label(player_box, "PLAYER", 18)
	player_hp_label = _make_label(player_box, "0 / 0", 15)
	var player_hp_stack := _make_hp_stack(player_box)
	player_delay_hp_bar = player_hp_stack["delay"]
	player_hp_bar = player_hp_stack["front"]
	player_state_label = _make_label(player_box, "INVINCIBLE", 15)
	player_state_label.visible = false
	player_special_label = _make_label(player_box, "SPECIAL --", 14)
	player_special_label.add_theme_color_override("font_color", Color(0.78, 0.88, 1.0, 1.0))
	player_low_hp_label = _make_label(player_box, "DANGER", 14)
	player_low_hp_label.add_theme_color_override("font_color", Color(1.0, 0.22, 0.16, 1.0))
	player_low_hp_label.visible = false

	team_panel = _make_panel("TeamStatusPanel", Control.PRESET_TOP_LEFT, Vector2(24.0, 154.0), Vector2(386.0, 94.0))
	var team_box := _make_margin_vbox(team_panel)
	team_box.name = "VBox"
	for index in range(3):
		var label := _make_label(team_box, "P%d READY" % (index + 1), 14)
		team_labels.append(label)

	enemy_panel = _make_panel("EnemyStatusPanel", Control.PRESET_TOP_RIGHT, Vector2(-410.0, 18.0), Vector2(-24.0, 150.0))
	var enemy_box := _make_margin_vbox(enemy_panel)
	enemy_icon_rect = _make_icon_rect(enemy_box)
	enemy_name_label = _make_label(enemy_box, "ENEMY", 18)
	enemy_type_label = _make_label(enemy_box, "", 14)
	enemy_progress_label = _make_label(enemy_box, "ENEMY 1 / 8", 14)
	enemy_hp_label = _make_label(enemy_box, "0 / 0", 15)
	var enemy_hp_stack := _make_hp_stack(enemy_box)
	enemy_delay_hp_bar = enemy_hp_stack["delay"]
	enemy_hp_bar = enemy_hp_stack["front"]
	enemy_low_hp_label = _make_label(enemy_box, "DANGER", 14)
	enemy_low_hp_label.add_theme_color_override("font_color", Color(1.0, 0.22, 0.16, 1.0))
	enemy_low_hp_label.visible = false

	message_label = Label.new()
	message_label.name = "StateMessageLabel"
	message_label.visible = false
	message_label.set_anchors_preset(Control.PRESET_CENTER)
	message_label.offset_left = -260.0
	message_label.offset_top = -90.0
	message_label.offset_right = 260.0
	message_label.offset_bottom = -24.0
	message_label.add_theme_font_size_override("font_size", 36)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(message_label)

	boss_warning_label = Label.new()
	boss_warning_label.name = "BossWarningLabel"
	boss_warning_label.visible = false
	boss_warning_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_warning_label.offset_left = 420.0
	boss_warning_label.offset_top = 24.0
	boss_warning_label.offset_right = -420.0
	boss_warning_label.offset_bottom = 96.0
	boss_warning_label.add_theme_font_size_override("font_size", 26)
	boss_warning_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.18, 1.0))
	boss_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_warning_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(boss_warning_label)

	result_panel = _make_panel("ResultLayer", Control.PRESET_CENTER, Vector2(-230.0, -130.0), Vector2(230.0, 130.0))
	result_panel.visible = false
	result_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var result_box := _make_margin_vbox(result_panel)
	result_title_label = _make_label(result_box, "GAME OVER", 36)
	result_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_body_label = _make_label(result_box, "RETRY", 18)
	result_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_retry_button = _make_action_button("RETRY")
	result_retry_button.pressed.connect(_request_restart)
	result_box.add_child(result_retry_button)
	result_title_button = _make_action_button("RETURN TO TITLE")
	result_title_button.pressed.connect(_request_return_to_title)
	result_box.add_child(result_title_button)

	pause_panel = _make_panel("PauseMenu", Control.PRESET_CENTER, Vector2(-220.0, -160.0), Vector2(220.0, 160.0))
	pause_panel.visible = false
	pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var pause_box := _make_margin_vbox(pause_panel)
	var pause_title := _make_label(pause_box, "PAUSE", 34)
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_continue_button = _make_action_button("CONTINUE")
	pause_continue_button.pressed.connect(_request_continue)
	pause_box.add_child(pause_continue_button)
	pause_how_to_button = _make_action_button("HOW TO PLAY")
	pause_how_to_button.pressed.connect(_show_pause_how_to_play)
	pause_box.add_child(pause_how_to_button)
	pause_options_button = _make_action_button("OPTIONS")
	pause_options_button.pressed.connect(_show_pause_options_hint)
	pause_box.add_child(pause_options_button)
	pause_restart_button = _make_action_button("RESTART")
	pause_restart_button.pressed.connect(show_restart_confirm)
	pause_box.add_child(pause_restart_button)
	pause_title_button = _make_action_button("RETURN TO TITLE")
	pause_title_button.pressed.connect(show_return_title_confirm)
	pause_box.add_child(pause_title_button)

	confirm_panel = _make_panel("ConfirmDialog", Control.PRESET_CENTER, Vector2(-210.0, -110.0), Vector2(210.0, 110.0))
	confirm_panel.visible = false
	confirm_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var confirm_box := _make_margin_vbox(confirm_panel)
	confirm_label = _make_label(confirm_box, "Are you sure?", 22)
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var confirm_buttons := HBoxContainer.new()
	confirm_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	confirm_buttons.add_theme_constant_override("separation", 12)
	confirm_box.add_child(confirm_buttons)
	confirm_yes_button = _make_action_button("YES")
	confirm_yes_button.pressed.connect(_confirm_current_action)
	confirm_buttons.add_child(confirm_yes_button)
	confirm_no_button = _make_action_button("NO")
	confirm_no_button.pressed.connect(_cancel_confirm)
	confirm_buttons.add_child(confirm_no_button)

	debug_overlay_label = Label.new()
	debug_overlay_label.name = "DebugOverlay"
	debug_overlay_label.visible = show_debug_overlay
	debug_overlay_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	debug_overlay_label.offset_left = -360.0
	debug_overlay_label.offset_top = -180.0
	debug_overlay_label.offset_right = -24.0
	debug_overlay_label.offset_bottom = -24.0
	debug_overlay_label.add_theme_font_size_override("font_size", 13)
	debug_overlay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(debug_overlay_label)

	floating_layer = Control.new()
	floating_layer.name = "FloatingFeedbackLayer"
	floating_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	floating_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floating_layer)


func _make_panel(panel_name: String, preset: int, offset_start: Vector2, offset_end: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(preset)
	panel.offset_left = offset_start.x
	panel.offset_top = offset_start.y
	panel.offset_right = offset_end.x
	panel.offset_bottom = offset_end.y
	add_child(panel)
	return panel


func _make_margin_vbox(panel: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)
	return box


func _make_label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _make_icon_rect(parent: Node) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(48.0, 48.0)
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect


func _make_action_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(240.0, 42.0)
	button.focus_mode = Control.FOCUS_ALL
	button.focus_entered.connect(_play_ui_se.bind("cursor"))
	return button


func _make_hp_stack(parent: Node) -> Dictionary:
	var stack := Control.new()
	stack.custom_minimum_size = Vector2(300.0, 18.0)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(stack)
	var delay_bar := ProgressBar.new()
	delay_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	delay_bar.show_percentage = false
	delay_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(delay_bar)
	var front_bar := ProgressBar.new()
	front_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	front_bar.show_percentage = false
	front_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(front_bar)
	return {
		"delay": delay_bar,
		"front": front_bar,
	}


func _animate_hp_bar(front_bar: ProgressBar, delay_bar: ProgressBar, previous_front: float, previous_delay: float, target_value: float, animate: bool) -> void:
	if not animate:
		front_bar.value = target_value
		delay_bar.value = target_value
		return
	front_bar.value = target_value
	if target_value < previous_front:
		delay_bar.value = previous_delay
		var tween := create_tween()
		_track_tween(tween)
		tween.tween_interval(0.25)
		tween.tween_property(delay_bar, "value", target_value, 0.35)
	else:
		var tween := create_tween()
		_track_tween(tween)
		tween.tween_property(front_bar, "value", target_value, 0.3)
		tween.parallel().tween_property(delay_bar, "value", target_value, 0.3)


func _display_message(data: Dictionary) -> void:
	if not show_battle_messages:
		return
	message_label.visible = false


func _finish_message() -> void:
	message_label.visible = false
	is_message_showing = false
	current_message_priority = MessagePriority.LOW
	process_message_queue()


func _update_live_state_labels() -> void:
	if current_player != null and is_instance_valid(current_player):
		_update_special_status()
		player_state_label.text = ""
		player_state_label.visible = false
	if show_debug_overlay and battle_manager != null:
		debug_overlay_label.visible = true
		debug_overlay_label.text = _debug_text()
	else:
		debug_overlay_label.visible = false


func _update_special_status() -> void:
	if player_special_label == null or current_player == null:
		return
	player_special_label.text = ""
	player_special_label.visible = false
	return
	if not current_player.has_method("has_special_attack") or not bool(current_player.has_special_attack()):
		player_special_label.text = "SPECIAL --"
		player_special_label.modulate = Color(0.7, 0.7, 0.7, 1.0)
		return
	var special_name := "SPECIAL"
	if current_player.has_method("get_special_display_name"):
		special_name = String(current_player.get_special_display_name())
	var cooldown := 0.0
	if current_player.has_method("get_special_cooldown_remaining"):
		cooldown = float(current_player.get_special_cooldown_remaining())
	var ready := cooldown <= 0.05 and (not current_player.has_method("can_start_special_attack") or bool(current_player.can_start_special_attack()))
	if ready:
		player_special_label.text = "%s READY" % special_name
		player_special_label.modulate = Color(0.55, 0.95, 1.0, 1.0)
	else:
		player_special_label.text = "%s %.1f" % [special_name, cooldown]
		player_special_label.modulate = Color(0.45, 0.55, 0.7, 1.0)


func _update_low_hp_label(label: Label, current_hp: float, max_hp: float) -> void:
	if label == null:
		return
	label.visible = false


func _debug_text() -> String:
	if battle_manager == null:
		return ""
	return "\n".join([
		"HUD DEBUG",
		"Player HP: %d" % [int(current_player.get("current_hp")) if current_player != null else 0],
		"Enemy HP: %d" % [int(current_enemy.get("current_hp")) if current_enemy != null else 0],
		"Messages: %d" % [message_queue.size()],
	])


func _connect_fighter_signals(fighter: Node) -> void:
	if fighter == null:
		return
	_connect_signal_once(fighter, "hp_changed", Callable(self, "_on_fighter_hp_changed").bind(fighter))
	_connect_signal_once(fighter, "damage_feedback_requested", Callable(self, "_on_damage_feedback_requested").bind(fighter))
	_connect_signal_once(fighter, "special_attack_started", Callable(self, "_on_special_attack_started"))
	_connect_signal_once(fighter, "special_attack_finished", Callable(self, "_on_special_attack_finished"))
	_connect_signal_once(fighter, "special_attack_interrupted", Callable(self, "_on_special_attack_finished"))
	_connect_signal_once(fighter, "ultimate_requested", Callable(self, "_on_ultimate_requested"))
	_connect_signal_once(fighter, "ultimate_started", Callable(self, "_on_ultimate_started"))
	_connect_signal_once(fighter, "ultimate_interrupted", Callable(self, "_on_ultimate_finished"))
	_connect_signal_once(fighter, "ultimate_finished", Callable(self, "_on_ultimate_finished"))


func _connect_signal_once(source: Object, signal_name: String, callable: Callable) -> void:
	if source == null or not source.has_signal(signal_name):
		return
	if not source.is_connected(signal_name, callable):
		source.connect(signal_name, callable)


func _callable_for_signal(signal_name: String) -> Callable:
	match signal_name:
		"current_player_changed":
			return Callable(self, "_on_current_player_changed")
		"active_fighter_changed":
			return Callable(self, "_on_active_fighter_changed")
		"team_progress_updated":
			return Callable(self, "_on_team_progress_updated")
		"player_defeated":
			return Callable(self, "_on_player_defeated")
		"battle_started":
			return Callable(self, "_on_battle_started")
		"battle_finished":
			return Callable(self, "_on_battle_finished")
		"game_over":
			return Callable(self, "show_game_over")
		"game_cleared":
			return Callable(self, "show_game_clear")
		"hud_enemy_spawned":
			return Callable(self, "_on_hud_enemy_spawned")
		"hud_enemy_defeated":
			return Callable(self, "_on_hud_enemy_defeated")
		"hud_healing_applied":
			return Callable(self, "_on_hud_healing_applied")
		"hud_message_requested":
			return Callable(self, "show_battle_message")
		"hud_retry_started":
			return Callable(self, "_on_hud_retry_started")
	return Callable()


func _on_current_player_changed(new_player: Node) -> void:
	update_player_status(new_player)
	refresh_from_manager()


func _on_active_fighter_changed(_player_id: StringName, _enemy_id: StringName) -> void:
	refresh_from_manager()


func _on_team_progress_updated(_remaining_players: int, _remaining_enemies: int) -> void:
	refresh_from_manager()


func _on_player_defeated(_character_id) -> void:
	refresh_from_manager()


func _on_battle_started(_player_id: StringName, _enemy_id: StringName) -> void:
	refresh_from_manager()


func _on_battle_finished(_result: Dictionary) -> void:
	refresh_from_manager()


func _on_hud_enemy_spawned(enemy_node: Node, enemy_index: int, enemy_data: Dictionary) -> void:
	update_enemy_status(enemy_node)
	update_enemy_information(enemy_data, enemy_index)


func _on_hud_enemy_defeated(enemy_node: Node, _enemy_index: int) -> void:
	show_enemy_defeated(enemy_node)


func _on_hud_healing_applied(target: Node, applied_amount: int) -> void:
	show_heal_number(target, applied_amount)


func _on_hud_retry_started() -> void:
	reset_battle_hud()


func _on_fighter_hp_changed(current_hp: int, max_hp: int, fighter: Node) -> void:
	if fighter == current_player:
		update_player_hp(current_hp, max_hp, true)
	elif fighter == current_enemy:
		update_enemy_hp(current_hp, max_hp, true)


func _on_damage_feedback_requested(target: Node, damage: int, guarded: bool, hit_position: Vector2, _fighter: Node) -> void:
	show_damage_number(target, damage, guarded, hit_position)


func _on_special_attack_started(attack_id: String) -> void:
	show_special_attack_warning(attack_id)


func _on_special_attack_finished(_attack_id: String = "") -> void:
	hide_boss_warning()


func _on_ultimate_requested() -> void:
	show_ultimate_warning()


func _on_ultimate_started() -> void:
	show_ultimate_warning()


func _on_ultimate_finished() -> void:
	hide_boss_warning()


func _clear_floating_labels() -> void:
	for child in floating_layer.get_children():
		child.queue_free()


func _screen_position_for_target(target: Node, fallback_position: Vector2) -> Vector2:
	var world_position := fallback_position
	if world_position == Vector2.ZERO and target is Node2D:
		world_position = target.global_position
	var transform := get_viewport().get_canvas_transform()
	return transform * world_position


func _fighter_display_name_from_node(fighter: Node, fallback: String) -> String:
	if battle_manager != null and fighter == battle_manager.get("player"):
		var player_index := int(battle_manager.get("current_player_index"))
		var team: Array = battle_manager.get("player_team")
		if player_index >= 0 and player_index < team.size():
			return String(team[player_index].get("display_name", fallback))
	if battle_manager != null and fighter == battle_manager.get("enemy"):
		var enemy_index := int(battle_manager.get("current_enemy_index"))
		var team: Array = battle_manager.get("enemy_team")
		if enemy_index >= 0 and enemy_index < team.size():
			return String(team[enemy_index].get("display_name", fallback))
	return fallback


func _fighter_icon_from_node(fighter: Node, is_player: bool) -> Texture2D:
	if battle_manager == null or fighter == null:
		return null
	var index_property := "current_player_index" if is_player else "current_enemy_index"
	var team_property := "player_team" if is_player else "enemy_team"
	var fighter_index := int(battle_manager.get(index_property))
	var team: Array = battle_manager.get(team_property)
	if fighter_index < 0 or fighter_index >= team.size():
		return null
	return _definition_texture(team[fighter_index].get("definition", null), "icon", "selection_icon")


func _definition_texture(definition: Resource, primary_property: String, fallback_property: String) -> Texture2D:
	if definition == null:
		return null
	var texture: Texture2D = definition.get(primary_property)
	if texture == null:
		texture = definition.get(fallback_property)
	return texture


func _enemy_type_label(enemy_data: Dictionary) -> String:
	var type_id := String(enemy_data.get("fighter_type", "")).to_lower()
	match type_id:
		"standard":
			return "Aggressive Type"
		"speed":
			return "Speed Type"
		"guard":
			return "Guard Type"
		"throw":
			return "Throw Type"
		"power":
			return "Power Type"
		"combo":
			return "Combo Type"
		"tricky":
			return "Tricky Type"
		"boss":
			return "Boss Type"
	return type_id.to_upper()


func _special_warning_text(attack_id: String) -> String:
	match attack_id:
		"enemy8_charge_attack":
			return "CHARGE"
		"enemy8_spin_kick":
			return "SPIN ATTACK"
		"enemy8_ultimate_shockwave":
			return "DANGER\nULTIMATE ATTACK"
	return "SPECIAL"


func _is_boss_enemy(enemy_data: Dictionary, enemy_index: int) -> bool:
	if enemy_index >= 7:
		return true
	return String(enemy_data.get("fighter_type", "")).to_lower() == "boss"


func _enemy_total_count() -> int:
	if battle_manager != null:
		var enemy_team_data: Array = battle_manager.get("enemy_team")
		return maxi(1, enemy_team_data.size())
	return 8


func _hide_legacy_battle_labels() -> void:
	if get_parent() == null:
		return
	for node_name in ["PlayerHpBar", "EnemyHpBar", "TimerLabel", "PlayerWinMarks", "EnemyWinMarks", "KOLabel", "ProgressLabel", "PlayerOrderHudLabel"]:
		var node := get_parent().get_node_or_null(node_name)
		if node is CanvasItem:
			node.visible = false


func _apply_minimal_battle_text_visibility() -> void:
	var hidden_labels := [
		player_name_label,
		player_hp_label,
		player_state_label,
		player_special_label,
		player_low_hp_label,
		enemy_name_label,
		enemy_type_label,
		enemy_progress_label,
		enemy_hp_label,
		enemy_low_hp_label,
		message_label,
		boss_warning_label,
		debug_overlay_label,
	]
	for label in hidden_labels:
		if label != null:
			label.text = ""
			label.visible = false
	if team_panel != null:
		team_panel.visible = false
	if show_battle_hp_bars:
		if player_hp_bar != null:
			player_hp_bar.visible = true
		if player_delay_hp_bar != null:
			player_delay_hp_bar.visible = true
		if enemy_hp_bar != null:
			enemy_hp_bar.visible = true
		if enemy_delay_hp_bar != null:
			enemy_delay_hp_bar.visible = true


func _track_tween(tween: Tween) -> void:
	_hud_tweens.append(tween)


func _play_ui_se(se_id: String) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play_ui_se"):
		audio.call("play_ui_se", se_id)
