extends Node2D

## Stage-specific illustrated backgrounds for the published campaign.
## The image is oversized slightly so the dynamic camera can zoom out without
## exposing empty canvas around the 1280x720 playfield.
const STAGE_1_TEXTURE: Texture2D = preload("res://assets/backgrounds/stage_01_downtown.webp")
const STAGE_2_TEXTURE: Texture2D = preload("res://assets/backgrounds/stage_02_back_alley.webp")
const STAGE_3_TEXTURE: Texture2D = preload("res://assets/backgrounds/stage_03_harbor_warehouse.webp")
const STAGE_4_TEXTURE: Texture2D = preload("res://assets/backgrounds/stage_04_ship_deck.webp")
const BACKDROP_RECT := Rect2(-112.0, -63.0, 1504.0, 846.0)
const COVER_RECT := Rect2(-900.0, -600.0, 3100.0, 1800.0)

var _backdrop_id: StringName = &"downtown_street"


func _ready() -> void:
	z_index = -20
	queue_redraw()


func set_backdrop_id(backdrop_id: StringName) -> void:
	var normalized := backdrop_id
	if normalized not in [&"downtown_street", &"back_alley", &"harbor_warehouse", &"ship_deck"]:
		normalized = &"downtown_street"
	if normalized == _backdrop_id:
		return
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


func _texture_for_backdrop(backdrop_id: StringName) -> Texture2D:
	match backdrop_id:
		&"back_alley":
			return STAGE_2_TEXTURE
		&"harbor_warehouse":
			return STAGE_3_TEXTURE
		&"ship_deck":
			return STAGE_4_TEXTURE
		_:
			return STAGE_1_TEXTURE


func _shade_alpha_for_backdrop(backdrop_id: StringName) -> float:
	match backdrop_id:
		&"back_alley":
			return 0.06
		&"harbor_warehouse":
			return 0.07
		&"ship_deck":
			return 0.08
		_:
			return 0.09
