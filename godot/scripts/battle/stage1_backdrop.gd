extends Node2D

## Stage-specific illustrated backgrounds for the published two-stage slice.
## The image is oversized slightly so the dynamic camera can zoom out without
## exposing empty canvas around the 1280x720 playfield.
const STAGE_1_TEXTURE: Texture2D = preload("res://assets/backgrounds/stage_01_downtown.webp")
const STAGE_2_TEXTURE: Texture2D = preload("res://assets/backgrounds/stage_02_back_alley.webp")
const BACKDROP_RECT := Rect2(-112.0, -63.0, 1504.0, 846.0)
const COVER_RECT := Rect2(-900.0, -600.0, 3100.0, 1800.0)

var _backdrop_id: StringName = &"downtown_street"


func _ready() -> void:
	z_index = -20
	queue_redraw()


func set_backdrop_id(backdrop_id: StringName) -> void:
	var normalized := &"back_alley" if backdrop_id == &"back_alley" else &"downtown_street"
	if normalized == _backdrop_id:
		return
	_backdrop_id = normalized
	queue_redraw()


func get_backdrop_id() -> StringName:
	return _backdrop_id


func _draw() -> void:
	draw_rect(COVER_RECT, Color("0b1018"))
	var texture: Texture2D = STAGE_2_TEXTURE if _backdrop_id == &"back_alley" else STAGE_1_TEXTURE
	draw_texture_rect(texture, BACKDROP_RECT, false)
	# A light cinematic veil keeps fighters and hit effects readable over the
	# detailed street art without flattening the neon/wet-pavement atmosphere.
	var shade_alpha := 0.06 if _backdrop_id == &"back_alley" else 0.09
	draw_rect(BACKDROP_RECT, Color(0.01, 0.018, 0.03, shade_alpha))
