extends Resource
class_name FighterMotionAtlas

## Authored, fixed-scale cells. Never fit a pose to its bounding box.
@export var texture: Texture2D
@export var cell_size := Vector2i(320, 224)
@export var columns: int = 4
@export var clips: Dictionary = {}
