extends "res://scripts/player/player_knockdown_movement.gd"

var fighter_definition: Resource
var base_max_hp := 100
var base_move_speed := 300.0
var base_jump_power := 500.0
var base_punch_damage := 5
var base_kick_damage := 8
var base_throw_damage := 15
var base_punch_knockback_x := 180.0
var base_punch_knockback_y := 160.0
var base_kick_knockback_x := 280.0
var base_kick_knockback_y := 260.0
var base_attack_cooldown_time := 0.35
var base_kick_cooldown_time := 0.5
var base_guard_damage_rate := 0.25
var base_second_hit_damage_scale := 0.90
var base_third_hit_damage_scale := 0.80


func _ready() -> void:
	_capture_base_stats()
	super._ready()


func apply_fighter_definition(definition: Resource) -> void:
	fighter_definition = definition
	if fighter_definition == null:
		_restore_base_stats()
		return

	max_hp = int(round(fighter_definition.max_health))
	move_speed = fighter_definition.move_speed
	jump_power = fighter_definition.jump_force
	punch_damage = maxi(1, int(round(float(base_punch_damage) * fighter_definition.punch_damage_scale)))
	kick_damage = maxi(1, int(round(float(base_kick_damage) * fighter_definition.kick_damage_scale)))
	throw_damage = maxi(1, int(round(float(base_throw_damage) * fighter_definition.throw_damage_scale)))
	punch_knockback_x = base_punch_knockback_x * fighter_definition.knockback_scale
	punch_knockback_y = base_punch_knockback_y * fighter_definition.knockback_scale
	kick_knockback_x = base_kick_knockback_x * fighter_definition.knockback_scale
	kick_knockback_y = base_kick_knockback_y * fighter_definition.knockback_scale
	attack_cooldown_time = base_attack_cooldown_time / maxf(fighter_definition.attack_speed_scale, 0.1)
	kick_cooldown_time = base_kick_cooldown_time / maxf(fighter_definition.attack_speed_scale, 0.1)
	guard_damage_rate = base_guard_damage_rate * fighter_definition.guard_damage_scale
	second_hit_damage_scale = base_second_hit_damage_scale * fighter_definition.combo_damage_scale
	third_hit_damage_scale = base_third_hit_damage_scale * fighter_definition.combo_damage_scale
	dev026_second_hit_damage_scale = second_hit_damage_scale
	dev026_third_hit_damage_scale = third_hit_damage_scale
	current_hp = clampi(current_hp, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)


func set_health(value: int) -> void:
	current_hp = clampi(value, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)


func _capture_base_stats() -> void:
	base_max_hp = max_hp
	base_move_speed = move_speed
	base_jump_power = jump_power
	base_punch_damage = punch_damage
	base_kick_damage = kick_damage
	base_throw_damage = throw_damage
	base_punch_knockback_x = punch_knockback_x
	base_punch_knockback_y = punch_knockback_y
	base_kick_knockback_x = kick_knockback_x
	base_kick_knockback_y = kick_knockback_y
	base_attack_cooldown_time = attack_cooldown_time
	base_kick_cooldown_time = kick_cooldown_time
	base_guard_damage_rate = guard_damage_rate
	base_second_hit_damage_scale = second_hit_damage_scale
	base_third_hit_damage_scale = third_hit_damage_scale


func _restore_base_stats() -> void:
	max_hp = base_max_hp
	move_speed = base_move_speed
	jump_power = base_jump_power
	punch_damage = base_punch_damage
	kick_damage = base_kick_damage
	throw_damage = base_throw_damage
	punch_knockback_x = base_punch_knockback_x
	punch_knockback_y = base_punch_knockback_y
	kick_knockback_x = base_kick_knockback_x
	kick_knockback_y = base_kick_knockback_y
	attack_cooldown_time = base_attack_cooldown_time
	kick_cooldown_time = base_kick_cooldown_time
	guard_damage_rate = base_guard_damage_rate
	second_hit_damage_scale = base_second_hit_damage_scale
	third_hit_damage_scale = base_third_hit_damage_scale
	dev026_second_hit_damage_scale = base_second_hit_damage_scale
	dev026_third_hit_damage_scale = base_third_hit_damage_scale
