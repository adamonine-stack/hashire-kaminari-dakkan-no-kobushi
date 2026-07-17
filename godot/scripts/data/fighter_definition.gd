extends Resource
class_name FighterDefinition

@export var fighter_id: StringName
@export var display_name: String
@export_multiline var description: String

@export var fighter_scene: PackedScene
@export var selection_portrait: Texture2D
@export var selection_icon: Texture2D

@export_group("Official Art Assets")
@export var portrait: Texture2D
@export var battle_texture: Texture2D
@export var icon: Texture2D
@export var sprite_sheet: Texture2D
@export var shadow_texture: Texture2D
@export var art_folder: String = ""
@export var battle_sprite_height: float = 150.0
@export var battle_sprite_offset: Vector2 = Vector2(0.0, 0.0)
@export var sprite_sheet_format: StringName = &"legacy"
@export var sprite_frame_size: Vector2i = Vector2i(96, 96)
@export var sprite_sheet_columns: int = 16
@export var sprite_animation_rows: Dictionary = {}
@export var sprite_animation_frame_counts: Dictionary = {}
@export var sprite_animation_speeds: Dictionary = {}
@export var sprite_animation_clips: Dictionary = {}
@export_group("Sprite Sheet Layout")
@export var sprite_frame_origin: Vector2 = Vector2(-1.0, -1.0)
@export var sprite_frame_step: Vector2 = Vector2(-1.0, -1.0)
@export var sprite_row_height: float = -1.0
@export var sprite_max_frames_per_animation: int = 8
@export var sprite_cleanup_background: bool = true
@export_range(0.0, 1.0, 0.01) var sprite_background_brightness_limit: float = 0.62
@export_range(0.0, 1.0, 0.01) var sprite_background_color_tolerance: float = 0.24

@export var fighter_type: StringName
@export var team_type: StringName = &"ALLY"
@export var enemy_order: int = 0
@export var ai_profile: Resource
@export var intro_title: String
@export_multiline var intro_description: String
@export var temporary_color: Color = Color.WHITE

@export var max_health: float = 100.0
@export var move_speed: float = 300.0
@export var air_move_speed: float = 300.0
@export var jump_force: float = 500.0

@export_group("Direct Character Stats")
@export var punch_damage: float = 0.0
@export var kick_damage: float = 0.0
@export var punch_startup_multiplier: float = 1.0
@export var kick_startup_multiplier: float = 1.0
@export var punch_recovery_multiplier: float = 1.0
@export var kick_recovery_multiplier: float = 1.0
@export var guard_damage_multiplier: float = 0.25
@export var guard_stamina_multiplier: float = 1.0
@export var attack_knockback_multiplier: float = 1.0
@export var received_knockback_multiplier: float = 1.0
@export var attack_sequence: Array[Resource] = []
@export var air_kick_attack: Resource
@export var max_attack_chain_count: int = 0
@export var special_attack_sequence: Array[Resource] = []

@export_group("Character Special")
@export var max_special_gauge: float = 100.0
@export var special_gauge_cost: float = 100.0
@export var special_ai_use_chance: float = 0.35
@export var special_has_armor: bool = false

@export_group("Legacy Scales")
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
