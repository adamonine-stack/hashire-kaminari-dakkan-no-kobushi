extends Node

const JAPANESE_FONT_PATH := "res://assets/fonts/NotoSansJP-Regular.otf"

func _enter_tree() -> void:
	_apply_japanese_ui_font()

func _apply_japanese_ui_font() -> void:
	if not ResourceLoader.exists(JAPANESE_FONT_PATH):
		push_warning("[FONT] Japanese UI font is missing: %s" % JAPANESE_FONT_PATH)
		return

	var font := load(JAPANESE_FONT_PATH) as Font
	if font == null:
		push_error("[FONT] Failed to load Japanese UI font: %s" % JAPANESE_FONT_PATH)
		return

	ThemeDB.fallback_font = font

	var project_theme := ThemeDB.get_project_theme()
	if project_theme != null:
		project_theme.default_font = font

	print("[FONT] Japanese UI font active: %s" % font.get_font_name())
