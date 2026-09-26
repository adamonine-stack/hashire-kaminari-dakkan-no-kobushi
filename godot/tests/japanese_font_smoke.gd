extends SceneTree

const FONT_PATH := "res://assets/fonts/NotoSansJP-Regular.otf"
const REQUIRED_TEXT := "鉄塊の門 最初の壁を突破し、奪還への道を開け。 アッキー クラッシャー 翼の舞踏家 闘 防御 攻撃 必殺"

func _initialize() -> void:
	var failures: Array[String] = []

	if not ResourceLoader.exists(FONT_PATH):
		failures.append("font resource is missing: %s" % FONT_PATH)
	else:
		var font := load(FONT_PATH) as Font
		if font == null:
			failures.append("font resource could not be loaded")
		else:
			for character in REQUIRED_TEXT:
				if character == " ":
					continue
				var codepoint := character.unicode_at(0)
				if not font.has_char(codepoint):
					failures.append("missing glyph U+%04X (%s)" % [codepoint, character])

	if failures.is_empty():
		print("JAPANESE_FONT_OK")
		quit(0)
		return

	for failure in failures:
		push_error("[JAPANESE_FONT] %s" % failure)
	print("JAPANESE_FONT_FAILURES=%s" % failures)
	quit(1)
