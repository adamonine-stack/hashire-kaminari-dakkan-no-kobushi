extends Resource
class_name PlayerAttackData

## Up + attack launches from the ground and also works during an existing jump.
@export var jump_on_start := false
## Crouching attacks preserve their low stance until recovery ends.
@export var crouch_on_start := false

@export var attack_id: String = ""
@export var display_name: String = ""
@export var attack_type: String = "punch"
@export var attack_category: String = "normal"

@export_group("Directional Command")
## Empty keeps legacy input routing until a fighter has reviewed move resources.
@export var command_direction: String = ""
@export var command_priority: int = 0
@export var ground_only: bool = true
@export var airborne_only: bool = false
## Seconds from attack start. Negative values preserve the legacy cancel window.
@export var cancel_start: float = -1.0
@export var cancel_end: float = -1.0
@export var cancel_targets: Array[String] = []
## Reviewed contact poses; negative retains the legacy clip phase map.
@export var contact_start_frame: int = -1
@export var contact_end_frame: int = -1
## Temporary collision geometry about the foot anchor; sprite scale stays fixed.
@export var hurtbox_height_scale: float = 1.0
@export var hurtbox_width_scale: float = 1.0
@export var hurtbox_offset: Vector2 = Vector2.ZERO
@export var hurtbox_start: float = 0.0
@export var hurtbox_end: float = 0.0
@export var launch_velocity: Vector2 = Vector2.ZERO
@export var knockdown: bool = false
# Zero keeps the fighter normal-chain limit; explicit routes may have a bounded limit.
@export_range(0, 6) var combo_route_hit_limit: int = 0
@export var hit_reaction: StringName = &""
@export var counter_hitstun_bonus: float = 0.0

@export_group("Air Movement / Landing")
## Zero preserves existing air attacks. Applied after startup, never during hitstun.
@export var dive_velocity: Vector2 = Vector2.ZERO
@export var landing_recovery: float = 0.0
@export var landing_animation: StringName = &"jump_land"

@export_group("Situation AI")
@export var ai_tags: Array[String] = []
@export var ai_distance_min: float = 0.0
@export var ai_distance_max: float = 0.0

@export_group("Directional Throw")
@export var throw_hold_seconds: float = 0.20
@export var throw_whiff_seconds: float = 0.50
@export var throw_velocity: Vector2 = Vector2(120.0, -120.0)
@export var throw_face_swapped_target := false
@export var throw_swap_positions: bool = false
@export var throw_counter_range: float = 0.0
@export var throw_counter_window: float = 0.0
@export var throw_down_seconds: float = 0.0
@export var throw_hold_offset: Vector2 = Vector2.ZERO
@export var throw_hold_offsets_by_fighter: Dictionary = {}
@export var throw_prepare_seconds: float = 0.0
@export var throw_start_animation: StringName = &""
@export var throw_hold_animation: StringName = &""
@export var throw_victim_hold_animation: StringName = &""
@export var throw_release_offset: Vector2 = Vector2.ZERO
@export var throw_prepare_animation: StringName = &""
@export var throw_release_animation: StringName = &""
@export var throw_whiff_animation: StringName = &""
@export var throw_victim_prepare_animation: StringName = &""
@export var throw_victim_air_animation: StringName = &""
@export var throw_victim_down_animation: StringName = &""

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
@export var keep_special_flight_in_view := false
@export var special_launch_speed_cap := Vector2.ZERO
@export var backflip_on_launch := false
@export var headfirst_on_launch := false
@export var somersault_on_special := false
@export var somersault_sidekick := false
@export var sidekick_time := 0.72
@export var sidekick_hit_window := 0.16
@export var special_hit_window := 0.0
@export var special_launch_gravity := 0.0
@export var effect_scene: PackedScene
@export var hit_effect_scene: PackedScene
@export var camera_shake: float = 3.0
@export var special_resource_cost: float = -1.0
@export var whiff_recovery_multiplier: float = 1.25
@export var ai_special_tags: Array[String] = []

@export_group("Ground Bounce")
@export_range(0, 1, 1) var ground_bounces := 0
@export var ground_bounce_velocity := Vector2(0, -160)
