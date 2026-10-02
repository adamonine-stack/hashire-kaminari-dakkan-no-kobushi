extends Resource
class_name FighterMotionAtlas

## Authored, fixed-scale cells. Never fit a pose to its bounding box.
@export var texture: Texture2D
@export var embedded_texture_format: StringName = &""
@export var embedded_texture_chunks: Array[Resource] = []
@export var embedded_texture_chunk_0: Resource
@export var embedded_texture_chunk_1: Resource
@export var embedded_texture_chunk_2: Resource
@export var embedded_texture_chunk_3: Resource
@export var embedded_texture_chunk_4: Resource
@export var embedded_texture_chunk_5: Resource
@export var embedded_texture_chunk_6: Resource
@export var embedded_texture_chunk_7: Resource
@export var cell_size := Vector2i(320, 224)
@export var columns: int = 4
@export var clips: Dictionary = {}
## Nonuniform source sheets must use measured rectangles, not width / columns.
## Complete source poses are packed into common display cells at load time.
@export var frame_regions: Array[Rect2i] = []
@export var frame_offsets: Array[Vector2i] = []
@export var frame_source_scales: PackedFloat32Array = []
