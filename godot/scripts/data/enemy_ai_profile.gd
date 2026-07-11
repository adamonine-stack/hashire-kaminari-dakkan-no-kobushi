extends Resource
class_name EnemyAIProfile

@export_range(0.0, 1.0, 0.01) var punch_weight: float = 0.40
@export_range(0.0, 1.0, 0.01) var kick_weight: float = 0.25
@export_range(0.0, 1.0, 0.01) var throw_weight: float = 0.10
@export_range(0.0, 1.0, 0.01) var guard_weight: float = 0.15
@export_range(0.0, 1.0, 0.01) var movement_weight: float = 0.10

@export_range(0.0, 1.0, 0.05) var second_hit_probability: float = 0.30
@export_range(0.0, 1.0, 0.05) var third_hit_probability: float = 0.10
@export_range(0.0, 1.0, 0.05) var throw_escape_probability: float = 0.25

@export var decision_interval_min: float = 0.30
@export var decision_interval_max: float = 0.70
@export var preferred_distance_min: float = 45.0
@export var preferred_distance_max: float = 110.0
@export var guard_duration_min: float = 0.30
@export var guard_duration_max: float = 0.80
@export var throw_cooldown: float = 1.50
@export var action_recovery_min: float = 0.15
@export var action_recovery_max: float = 0.45
