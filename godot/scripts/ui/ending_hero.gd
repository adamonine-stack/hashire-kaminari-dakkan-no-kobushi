extends Node2D

const HEAD_SHADER := preload("res://scripts/characters/seiya_head.gdshader")

# Only the two static authored poses used by the Stage 8 dialogue.
# Keep the display interface without instantiating combat or loading its atlases.
var visual_root := Node2D.new()
var animated_character_sprite := AnimatedSprite2D.new()
var character_visual_controller: Node2D = self
var poses: Dictionary = {}

func setup(hero_id: String) -> void:
	poses = JSON.parse_string(FileAccess.get_file_as_string("res://assets/endings/cast/poses.json"))[hero_id]
	add_child(visual_root)
	visual_root.add_child(animated_character_sprite)
	animated_character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for clip in poses:
		frames.add_animation(clip)
		frames.add_frame(clip, load("res://assets/endings/cast/%s_%s.png" % [hero_id, clip]))
	animated_character_sprite.sprite_frames = frames
	play_animation(&"idle_prebattle", true)

func play_animation(clip: StringName, _force := false) -> void:
	var pose: Dictionary = poses[String(clip)]
	animated_character_sprite.animation = clip
	animated_character_sprite.frame = 0
	animated_character_sprite.scale = Vector2(pose.scale[0], pose.scale[1])
	animated_character_sprite.position = Vector2(pose.position[0], pose.position[1])
	if pose.has("head"):
		var head: Dictionary = pose.head
		var material := ShaderMaterial.new()
		material.shader = HEAD_SHADER
		var texture := animated_character_sprite.sprite_frames.get_frame_texture(clip, 0)
		material.set_shader_parameter("atlas_size", texture.get_size())
		material.set_shader_parameter("cell_rect", Vector4(0, 0, texture.get_width(), texture.get_height()))
		material.set_shader_parameter("head_rect", Vector4(head.rect[0], head.rect[1], head.rect[2], head.rect[3]))
		material.set_shader_parameter("head_anchor", Vector2(head.anchor[0], head.anchor[1]))
		material.set_shader_parameter("neck_direction", Vector2(head.neck[0], head.neck[1]))
		material.set_shader_parameter("head_scale", head.scale)
		animated_character_sprite.material = material
	animated_character_sprite.stop()
