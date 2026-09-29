extends Button
class_name FighterCard

signal card_focused(player_index: int)
signal card_confirmed(player_index: int)

var player_index := -1
var progress_data: Dictionary = {}


func _ready() -> void:
	focus_entered.connect(_emit_focus)
	mouse_entered.connect(grab_focus)
	pressed.connect(_emit_confirmed)
	custom_minimum_size = Vector2(230.0, 170.0)
	_apply_card_style()


func _apply_card_style() -> void:
	add_theme_font_size_override("font_size", 18)
	add_theme_constant_override("outline_size", 2)
	add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.82))
	add_theme_color_override("font_color", Color(0.94, 0.95, 0.98, 1.0))
	add_theme_color_override("font_hover_color", Color(1.0, 0.84, 0.38, 1.0))
	add_theme_color_override("font_focus_color", Color(1.0, 0.90, 0.54, 1.0))
	add_theme_stylebox_override("normal", _card_box(Color(0.025, 0.032, 0.052, 0.98), Color(0.39, 0.43, 0.53, 0.96), 5))
	add_theme_stylebox_override("hover", _card_box(Color(0.065, 0.055, 0.05, 1.0), Color(1.0, 0.67, 0.16, 1.0), 5))
	add_theme_stylebox_override("pressed", _card_box(Color(0.015, 0.02, 0.032, 1.0), Color(1.0, 0.72, 0.18, 1.0), 2))
	add_theme_stylebox_override("focus", _card_box(Color(0.075, 0.06, 0.042, 1.0), Color(1.0, 0.94, 0.64, 1.0), 5))
	add_theme_stylebox_override("disabled", _card_box(Color(0.024, 0.026, 0.032, 0.80), Color(0.18, 0.19, 0.22, 0.75), 3))


func _card_box(background: Color, border: Color, bottom_depth: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.border_width_left = 3
	box.border_width_top = 3
	box.border_width_right = 3
	box.border_width_bottom = bottom_depth
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	box.corner_radius_bottom_left = 8
	box.corner_radius_bottom_right = 8
	box.content_margin_left = 14.0
	box.content_margin_top = 10.0
	box.content_margin_right = 14.0
	box.content_margin_bottom = 12.0
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.62)
	box.shadow_size = 5
	box.shadow_offset = Vector2(0.0, 4.0 if bottom_depth >= 4 else 2.0)
	return box


func setup(index: int, data: Dictionary) -> void:
	player_index = index
	progress_data = data
	var definition: Resource = data["definition"]
	var defeated := bool(data["is_defeated"])
	var available := bool(data.get("is_available", true))
	var current_health := int(data["current_health"])
	var max_health := int(data["max_health"])
	var status := "DEFEATED" if defeated or not available else "AVAILABLE"

	text = "%s\n%s\nHP %d / %d\n%s" % [
		definition.display_name,
		String(definition.fighter_type).to_upper(),
		current_health,
		max_health,
		status,
	]
	icon = _definition_texture(definition, "icon", "selection_icon")
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	disabled = defeated or not available or current_health <= 0
	focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	modulate = Color(0.45, 0.45, 0.45, 0.8) if disabled else Color.WHITE


func _emit_focus() -> void:
	if disabled:
		return
	card_focused.emit(player_index)


func _emit_confirmed() -> void:
	if disabled:
		return
	card_confirmed.emit(player_index)


func _definition_texture(definition: Resource, primary_property: String, fallback_property: String) -> Texture2D:
	if definition == null:
		return null
	var texture: Texture2D = definition.get(primary_property)
	if texture == null:
		texture = definition.get(fallback_property)
	return texture
