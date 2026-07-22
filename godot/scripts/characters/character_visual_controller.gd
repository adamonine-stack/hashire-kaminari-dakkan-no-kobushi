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

const STANDARD_192_FORMAT := &"standard_192"
const STANDARD_192_CELL_SIZE := Vector2i(192, 192)
const STANDARD_192_COLUMNS := 8

const REQUIRED_ANIMATION_ALIASES := {
	&"walk_forward": &"walk",
	&"walk_backward": &"walk",
	&"jump_start": &"jump",
	&"jump_air": &"jump",
	&"jump_land": &"jump",
	&"jump_up": &"jump",
	&"jump_fall": &"jump",
	&"fall": &"jump",
	&"landing": &"jump",
	&"crouch_idle": &"crouch",
	&"punch_1": &"punch",
	&"punch_2": &"punch",
	&"crouch_punch": &"punch",
	&"jump_punch": &"jump_punch_down",
	&"light_attack": &"punch",
	&"kick_1": &"kick",
	&"kick_2": &"kick",
	&"crouch_kick": &"crouch_kick_sweep",
	&"jump_kick": &"kick",
	&"heavy_attack": &"kick",
	&"combo_finisher": &"kick",
	&"damage": &"damage_light",
	&"guard_hit": &"damage",
	&"knockback": &"damage_heavy",
	&"knockdown": &"down",
	&"getup": &"stand_up",
	&"get_up": &"stand_up",
	&"defeat": &"ko",
	&"special_startup": &"special",
	&"special_attack": &"special",
	&"special_recovery": &"special",
}

var animated_sprite: AnimatedSprite2D
var fallback_sprite: Sprite2D
var current_animation: StringName = &""
var fallback_active := true
var animated_art_active := false
var definition: Resource
var battle_visual_scale_multiplier := 1.2
var missing_animation_warnings := {}


func setup(character_data: Resource, animated_node: AnimatedSprite2D, fallback_node: Sprite2D) -> bool:
	definition = character_data
	animated_sprite = animated_node
	fallback_sprite = fallback_node
	current_animation = &""
	fallback_active = true
	animated_art_active = false
	missing_animation_warnings.clear()

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

	# Reused fighter nodes must never inherit visual state from the previous stage.
	animated_sprite.stop()
	animated_sprite.sprite_frames = frames
	animated_sprite.animation = &""
	animated_sprite.frame = 0
	animated_sprite.speed_scale = 1.0
	animated_sprite.scale = Vector2.ONE
	animated_sprite.position = Vector2.ZERO
	animated_sprite.offset = Vector2.ZERO
	animated_sprite.flip_h = false
	animated_sprite.centered = true
	animated_sprite.visible = true
	animated_sprite.z_index = 2
	animated_sprite.modulate = Color.WHITE
	animated_sprite.self_modulate = Color.WHITE
	animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_visual_transform(sprite_sheet)
	animated_art_active = true
	set_fallback_enabled(false)
	play_animation(&"idle", true)
	return true


func play_animation(animation_name: StringName, force := false) -> void:
	if fallback_active or animated_sprite == null or animated_sprite.sprite_frames == null:
		return

	var resolved_name := _resolve_animation_name(animation_name)
	if resolved_name == &"":
		if has_animation(&"idle"):
			resolved_name = &"idle"
		else:
			return
	set_fallback_enabled(false)
	if fallback_sprite != null:
		fallback_sprite.visible = false
	if animated_sprite != null:
		animated_sprite.visible = true
		animated_sprite.centered = true
		if animated_sprite.modulate != Color.WHITE and not animated_sprite.is_playing():
			animated_sprite.modulate = Color.WHITE
		else:
			animated_sprite.modulate.a = 1.0
		animated_sprite.self_modulate = Color.WHITE

	if resolved_name == &"":
		return

	if not force and current_animation == resolved_name:
		if not animated_sprite.is_playing():
			animated_sprite.play(String(resolved_name))
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
		if enabled:
			fallback_sprite.visible = fallback_sprite.texture != null
		else:
			fallback_sprite.visible = false
			if animated_art_active:
				fallback_sprite.texture = null


func has_animation(animation_name: StringName) -> bool:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return false
	return animated_sprite.sprite_frames.has_animation(String(animation_name))


func get_debug_source() -> String:
	return "battle.png" if fallback_active else "sprite_sheet"


func _build_sprite_frames(sprite_sheet: Texture2D, character_data: Resource) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	if _uses_standard_192_sheet(character_data):
		if _add_standard_192_animations(frames, sprite_sheet, character_data):
			_add_required_aliases(frames)
			return frames
		push_warning("[SpriteSheet] Invalid standard_192 sheet: character=%s" % _fighter_id())
		return frames

	var is_enemy: bool = character_data.get("team_type") == &"ENEMY"
	if is_enemy:
		_add_enemy_animations(frames, sprite_sheet, character_data)
	else:
		_add_player_animations(frames, sprite_sheet, character_data)
	_add_required_aliases(frames)
	return frames


func _uses_standard_192_sheet(character_data: Resource) -> bool:
	if character_data == null:
		return false
	return StringName(character_data.get("sprite_sheet_format")) == STANDARD_192_FORMAT


func _add_standard_192_animations(frames: SpriteFrames, sprite_sheet: Texture2D, character_data: Resource) -> bool:
	if sprite_sheet == null:
		return false
	if sprite_sheet.get_width() < STANDARD_192_CELL_SIZE.x * STANDARD_192_COLUMNS:
		return false

	var rows: Dictionary = character_data.get("sprite_animation_rows")
	var frame_counts: Dictionary = character_data.get("sprite_animation_frame_counts")
	if rows.is_empty() or not rows.has("idle") or int(frame_counts.get("idle", 0)) <= 0:
		return false

	var sheet_image := sprite_sheet.get_image()
	for animation_key in rows.keys():
		var animation_name := StringName(String(animation_key))
		var row_index := int(rows[animation_key])
		var frame_count := int(frame_counts.get(animation_key, STANDARD_192_COLUMNS))
		_add_standard_192_animation(frames, sheet_image, animation_name, row_index, frame_count)

	var clips: Dictionary = character_data.get("sprite_animation_clips")
	for animation_key in clips.keys():
		var animation_name := StringName(String(animation_key))
		var clip: Dictionary = clips[animation_key]
		var row_index := int(clip.get("row", -1))
		var start_column := int(clip.get("start", 0))
		var frame_count := int(clip.get("count", STANDARD_192_COLUMNS))
		_add_standard_192_clip_animation(frames, sheet_image, animation_name, row_index, start_column, frame_count)

	return frames.has_animation("idle") and frames.get_frame_count("idle") > 0


func _add_standard_192_animation(frames: SpriteFrames, sheet_image: Image, animation_name: StringName, row_index: int, frame_count: int) -> void:
	_add_standard_192_clip_animation(frames, sheet_image, animation_name, row_index, 0, frame_count)


func _add_standard_192_clip_animation(frames: SpriteFrames, sheet_image: Image, animation_name: StringName, row_index: int, start_column: int, frame_count: int) -> void:
	if row_index < 0 or frame_count <= 0:
		return
	if sheet_image == null:
		return
	if (row_index + 1) * STANDARD_192_CELL_SIZE.y > sheet_image.get_height():
		push_warning("[SpriteSheet] Skipped animation outside sheet: character=%s animation=%s row=%d sheet=%dx%d" % [
			_fighter_id(),
			String(animation_name),
			row_index,
			sheet_image.get_width(),
			sheet_image.get_height(),
		])
		return

	var clamped_count := clampi(frame_count, 1, STANDARD_192_COLUMNS)
	var frame_images: Array[Image] = []
	var content_rects: Array[Rect2i] = []

	for column_index in range(clamped_count):
		var source_column := start_column + column_index
		if source_column < 0 or source_column >= STANDARD_192_COLUMNS:
			continue
		var frame_rect := Rect2i(
			source_column * STANDARD_192_CELL_SIZE.x,
			row_index * STANDARD_192_CELL_SIZE.y,
			STANDARD_192_CELL_SIZE.x,
			STANDARD_192_CELL_SIZE.y
		)
		if frame_rect.position.x + frame_rect.size.x > sheet_image.get_width():
			break
		var frame_image := sheet_image.get_region(frame_rect)
		frame_image.convert(Image.FORMAT_RGBA8)
		_sanitize_standard_192_frame(frame_image)
		if _is_blank_frame(frame_image):
			continue
		var content_rect := _get_visible_content_rect(frame_image)
		if content_rect.size.x <= 0 or content_rect.size.y <= 0:
			continue
		frame_images.append(frame_image)
		content_rects.append(content_rect)

	if frame_images.is_empty():
		push_warning("[SpriteSheet] Skipped blank animation: character=%s animation=%s row=%d" % [
			_fighter_id(),
			String(animation_name),
			row_index,
		])
		return

	var target_center_x := _standard_192_target_center_x(content_rects, animation_name)
	var target_bottom_y := _standard_192_target_bottom_y(content_rects, animation_name)

	if frames.has_animation(String(animation_name)):
		frames.remove_animation(String(animation_name))
	frames.add_animation(String(animation_name))
	frames.set_animation_speed(String(animation_name), _animation_speed(animation_name))
	frames.set_animation_loop(String(animation_name), _animation_should_loop(animation_name))

	for index in range(frame_images.size()):
		var normalized_frame := _normalize_standard_192_frame(frame_images[index], content_rects[index], target_center_x, target_bottom_y)
		var frame_texture := ImageTexture.create_from_image(normalized_frame)
		if frame_texture != null:
			frames.add_frame(String(animation_name), frame_texture)

	if frames.get_frame_count(String(animation_name)) == 0:
		frames.remove_animation(String(animation_name))


func _sanitize_standard_192_frame(frame_image: Image) -> void:
	if frame_image == null:
		return
	if bool(definition.get("sprite_cleanup_background")):
		_remove_connected_sheet_background(frame_image)


func _is_blank_frame(image: Image) -> bool:
	if image == null:
		return true
	var width := image.get_width()
	var height := image.get_height()
	if width <= 0 or height <= 0:
		return true
	for y in range(height):
		for x in range(width):
			if image.get_pixel(x, y).a > 0.01:
				return false
	return true


func _get_visible_content_rect(image: Image) -> Rect2i:
	if image == null:
		return Rect2i()
	var width := image.get_width()
	var height := image.get_height()
	var min_x := width
	var min_y := height
	var max_x := -1
	var max_y := -1
	for y in range(height):
		for x in range(width):
			if image.get_pixel(x, y).a <= 0.01:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _standard_192_target_center_x(content_rects: Array[Rect2i], animation_name: StringName) -> int:
	if content_rects.is_empty():
		return STANDARD_192_CELL_SIZE.x / 2
	var sum := 0.0
	for rect in content_rects:
		sum += float(rect.position.x) + float(rect.size.x) * 0.5
	return clampi(roundi(sum / float(content_rects.size())) + _animation_center_offset(animation_name), 0, STANDARD_192_CELL_SIZE.x)


func _standard_192_target_bottom_y(content_rects: Array[Rect2i], animation_name: StringName) -> int:
	if content_rects.is_empty():
		return STANDARD_192_CELL_SIZE.y
	var bottoms: Array[int] = []
	var max_content_height := 1
	for rect in content_rects:
		bottoms.append(rect.position.y + rect.size.y)
		max_content_height = maxi(max_content_height, rect.size.y)
	bottoms.sort()
	var percentile_index := clampi(int(floor(float(bottoms.size() - 1) * 0.75)), 0, bottoms.size() - 1)
	var bottom_y := bottoms[percentile_index] + _animation_bottom_offset(animation_name)
	return clampi(bottom_y, max_content_height, STANDARD_192_CELL_SIZE.y)


func _animation_center_offset(animation_name: StringName) -> int:
	if definition == null:
		return 0
	var offsets: Dictionary = definition.get("sprite_animation_center_offsets")
	return _animation_int_offset(offsets, animation_name)


func _animation_bottom_offset(animation_name: StringName) -> int:
	if definition == null:
		return 0
	var offsets: Dictionary = definition.get("sprite_animation_bottom_offsets")
	return _animation_int_offset(offsets, animation_name)


func _animation_int_offset(offsets: Dictionary, animation_name: StringName) -> int:
	if offsets.is_empty():
		return 0
	var string_key := String(animation_name)
	if offsets.has(string_key):
		return roundi(float(offsets[string_key]))
	if offsets.has(animation_name):
		return roundi(float(offsets[animation_name]))
	return 0


func _normalize_standard_192_frame(source_image: Image, content_rect: Rect2i, target_center_x: int, target_bottom_y: int) -> Image:
	var normalized := Image.create(STANDARD_192_CELL_SIZE.x, STANDARD_192_CELL_SIZE.y, false, Image.FORMAT_RGBA8)
	normalized.fill(Color(0.0, 0.0, 0.0, 0.0))

	var content_center_x := content_rect.position.x + int(round(float(content_rect.size.x) * 0.5))
	var content_bottom_y := content_rect.position.y + content_rect.size.y
	var offset := Vector2i(target_center_x - content_center_x, target_bottom_y - content_bottom_y)
	var dst_position := content_rect.position + offset
	var src_rect := content_rect

	if dst_position.x < 0:
		src_rect.position.x -= dst_position.x
		src_rect.size.x += dst_position.x
		dst_position.x = 0
	if dst_position.y < 0:
		src_rect.position.y -= dst_position.y
		src_rect.size.y += dst_position.y
		dst_position.y = 0
	if dst_position.x + src_rect.size.x > STANDARD_192_CELL_SIZE.x:
		src_rect.size.x = STANDARD_192_CELL_SIZE.x - dst_position.x
	if dst_position.y + src_rect.size.y > STANDARD_192_CELL_SIZE.y:
		src_rect.size.y = STANDARD_192_CELL_SIZE.y - dst_position.y

	if src_rect.size.x > 0 and src_rect.size.y > 0:
		normalized.blit_rect(source_image, src_rect, dst_position)
	return normalized


func _add_player_animations(frames: SpriteFrames, sprite_sheet: Texture2D, character_data: Resource) -> void:
	var clips: Dictionary = character_data.get("sprite_animation_clips")
	if not clips.is_empty():
		_add_clip_animations(frames, sprite_sheet, clips, false)
		return

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


func _add_clip_animations(frames: SpriteFrames, sprite_sheet: Texture2D, clips: Dictionary, is_enemy: bool) -> void:
	for animation_key in clips.keys():
		var animation_name := StringName(String(animation_key))
		var clip: Dictionary = clips[animation_key]
		var row_number := int(clip.get("row", 1))
		var start_column := int(clip.get("start", 0))
		var frame_count := int(clip.get("count", _max_frames_per_animation()))
		_add_clip_animation(frames, sprite_sheet, animation_name, row_number, start_column, frame_count, is_enemy)


func _add_clip_animation(frames: SpriteFrames, sprite_sheet: Texture2D, animation_name: StringName, row_number: int, start_column: int, frame_count: int, is_enemy: bool) -> void:
	if row_number <= 0 or frame_count <= 0:
		return
	var top_y := _layout_top_y(is_enemy)
	var row_height := _layout_row_height(is_enemy)
	var x_start := _layout_x_start(is_enemy)
	var frame_width := _layout_frame_width(is_enemy)
	var frame_height := _layout_frame_height(is_enemy)
	var frame_step := _layout_frame_step(is_enemy)
	var y := top_y + float(row_number - 1) * row_height
	if y + frame_height > float(sprite_sheet.get_height()):
		frame_height = maxf(float(sprite_sheet.get_height()) - y, 1.0)
	if y >= float(sprite_sheet.get_height()):
		return

	frames.add_animation(String(animation_name))
	frames.set_animation_speed(String(animation_name), _animation_speed(animation_name))
	frames.set_animation_loop(String(animation_name), _animation_should_loop(animation_name))

	var sheet_image := sprite_sheet.get_image()
	for index in range(frame_count):
		var x := x_start + float(start_column + index) * frame_step
		if x >= float(sprite_sheet.get_width()):
			break
		var clipped_width := minf(frame_width, float(sprite_sheet.get_width()) - x)
		if clipped_width <= 0.0:
			continue
		var frame_texture := _create_clean_frame_texture(sheet_image, Rect2i(roundi(x), roundi(y), roundi(clipped_width), roundi(frame_height)))
		if frame_texture != null:
			frames.add_frame(String(animation_name), frame_texture)

	if frames.get_frame_count(String(animation_name)) == 0:
		frames.remove_animation(String(animation_name))


func _add_enemy_animations(frames: SpriteFrames, sprite_sheet: Texture2D, character_data: Resource) -> void:
	var clips: Dictionary = character_data.get("sprite_animation_clips")
	if not clips.is_empty():
		_add_clip_animations(frames, sprite_sheet, clips, true)
		return

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
		if not frames.has_animation(String(source_name)):
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
	var origin: Vector2 = definition.get("sprite_frame_origin")
	var step: Vector2 = definition.get("sprite_frame_step")
	if origin.x >= 0.0 or origin.y >= 0.0 or step.x > 0.0 or step.y > 0.0:
		return 1.0
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
		&"jump_start", &"jump_air", &"jump_land", &"jump_up", &"jump_fall", &"fall", &"landing", &"land":
			fallbacks = [&"jump", &"idle"]
		&"crouch_idle":
			fallbacks = [&"crouch", &"idle"]
		&"crouch_guard":
			fallbacks = [&"guard", &"crouch", &"idle"]
		&"punch_1", &"punch_2", &"crouch_punch":
			fallbacks = [&"punch", &"idle"]
		&"jump_punch", &"jump_punch_down":
			fallbacks = [&"jump_punch_down", &"punch", &"jump", &"idle"]
		&"kick_1", &"kick_2", &"jump_kick", &"combo_finisher":
			fallbacks = [&"kick", &"punch", &"idle"]
		&"crouch_kick", &"crouch_kick_sweep":
			fallbacks = [&"crouch_kick_sweep", &"kick", &"crouch", &"idle"]
		&"damage_light", &"damage_heavy", &"guard_hit", &"knockback":
			fallbacks = [&"damage_light", &"damage_heavy", &"damage", &"idle"]
		&"knockdown":
			fallbacks = [&"down", &"damage_heavy", &"damage_light", &"idle"]
		&"getup", &"get_up", &"stand_up":
			fallbacks = [&"stand_up", &"idle"]
		&"throw_start", &"throw_hold", &"throw_release":
			fallbacks = [&"throw", &"special", &"punch", &"idle"]
		&"thrown", &"grabbed":
			fallbacks = [&"damage_heavy", &"damage_light", &"down", &"idle"]
		&"ko", &"defeat":
			fallbacks = [&"ko", &"down", &"damage_heavy", &"damage_light", &"idle"]
		&"special_01", &"special_02", &"ultimate_startup", &"ultimate_attack", &"ultimate_recovery":
			fallbacks = [&"special", &"kick", &"punch", &"idle"]
		_:
			fallbacks = [&"idle"]
	for fallback in fallbacks:
		if has_animation(fallback):
			return fallback
	_warn_missing_animation(animation_name)
	return &""


func _warn_missing_animation(animation_name: StringName) -> void:
	var warning_key := "%s:%s" % [_fighter_id(), String(animation_name)]
	if missing_animation_warnings.has(warning_key):
		return
	missing_animation_warnings[warning_key] = true
	push_warning("[CharacterVisual] %s: animation \"%s\" not found. Using idle from sprite sheet." % [_fighter_id(), String(animation_name)])


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
	if definition != null:
		var speeds: Dictionary = definition.get("sprite_animation_speeds")
		if speeds.has(String(animation_name)):
			return float(speeds[String(animation_name)])
		if speeds.has(animation_name):
			return float(speeds[animation_name])
	match animation_name:
		&"idle", &"guard", &"crouch_guard", &"crouch", &"crouch_idle", &"victory":
			return 6.0
		&"walk", &"walk_forward", &"walk_backward", &"jump_start", &"jump_up", &"jump_fall", &"landing":
			return 10.0
		&"dash":
			return 12.0
		&"punch", &"punch_1", &"punch_2", &"jump_punch_down", &"kick", &"kick_1", &"kick_2", &"crouch_kick_sweep", &"special":
			return 14.0
		&"damage", &"damage_light", &"damage_heavy", &"guard_hit", &"knockback":
			return 12.0
		&"down", &"knockdown", &"getup", &"ko", &"defeat":
			return 8.0
		&"stand_up", &"get_up":
			return 10.0
		_:
			return 8.0


func _animation_should_loop(animation_name: StringName) -> bool:
	return animation_name == &"idle" or animation_name == &"walk" or animation_name == &"walk_forward" or animation_name == &"walk_backward" or animation_name == &"dash" or animation_name == &"crouch" or animation_name == &"crouch_idle" or animation_name == &"crouch_guard" or animation_name == &"guard" or animation_name == &"victory"


func _fighter_id() -> String:
	if definition == null:
		return "unknown"
	return String(definition.get("fighter_id"))
