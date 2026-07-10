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
	custom_minimum_size = Vector2(220.0, 160.0)


func setup(index: int, data: Dictionary) -> void:
	player_index = index
	progress_data = data
	var definition: Resource = data["definition"]
	var defeated := bool(data["is_defeated"])
	var current_health := int(data["current_health"])
	var max_health := int(definition.max_health)
	var status := "DEFEATED" if defeated else "AVAILABLE"

	text = "%s\n%s\nHP %d / %d\n%s" % [
		definition.display_name,
		String(definition.fighter_type).to_upper(),
		current_health,
		max_health,
		status,
	]
	disabled = defeated or current_health <= 0
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
