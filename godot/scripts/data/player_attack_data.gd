extends Resource
class_name PlayerAttackData

@export var attack_id: String = ""
@export var display_name: String = ""
@export var attack_type: String = "punch"

@export_group("Damage")
@export var base_damage: float = 1.0

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

@export_group("Knockback")
@export var knockback: Vector2 = Vector2(180.0, -40.0)

@export_group("Hit Reaction")
@export var hitstop_time: float = 0.05
@export var hitstun_time: float = 0.20

@export_group("Combo")
@export var next_attack_ids: Array[String] = []
@export var can_cancel_on_hit: bool = true
@export var can_cancel_on_whiff: bool = false

@export_group("Animation")
@export var animation_name: String = ""
