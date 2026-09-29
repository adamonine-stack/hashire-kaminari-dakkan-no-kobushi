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
var portrait_texture_rect: TextureRect
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

	portrait_texture_rect = TextureRect.new()
	portrait_texture_rect.custom_minimum_size = Vector2(140.0, 160.0)
	portrait_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	details_box.add_child(portrait_texture_rect)

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
	confirm_button.custom_minimum_size = Vector2(280.0, 56.0)
	confirm_button.pressed.connect(confirm_selection)
	_style_selection_button(confirm_button, true)
	root.add_child(confirm_button)

	guide_label = Label.new()
	guide_label.text = "Left / Right: Select    Enter: Confirm"
	guide_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(guide_label)

	debug_label = Label.new()
	debug_label.add_theme_font_size_override("font_size", 13)
	root.add_child(debug_label)


func _style_selection_button(button: Button, primary: bool = false) -> void:
	button.add_theme_font_size_override("font_size", 20 if primary else 17)
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.78))
	button.add_theme_color_override("font_color", Color(0.10, 0.055, 0.01, 1.0) if primary else Color(0.96, 0.97, 1.0, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.04, 0.025, 0.01, 1.0) if primary else Color(1.0, 0.84, 0.38, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.04, 0.025, 0.01, 1.0) if primary else Color(1.0, 0.76, 0.24, 1.0))
	button.add_theme_stylebox_override("normal", _selection_button_box(
		Color(0.94, 0.58, 0.08, 0.98) if primary else Color(0.026, 0.034, 0.055, 0.98),
		Color(1.0, 0.84, 0.34, 1.0) if primary else Color(0.43, 0.47, 0.58, 0.96),
		5
	))
	button.add_theme_stylebox_override("hover", _selection_button_box(
		Color(1.0, 0.72, 0.18, 1.0) if primary else Color(0.07, 0.06, 0.055, 1.0),
		Color(1.0, 0.95, 0.66, 1.0) if primary else Color(1.0, 0.68, 0.18, 1.0),
		5
	))
	button.add_theme_stylebox_override("pressed", _selection_button_box(
		Color(0.76, 0.40, 0.04, 1.0) if primary else Color(0.016, 0.021, 0.034, 1.0),
		Color(1.0, 0.74, 0.20, 1.0),
		2
	))
	button.add_theme_stylebox_override("focus", _selection_button_box(
		Color(1.0, 0.69, 0.14, 1.0) if primary else Color(0.075, 0.06, 0.045, 1.0),
		Color(1.0, 0.96, 0.72, 1.0),
		5
	))
	button.add_theme_stylebox_override("disabled", _selection_button_box(
		Color(0.025, 0.03, 0.04, 0.82),
		Color(0.22, 0.23, 0.28, 0.74),
		3
	))


func _selection_button_box(background: Color, border: Color, bottom_depth: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.border_width_left = 3
	box.border_width_top = 3
	box.border_width_right = 3
	box.border_width_bottom = bottom_depth
	box.corner_radius_top_left = 7
	box.corner_radius_top_right = 7
	box.corner_radius_bottom_left = 7
	box.corner_radius_bottom_right = 7
	box.content_margin_left = 18.0
	box.content_margin_top = 9.0
	box.content_margin_right = 18.0
	box.content_margin_bottom = 10.0
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.62)
	box.shadow_size = 5
	box.shadow_offset = Vector2(0.0, 4.0 if bottom_depth >= 4 else 2.0)
	return box


func _update_title_for_reason() -> void:
	if title_label == null:
		return
	match selection_reason:
		"PLAYER_DEFEATED":
			title_label.text = "SELECT NEXT FIGHTER"
			guide_label.text = "K.O. fighters cannot return in this run"
		"NEXT_STAGE":
			title_label.text = "SELECT FIGHTER FOR NEXT STAGE"
			guide_label.text = "Fighters who sat out recover 20% of their maximum HP"
		"CONTINUE":
			title_label.text = "CONTINUE — SELECT FIGHTER"
			guide_label.text = "Resume from the last checkpoint"
		_:
			title_label.text = "SELECT FIGHTER"
			guide_label.text = "Choose one of the three fighters for this stage"


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
		if portrait_texture_rect != null:
			portrait_texture_rect.texture = null
		confirm_button.disabled = true
		_update_debug()
		return

	var data := progress_team[focused_index]
	var definition: Resource = data["definition"]
	if portrait_texture_rect != null:
		portrait_texture_rect.texture = _definition_texture(definition, "portrait", "selection_portrait")
	var status := "DEFEATED / UNAVAILABLE" if not bool(data.get("is_available", true)) or data["is_defeated"] else "AVAILABLE"
	details_label.text = "%s\nTYPE: %s\nHP %d / %d\n%s\n\n%s" % [
		definition.display_name,
		String(definition.fighter_type).to_upper(),
		int(data["current_health"]),
		int(data["max_health"]),
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


func _definition_texture(definition: Resource, primary_property: String, fallback_property: String) -> Texture2D:
	if definition == null:
		return null
	var texture: Texture2D = definition.get(primary_property)
	if texture == null:
		texture = definition.get(fallback_property)
	return texture


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
