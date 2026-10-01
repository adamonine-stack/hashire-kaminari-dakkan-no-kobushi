extends Control

const BATTLE_SCENE := "res://scenes/Battle.tscn"
const TITLE_SCENE := "res://scenes/Title.tscn"
const PORTRAITS := {
	"アッキー": "res://assets/characters/player01/portrait.png",
	"ごう": "res://assets/characters/player02/portrait.png",
	"せいや": "res://assets/characters/player03/portrait.png",
}

var flow: Node
var lines: Array = []
var line_index := 0
var opening := false
var advancing := false
var name_label: Label
var dialogue_label: Label
var proceed_button: Button
var skip_button: Button
var mark_label: Label
var character_sprites: Array[TextureRect] = []
var mystery: Control

func _ready() -> void:
	flow = get_node("/root/StoryFlow")
	opening = not (flow.get("opening_lines") as Array).is_empty()
	if opening:
		lines = flow.get("opening_lines")
	else:
		lines = flow.get("ending_lines")
	_build()
	_show_line()
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		if opening: audio.call("play_bgm", "title")
		else: audio.call("stop_bgm")

func _unhandled_input(event: InputEvent) -> void:
	if advancing: return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("attack"):
		_advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and opening:
		_skip()
		get_viewport().set_input_as_handled()

func _build() -> void:
	var background := ColorRect.new()
	background.color = Color("10121d") if opening else Color("101825")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	for i in range(12):
		var building := ColorRect.new()
		building.color = Color("1b1c29") if opening else Color("182130")
		building.position = Vector2(i * 115, 155 + (i % 4) * 26)
		building.size = Vector2(72, 390 - (i % 4) * 25)
		add_child(building)
	var title := Label.new()
	title.text = "夜・街" if opening else "ブラックスパロウ基地・地下区画"
	title.position = Vector2(42, 36)
	title.add_theme_font_size_override("font_size", 22)
	add_child(title)
	for i in range(3):
		var portrait := TextureRect.new()
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.position = Vector2(210 + i * 290, 145)
		portrait.size = Vector2(210, 300)
		portrait.modulate = Color(0.55, 0.63, 0.80) if i != 1 else Color(0.80, 0.67, 0.48)
		var path := "res://assets/characters/player%02d/portrait.png" % (i + 1)
		if ResourceLoader.exists(path): portrait.texture = load(path)
		add_child(portrait)
		character_sprites.append(portrait)
	var box := PanelContainer.new()
	box.anchor_left = 0.06
	box.anchor_right = 0.94
	box.anchor_top = 0.70
	box.anchor_bottom = 0.97
	add_child(box)
	var layout := VBoxContainer.new()
	box.add_child(layout)
	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 22)
	layout.add_child(name_label)
	dialogue_label = Label.new()
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 26)
	dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(dialogue_label)
	proceed_button = Button.new()
	proceed_button.text = "進む  [決定 / タップ]"
	proceed_button.custom_minimum_size = Vector2(210, 46)
	proceed_button.anchor_left = 0.70
	proceed_button.anchor_right = 0.94
	proceed_button.anchor_top = 0.63
	proceed_button.anchor_bottom = 0.69
	proceed_button.pressed.connect(_advance)
	add_child(proceed_button)
	if opening:
		skip_button = Button.new()
		skip_button.text = "スキップ"
		skip_button.anchor_left = 0.82
		skip_button.anchor_right = 0.96
		skip_button.anchor_top = 0.03
		skip_button.anchor_bottom = 0.10
		skip_button.pressed.connect(_skip)
		add_child(skip_button)
	else:
		mystery = Control.new()
		mystery.position = Vector2(1030, 180)
		mystery.size = Vector2(130, 280)
		mystery.visible = false
		add_child(mystery)
		var body := ColorRect.new()
		body.color = Color(0.005, 0.005, 0.01, 0.92)
		body.position = Vector2(28, 60)
		body.size = Vector2(74, 210)
		mystery.add_child(body)
		var head := ColorRect.new()
		head.color = Color(0.0, 0.0, 0.0, 0.98)
		head.position = Vector2(35, 20)
		head.size = Vector2(60, 65)
		mystery.add_child(head)

func _show_line() -> void:
	if line_index >= lines.size():
		_finish()
		return
	var entry: Dictionary = lines[line_index]
	name_label.text = String(entry.get("speaker", ""))
	name_label.visible = not name_label.text.is_empty()
	dialogue_label.text = String(entry.get("text", ""))
	mark_label = null
	if entry.get("mark", false):
		var mark := Label.new()
		mark.text = "BLACK SPARROW"
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.position = Vector2(420, 250)
		mark.size = Vector2(450, 90)
		mark.add_theme_font_size_override("font_size", 48)
		mark.add_theme_color_override("font_color", Color("c73a42"))
		add_child(mark)
		mark_label = mark
	if mystery != null:
		var show_mystery := bool(entry.get("silhouette", false))
		if show_mystery and not mystery.visible:
			var audio := get_node_or_null("/root/AudioManager")
			if audio != null: audio.call("play_se", "mystery_footstep")
		mystery.visible = show_mystery
	if not opening:
		for i in range(character_sprites.size()):
			var hero_id: String = ["player_01_akky", "player_02_gou", "player_03_seiya"][i]
			character_sprites[i].visible = flow.get("survivors").has(hero_id)

func _advance() -> void:
	if advancing: return
	if mark_label != null:
		mark_label.queue_free()
		mark_label = null
	line_index += 1
	_show_line()

func _skip() -> void:
	if advancing: return
	line_index = lines.size()
	_show_line()

func _finish() -> void:
	if advancing: return
	advancing = true
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	var tween := create_tween()
	tween.tween_property(fade, "color", Color.BLACK, 0.45)
	await tween.finished
	if not opening:
		flow.call("complete_ending")
		get_tree().change_scene_to_file(TITLE_SCENE)
	else:
		get_tree().change_scene_to_file(BATTLE_SCENE)
