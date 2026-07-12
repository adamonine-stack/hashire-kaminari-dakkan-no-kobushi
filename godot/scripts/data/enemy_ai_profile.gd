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

@export_group("AI Distance")
@export var preferred_distance: float = 60.0
@export var attack_distance: float = 55.0
@export var retreat_distance: float = 35.0
@export var distance_random_range: float = 8.0

@export_group("AI Behavior")
@export_range(0.0, 1.0, 0.01) var aggression_rate: float = 0.60
@export_range(0.0, 1.0, 0.01) var guard_rate: float = 0.20
@export_range(0.0, 1.0, 0.01) var retreat_rate: float = 0.20
@export_range(0.0, 1.0, 0.01) var combo_rate: float = 0.20
@export_range(0.0, 1.0, 0.01) var feint_rate: float = 0.00
@export_range(0.0, 1.0, 0.01) var special_attack_rate: float = 0.00

@export_group("AI Timing")
@export var reaction_time_min: float = 0.20
@export var reaction_time_max: float = 0.45
@export var idle_time_min: float = 0.25
@export var idle_time_max: float = 0.65
@export var attack_cooldown_min: float = 0.30
@export var attack_cooldown_max: float = 0.60
@export var guard_time_min: float = 0.30
@export var guard_time_max: float = 0.75
@export var retreat_time_min: float = 0.35
@export var retreat_time_max: float = 0.80
@export var feint_cooldown_min: float = 2.0
@export var feint_cooldown_max: float = 4.0

@export_group("AI Movement")
@export var ai_move_speed_multiplier: float = 1.0
@export var approach_speed_multiplier: float = 1.0
@export var retreat_speed_multiplier: float = 0.9

@export_group("AI Options")
@export var can_guard: bool = true
@export var can_retreat: bool = true
@export var can_combo: bool = false
@export var can_feint: bool = false
@export var can_request_special_attack: bool = false
