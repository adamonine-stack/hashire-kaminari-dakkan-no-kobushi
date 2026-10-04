extends Stage1BattleManager

const TRUE_SEIYA_PATH := "res://data/enemies/enemy_09_seiya.tres"
const TRUE_SEIYA := preload(TRUE_SEIYA_PATH)
const TRUE_STAGE := preload("res://data/stages/stage_09_true_seiya.tres")

func _ready() -> void:
	super._ready()
	if battle_hud != null:
		battle_hud.enemy_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		battle_hud.enemy_panel.offset_left = -454.0
		battle_hud.enemy_panel.offset_right = -24.0
	var heading := Label.new()
	heading.text = "TRUE FINAL BATTLE"
	heading.anchor_left = 0.5
	heading.anchor_right = 0.5
	heading.offset_left = -200
	heading.offset_right = 200
	heading.offset_top = 24
	heading.offset_bottom = 64
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", Color("f8da99"))
	battle_ui_root.add_child(heading)
	get_viewport().size_changed.connect(_queue_true_layout)
	_queue_true_layout()

func refresh_mobile_controls_visibility() -> void:
	super.refresh_mobile_controls_visibility()
	_queue_true_layout()

func _queue_true_layout() -> void:
	call_deferred("_place_true_pause")

func _place_true_pause() -> void:
	if not is_inside_tree(): return
	if mobile_controls == null or mobile_controls.pause_button == null: return
	var button: Button = mobile_controls.pause_button
	button.position = Vector2(get_viewport().get_visible_rect().size.x * 0.5 - button.size.x * 0.5, 76.0)

func initialize_game_progress() -> void:
	super.initialize_game_progress()
	current_enemy_index = 8
	_last_intro_enemy_index = 8
	_update_all_ui()

func initialize_enemy_team() -> void:
	super.initialize_enemy_team()
	for data in enemy_team:
		data["is_defeated"] = true
		data["current_health"] = 0
		defeated_enemy_ids.append(StringName(data["fighter_id"]))
	var true_seiya_progress := _create_progress_entry_from_definition(TRUE_SEIYA, 8)
	# BattleManager now resolves the active enemy through definition_path.
	# Keep the progress row lightweight and let the current-enemy cache own the
	# only runtime Resource reference used by the battle flow/HUD.
	true_seiya_progress["definition"] = null
	true_seiya_progress["definition_path"] = TRUE_SEIYA_PATH
	enemy_team.append(true_seiya_progress)
	enemy_order.append(TRUE_SEIYA.fighter_id)

func reset_player_roster() -> void:
	super.reset_player_roster()
	# Seiya changes sides, he is never selectable against himself.
	player_team.resize(2)
	var snapshot: Array = get_tree().root.get_meta(&"stage8_ending_snapshot", [])
	for data in player_team:
		for saved in snapshot:
			if saved.get("character_id", "") == data["character_id"]:
				data["current_health"] = clampi(int(saved.get("current_health", data["max_health"])), 1, int(data["max_health"]))
				data["special_gauge"] = float(saved.get("special_gauge", 0.0))
	player_roster = player_team

func start_initial_player_selection() -> void:
	if flow_state == BattleState.CLEAR: return
	selected_player_order.assign(["player_01_akky", "player_02_gou"])
	is_player_order_confirmed = true
	select_player_by_id("player_01_akky")

func _stage_definition_for_enemy_index(enemy_index: int) -> Resource:
	return TRUE_STAGE if enemy_index == 8 else super._stage_definition_for_enemy_index(enemy_index)

func _should_show_enemy_intro() -> bool:
	return false

func enter_game_clear() -> void:
	if flow_state == BattleState.CLEAR: return
	_set_battle_state(BattleState.CLEAR)
	isBattleFinished = true
	is_run_active = false
	_set_battle_active(false)
	_hide_player_selection()
	close_player_order_select()
	_clear_active_fighter_actions(player)
	_clear_active_fighter_actions(enemy)
	for fighter in [player, enemy]:
		fighter.input_enabled = false
		fighter.ai_enabled = false
		fighter.is_round_active = false
		if fighter.aura_controller != null: fighter.aura_controller.cancel()
	_hide_end_panel()
	battle_ui_root.hide()
	if mobile_controls != null: mobile_controls.hide()
	set_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	clear_run_save()
	get_node("/root/AudioManager").fade_out()
	var cfg := ConfigFile.new()
	if not FileAccess.file_exists("user://story_progress.cfg") or cfg.load("user://story_progress.cfg") == OK:
		cfg.set_value("story", "true_boss_defeated", true)
		cfg.save("user://story_progress.cfg")
	print("[STAGE8_TRUE_ENDING_V1] TRUE BOSS SEIYA DEFEATED")
	var layer := CanvasLayer.new()
	layer.layer = 100
	get_parent().add_child(layer)
	var fade := ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0,0,0,0)
	layer.add_child(fade)
	await get_tree().create_timer(0.9).timeout
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.9)
	await tween.finished
	if is_inside_tree(): get_tree().change_scene_to_file("res://scenes/TrueEnding.tscn")
