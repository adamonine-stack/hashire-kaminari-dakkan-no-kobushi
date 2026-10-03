extends SceneTree

const FONT_PATH := "res://assets/fonts/NotoSansJP-Regular.otf"
const REQUIRED_TEXT := "走れカミナリ 奪還の拳 企画・構成 蒼大 ディレクター 音楽 クリエイター スタート 鉄塊の門 最初の壁を突破し、奪還への道を開け。 アッキー クラッシャー 翼の舞踏家 闘 防御 攻撃 必殺"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	if ProjectSettings.get_setting("gui/theme/custom_font", "") != FONT_PATH:
		failures.append("gui/theme/custom_font must be %s" % FONT_PATH)

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

	# Exercise the same theme resolution used by dynamically created UI controls.
	var panel := Panel.new()
	root.add_child(panel)
	var label := Label.new()
	label.text = "走れカミナリ 奪還の拳"
	panel.add_child(label)
	_check_glyphs(label.get_theme_font("font"), label.text + " " + REQUIRED_TEXT, "Label", failures)
	var button := Button.new()
	button.text = "スタート"
	panel.add_child(button)
	_check_glyphs(button.get_theme_font("font"), button.text + " " + REQUIRED_TEXT, "Button", failures)
	var rich_text := RichTextLabel.new()
	rich_text.text = REQUIRED_TEXT
	panel.add_child(rich_text)
	_check_glyphs(rich_text.get_theme_font("normal_font"), rich_text.text, "RichTextLabel", failures)
	panel.free()

	if failures.is_empty():
		print("JAPANESE_FONT_OK")
		quit(0)
		return

	for failure in failures:
		push_error("[JAPANESE_FONT] %s" % failure)
	print("JAPANESE_FONT_FAILURES=%s" % failures)
	quit(1)

func _check_glyphs(font: Font, text: String, control_name: String, failures: Array[String]) -> void:
	if font == null:
		failures.append("%s resolved no theme font" % control_name)
		return
	for character in text:
		if character != " " and not font.has_char(character.unicode_at(0)):
			failures.append("%s theme font missing glyph U+%04X (%s)" % [control_name, character.unicode_at(0), character])
