extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal hp_depleted
signal screen_shake_requested(strength: float)
signal throw_hit(target: Node)
signal combo_changed(combo_count: int, combo_owner: Node)

@export var move_speed := 300.0
@export var air_move_speed := 300.0
@export var crouch_speed := 120.0
@export var jump_power := 500.0
@export var screen_margin := 36.0
@export var attack_active_time := 0.12
@export var attack_cooldown_time := 0.35
@export var attack_offset := 56.0
@export var kick_active_time := 0.18
@export var kick_cooldown_time := 0.5
@export var kick_offset := 72.0
@export var max_hp := 100
@export var punch_damage := 5
@export var kick_damage := 8
@export var punch_knockback_x := 180.0
@export var punch_knockback_y := 160.0
@export var kick_knockback_x := 280.0
@export var kick_knockback_y := 260.0
@export var hit_reaction_time := 0.25
@export var invincibility_time := 0.3
@export var input_enabled := true
@export var can_guard := true
@export var guard_damage_rate := 0.25
@export var guard_hit_time := 0.15
@export var guard_knockback_x := 80.0
@export var guard_hit_stop_time := 0.03
@export var throw_range := 55.0
@export var throw_body_width := 72.0
@export var throw_damage := 15
@export var throw_knockback := 320.0
@export var throw_vertical_force := -120.0
@export var throw_startup_time := 0.15
@export var throw_hold_time := 0.2
@export var throw_recovery_time := 0.35
@export var throw_whiff_recovery_time := 0.5
@export var throw_escape_window := 0.12
@export var throw_escape_pushback := 80.0
@export var throw_escape_recovery_time := 0.25
@export var throw_vertical_tolerance := 40.0
@export_range(0.0, 1.0, 0.05) var throw_escape_probability := 0.25
@export_range(0.0, 1.0, 0.05) var ai_throw_probability := 0.2
@export var ai_throw_cooldown := 1.5
@export var ai_throw_check_interval := 0.4
@export var combo_timeout := 1.0
@export var combo_input_buffer_time := 0.20
@export var combo_continue_window := 0.25
@export var combo_reset_time := 0.80
@export var max_combo_hits: int = 3
@export var minimum_combo_damage := 1.0
@export var combo_hitstun_time := 0.30
@export_range(0.0, 1.0, 0.05) var second_hit_damage_scale := 0.90
@export_range(0.0, 1.0, 0.05) var third_hit_damage_scale := 0.80
@export_range(0.0, 1.0, 0.05) var first_combo_knockback_scale := 0.50
@export_range(0.0, 1.0, 0.05) var second_combo_knockback_scale := 0.65
@export_range(0.0, 1.0, 0.05) var ai_combo_continue_probability := 0.45
@export_range(0.0, 1.0, 0.05) var ai_third_hit_probability := 0.25
@export var combo_log_enabled := true
@export var cancel_window_time := 0.25
@export var debug_state_label_enabled := true
@export var ai_guard_enabled := true
@export var ai_guard_chance := 0.25
@export var ai_guard_check_interval := 0.35
@export var ai_guard_min_time := 0.3
@export var ai_guard_max_time := 1.0

var punch_startup_multiplier := 1.0
var kick_startup_multiplier := 1.0
var punch_recovery_multiplier := 1.0
var kick_recovery_multiplier := 1.0
var guard_stamina_multiplier := 1.0
var attack_knockback_multiplier := 1.0
var received_knockback_multiplier := 1.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_hp := 100
var facing_direction := 1.0
var attack_active_timer := 0.0
var attack_cooldown_timer := 0.0
var kick_active_timer := 0.0
var kick_cooldown_timer := 0.0
var is_guarding := false
var is_crouching := false
var is_crouch_guarding := false
var guard_type := "none"
var punch_hitbox_active := false
var kick_hitbox_active := false
var punch_hit_targets: Array[Node] = []
var kick_hit_targets: Array[Node] = []
var is_hit := false
var is_invincible := false
var is_guard_hit := false
var is_throwing := false
var is_throw_locked := false
var is_throw_escape_pending := false
var is_throw_escaping := false
var is_round_active := false
var hit_reaction_timer := 0.0
var invincibility_timer := 0.0
var hit_stop_timer := 0.0
var guard_hit_timer := 0.0
var throw_startup_timer := 0.0
var throw_hold_timer := 0.0
var throw_recovery_timer := 0.0
var throw_escape_timer := 0.0
var pending_throw_damage := 0
var pending_throw_hit_position := Vector2.ZERO
var pending_throw_direction := 0.0
var pending_throw_velocity := Vector2.ZERO
var pending_throw_attacker: Node
var pending_throw_ai_checked := false
var throw_state := ""
var current_throw_target: Node
var has_throw_connected := false
var has_throw_damage_applied := false
var combo_count := 0
var current_combo_hits := 0
var combo_timer := 0.0
var combo_window_open := false
var buffered_attack: StringName = &""
var attack_buffer_timer := 0.0
var last_attack_type: StringName = &""
var combo_target: Node
var current_attack_connected := false
var combo_step := 0
var can_cancel := false
var cancel_window_timer := 0.0
var current_attack_type := ""
var ai_guard_check_timer := 0.0
var ai_guard_timer := 0.0
var ai_throw_check_timer := 0.0
var ai_throw_cooldown_timer := 0.0
var weak_hit_se: AudioStreamPlayer2D
var strong_hit_se: AudioStreamPlayer2D
var guard_hit_se: AudioStreamPlayer2D
var throw_se: AudioStreamPlayer2D
var throw_escape_se: AudioStreamPlayer2D

@onready var visual_root := $VisualRoot
@onready var state_label := $VisualRoot/IdlePlaceholder/IdleStateLabel
@onready var guard_visual := $VisualRoot/IdlePlaceholder/GuardPlaceholder
@onready var crouch_visual := $VisualRoot/IdlePlaceholder/CrouchPlaceholder
@onready var crouch_guard_visual := $VisualRoot/IdlePlaceholder/CrouchGuardPlaceholder
@onready var punch_area := $PunchHitBox
@onready var punch_shape := $PunchHitBox/CollisionShape2D
@onready var kick_area := $KickHitBox
@onready var kick_shape := $KickHitBox/CollisionShape2D
@onready var hurt_box := $HurtBox
@onready var animation_player := get_node_or_null("AnimationPlayer") as AnimationPlayer


func _ready() -> void:
	current_hp = max_hp
	punch_area.area_entered.connect(_on_punch_hitbox_area_entered)
	kick_area.area_entered.connect(_on_kick_hitbox_area_entered)
	_setup_hit_audio()
	_set_punch_hitbox_active(false, false)
	_set_kick_hitbox_active(false, false)
	hp_changed.emit(current_hp, max_hp)


func _physics_process(delta: float) -> void:
	if _update_hit_stop(delta):
		return

	var direction := Input.get_axis("move_left", "move_right") if input_enabled else 0.0
	var is_kicking := kick_active_timer > 0.0

	_update_invincibility(delta)
	_update_hit_reaction(delta)
	_update_guard_hit(delta)
	_update_throw_state(delta)
	_update_combo_timer(delta)
	_update_cancel_window(delta)
	_update_attack_buffer(delta)
	_update_ai_throw(delta)

	if input_enabled and not is_hit and not is_guard_hit and not _is_throw_busy():
		_update_defensive_state()
	elif _uses_ai_guard():
		_update_ai_guard(delta)

	if is_kicking or is_crouching or is_crouch_guarding or is_hit or _is_throw_busy():
		direction = 0.0

	if direction != 0.0 and not is_hit and not _is_throw_busy():
		facing_direction = signf(direction)
		visual_root.scale.x = facing_direction

	if not is_hit and not _is_throw_busy():
		velocity.x = direction * get_current_move_speed()

	if is_on_floor():
		if input_enabled and current_attack_type == "" and Input.is_action_just_pressed("jump") and not is_crouching and not is_kicking and not is_guarding and not is_crouch_guarding and not is_hit and not is_guard_hit and not _is_throw_busy():
			velocity.y = -jump_power
		elif not is_hit:
			velocity.y = 0.0
	else:
		velocity.y += gravity * delta

	if input_enabled and _is_throw_input_pressed() and _can_start_throw():
		_start_throw()
	var did_cancel_attack := _try_cancel_attack_from_input()
	if input_enabled and not did_cancel_attack and current_attack_type == "" and not is_kicking and not is_guarding and not is_crouching and not is_crouch_guarding and not is_hit and not is_guard_hit and not _is_throw_busy() and not _is_throw_input_held() and Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0.0:
		_start_attack()
	if input_enabled and not did_cancel_attack and current_attack_type == "" and not is_guarding and not is_crouching and not is_crouch_guarding and not is_hit and not is_guard_hit and not _is_throw_busy() and not _is_throw_input_held() and Input.is_action_just_pressed("kick") and kick_cooldown_timer <= 0.0 and attack_active_timer <= 0.0:
		_start_kick()

	if not is_hit and not is_guard_hit and not _is_throw_busy():
		_update_attack(delta)
		_update_kick(delta)
	_update_visual_state()
	move_and_slide()

	if is_guard_hit and is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)

	var viewport_width := get_viewport_rect().size.x
	position.x = clampf(position.x, screen_margin, viewport_width - screen_margin)


func _start_attack(is_combo_attack := false) -> void:
	if not is_combo_attack:
		combo_step = 1
		last_attack_type = &""
	else:
		combo_step = mini(combo_count + 1, max_combo_hits)
	current_attack_type = "Punch"
	current_attack_connected = false
	attack_active_timer = get_attack_active_time()
	attack_cooldown_timer = get_attack_cooldown_time()
	punch_hit_targets.clear()
	punch_area.position.x = facing_direction * attack_offset
	_play_attack_animation(_get_attack_animation_name(&"Punch"))
	_set_punch_hitbox_active(true)


func _update_defensive_state() -> void:
	var down_pressed := Input.is_action_pressed("down")
	var guard_pressed := Input.is_action_pressed("guard")

	if not _can_start_guard_or_crouch():
		_clear_guard_state()
		if not is_on_floor():
			is_crouching = false
		return

	if guard_pressed:
		is_guarding = true
		is_crouch_guarding = down_pressed
		is_crouching = false
		guard_type = "crouch" if down_pressed else "stand"
		return

	_clear_guard_state()
	is_crouching = down_pressed and is_on_floor()
	if is_crouching:
		velocity.x = 0.0


func _start_kick(is_combo_attack := false) -> void:
	print("Kick Start")
	if not is_combo_attack:
		combo_step = 1
		last_attack_type = &""
	else:
		combo_step = mini(combo_count + 1, max_combo_hits)
	current_attack_type = "Kick"
	current_attack_connected = false
	kick_active_timer = get_kick_active_time()
	kick_cooldown_timer = get_kick_cooldown_time()
	velocity.x = 0.0
	kick_hit_targets.clear()
	kick_area.position.x = facing_direction * kick_offset
	_play_attack_animation(_get_attack_animation_name(&"Kick"))
	_set_kick_hitbox_active(true)


func _start_throw() -> void:
	interrupt_combo()
	is_throwing = true
	throw_state = "THROW_STARTUP"
	throw_startup_timer = throw_startup_time
	throw_hold_timer = 0.0
	throw_recovery_timer = 0.0
	velocity = Vector2.ZERO
	_clear_guard_state()
	is_crouching = false
	current_attack_type = ""
	has_throw_connected = false
	has_throw_damage_applied = false
	current_throw_target = null
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)
	_play_throw_animation("throw_start")
	print("THROW STARTUP")


func receive_throw(attacker: Node, damage: int, hit_position: Vector2, throw_direction: float, throw_velocity: Vector2) -> void:
	if not can_be_thrown(attacker):
		return

	interrupt_combo()
	attack_active_timer = 0.0
	kick_active_timer = 0.0
	_clear_guard_state()
	is_crouching = false
	is_guard_hit = false
	is_hit = false
	is_throwing = false
	is_throw_locked = true
	is_throw_escape_pending = true
	is_throw_escaping = false
	throw_state = "THROWN"
	throw_startup_timer = 0.0
	throw_hold_timer = 0.0
	throw_recovery_timer = 0.0
	throw_escape_timer = throw_escape_window
	pending_throw_attacker = attacker
	pending_throw_damage = damage
	pending_throw_hit_position = hit_position
	pending_throw_direction = throw_direction
	pending_throw_velocity = throw_velocity
	pending_throw_ai_checked = false
	velocity = Vector2.ZERO
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)
	_play_throw_animation("thrown")


func _get_throw_target() -> Node:
	var target := _get_opponent()
	if target == null or not target.has_method("receive_throw"):
		return null
	if _get_throw_gap_to(target) > throw_range:
		return null
	if target is Node2D and absf(target.global_position.y - global_position.y) > throw_vertical_tolerance:
		return null
	if not _is_facing_attacker(target):
		return null
	if not target.can_be_thrown(self):
		return null
	return target


func _can_start_throw() -> bool:
	return is_round_active and current_hp > 0 and is_on_floor() and current_attack_type == "" and not is_hit and not is_guard_hit and not _is_throw_busy() and not is_guarding and not is_crouching and not is_crouch_guarding and attack_active_timer <= 0.0 and kick_active_timer <= 0.0


func can_be_thrown(attacker: Node) -> bool:
	return is_round_active and current_hp > 0 and is_on_floor() and not is_hit and not is_guard_hit and not is_throwing and not is_throw_locked and not is_throw_escape_pending and not is_throw_escaping and not is_invincible


func _get_throw_gap_to(target: Node) -> float:
	return maxf(absf(global_position.x - target.global_position.x) - throw_body_width, 0.0)


func _is_throw_input_pressed() -> bool:
	return Input.is_action_just_pressed("throw_attack")


func _is_throw_input_held() -> bool:
	return Input.is_action_pressed("throw_attack")


func _is_throw_busy() -> bool:
	return is_throwing or is_throw_locked or is_throw_escape_pending or is_throw_escaping


func _update_throw_state(delta: float) -> void:
	if is_throwing:
		_update_active_throw(delta)
		return

	if is_throw_escape_pending:
		_update_throw_escape(delta)
		return

	if is_throw_locked or is_throw_escaping:
		_update_throw_recovery(delta)


func _update_active_throw(delta: float) -> void:
	velocity = Vector2.ZERO

	match throw_state:
		"THROW_STARTUP":
			throw_startup_timer = maxf(throw_startup_timer - delta, 0.0)
			if throw_startup_timer == 0.0:
				var target := _get_throw_target()
				if target == null:
					_fail_throw()
				else:
					_connect_throw(target)
		"THROW_HOLD":
			if not _is_valid_throw_target(current_throw_target):
				_fail_throw()
				return
			_lock_throw_target_position(current_throw_target)
			throw_hold_timer = maxf(throw_hold_timer - delta, 0.0)
			if throw_hold_timer == 0.0:
				_release_throw()
		"THROW_RECOVERY", "THROW_WHIFF", "THROW_ESCAPE":
			throw_recovery_timer = maxf(throw_recovery_timer - delta, 0.0)
			if throw_recovery_timer == 0.0:
				_finish_throw()


func _update_throw_escape(delta: float) -> void:
	if _should_escape_throw():
		_complete_throw_escape()
		return

	throw_escape_timer = maxf(throw_escape_timer - delta, 0.0)


func _should_escape_throw() -> bool:
	if not _can_escape_throw():
		return false
	if input_enabled and _is_throw_input_held():
		return true
	if not input_enabled and not pending_throw_ai_checked:
		pending_throw_ai_checked = true
		return randf() <= throw_escape_probability
	return false


func _can_escape_throw() -> bool:
	return is_throw_escape_pending and throw_escape_timer > 0.0 and current_hp > 0 and not is_hit and not is_guard_hit


func _complete_throw_escape() -> void:
	var attacker := pending_throw_attacker
	is_throw_escape_pending = false
	is_throw_escaping = true
	is_throw_locked = true
	throw_state = "THROW_ESCAPE"
	throw_recovery_timer = throw_escape_recovery_time
	throw_escape_timer = 0.0
	velocity = Vector2.ZERO
	_clear_pending_throw()

	if attacker != null and attacker.has_method("enter_throw_escape_recovery"):
		attacker.enter_throw_escape_recovery(self)

	_push_throw_escape_apart(attacker)
	_spawn_throw_escape_effect(global_position)
	_play_throw_escape_se()


func enter_throw_escape_recovery(escaped_target: Node) -> void:
	interrupt_combo()
	is_throwing = false
	is_throw_locked = true
	is_throw_escaping = true
	throw_state = "THROW_ESCAPE"
	throw_recovery_timer = throw_escape_recovery_time
	current_throw_target = null
	has_throw_connected = false
	has_throw_damage_applied = false
	velocity = Vector2.ZERO
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)


func _complete_throw_hit() -> void:
	var attacker := pending_throw_attacker
	var hit_position := pending_throw_hit_position
	var damage := pending_throw_damage
	var throw_velocity := pending_throw_velocity
	is_throw_escape_pending = false
	is_throw_locked = false
	throw_state = ""
	throw_escape_timer = 0.0
	_clear_pending_throw()
	_enter_hit_state()
	apply_damage(damage)
	velocity = throw_velocity

	if attacker != null and attacker.has_method("_spawn_throw_impact_effect"):
		attacker._spawn_throw_impact_effect(hit_position)
	if attacker != null and attacker.has_method("_play_throw_se"):
		attacker._play_throw_se()


func _clear_pending_throw() -> void:
	pending_throw_attacker = null
	pending_throw_damage = 0
	pending_throw_hit_position = Vector2.ZERO
	pending_throw_direction = 0.0
	pending_throw_velocity = Vector2.ZERO
	pending_throw_ai_checked = false


func _push_throw_escape_apart(attacker: Node) -> void:
	if not (attacker is Node2D):
		return

	var direction_from_attacker := signf(global_position.x - attacker.global_position.x)
	if direction_from_attacker == 0.0:
		direction_from_attacker = 1.0
	position.x += direction_from_attacker * throw_escape_pushback
	var attacker_2d := attacker as Node2D
	attacker_2d.position.x -= direction_from_attacker * throw_escape_pushback


func _spawn_throw_escape_effect(effect_position: Vector2) -> void:
	var effect_root := Node2D.new()
	effect_root.global_position = effect_position
	effect_root.name = "ThrowEscapeEffect"

	var flash := Polygon2D.new()
	var points := PackedVector2Array()
	var radius := 22.0
	for point_index in range(12):
		var angle := TAU * float(point_index) / 12.0
		var point_radius := radius if point_index % 2 == 0 else radius * 0.45
		points.append(Vector2(cos(angle), sin(angle)) * point_radius)
	flash.color = Color(0.55, 0.95, 1.0, 0.78)
	flash.polygon = points
	effect_root.add_child(flash)
	get_tree().current_scene.add_child(effect_root)

	var tween := effect_root.create_tween()
	tween.tween_property(effect_root, "scale", Vector2(1.5, 1.5), 0.16)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.16)
	tween.tween_callback(effect_root.queue_free)


func _update_throw_recovery(delta: float) -> void:
	throw_recovery_timer = maxf(throw_recovery_timer - delta, 0.0)
	if throw_recovery_timer > 0.0:
		return

	is_throwing = false
	is_throw_locked = false
	is_throw_escaping = false
	throw_state = ""


func _connect_throw(target: Node) -> void:
	if not _is_valid_throw_target(target):
		_fail_throw()
		return
	if target.get("throw_state") == "THROW_STARTUP":
		_complete_simultaneous_throw(target)
		return

	has_throw_connected = true
	current_throw_target = target
	throw_state = "THROW_HOLD"
	throw_hold_timer = throw_hold_time
	_play_throw_animation("throw_hold")
	print("THROW CONNECTED")
	throw_hit.emit(target)
	var throw_velocity := Vector2(throw_knockback * facing_direction, throw_vertical_force)
	target.receive_throw(self, throw_damage, _get_hit_position(target), facing_direction, throw_velocity)
	_lock_throw_target_position(target)
	_spawn_throw_success_effect(_get_hit_position(target))


func _release_throw() -> void:
	if has_throw_damage_applied:
		return

	has_throw_damage_applied = true
	_play_throw_animation("throw_release")
	print("THROW RELEASE")
	if _is_valid_throw_target(current_throw_target) and current_throw_target.has_method("_complete_throw_hit"):
		current_throw_target._complete_throw_hit()
	throw_state = "THROW_RECOVERY"
	throw_recovery_timer = throw_recovery_time
	current_throw_target = null


func _fail_throw() -> void:
	print("THROW WHIFF")
	current_throw_target = null
	has_throw_connected = false
	has_throw_damage_applied = false
	throw_state = "THROW_WHIFF"
	throw_recovery_timer = throw_whiff_recovery_time


func _finish_throw() -> void:
	is_throwing = false
	is_throw_locked = false
	is_throw_escape_pending = false
	is_throw_escaping = false
	throw_state = ""
	throw_startup_timer = 0.0
	throw_hold_timer = 0.0
	throw_recovery_timer = 0.0
	throw_escape_timer = 0.0
	current_throw_target = null
	has_throw_connected = false
	has_throw_damage_applied = false
	_clear_pending_throw()


func _complete_simultaneous_throw(target: Node) -> void:
	print("THROW ESCAPE")
	_push_throw_escape_apart(target)
	_spawn_throw_escape_effect(_get_hit_position(target))
	_play_throw_escape_se()
	throw_state = "THROW_ESCAPE"
	throw_recovery_timer = throw_escape_recovery_time
	if target.has_method("enter_throw_escape_recovery"):
		target.enter_throw_escape_recovery(self)


func _lock_throw_target_position(target: Node) -> void:
	if not (target is Node2D):
		return

	var hold_offset := Vector2(30.0 * facing_direction, -5.0)
	var viewport_width := get_viewport_rect().size.x
	var target_position := global_position + hold_offset
	target_position.x = clampf(target_position.x, screen_margin, viewport_width - screen_margin)
	target.global_position = target_position
	target.velocity = Vector2.ZERO


func _is_valid_throw_target(target: Node) -> bool:
	return target != null and is_instance_valid(target) and target.has_method("receive_throw") and target.get("current_hp") > 0


func _play_throw_animation(animation_name := "Throw") -> void:
	if animation_player == null:
		return
	if animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
	elif animation_player.has_animation("Throw"):
		animation_player.play("Throw")


func _play_attack_animation(animation_name: StringName) -> void:
	if animation_player == null:
		return
	if animation_player.has_animation(String(animation_name)):
		animation_player.play(String(animation_name))
	elif animation_player.has_animation("Punch") and current_attack_type == "Punch":
		animation_player.play("Punch")
	elif animation_player.has_animation("Kick") and current_attack_type == "Kick":
		animation_player.play("Kick")


func _get_attack_animation_name(attack_type: StringName) -> StringName:
	if attack_type == &"Punch":
		return &"punch_2" if combo_step == 2 else &"punch_1"
	if combo_step >= max_combo_hits:
		return &"combo_finisher"
	return &"kick_1"


func _update_attack(delta: float) -> void:
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer = maxf(attack_cooldown_timer - delta, 0.0)
		if attack_cooldown_timer == 0.0 and current_attack_type == "Punch":
			if combo_count > 0 and not current_attack_connected:
				reset_combo()
			current_attack_type = ""
			clear_attack_buffer()
			close_combo_window()
			if combo_count >= max_combo_hits:
				reset_combo()

	if attack_active_timer <= 0.0:
		_set_punch_hitbox_active(false)
		return

	attack_active_timer = maxf(attack_active_timer - delta, 0.0)
	if attack_active_timer == 0.0:
		_set_punch_hitbox_active(false)


func _update_kick(delta: float) -> void:
	if kick_cooldown_timer > 0.0:
		kick_cooldown_timer = maxf(kick_cooldown_timer - delta, 0.0)
		if kick_cooldown_timer == 0.0 and current_attack_type == "Kick":
			if combo_count > 0 and not current_attack_connected:
				reset_combo()
			current_attack_type = ""
			clear_attack_buffer()
			close_combo_window()
			if combo_count >= max_combo_hits:
				reset_combo()

	if kick_active_timer <= 0.0:
		_set_kick_hitbox_active(false)
		return

	kick_active_timer = maxf(kick_active_timer - delta, 0.0)
	if kick_active_timer == 0.0:
		_set_kick_hitbox_active(false)
		print("Kick End")


func _set_punch_hitbox_active(is_active: bool, should_print := true) -> void:
	if punch_hitbox_active == is_active:
		return

	punch_hitbox_active = is_active
	punch_area.set_deferred("monitoring", is_active)
	punch_shape.set_deferred("disabled", not is_active)
	if not is_active:
		punch_hit_targets.clear()
	if should_print:
		print("Punch HitBox ON" if is_active else "Punch HitBox OFF")


func _set_kick_hitbox_active(is_active: bool, should_print := true) -> void:
	if kick_hitbox_active == is_active:
		return

	kick_hitbox_active = is_active
	kick_area.set_deferred("monitoring", is_active)
	kick_shape.set_deferred("disabled", not is_active)
	if not is_active:
		kick_hit_targets.clear()
	if should_print:
		print("Kick HitBox ON" if is_active else "Kick HitBox OFF")


func _on_punch_hitbox_area_entered(area: Area2D) -> void:
	if not punch_hitbox_active:
		return

	var hit_target := _get_valid_hurtbox_target(area)
	if hit_target == null or punch_hit_targets.has(hit_target):
		return

	punch_hit_targets.append(hit_target)
	print("Punch Hit")
	_apply_attack_to_target(hit_target, _get_punch_attack_data())


func _on_kick_hitbox_area_entered(area: Area2D) -> void:
	if not kick_hitbox_active:
		return

	var hit_target := _get_valid_hurtbox_target(area)
	if hit_target == null or kick_hit_targets.has(hit_target):
		return

	kick_hit_targets.append(hit_target)
	print("Kick Hit")
	_apply_attack_to_target(hit_target, _get_kick_attack_data())


func _get_valid_hurtbox_target(area: Area2D) -> Node:
	if area == hurt_box or area.name != "HurtBox":
		return null

	var target := area.get_parent()
	if target == self:
		return null
	if not target.has_method("apply_damage"):
		return null
	if target.get("is_invincible") == true:
		return null

	return target


func apply_damage(damage: int) -> void:
	var was_alive := current_hp > 0
	current_hp = maxi(current_hp - damage, 0)
	if damage > 0:
		reset_combo()
	print("Damage: %d" % damage)
	print("HP: %d" % current_hp)
	hp_changed.emit(current_hp, max_hp)
	if current_hp == 0 and was_alive:
		print("HP reached 0")
		hp_depleted.emit()


func receive_attack(attack_data: Dictionary, attack_direction: float, hit_position: Vector2, attacker: Node) -> bool:
	if _can_guard_attack(attack_data, attacker):
		_receive_guarded_attack(attack_data, attack_direction, hit_position, attacker)
		return false

	interrupt_combo()
	_cancel_current_action()
	_enter_hit_state()
	if int(attack_data.get("combo_hit_index", 1)) < max_combo_hits:
		hit_reaction_timer = maxf(hit_reaction_timer, combo_hitstun_time)
	apply_damage(attack_data["damage"])
	if attacker != null and attacker.has_method("register_combo_hit"):
		attacker.register_combo_hit(self)
		if current_hp == 0 and attacker.has_method("_finish_combo_after_ko"):
			attacker._finish_combo_after_ko()
	_apply_knockback(attack_data, attack_direction)
	_start_invincibility()
	_start_hit_stop(attack_data["hit_stop_frames"])
	_spawn_hit_effect(hit_position, attack_data["effect_size"])
	_play_hit_se(attack_data["se_type"])
	if attacker != null and attacker.has_method("start_hit_stop"):
		attacker.start_hit_stop(attack_data["hit_stop_frames"])
	screen_shake_requested.emit(attack_data["screen_shake"])
	return true


func start_hit_stop(frame_count: int) -> void:
	_start_hit_stop(frame_count)


func start_hit_stop_seconds(duration: float) -> void:
	_start_hit_stop_seconds(duration)


func _apply_attack_to_target(target: Node, attack_data: Dictionary) -> void:
	if not target.has_method("receive_attack"):
		return

	var scaled_attack_data := _build_combo_scaled_attack_data(attack_data, target)
	target.receive_attack(scaled_attack_data, facing_direction, _get_hit_position(target), self)


func _get_punch_attack_data() -> Dictionary:
	return {
		"damage": punch_damage,
		"attack_height": "middle",
		"knockback_x": calculate_attack_knockback(Vector2(punch_knockback_x, punch_knockback_y)).x,
		"knockback_y": calculate_attack_knockback(Vector2(punch_knockback_x, punch_knockback_y)).y,
		"hit_stop_frames": 3,
		"effect_size": 1.0,
		"screen_shake": 2.0,
		"se_type": "weak",
	}


func _get_kick_attack_data() -> Dictionary:
	return {
		"damage": kick_damage,
		"attack_height": "low",
		"knockback_x": calculate_attack_knockback(Vector2(kick_knockback_x, kick_knockback_y)).x,
		"knockback_y": calculate_attack_knockback(Vector2(kick_knockback_x, kick_knockback_y)).y,
		"hit_stop_frames": 8,
		"effect_size": 1.5,
		"screen_shake": 4.0,
		"se_type": "strong",
	}


func _get_hit_position(target: Node) -> Vector2:
	if target is Node2D:
		return (global_position + target.global_position) * 0.5
	return global_position


func _cancel_current_action() -> void:
	attack_active_timer = 0.0
	kick_active_timer = 0.0
	_clear_guard_state()
	is_crouching = false
	is_guard_hit = false
	is_throwing = false
	is_throw_locked = false
	is_throw_escape_pending = false
	is_throw_escaping = false
	throw_recovery_timer = 0.0
	throw_escape_timer = 0.0
	throw_startup_timer = 0.0
	throw_hold_timer = 0.0
	throw_state = ""
	current_throw_target = null
	has_throw_connected = false
	has_throw_damage_applied = false
	ai_guard_check_timer = 0.0
	ai_guard_timer = 0.0
	ai_throw_check_timer = 0.0
	ai_throw_cooldown_timer = 0.0
	_clear_cancel_window()
	current_attack_type = ""
	_clear_pending_throw()
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)


func _enter_hit_state() -> void:
	is_hit = true
	hit_reaction_timer = hit_reaction_time


func _apply_knockback(attack_data: Dictionary, attack_direction: float) -> void:
	var received_knockback := calculate_received_knockback(Vector2(attack_data["knockback_x"], attack_data["knockback_y"]))
	velocity.x = received_knockback.x * attack_direction
	if not is_on_floor():
		velocity.y = -received_knockback.y


func _receive_guarded_attack(attack_data: Dictionary, attack_direction: float, hit_position: Vector2, attacker: Node) -> void:
	attack_active_timer = 0.0
	kick_active_timer = 0.0
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)
	if attacker != null and attacker.has_method("reset_combo"):
		attacker.reset_combo()
	if attacker != null and attacker.has_method("_clear_cancel_window"):
		attacker._clear_cancel_window()
	if attacker != null and attacker.has_method("clear_attack_buffer"):
		attacker.clear_attack_buffer()
	_enter_guard_hit_state()
	guard_hit_timer = float(attack_data.get("guard_hit_time", guard_hit_timer))
	apply_damage(_get_guard_damage_from_attack_data(attack_data))
	_apply_guard_knockback(attack_data, attack_direction)
	_start_hit_stop_seconds(float(attack_data.get("guard_hit_stop_time", guard_hit_stop_time)))
	_spawn_guard_effect(hit_position)
	_play_guard_se()
	if attacker != null and attacker.has_method("start_hit_stop"):
		attacker.start_hit_stop_seconds(float(attack_data.get("guard_hit_stop_time", guard_hit_stop_time)))


func _enter_guard_hit_state() -> void:
	is_guard_hit = true
	is_hit = false
	guard_hit_timer = guard_hit_time


func _get_guard_damage(damage: int) -> int:
	return int(calculate_guarded_damage(float(damage)))


func _get_guard_damage_from_attack_data(attack_data: Dictionary) -> int:
	var base_damage := int(attack_data.get("base_damage", attack_data["damage"]))
	if attack_data.has("guard_damage_multiplier"):
		return maxi(1, int(round(float(base_damage) * float(attack_data["guard_damage_multiplier"]))))
	return _get_guard_damage(base_damage)


func _apply_guard_knockback(attack_data: Dictionary, attack_direction: float) -> void:
	var guard_knockback_value: Vector2 = attack_data.get("guard_knockback", Vector2(guard_knockback_x, 0.0))
	var guard_knockback := calculate_received_knockback(guard_knockback_value)
	velocity.x = guard_knockback.x * attack_direction
	if is_on_floor():
		velocity.y = 0.0


func _can_guard_attack(attack_data: Dictionary, attacker: Node) -> bool:
	if not bool(attack_data.get("is_guardable", true)):
		return false
	if not can_guard or not is_round_active or is_guard_hit:
		return false
	if is_hit or is_invincible or not is_on_floor():
		return false
	if attack_active_timer > 0.0 or kick_active_timer > 0.0:
		return false
	if not is_guarding:
		return false
	if not _is_facing_attacker(attacker):
		return false
	return _is_attack_height_guardable(str(attack_data.get("attack_height", "middle")))


func _is_attack_height_guardable(attack_height: String) -> bool:
	match attack_height:
		"high":
			return guard_type == "stand" or guard_type == "crouch"
		"middle":
			return guard_type == "stand"
		"low":
			return guard_type == "crouch"
		_:
			return false


func _can_start_guard_or_crouch() -> bool:
	return can_guard and is_round_active and is_on_floor() and attack_active_timer <= 0.0 and kick_active_timer <= 0.0 and not is_hit and not is_guard_hit


func get_current_move_speed() -> float:
	return move_speed if is_on_floor() else air_move_speed


func get_attack_active_time() -> float:
	return attack_active_time * maxf(punch_startup_multiplier, 0.01)


func get_kick_active_time() -> float:
	return kick_active_time * maxf(kick_startup_multiplier, 0.01)


func get_attack_cooldown_time() -> float:
	return attack_cooldown_time * maxf(punch_recovery_multiplier, 0.01)


func get_kick_cooldown_time() -> float:
	return kick_cooldown_time * maxf(kick_recovery_multiplier, 0.01)


func get_punch_damage() -> float:
	return float(punch_damage)


func get_kick_damage() -> float:
	return float(kick_damage)


func get_guard_damage_multiplier() -> float:
	return guard_damage_rate


func get_attack_knockback_multiplier() -> float:
	return attack_knockback_multiplier


func get_received_knockback_multiplier() -> float:
	return received_knockback_multiplier


func calculate_guarded_damage(incoming_damage: float) -> float:
	return maxi(1, int(round(incoming_damage * get_guard_damage_multiplier())))


func calculate_attack_knockback(base_knockback: Vector2) -> Vector2:
	return base_knockback * get_attack_knockback_multiplier()


func calculate_received_knockback(incoming_knockback: Vector2) -> Vector2:
	return incoming_knockback * get_received_knockback_multiplier()


func _is_holding_back_against_opponent() -> bool:
	return _is_holding_back_against_attacker(_get_opponent())


func _is_holding_back_against_attacker(attacker: Node) -> bool:
	if attacker is Node2D and input_enabled:
		var direction_to_attacker := signf(attacker.global_position.x - global_position.x)
		var input_direction := Input.get_axis("move_left", "move_right")
		return direction_to_attacker != 0.0 and input_direction != 0.0 and signf(input_direction) == -direction_to_attacker

	return is_guarding


func _is_facing_attacker(attacker: Node) -> bool:
	if not (attacker is Node2D):
		return true

	var direction_to_attacker := signf(attacker.global_position.x - global_position.x)
	return direction_to_attacker == 0.0 or signf(facing_direction) == direction_to_attacker


func _uses_ai_guard() -> bool:
	return ai_guard_enabled and name == "Enemy" and is_round_active and not input_enabled and not is_hit and not is_guard_hit and not _is_throw_busy()


func _update_ai_throw(delta: float) -> void:
	if name != "Enemy" or input_enabled:
		return

	ai_throw_cooldown_timer = maxf(ai_throw_cooldown_timer - delta, 0.0)
	ai_throw_check_timer = maxf(ai_throw_check_timer - delta, 0.0)
	if ai_throw_check_timer > 0.0:
		return

	ai_throw_check_timer = ai_throw_check_interval
	if ai_throw_cooldown_timer > 0.0:
		return
	if not _can_start_throw() or is_guarding:
		return
	if _get_throw_target() == null:
		return
	if randf() > ai_throw_probability:
		return

	ai_throw_cooldown_timer = ai_throw_cooldown
	_face_opponent()
	_start_throw()


func _maybe_buffer_ai_combo() -> void:
	if name != "Enemy" or input_enabled:
		return
	if not combo_window_open or buffered_attack != &"" or combo_count >= max_combo_hits:
		return
	if not current_attack_connected or current_attack_type == "":
		return

	var continue_probability := ai_combo_continue_probability if combo_count <= 1 else ai_third_hit_probability
	if randf() > continue_probability:
		return

	var next_attack := _choose_ai_combo_attack()
	if next_attack == &"":
		return

	buffer_attack(next_attack)


func _choose_ai_combo_attack() -> StringName:
	match StringName(current_attack_type):
		&"Punch":
			return &"Kick" if randf() < 0.5 else &"Punch"
		&"Kick":
			return &"Punch"
		_:
			return &""


func _update_ai_guard(delta: float) -> void:
	if not _can_start_guard_or_crouch():
		_clear_guard_state()
		ai_guard_timer = 0.0
		return

	if ai_guard_timer > 0.0:
		ai_guard_timer = maxf(ai_guard_timer - delta, 0.0)
		is_guarding = true
		is_crouch_guarding = false
		is_crouching = false
		guard_type = "stand"
		_face_opponent()
		return

	_clear_guard_state()
	ai_guard_check_timer = maxf(ai_guard_check_timer - delta, 0.0)
	if ai_guard_check_timer > 0.0:
		return

	ai_guard_check_timer = ai_guard_check_interval
	if randf() <= ai_guard_chance:
		ai_guard_timer = randf_range(ai_guard_min_time, ai_guard_max_time)
		is_guarding = true
		is_crouch_guarding = false
		is_crouching = false
		guard_type = "stand"
		_face_opponent()


func _face_opponent() -> void:
	var opponent := _get_opponent()
	if not (opponent is Node2D):
		return

	var direction_to_opponent := signf(opponent.global_position.x - global_position.x)
	if direction_to_opponent == 0.0:
		return
	facing_direction = direction_to_opponent
	visual_root.scale.x = facing_direction


func _get_opponent() -> Node:
	var parent_node := get_parent()
	if parent_node == null:
		return null
	if name == "Player":
		return parent_node.get_node_or_null("Enemy")
	if name == "Enemy":
		return parent_node.get_node_or_null("Player")
	return null


func _clear_guard_state() -> void:
	is_guarding = false
	is_crouch_guarding = false
	guard_type = "none"


func _update_guard_hit(delta: float) -> void:
	if not is_guard_hit:
		return

	guard_hit_timer = maxf(guard_hit_timer - delta, 0.0)
	if guard_hit_timer > 0.0:
		return

	is_guard_hit = false
	_clear_guard_state()
	if input_enabled:
		_update_defensive_state()


func _start_invincibility() -> void:
	is_invincible = true
	invincibility_timer = invincibility_time
	hurt_box.set_deferred("monitorable", false)
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)


func _update_invincibility(delta: float) -> void:
	if not is_invincible:
		return

	invincibility_timer = maxf(invincibility_timer - delta, 0.0)
	if invincibility_timer == 0.0:
		is_invincible = false
		hurt_box.set_deferred("monitorable", true)


func _start_hit_stop(frame_count: int) -> void:
	hit_stop_timer = maxf(hit_stop_timer, float(frame_count) / 60.0)


func _start_hit_stop_seconds(duration: float) -> void:
	hit_stop_timer = maxf(hit_stop_timer, duration)


func _update_hit_stop(delta: float) -> bool:
	if hit_stop_timer <= 0.0:
		return false

	hit_stop_timer = maxf(hit_stop_timer - delta, 0.0)
	return hit_stop_timer > 0.0


func _update_hit_reaction(delta: float) -> void:
	if not is_hit:
		return

	hit_reaction_timer = maxf(hit_reaction_timer - delta, 0.0)
	if hit_reaction_timer == 0.0:
		is_hit = false
		if is_on_floor():
			velocity.x = 0.0


func register_combo_hit(target: Node) -> void:
	if target == null or not is_instance_valid(target):
		reset_combo()
		return

	if combo_timer <= 0.0 or combo_target == null or not is_instance_valid(combo_target):
		combo_count = 0
		current_combo_hits = 0
		combo_target = target
	elif combo_target != target:
		reset_combo()
		combo_target = target

	combo_count = mini(combo_count + 1, max_combo_hits)
	current_combo_hits = combo_count
	current_attack_connected = true
	last_attack_type = StringName(current_attack_type)
	combo_step = combo_count

	combo_timer = combo_reset_time
	combo_changed.emit(combo_count, self)
	if combo_log_enabled and combo_count >= 2:
		print("Combo: %s %d HIT" % [_get_combo_log_name(), combo_count])

	if combo_count < max_combo_hits and current_hp > 0:
		open_combo_window()
	else:
		close_combo_window()
		clear_attack_buffer()


func reset_combo() -> void:
	if combo_count == 0 and combo_timer == 0.0 and not combo_window_open and buffered_attack == &"":
		return

	combo_count = 0
	current_combo_hits = 0
	combo_timer = 0.0
	combo_window_open = false
	buffered_attack = &""
	attack_buffer_timer = 0.0
	last_attack_type = &""
	combo_target = null
	current_attack_connected = false
	combo_step = 0
	_clear_cancel_window()
	combo_changed.emit(combo_count, self)


func _update_combo_timer(delta: float) -> void:
	if combo_count == 0:
		return

	combo_timer = maxf(combo_timer - delta, 0.0)
	if combo_timer == 0.0:
		reset_combo()


func buffer_attack(attack_type: StringName) -> void:
	if attack_type != &"Punch" and attack_type != &"Kick":
		return

	buffered_attack = attack_type
	attack_buffer_timer = combo_input_buffer_time


func clear_attack_buffer() -> void:
	buffered_attack = &""
	attack_buffer_timer = 0.0


func open_combo_window() -> void:
	if current_attack_type == "":
		return

	can_cancel = true
	combo_window_open = true
	cancel_window_timer = combo_continue_window
	_maybe_buffer_ai_combo()


func close_combo_window() -> void:
	combo_window_open = false
	can_cancel = false
	cancel_window_timer = 0.0


func _open_cancel_window() -> void:
	open_combo_window()


func _update_cancel_window(delta: float) -> void:
	if not can_cancel and not combo_window_open:
		return

	cancel_window_timer = maxf(cancel_window_timer - delta, 0.0)
	if cancel_window_timer == 0.0:
		close_combo_window()


func _update_attack_buffer(delta: float) -> void:
	if attack_buffer_timer > 0.0:
		attack_buffer_timer = maxf(attack_buffer_timer - delta, 0.0)
		if attack_buffer_timer == 0.0:
			clear_attack_buffer()

	if not input_enabled or current_attack_type == "" or _is_throw_input_held():
		return
	if Input.is_action_just_pressed("attack"):
		buffer_attack(&"Punch")
	elif Input.is_action_just_pressed("kick"):
		buffer_attack(&"Kick")


func _try_cancel_attack_from_input() -> bool:
	return try_continue_combo()


func _can_cancel_attack() -> bool:
	return is_round_active and combo_window_open and can_cancel and cancel_window_timer > 0.0 and current_attack_type != "" and current_hp > 0 and current_attack_connected and combo_count < max_combo_hits and is_on_floor() and not is_hit and not is_guard_hit and not is_guarding and not is_crouching and not is_crouch_guarding and not _is_throw_busy()


func can_chain_attack(current_attack: StringName, next_attack: StringName) -> bool:
	match current_attack:
		&"Punch":
			return next_attack == &"Punch" or next_attack == &"Kick"
		&"Kick":
			return next_attack == &"Punch"
		_:
			return false


func try_continue_combo() -> bool:
	if not _can_cancel_attack():
		return false
	if buffered_attack == &"":
		return false
	if not can_chain_attack(StringName(current_attack_type), buffered_attack):
		clear_attack_buffer()
		return false

	var next_attack := buffered_attack
	clear_attack_buffer()
	start_combo_attack(next_attack)
	return true


func start_combo_attack(next_attack_type: StringName) -> void:
	var previous_attack_type := current_attack_type
	attack_active_timer = 0.0
	kick_active_timer = 0.0
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)
	punch_hit_targets.clear()
	kick_hit_targets.clear()
	close_combo_window()
	current_attack_connected = false
	print("Cancel: %s -> %s" % [previous_attack_type, next_attack_type])
	if next_attack_type == &"Kick":
		_start_kick(true)
	else:
		_start_attack(true)


func _cancel_into_attack(next_attack_type: String) -> void:
	start_combo_attack(StringName(next_attack_type))


func _clear_cancel_window() -> void:
	can_cancel = false
	cancel_window_timer = 0.0
	combo_window_open = false


func _build_combo_scaled_attack_data(attack_data: Dictionary, target: Node) -> Dictionary:
	var scaled_attack_data := attack_data.duplicate()
	var hit_index := _get_next_combo_hit_index(target)
	var damage_scale := _get_combo_damage_scale_for_hit(hit_index)
	var knockback_scale := _get_combo_knockback_scale_for_hit(hit_index)
	scaled_attack_data["base_damage"] = attack_data["damage"]
	scaled_attack_data["damage"] = maxi(int(round(float(attack_data["damage"]) * damage_scale)), int(minimum_combo_damage))
	scaled_attack_data["knockback_x"] = float(attack_data["knockback_x"]) * knockback_scale
	scaled_attack_data["knockback_y"] = float(attack_data["knockback_y"]) * knockback_scale
	scaled_attack_data["combo_hit_index"] = hit_index
	scaled_attack_data["damage_scale"] = damage_scale
	return scaled_attack_data


func _get_next_combo_hit_index(target: Node) -> int:
	if combo_timer <= 0.0 or combo_target == null or not is_instance_valid(combo_target) or combo_target != target:
		return 1
	return mini(combo_count + 1, max_combo_hits)


func get_combo_damage_scale() -> float:
	return _get_combo_damage_scale_for_hit(maxi(combo_count, 1))


func _get_combo_damage_scale_for_hit(hit_index: int) -> float:
	match hit_index:
		1:
			return 1.0
		2:
			return second_hit_damage_scale
		_:
			return third_hit_damage_scale


func get_combo_knockback_scale() -> float:
	return _get_combo_knockback_scale_for_hit(maxi(combo_count, 1))


func _get_combo_knockback_scale_for_hit(hit_index: int) -> float:
	if hit_index <= 1:
		return first_combo_knockback_scale
	if hit_index == 2 and max_combo_hits > 2:
		return second_combo_knockback_scale
	return 1.0


func interrupt_combo() -> void:
	_set_punch_hitbox_active(false)
	_set_kick_hitbox_active(false)
	clear_attack_buffer()
	close_combo_window()
	reset_combo()


func _finish_combo_after_ko() -> void:
	clear_attack_buffer()
	close_combo_window()


func _get_combo_log_name() -> String:
	if name == "Player":
		return "Player1"
	if name == "Enemy":
		return "Player2"
	return name


func _spawn_hit_effect(hit_position: Vector2, effect_size: float) -> void:
	var effect_root := Node2D.new()
	effect_root.global_position = hit_position
	effect_root.name = "HitEffect"

	var flash := Polygon2D.new()
	var size := 18.0 * effect_size
	flash.color = Color(1.0, 0.95, 0.25, 0.75)
	flash.polygon = PackedVector2Array([
		Vector2(0, -size),
		Vector2(size, 0),
		Vector2(0, size),
		Vector2(-size, 0),
	])
	effect_root.add_child(flash)
	get_tree().current_scene.add_child(effect_root)

	var timer := get_tree().create_timer(0.15)
	timer.timeout.connect(effect_root.queue_free)


func _spawn_throw_success_effect(effect_position: Vector2) -> void:
	_spawn_throw_effect(effect_position, "ThrowSuccessEffect", Color(0.55, 0.95, 1.0, 0.7), 14.0)


func _spawn_throw_impact_effect(effect_position: Vector2) -> void:
	_spawn_throw_effect(effect_position, "ThrowImpactEffect", Color(1.0, 0.92, 0.35, 0.78), 22.0)


func _spawn_throw_effect(effect_position: Vector2, effect_name: String, effect_color: Color, radius: float) -> void:
	var effect_root := Node2D.new()
	effect_root.global_position = effect_position
	effect_root.name = effect_name

	var flash := Polygon2D.new()
	var points := PackedVector2Array()
	for point_index in range(12):
		var angle := TAU * float(point_index) / 12.0
		var point_radius := radius if point_index % 2 == 0 else radius * 0.45
		points.append(Vector2(cos(angle), sin(angle)) * point_radius)
	flash.color = effect_color
	flash.polygon = points
	effect_root.add_child(flash)
	get_tree().current_scene.add_child(effect_root)

	var tween := effect_root.create_tween()
	tween.tween_property(effect_root, "scale", Vector2(1.6, 1.6), 0.14)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.14)
	tween.tween_callback(effect_root.queue_free)


func _setup_hit_audio() -> void:
	weak_hit_se = AudioStreamPlayer2D.new()
	weak_hit_se.name = "WeakHitSE"
	weak_hit_se.stream = _create_hit_stream(540.0)
	add_child(weak_hit_se)

	strong_hit_se = AudioStreamPlayer2D.new()
	strong_hit_se.name = "StrongHitSE"
	strong_hit_se.stream = _create_hit_stream(220.0)
	add_child(strong_hit_se)

	guard_hit_se = AudioStreamPlayer2D.new()
	guard_hit_se.name = "GuardHitSE"
	guard_hit_se.stream = _create_hit_stream(760.0)
	add_child(guard_hit_se)

	throw_se = AudioStreamPlayer2D.new()
	throw_se.name = "ThrowSE"
	throw_se.stream = _create_hit_stream(140.0)
	add_child(throw_se)

	throw_escape_se = AudioStreamPlayer2D.new()
	throw_escape_se.name = "ThrowEscapeSE"
	throw_escape_se.stream = _create_hit_stream(920.0)
	add_child(throw_escape_se)


func _create_hit_stream(frequency: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.08
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	for sample_index in sample_count:
		var fade := 1.0 - (float(sample_index) / float(sample_count))
		var value := int(sin(TAU * frequency * float(sample_index) / float(sample_rate)) * 12000.0 * fade)
		data.append(value & 0xff)
		data.append((value >> 8) & 0xff)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _play_hit_se(se_type: String) -> void:
	if se_type == "strong":
		strong_hit_se.play()
	else:
		weak_hit_se.play()


func _play_guard_se() -> void:
	guard_hit_se.play()


func _play_throw_se() -> void:
	throw_se.play()


func _play_throw_escape_se() -> void:
	throw_escape_se.play()


func _spawn_guard_effect(hit_position: Vector2) -> void:
	var effect_root := Node2D.new()
	effect_root.global_position = hit_position
	effect_root.name = "GuardEffect"

	var flash := Polygon2D.new()
	var points := PackedVector2Array()
	var radius := 16.0
	for point_index in range(16):
		var angle := TAU * float(point_index) / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	flash.color = Color(0.45, 0.9, 1.0, 0.65)
	flash.polygon = points
	effect_root.add_child(flash)
	get_tree().current_scene.add_child(effect_root)

	var tween := effect_root.create_tween()
	tween.tween_property(effect_root, "scale", Vector2(1.7, 1.7), 0.12)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.12)
	tween.tween_callback(effect_root.queue_free)


func _update_visual_state() -> void:
	if not debug_state_label_enabled:
		state_label.visible = false
		queue_redraw()
		return

	state_label.visible = true
	if throw_state != "":
		state_label.text = throw_state
	elif is_throw_escaping:
		state_label.text = "THROW_ESCAPE"
	elif is_throwing or is_throw_locked or is_throw_escape_pending:
		state_label.text = "THROWN"
	elif is_guard_hit:
		state_label.text = "BLOCKED"
	elif is_hit:
		state_label.text = "Hit"
	elif is_crouch_guarding:
		state_label.text = "CrouchGuard"
	elif is_guarding:
		state_label.text = "GUARD"
	elif is_crouching:
		state_label.text = "Crouch"
	elif kick_active_timer > 0.0:
		state_label.text = "Kick"
	elif attack_active_timer > 0.0:
		state_label.text = "Punch"
	elif absf(velocity.x) > 0.0:
		state_label.text = "Walk"
	else:
		state_label.text = "Idle"

	if combo_count > 0 or combo_window_open or buffered_attack != &"":
		var buffered_text := "NONE" if buffered_attack == &"" else String(buffered_attack).to_upper()
		var window_text := "OPEN" if combo_window_open else "CLOSED"
		state_label.text += "\nCOMBO HITS: %d\nCOMBO STEP: %d\nBUFFERED ATTACK: %s\nCOMBO WINDOW: %s\nATTACK CONNECTED: %s\nDAMAGE SCALE: %.2f" % [
			combo_count,
			combo_step,
			buffered_text,
			window_text,
			str(current_attack_connected).to_upper(),
			get_combo_damage_scale(),
		]

	guard_visual.visible = is_guarding and not is_crouch_guarding
	crouch_visual.visible = is_crouching
	crouch_guard_visual.visible = is_crouch_guarding
	var target_y_scale := 0.7 if is_crouching or is_crouch_guarding else 1.0
	visual_root.scale.y = target_y_scale
	queue_redraw()


func _draw() -> void:
	if not debug_state_label_enabled:
		return

	var range_x := facing_direction * (throw_range + throw_body_width)
	var rect_x := 0.0 if facing_direction > 0.0 else range_x
	var throw_rect := Rect2(rect_x, -96.0, absf(range_x), 96.0)
	draw_rect(throw_rect, Color(0.35, 0.8, 1.0, 0.12), true)
	draw_rect(throw_rect, Color(0.35, 0.8, 1.0, 0.45), false, 1.0)
