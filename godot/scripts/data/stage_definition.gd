extends Resource
class_name StageDefinition

@export_range(1, 9, 1) var stage_number: int = 1
@export var stage_name: String = ""
@export var enemy_definition: Resource
@export_multiline var intro_text: String = ""
@export_multiline var player_dialogue: String = ""
@export_multiline var enemy_dialogue: String = ""
@export var player_dialogues: Dictionary = {}
@export var enemy_dialogues: Dictionary = {}
@export var backdrop_id: StringName = &"industrial"
@export var bgm_id: StringName = &"battle"
@export var player_start_position: Vector2 = Vector2(320.0, 520.0)
@export var enemy_start_position: Vector2 = Vector2(960.0, 520.0)
@export var camera_position: Vector2 = Vector2(640.0, 360.0)
@export var is_boss_stage: bool = false
@export var is_secret_boss_stage: bool = false
