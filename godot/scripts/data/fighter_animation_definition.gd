extends Resource
class_name FighterAnimationDefinition

@export var animation_name: StringName
@export var texture: Texture2D
@export var cell_size: Vector2i = Vector2i(320, 480)
@export var frame_count: int = 0
@export var fps: float = 12.0
@export var loop: bool = false
@export var body_height_px: float = 0.0
@export var foot_offset: Vector2 = Vector2.ZERO
