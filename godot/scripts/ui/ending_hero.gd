extends Node2D

const HEAD_SHADER := preload("res://scripts/characters/seiya_head.gdshader")

# Only authored poses/frames selected for the current ending.
# Keep the display interface without instantiating combat or loading its atlases.
var visual_root := Node2D.new()
var animated_character_sprite := AnimatedSprite2D.new()
var character_visual_controller: Node2D = self
var poses: Dictionary = {}
var input_enabled := false
var ai_enabled := false
var is_round_active := false
var _pose_material: ShaderMaterial

func setup(hero_id: String, manifest_path := "res://assets/endings/cast/poses.json") -> void:
	poses = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))[hero_id]
	add_child(visual_root)
	visual_root.add_child(animated_character_sprite)
	animated_character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for clip in poses:
		frames.add_animation(clip)
		var pose: Dictionary = poses[clip]
		if pose.has("frames"):
			frames.set_animation_speed(clip, float(pose.fps))
			frames.set_animation_loop(clip, bool(pose.loop))
			for frame in pose.frames:
				frames.add_frame(clip, load(manifest_path.get_base_dir().path_join(frame.file)), float(frame.duration))
		else:
			frames.add_frame(clip, load("res://assets/endings/cast/%s_%s.png" % [hero_id, clip]))
	animated_character_sprite.sprite_frames = frames
	animated_character_sprite.frame_changed.connect(_apply_pose)
	play_animation(&"idle_prebattle" if poses.has("idle_prebattle") else StringName(poses.keys()[0]), true)

func play_animation(clip: StringName, _force := false) -> void:
	animated_character_sprite.animation = clip
	animated_character_sprite.frame = 0
	_apply_pose()
	animated_character_sprite.stop()

func _apply_pose() -> void:
	var clip := animated_character_sprite.animation
	if not poses.has(String(clip)): return
	var pose: Dictionary = poses[String(clip)]
	if pose.has("frames"): pose = pose.frames[animated_character_sprite.frame]
	animated_character_sprite.scale = Vector2(pose.scale[0], pose.scale[1])
	animated_character_sprite.position = Vector2(pose.position[0], pose.position[1])
	if pose.has("head"):
		var head: Dictionary = pose.head
		if _pose_material == null:
			_pose_material = ShaderMaterial.new()
			_pose_material.shader = HEAD_SHADER
		var material := _pose_material
		var texture := animated_character_sprite.sprite_frames.get_frame_texture(clip, animated_character_sprite.frame)
		material.set_shader_parameter("atlas_size", texture.get_size())
		material.set_shader_parameter("cell_rect", Vector4(0, 0, texture.get_width(), texture.get_height()))
		material.set_shader_parameter("head_rect", Vector4(head.rect[0], head.rect[1], head.rect[2], head.rect[3]))
		material.set_shader_parameter("head_anchor", Vector2(head.anchor[0], head.anchor[1]))
		material.set_shader_parameter("neck_direction", Vector2(head.neck[0], head.neck[1]))
		material.set_shader_parameter("head_scale", head.scale)
		animated_character_sprite.material = material
	else:
		animated_character_sprite.material = null
