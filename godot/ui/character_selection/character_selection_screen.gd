extends Control
class_name CharacterSelectionScreen

signal fighter_focused(player_index: int)
signal fighter_selected(player_index: int)
signal selection_opened()
signal selection_closed()

const CARD_SCENE := preload("res://ui/character_selection/fighter_card.tscn")

var is_open := false
var selection_locked := false
var selection_reason := "GAME_START"
var focused_index := -1
var progress_team: Array[Dictionary] = []
var cards: Array[Button] = []

var title_label: Label
var cards_container: HBoxContainer
var details_label: Label
var stats_label: Label
var confirm_button: Button
var guide_label: Label
var debug_label: Label


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_layout()


func open_selection(team_data: Array[Dictionary], reason := "GAME_START") -> void:
	progress_team = team_data
	selection_reason = reason
	selection_locked = false
	is_open = true
	visible = true
	_update_title_for_reason()
	_refresh_cards()
	_focus_first_available()
	selection_opened.emit()


func close_selection() -> void:
	is_open = false
	visible = false
	selection_closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open or selection_locked:
		return
	if event.is_action_pressed("ui_left"):
		_move_focus(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_move_focus(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		confirm_selection()
		get_viewport().set_input_as_handled()


func confirm_selection() -> void:
	if selection_locked or not _is_selectable(focused_index):
		return
	selection_locked = true
	fighter_selected.emit(focused_index)


func focus_fighter(player_index: int) -> void:
	if not _is_selectable(player_index):
		return
	focused_index = player_index
	if player_index < cards.size():
		cards[player_index].grab_focus()
	_update_details()
	fighter_focused.emit(player_index)


func _build_layout() -> void:
	var background := ColorRect.new()
	background.color = Color(0.05, 0.06, 0.08, 0.92)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 48.0
	root.offset_top = 36.0
	root.offset_right = -48.0
	root.offset_bottom = -32.0
	root.add_theme_constant_override("separation", 18)
	add_child(root)

	title_label = Label.new()
	title_label.text = "SELECT FIGHTER"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	root.add_child(title_label)

	cards_container = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 18)
	root.add_child(cards_container)

	var detail_panel := PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(0.0, 190.0)
	root.add_child(detail_panel)

	var details_box := HBoxContainer.new()
	details_box.add_theme_constant_override("separation", 24)
	detail_panel.add_child(details_box)

	var portrait := ColorRect.new()
	portrait.custom_minimum_size = Vector2(140.0, 160.0)
	portrait.color = Color(0.18, 0.24, 0.32, 1.0)
	details_box.add_child(portrait)

	details_label = Label.new()
	details_label.custom_minimum_size = Vector2(430.0, 150.0)
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_box.add_child(details_label)

	stats_label = Label.new()
	stats_label.custom_minimum_size = Vector2(260.0, 150.0)
	stats_label.add_theme_font_size_override("font_size", 16)
	details_box.add_child(stats_label)

	confirm_button = Button.new()
	confirm_button.text = "CONFIRM"
	confirm_button.custom_minimum_size = Vector2(240.0, 46.0)
	confirm_button.pressed.connect(confirm_selection)
	root.add_child(confirm_button)

	guide_label = Label.new()
	guide_label.text = "Left / Right: Select    Enter: Confirm"
	guide_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(guide_label)

	debug_label = Label.new()
	debug_label.add_theme_font_size_override("font_size", 13)
	root.add_child(debug_label)


func _update_title_for_reason() -> void:
	if title_label == null:
		return
	if selection_reason == "PLAYER_DEFEATED":
		title_label.text = "SELECT NEXT FIGHTER"
		guide_label.text = "Defeated fighters cannot be selected"
	else:
		title_label.text = "SELECT FIRST FIGHTER"
		guide_label.text = "Left / Right: Select    Enter: Confirm"


func _refresh_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()
	cards.clear()

	for index in range(progress_team.size()):
		var card := CARD_SCENE.instantiate()
		cards_container.add_child(card)
		cards.append(card)
		card.setup(index, progress_team[index])
		card.card_focused.connect(focus_fighter)
		card.card_confirmed.connect(_confirm_from_card)


func _focus_first_available() -> void:
	for index in range(progress_team.size()):
		if _is_selectable(index):
			focus_fighter(index)
			return
	focused_index = -1
	_update_details()


func _move_focus(direction: int) -> void:
	if progress_team.is_empty():
		return

	var index := focused_index
	for step in range(progress_team.size()):
		index = wrapi(index + direction, 0, progress_team.size())
		if _is_selectable(index):
			focus_fighter(index)
			return


func _confirm_from_card(player_index: int) -> void:
	focus_fighter(player_index)
	confirm_selection()


func _is_selectable(player_index: int) -> bool:
	if player_index < 0 or player_index >= progress_team.size():
		return false
	var data := progress_team[player_index]
	return bool(data.get("is_available", true)) and not data["is_defeated"] and data["current_health"] > 0


func _update_details() -> void:
	if focused_index < 0 or focused_index >= progress_team.size():
		details_label.text = "No selectable fighter."
		stats_label.text = ""
		confirm_button.disabled = true
		_update_debug()
		return

	var data := progress_team[focused_index]
	var definition: Resource = data["definition"]
	var status := "DEFEATED / UNAVAILABLE" if not bool(data.get("is_available", true)) or data["is_defeated"] else "AVAILABLE"
	details_label.text = "%s\nTYPE: %s\nHP %d / %d\n%s\n\n%s" % [
		definition.display_name,
		String(definition.fighter_type).to_upper(),
		int(data["current_health"]),
		int(definition.max_health),
		status,
		definition.description,
	]
	stats_label.text = "\n".join([
		"POWER  %s" % _rating_text(definition.power_rating),
		"SPEED  %s" % _rating_text(definition.speed_rating),
		"HEALTH %s" % _rating_text(definition.health_rating),
		"THROW  %s" % _rating_text(definition.throw_rating),
		"COMBO  %s" % _rating_text(definition.combo_rating),
	])
	confirm_button.disabled = not _is_selectable(focused_index)
	_update_debug()


func _rating_text(value: int) -> String:
	return "#".repeat(clampi(value, 1, 5)) + "-".repeat(5 - clampi(value, 1, 5))


func _update_debug() -> void:
	var selectable_count := 0
	for index in range(progress_team.size()):
		if _is_selectable(index):
			selectable_count += 1

	var focused_id := &""
	if focused_index >= 0 and focused_index < progress_team.size():
		focused_id = progress_team[focused_index]["definition"].fighter_id

	debug_label.text = "\n".join([
		"SELECTION REASON: %s" % selection_reason,
		"FOCUSED FIGHTER: %s" % focused_id,
		"SELECTION LOCKED: %s" % str(selection_locked).to_upper(),
		"SELECTABLE FIGHTERS: %d" % selectable_count,
	])
