extends Node
class_name CharacterVisualController

const PLAYER_TOP_Y := 104.0
const PLAYER_ROW_HEIGHT := 42.0
const PLAYER_X_START := 104.0
const PLAYER_FRAME_WIDTH := 48.0
const PLAYER_FRAME_HEIGHT := 42.0
const PLAYER_FRAME_STEP := 50.0

const ENEMY_TOP_Y := 76.0
const ENEMY_ROW_HEIGHT := 25.0
const ENEMY_X_START := 150.0
const ENEMY_FRAME_WIDTH := 28.0
const ENEMY_FRAME_HEIGHT := 25.0
const ENEMY_FRAME_STEP := 29.0

const REQUIRED_ANIMATION_ALIASES := {
	&"walk_forward": &"walk",
	&"walk_backward": &"walk",
	&"jump_start": &"jump",
	&"jump_up": &"jump",
	&"jump_fall": &"fall",
	&"landing": &"land",
	&"crouch_idle": &"crouch",
	&"guard_hit": &"damage",
	&"knockback": &"damage_heavy",
	&"knockdown": &"down",
	&"defeat": &"ko",
}

var animated_sprite: AnimatedSprite2D
var fallback_sprite: Sprite2D
var current_animation: StringName = &""
var fallback_active := true
var definition: Resource
var battle_visual_scale_multiplier := 1.2


func setup(character_data: Resource, animated_node: AnimatedSprite2D, fallback_node: Sprite2D) -> bool:
	definition = character_data
	animated_sprite = animated_node
	fallback_sprite = fallback_node
	current_animation = &""
	fallback_active = true

	if animated_sprite == null or definition == null:
		set_fallback_enabled(true)
		return false

	var sprite_sheet: Texture2D = definition.get("sprite_sheet")
	if sprite_sheet == null:
		set_fallback_enabled(true)
		return false

	var frames := _build_sprite_frames(sprite_sheet, definition)
	if frames == null or frames.get_animation_names().is_empty():
		push_warning("[CharacterVisual] %s: sprite sheet frames unavailable. Fallback to battle texture." % _fighter_id())
		set_fallback_enabled(true)
		return false

	animated_sprite.sprite_frames = frames
	animated_sprite.centered = true
	animated_sprite.visible = true
	animated_sprite.z_index = 2
	animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_visual_transform(sprite_sheet)
	set_fallback_enabled(false)
	play_animation(&"idle", true)
	return true


func play_animation(animation_name: StringName, force := false) -> void:
	if fallback_active or animated_sprite == null or animated_sprite.sprite_frames == null:
		return

	var resolved_name := _resolve_animation_name(animation_name)
	if resolved_name == &"":
		set_fallback_enabled(true)
		return

	if not force and current_animation == resolved_name and animated_sprite.is_playing():
		return

	current_animation = resolved_name
	animated_sprite.play(String(resolved_name))


func set_facing(direction: int) -> void:
	if animated_sprite == null:
		return
	if direction == 0:
		return
	animated_sprite.flip_h = direction < 0


func set_visual_scale(value: Vector2) -> void:
	if animated_sprite != null:
		animated_sprite.scale = value
	if fallback_sprite != null:
		fallback_sprite.scale = value


func set_visual_offset(value: Vector2) -> void:
	if animated_sprite != null:
		animated_sprite.position = value
	if fallback_sprite != null:
		fallback_sprite.position = value


func show_damage_flash() -> void:
	if animated_sprite == null or fallback_active:
		return
	animated_sprite.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1.0, 0.72, 0.72, 1.0), 0.04)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.08)


func set_fallback_enabled(enabled: bool) -> void:
	fallback_active = enabled
	if animated_sprite != null:
		animated_sprite.visible = not enabled
	if fallback_sprite != null:
		fallback_sprite.visible = enabled and fallback_sprite.texture != null


func has_animation(animation_name: StringName) -> bool:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return false
	return animated_sprite.sprite_frames.has_animation(String(animation_name))


func get_debug_source() -> String:
	return "battle.png" if fallback_active else "sprite_sheet"


func _build_sprite_frames(sprite_sheet: Texture2D, character_data: Resource) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var is_enemy: bool = character_data.get("team_type") == &"ENEMY"
	if is_enemy:
		_add_enemy_animations(frames, sprite_sheet, character_data)
	else:
		_add_player_animations(frames, sprite_sheet, character_data)
	_add_required_aliases(frames)
	return frames


func _add_player_animations(frames: SpriteFrames, sprite_sheet: Texture2D, character_data: Resource) -> void:
	var rows: Dictionary = character_data.get("sprite_animation_rows")
	var row_map := {
		&"idle": int(rows.get("idle", 1)),
		&"walk": int(rows.get("walk", 2)),
		&"dash": int(rows.get("dash", 3)),
		&"jump": int(rows.get("jump", 4)),
		&"fall": int(rows.get("jump", 4)),
		&"land": int(rows.get("idle", 1)),
		&"crouch": int(rows.get("crouch", 6)),
		&"guard": int(rows.get("guard", 13)),
		&"punch": int(rows.get("punch1", 9)),
		&"punch_1": int(rows.get("punch1", 9)),
		&"punch_2": int(rows.get("punch2", 10)),
		&"crouch_punch": int(rows.get("crouch_punch", 7)),
		&"kick": int(rows.get("kick1", 11)),
		&"kick_1": int(rows.get("kick1", 11)),
		&"kick_2": int(rows.get("kick2", 12)),
		&"crouch_kick": int(rows.get("crouch_kick", 8)),
		&"jump_punch": int(rows.get("jump_attack", 5)),
		&"jump_kick": int(rows.get("jump_attack", 5)),
		&"damage": int(rows.get("damage", 15)),
		&"damage_light": int(rows.get("damage", 15)),
		&"damage_heavy": int(rows.get("damage", 15)),
		&"down": int(rows.get("down", 16)),
		&"getup": int(rows.get("getup", 17)),
		&"special": int(rows.get("special", 18)),
		&"ko": int(rows.get("down", 16)),
		&"victory": int(rows.get("victory", 19)),
		&"grab": int(rows.get("punch1", 9)),
		&"throw": int(rows.get("special", 18)),
		&"grabbed": int(rows.get("damage", 15)),
		&"thrown": int(rows.get("down", 16)),
	}
	for animation_name in row_map.keys():
		_add_row_animation(frames, sprite_sheet, animation_name, row_map[animation_name], false)


func _add_enemy_animations(frames: SpriteFrames, sprite_sheet: Texture2D, character_data: Resource) -> void:
	var row_map := {
		&"idle": 1,
		&"walk": 2,
		&"dash": 3,
		&"jump": 4,
		&"fall": 4,
		&"land": 1,
		&"crouch": 5,
		&"punch": 6,
		&"punch_1": 6,
		&"punch_2": 6,
		&"kick": 7,
		&"kick_1": 7,
		&"kick_2": 7,
		&"guard": 8,
		&"grab": 9,
		&"throw": 9,
		&"damage": 10,
		&"damage_light": 10,
		&"damage_heavy": 10,
		&"down": 11,
		&"getup": 11,
		&"ko": 11,
		&"special": 13,
		&"victory": 1,
		&"grabbed": 10,
		&"thrown": 11,
	}
	for animation_name in row_map.keys():
		_add_row_animation(frames, sprite_sheet, animation_name, row_map[animation_name], true)


func _add_row_animation(frames: SpriteFrames, sprite_sheet: Texture2D, animation_name: StringName, row_number: int, is_enemy: bool) -> void:
	if row_number <= 0:
		return
	var top_y := _layout_top_y(is_enemy)
	var row_height := _layout_row_height(is_enemy)
	var x_start := _layout_x_start(is_enemy)
	var frame_width := _layout_frame_width(is_enemy)
	var frame_height := _layout_frame_height(is_enemy)
	var frame_step := _layout_frame_step(is_enemy)
	var y := top_y + float(row_number - 1) * row_height
	if y + frame_height > float(sprite_sheet.get_height()):
		return

	var max_count := int(floor((float(sprite_sheet.get_width()) - x_start) / frame_step))
	var frame_count := clampi(max_count, 1, _max_frames_per_animation())
	frames.add_animation(String(animation_name))
	frames.set_animation_speed(String(animation_name), _animation_speed(animation_name))
	frames.set_animation_loop(String(animation_name), _animation_should_loop(animation_name))

	var sheet_image := sprite_sheet.get_image()
	for index in range(frame_count):
		var x := x_start + float(index) * frame_step
		if x + frame_width > float(sprite_sheet.get_width()):
			continue
		var frame_texture := _create_clean_frame_texture(sheet_image, Rect2i(roundi(x), roundi(y), roundi(frame_width), roundi(frame_height)))
		if frame_texture != null:
			frames.add_frame(String(animation_name), frame_texture)

	if frames.get_frame_count(String(animation_name)) == 0:
		frames.remove_animation(String(animation_name))


func _add_required_aliases(frames: SpriteFrames) -> void:
	for alias_name: StringName in REQUIRED_ANIMATION_ALIASES.keys():
		if frames.has_animation(String(alias_name)):
			continue
		var source_name: StringName = REQUIRED_ANIMATION_ALIASES[alias_name]
		source_name = _first_existing_animation(frames, [source_name, &"idle"])
		if source_name == &"":
			continue
		_clone_animation(frames, source_name, alias_name)


func _clone_animation(frames: SpriteFrames, source_name: StringName, alias_name: StringName) -> void:
	var source := String(source_name)
	var alias := String(alias_name)
	if not frames.has_animation(source):
		return
	frames.add_animation(alias)
	frames.set_animation_speed(alias, _animation_speed(alias_name))
	frames.set_animation_loop(alias, _animation_should_loop(alias_name))
	for index in range(frames.get_frame_count(source)):
		frames.add_frame(alias, frames.get_frame_texture(source, index), frames.get_frame_duration(source, index))


func _first_existing_animation(frames: SpriteFrames, names: Array[StringName]) -> StringName:
	for animation_name in names:
		if frames.has_animation(String(animation_name)):
			return animation_name
	return &""


func _create_clean_frame_texture(sheet_image: Image, region: Rect2i) -> Texture2D:
	if sheet_image == null or region.size.x <= 0 or region.size.y <= 0:
		return null
	var frame_image := sheet_image.get_region(region)
	frame_image.convert(Image.FORMAT_RGBA8)
	if bool(definition.get("sprite_cleanup_background")):
		_remove_connected_sheet_background(frame_image)
	return ImageTexture.create_from_image(frame_image)


func _remove_connected_sheet_background(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	if width <= 0 or height <= 0:
		return
	var visited := PackedByteArray()
	visited.resize(width * height)
	for x in range(width):
		_try_flood_background_from(image, Vector2i(x, 0), visited)
		_try_flood_background_from(image, Vector2i(x, height - 1), visited)
	for y in range(height):
		_try_flood_background_from(image, Vector2i(0, y), visited)
		_try_flood_background_from(image, Vector2i(width - 1, y), visited)


func _try_flood_background_from(image: Image, start: Vector2i, visited: PackedByteArray) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var start_index := start.y * width + start.x
	if start_index < 0 or start_index >= visited.size() or visited[start_index] == 1:
		return
	var seed_color := image.get_pixelv(start)
	if not _is_sheet_background_seed(seed_color):
		return
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var point: Vector2i = stack.pop_back()
		if point.x < 0 or point.y < 0 or point.x >= width or point.y >= height:
			continue
		var index: int = point.y * width + point.x
		if visited[index] == 1:
			continue
		var color := image.get_pixelv(point)
		if not _is_connected_background_color(color, seed_color):
			continue
		visited[index] = 1
		color.a = 0.0
		image.set_pixelv(point, color)
		stack.append(point + Vector2i(1, 0))
		stack.append(point + Vector2i(-1, 0))
		stack.append(point + Vector2i(0, 1))
		stack.append(point + Vector2i(0, -1))


func _is_sheet_background_seed(color: Color) -> bool:
	if color.a < 0.05:
		return true
	return _brightness(color) <= float(definition.get("sprite_background_brightness_limit"))


func _is_connected_background_color(color: Color, seed_color: Color) -> bool:
	if color.a < 0.05:
		return true
	if _brightness(color) <= 0.26:
		return true
	return _color_distance(color, seed_color) <= float(definition.get("sprite_background_color_tolerance"))


func _brightness(color: Color) -> float:
	return (color.r + color.g + color.b) / 3.0


func _color_distance(a: Color, b: Color) -> float:
	var dr := a.r - b.r
	var dg := a.g - b.g
	var db := a.b - b.b
	return sqrt(dr * dr + dg * dg + db * db)


func _layout_top_y(is_enemy: bool) -> float:
	var origin: Vector2 = definition.get("sprite_frame_origin")
	if origin.y >= 0.0:
		return origin.y
	return ENEMY_TOP_Y if is_enemy else PLAYER_TOP_Y


func _layout_x_start(is_enemy: bool) -> float:
	var origin: Vector2 = definition.get("sprite_frame_origin")
	if origin.x >= 0.0:
		return origin.x
	return ENEMY_X_START if is_enemy else PLAYER_X_START


func _layout_frame_width(is_enemy: bool) -> float:
	var frame_size: Vector2i = definition.get("sprite_frame_size")
	if frame_size.x > 0:
		return float(frame_size.x) * _layout_source_scale(is_enemy)
	return ENEMY_FRAME_WIDTH if is_enemy else PLAYER_FRAME_WIDTH


func _layout_frame_height(is_enemy: bool) -> float:
	var frame_size: Vector2i = definition.get("sprite_frame_size")
	if frame_size.y > 0:
		return float(frame_size.y) * _layout_source_scale(is_enemy)
	return ENEMY_FRAME_HEIGHT if is_enemy else PLAYER_FRAME_HEIGHT


func _layout_row_height(is_enemy: bool) -> float:
	var configured := float(definition.get("sprite_row_height"))
	if configured > 0.0:
		return configured
	var step: Vector2 = definition.get("sprite_frame_step")
	if step.y > 0.0:
		return step.y
	return ENEMY_ROW_HEIGHT if is_enemy else PLAYER_ROW_HEIGHT


func _layout_frame_step(is_enemy: bool) -> float:
	var step: Vector2 = definition.get("sprite_frame_step")
	if step.x > 0.0:
		return step.x
	return ENEMY_FRAME_STEP if is_enemy else PLAYER_FRAME_STEP


func _layout_source_scale(is_enemy: bool) -> float:
	var frame_size: Vector2i = definition.get("sprite_frame_size")
	if is_enemy:
		return ENEMY_FRAME_WIDTH / maxf(float(frame_size.x), 1.0)
	return PLAYER_FRAME_WIDTH / maxf(float(frame_size.x), 1.0)


func _max_frames_per_animation() -> int:
	if definition == null:
		return 8
	return clampi(int(definition.get("sprite_max_frames_per_animation")), 1, 12)


func _resolve_animation_name(animation_name: StringName) -> StringName:
	if has_animation(animation_name):
		return animation_name
	var fallbacks: Array[StringName] = []
	match animation_name:
		&"walk_forward", &"walk_backward":
			fallbacks = [&"walk", &"idle"]
		&"jump_start", &"jump_up", &"jump_fall":
			fallbacks = [&"jump", &"idle"]
		&"landing":
			fallbacks = [&"land", &"idle"]
		&"crouch_idle":
			fallbacks = [&"crouch", &"idle"]
		&"punch_1", &"punch_2", &"crouch_punch", &"jump_punch":
			fallbacks = [&"punch", &"idle"]
		&"kick_1", &"kick_2", &"crouch_kick", &"jump_kick", &"combo_finisher":
			fallbacks = [&"kick", &"punch", &"idle"]
		&"damage_light", &"damage_heavy", &"guard_hit", &"knockback":
			fallbacks = [&"damage", &"idle"]
		&"knockdown":
			fallbacks = [&"down", &"damage", &"idle"]
		&"fall", &"land":
			fallbacks = [&"jump", &"idle"]
		&"throw_start", &"throw_hold", &"throw_release":
			fallbacks = [&"throw", &"special", &"punch", &"idle"]
		&"thrown", &"grabbed":
			fallbacks = [&"damage", &"down", &"idle"]
		&"ko", &"defeat":
			fallbacks = [&"down", &"damage", &"idle"]
		&"special_01", &"special_02", &"ultimate_startup", &"ultimate_attack", &"ultimate_recovery":
			fallbacks = [&"special", &"kick", &"punch", &"idle"]
		_:
			fallbacks = [&"idle"]
	for fallback in fallbacks:
		if has_animation(fallback):
			return fallback
	push_warning("[CharacterVisual] %s: animation \"%s\" not found. Fallback to battle texture." % [_fighter_id(), String(animation_name)])
	return &""


func _apply_visual_transform(sprite_sheet: Texture2D) -> void:
	var target_height := 150.0
	var visual_offset := Vector2.ZERO
	if definition != null:
		target_height = float(definition.get("battle_sprite_height"))
		visual_offset = Vector2(definition.get("battle_sprite_offset"))
	target_height *= battle_visual_scale_multiplier
	visual_offset *= battle_visual_scale_multiplier
	var source_height := _layout_frame_height(definition != null and definition.get("team_type") == &"ENEMY")
	var sprite_scale := target_height / maxf(source_height, 1.0)
	set_visual_scale(Vector2(sprite_scale, sprite_scale))
	set_visual_offset(Vector2(0.0, -target_height * 0.5) + visual_offset)


func _animation_speed(animation_name: StringName) -> float:
	match animation_name:
		&"idle", &"guard", &"crouch", &"crouch_idle", &"victory":
			return 6.0
		&"walk", &"walk_forward", &"walk_backward", &"jump_start", &"jump_up", &"jump_fall", &"landing":
			return 10.0
		&"dash":
			return 12.0
		&"punch", &"punch_1", &"punch_2", &"kick", &"kick_1", &"kick_2", &"special":
			return 14.0
		&"damage", &"damage_light", &"damage_heavy", &"guard_hit", &"knockback":
			return 12.0
		&"down", &"knockdown", &"getup", &"ko", &"defeat":
			return 8.0
		_:
			return 8.0


func _animation_should_loop(animation_name: StringName) -> bool:
	return animation_name == &"idle" or animation_name == &"walk" or animation_name == &"walk_forward" or animation_name == &"walk_backward" or animation_name == &"dash" or animation_name == &"crouch" or animation_name == &"crouch_idle" or animation_name == &"guard" or animation_name == &"victory"


func _fighter_id() -> String:
	if definition == null:
		return "unknown"
	return String(definition.get("fighter_id"))
