extends Resource
class_name FighterDefinition

@export var fighter_id: StringName
@export var display_name: String
@export_multiline var description: String

@export var fighter_scene: PackedScene
@export var selection_portrait: Texture2D
@export var selection_icon: Texture2D

@export var fighter_type: StringName
@export var team_type: StringName = &"ALLY"
@export var enemy_order: int = 0
@export var ai_profile: Resource
@export var intro_title: String
@export_multiline var intro_description: String
@export var temporary_color: Color = Color.WHITE

@export var max_health: float = 100.0
@export var move_speed: float = 300.0
@export var jump_force: float = 500.0

@export var punch_damage_scale: float = 1.0
@export var kick_damage_scale: float = 1.0
@export var throw_damage_scale: float = 1.0

@export var knockback_scale: float = 1.0
@export var attack_speed_scale: float = 1.0

@export var combo_damage_scale: float = 1.0
@export var guard_damage_scale: float = 1.0

@export_range(1, 5) var power_rating: int = 3
@export_range(1, 5) var speed_rating: int = 3
@export_range(1, 5) var health_rating: int = 3
@export_range(1, 5) var throw_rating: int = 3
@export_range(1, 5) var combo_rating: int = 3
