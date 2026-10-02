extends Resource
class_name PlayerAttackData

@export var attack_id: String = ""
@export var display_name: String = ""
@export var attack_type: String = "punch"
@export var attack_category: String = "normal"

@export_group("Damage")
@export var base_damage: float = 1.0
@export var damage_multiplier: float = 1.0

@export_group("Timing")
@export var startup_time: float = 0.15
@export var active_time: float = 0.10
@export var recovery_time: float = 0.25
@export var combo_input_start: float = 0.10
@export var combo_input_end: float = 0.30

@export_group("Hitbox")
@export var hitbox_size: Vector2 = Vector2(50.0, 30.0)
@export var hitbox_offset: Vector2 = Vector2(35.0, 0.0)

@export_group("Movement")
@export var forward_move_distance: float = 0.0
@export var forward_move_duration: float = 0.0
@export var move_distance: float = 0.0
@export var move_duration: float = 0.0
@export var move_speed_multiplier: float = 1.0

@export_group("Knockback")
@export var knockback: Vector2 = Vector2(180.0, -40.0)

@export_group("Hit Reaction")
@export var hitstop_time: float = 0.05
@export var hitstun_time: float = 0.20

@export_group("Defense")
@export var is_guardable: bool = true
@export_enum("default", "high", "middle", "low", "overhead", "throw") var attack_height: String = "default"
@export var guard_damage_multiplier: float = 0.0
@export var guard_hit_time: float = 0.15
@export var guard_knockback: Vector2 = Vector2(80.0, 0.0)

@export_group("Control")
@export var can_be_interrupted: bool = true
@export var interruptible_until_active: bool = true
@export var cooldown: float = 4.0

@export_group("Combo")
@export var next_attack_ids: Array[String] = []
@export var can_cancel_on_hit: bool = true
@export var can_cancel_on_whiff: bool = false

@export_group("Animation")
@export var animation_name: String = ""
@export var warning_effect_name: String = ""
@export var attack_effect_name: String = ""

@export_group("Special Reversal")
@export var is_special: bool = false
@export var can_interrupt_attack: bool = false
@export var can_break_combo: bool = false
@export var can_use_during_hitstun: bool = false
@export var startup_invulnerability: float = 0.0
@export var armor_frames: int = 0
@export var special_hit_reaction: StringName = &"special_hit"
@export var special_knockback_reaction: StringName = &"special_knockback"
@export var special_knockdown_reaction: StringName = &"special_knockdown"
@export var special_guard_reaction: StringName = &"special_guard"
@export var special_startup_animation: StringName = &"special_startup"
@export var special_finish_animation: StringName = &"special_recovery"
@export var wall_slam := false
@export var special_launch_speed_cap := Vector2.ZERO
@export var backflip_on_launch := false
@export var special_launch_gravity := 0.0
@export var effect_scene: PackedScene
@export var hit_effect_scene: PackedScene
@export var camera_shake: float = 3.0
@export var special_resource_cost: float = -1.0
@export var whiff_recovery_multiplier: float = 1.25
@export var ai_special_tags: Array[String] = []
