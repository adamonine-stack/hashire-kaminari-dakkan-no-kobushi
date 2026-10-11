extends RefCounted

# All endings use the same staff list and positioning.
const CREDIT_TEXT_PATH := "res://data/story/credits.txt"
const NORMAL_SCROLL_SECONDS := 38.0
# In the true ending the theme still plays to completion, but the roll moves
# roughly 28% faster and the final card holds for the remaining music.
const TRUE_SONG_REMAINING_SHARE := 0.78

static func make_roll(parent: Control) -> Label:
	var roll := Label.new()
	roll.text = FileAccess.get_file_as_string(CREDIT_TEXT_PATH)
	roll.position = Vector2(180, 735)
	roll.size = Vector2(920, 1100)
	roll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	roll.add_theme_font_size_override("font_size", 29)
	roll.add_theme_color_override("font_outline_color", Color("080c18"))
	roll.add_theme_constant_override("outline_size", 3)
	roll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	roll.z_index = 12
	parent.add_child(roll)
	return roll

static func offscreen_y(roll: Label) -> float:
	# Every credit line must leave the top of the viewport.
	return -maxf(1150.0, roll.get_combined_minimum_size().y + 50.0)
