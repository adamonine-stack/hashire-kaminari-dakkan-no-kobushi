extends Node2D

## Stage-specific illustrated backgrounds for the published campaign.
## The image is oversized slightly so the dynamic camera can zoom out without
## exposing empty canvas around the 1280x720 playfield.
##
## Keep only the active backdrop texture referenced. Mobile Web (especially
## iPhone Safari) has a much tighter memory ceiling than desktop builds, and
## preloading every campaign backdrop at scene startup causes an avoidable
## decoded-texture spike during the opening -> battle transition.
const BACKDROP_TEXTURE_PATHS := {
	&"downtown_street": "res://assets/backgrounds/stage_01_downtown.webp",
	&"back_alley": "res://assets/backgrounds/stage_02_back_alley.webp",
	&"island_pier": "res://assets/backgrounds/stage_05_island_pier_v2.png",
	&"secret_base_gate": "res://assets/backgrounds/stage_06_secret_base_gate_v2.png",
	&"island_hideout_entrance": "res://assets/backgrounds/stage_07_hideout_entrance.webp",
	&"island_hideout_boss_room": "res://assets/backgrounds/stage_08_hideout_boss_room.webp",
}
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
const BACKDROP_RECT := Rect2(-112.0, -63.0, 1504.0, 846.0)
const COVER_RECT := Rect2(-900.0, -600.0, 3100.0, 1800.0)

var _backdrop_id: StringName = &"downtown_street"
var _backdrop_texture: Texture2D
var _loaded_backdrop_id: StringName = &""


func _ready() -> void:
	z_index = -20
	_prepare_backdrop_texture(_backdrop_id)
	queue_redraw()


func set_backdrop_id(backdrop_id: StringName) -> void:
	var normalized := backdrop_id
	if normalized not in [&"downtown_street", &"back_alley", &"harbor_warehouse", &"ship_deck", &"island_pier", &"secret_base_gate", &"island_hideout_entrance", &"island_hideout_boss_room"]:
		normalized = &"downtown_street"
	if normalized == _backdrop_id and _backdrop_texture != null:
		return
	_backdrop_id = normalized
	_prepare_backdrop_texture(normalized)
	queue_redraw()


func get_backdrop_id() -> StringName:
	return _backdrop_id


func _draw() -> void:
	draw_rect(COVER_RECT, Color("0b1018"))
	var texture := _texture_for_backdrop(_backdrop_id)
	if texture != null:
		draw_texture_rect(texture, BACKDROP_RECT, false)
	# A light cinematic veil keeps fighters and hit effects readable without
	# flattening the authored background atmosphere.
	var shade_alpha := _shade_alpha_for_backdrop(_backdrop_id)
	draw_rect(BACKDROP_RECT, Color(0.01, 0.018, 0.03, shade_alpha))


func _prepare_backdrop_texture(backdrop_id: StringName) -> void:
	if backdrop_id == _loaded_backdrop_id and _backdrop_texture != null:
		return

	# Drop the previous strong reference before loading the next stage so the
	# decoded texture can be reclaimed as soon as Godot no longer uses it.
	_backdrop_texture = null
	_loaded_backdrop_id = &""

	match backdrop_id:
		&"harbor_warehouse":
			_backdrop_texture = _load_base64_webp(STAGE_3_TEXTURE_PARTS)
		&"ship_deck":
			_backdrop_texture = _load_base64_webp(STAGE_4_TEXTURE_PARTS)
		_:
			var texture_path := String(BACKDROP_TEXTURE_PATHS.get(backdrop_id, ""))
			if not texture_path.is_empty():
				# Do not leave completed stage backgrounds in the global resource cache.
				# On iPhone 13 the Stage 5 -> 6 transition otherwise overlaps two large
				# decoded PNGs with Rio's authored motion atlas.
				_backdrop_texture = ResourceLoader.load(
					texture_path,
					"Texture2D",
					ResourceLoader.CACHE_MODE_IGNORE_DEEP
				) as Texture2D

	# Preserve the previous visual fallback without keeping Stage 1 resident
	# during the whole campaign.
	if _backdrop_texture == null and backdrop_id != &"downtown_street":
		var fallback_path := String(BACKDROP_TEXTURE_PATHS[&"downtown_street"])
		_backdrop_texture = ResourceLoader.load(
			fallback_path,
			"Texture2D",
			ResourceLoader.CACHE_MODE_IGNORE_DEEP
		) as Texture2D

	_loaded_backdrop_id = backdrop_id


func _texture_for_backdrop(backdrop_id: StringName) -> Texture2D:
	if _loaded_backdrop_id != backdrop_id or _backdrop_texture == null:
		_prepare_backdrop_texture(backdrop_id)
	return _backdrop_texture


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
