extends Node2D

## Stage-specific illustrated backgrounds for the published campaign.
## The image is oversized slightly so the dynamic camera can zoom out without
## exposing empty canvas around the 1280x720 playfield.
const STAGE_1_TEXTURE: Texture2D = preload("res://assets/backgrounds/stage_01_downtown.webp")
const STAGE_2_TEXTURE: Texture2D = preload("res://assets/backgrounds/stage_02_back_alley.webp")
const STAGE_3_TEXTURE_PARTS := [
	"res://assets/backgrounds/generated/stage_03_harbor_warehouse_00.b64",
	"res://assets/backgrounds/generated/stage_03_harbor_warehouse_01.b64",
	"res://assets/backgrounds/generated/stage_03_harbor_warehouse_02.b64",
	"res://assets/backgrounds/generated/stage_03_harbor_warehouse_03.b64",
	"res://assets/backgrounds/generated/stage_03_harbor_warehouse_04.b64",
]
const STAGE_4_TEXTURE_PARTS := [
	"res://assets/backgrounds/generated/stage_04_ship_deck_00.b64",
	"res://assets/backgrounds/generated/stage_04_ship_deck_01.b64",
	"res://assets/backgrounds/generated/stage_04_ship_deck_02.b64",
	"res://assets/backgrounds/generated/stage_04_ship_deck_03.b64",
	"res://assets/backgrounds/generated/stage_04_ship_deck_04.b64",
	"res://assets/backgrounds/generated/stage_04_ship_deck_05a.b64",
	"res://assets/backgrounds/generated/stage_04_ship_deck_05b.b64",
	"res://assets/backgrounds/generated/stage_04_ship_deck_05c.b64",
	"res://assets/backgrounds/generated/stage_04_ship_deck_05d.b64",
	"res://assets/backgrounds/generated/stage_04_ship_deck_06.b64",
	"res://assets/backgrounds/generated/stage_04_ship_deck_07.b64",
]
const STAGE_5_TEXTURE: Texture2D = preload("res://assets/backgrounds/stage_05_island_pier_v2.png")
const STAGE_6_TEXTURE: Texture2D = preload("res://assets/backgrounds/stage_06_secret_base_gate_v2.png")
const STAGE_7_TEXTURE: Texture2D = preload("res://assets/backgrounds/stage_07_hideout_entrance.webp")
const STAGE_8_TEXTURE: Texture2D = preload("res://assets/backgrounds/stage_08_hideout_boss_room.webp")
const BACKDROP_RECT := Rect2(-112.0, -63.0, 1504.0, 846.0)
const COVER_RECT := Rect2(-900.0, -600.0, 3100.0, 1800.0)

var _backdrop_id: StringName = &"downtown_street"
var _stage_3_texture: Texture2D
var _stage_4_texture: Texture2D


func _ready() -> void:
	z_index = -20
	queue_redraw()


func set_backdrop_id(backdrop_id: StringName) -> void:
	var normalized := backdrop_id
	if normalized not in [&"downtown_street", &"back_alley", &"harbor_warehouse", &"ship_deck", &"island_pier", &"secret_base_gate", &"island_hideout_entrance", &"island_hideout_boss_room"]:
		normalized = &"downtown_street"
	if normalized == _backdrop_id:
		return
	_prepare_backdrop_texture(normalized)
	_backdrop_id = normalized
	queue_redraw()


func get_backdrop_id() -> StringName:
	return _backdrop_id


func _draw() -> void:
	draw_rect(COVER_RECT, Color("0b1018"))
	var texture := _texture_for_backdrop(_backdrop_id)
	draw_texture_rect(texture, BACKDROP_RECT, false)
	# A light cinematic veil keeps fighters and hit effects readable without
	# flattening the authored background atmosphere.
	var shade_alpha := _shade_alpha_for_backdrop(_backdrop_id)
	draw_rect(BACKDROP_RECT, Color(0.01, 0.018, 0.03, shade_alpha))


func _prepare_backdrop_texture(backdrop_id: StringName) -> void:
	match backdrop_id:
		&"harbor_warehouse":
			if _stage_3_texture == null:
				_stage_3_texture = _load_base64_webp(STAGE_3_TEXTURE_PARTS)
		&"ship_deck":
			if _stage_4_texture == null:
				_stage_4_texture = _load_base64_webp(STAGE_4_TEXTURE_PARTS)


func _texture_for_backdrop(backdrop_id: StringName) -> Texture2D:
	match backdrop_id:
		&"back_alley":
			return STAGE_2_TEXTURE
		&"harbor_warehouse":
			if _stage_3_texture == null:
				_stage_3_texture = _load_base64_webp(STAGE_3_TEXTURE_PARTS)
			return _stage_3_texture if _stage_3_texture != null else STAGE_1_TEXTURE
		&"ship_deck":
			if _stage_4_texture == null:
				_stage_4_texture = _load_base64_webp(STAGE_4_TEXTURE_PARTS)
			return _stage_4_texture if _stage_4_texture != null else STAGE_1_TEXTURE
		&"island_pier":
			return STAGE_5_TEXTURE
		&"secret_base_gate":
			return STAGE_6_TEXTURE
		&"island_hideout_entrance":
			return STAGE_7_TEXTURE
		&"island_hideout_boss_room":
			return STAGE_8_TEXTURE
		_:
			return STAGE_1_TEXTURE


func _load_base64_webp(parts: Array) -> Texture2D:
	var encoded := ""
	for path in parts:
		if not FileAccess.file_exists(path):
			push_error("Missing background data: %s" % path)
			return null
		encoded += FileAccess.get_file_as_string(path).strip_edges()

	var raw := Marshalls.base64_to_raw(encoded)
	if raw.is_empty():
		push_error("Failed to decode background image data.")
		return null

	var image := Image.new()
	var error := image.load_webp_from_buffer(raw)
	if error != OK:
		push_error("Failed to load background WebP: %s" % error)
		return null
	return ImageTexture.create_from_image(image)


func _shade_alpha_for_backdrop(backdrop_id: StringName) -> float:
	match backdrop_id:
		&"back_alley":
			return 0.06
		&"harbor_warehouse":
			return 0.07
		&"ship_deck":
			return 0.08
		&"island_pier":
			return 0.05
		&"secret_base_gate":
			return 0.06
		&"island_hideout_entrance":
			return 0.02
		&"island_hideout_boss_room":
			return 0.015
		_:
			return 0.09
