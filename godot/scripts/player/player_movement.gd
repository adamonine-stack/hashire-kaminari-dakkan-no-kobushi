extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal hp_depleted
signal screen_shake_requested(strength: float)
signal throw_hit(target: Node)
signal combo_changed(combo_count: int, combo_owner: Node)
signal damage_feedback_requested(target: Node, amount: int, guarded: bool, hit_position: Vector2)

@export var move_speed := 300.0
@export var air_move_speed := 300.0
@export var jump_horizontal_speed := 220.0
@export var air_control_acceleration := 900.0
@export var air_brake_acceleration := 160.0
@export var crouch_speed := 120.0
@export var jump_power := 500.0
@export var screen_margin := 64.0
@export var attack_active_time := 0.12
@export var attack_cooldown_time := 0.35
@export var attack_offset := 67.0
@export var kick_active_time := 0.18
@export var kick_cooldown_time := 0.5
@export var kick_offset := 86.0
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
@export var throw_regrab_lock_time := 0.9
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
@export var debug_state_label_enabled := false
@export var battle_visual_scale_multiplier := 1.2
@export var ai_guard_enabled := true
@export var ai_guard_chance := 0.25
@export var ai_guard_check_interval := 0.35
@export var ai_guard_min_time := 0.3
@export var ai_guard_max_time := 1.0
@export_group("Game Feel")
@export var feel_effect_pool_size := 24
@export var landing_shake_strength := 0.8
@export var ko_shake_strength := 8.0

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
var last_damage_animation: StringName = &"damage_light"
var throw_startup_timer := 0.0
var throw_hold_timer := 0.0
var throw_recovery_timer := 0.0
var throw_escape_timer := 0.0
var throw_regrab_lock_timer := 0.0
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
var ko_hit_se: AudioStreamPlayer2D
var special_hit_se: AudioStreamPlayer2D
var movement_dust_pool: Array[Node2D] = []
var hit_effect_pool: Array[Node2D] = []
var afterimage_pool: Array[Node2D] = []
var was_moving_last_frame := false
var was_on_floor_last_frame := false
var invincible_flash_timer := 0.0
var base_shadow_scale := Vector2.ONE
var uses_official_character_art := false
var uses_animated_character_art := false
var visual_sort_offset_y := 0.0
var jump_pressed_this_airtime := false

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
@onready var animated_character_sprite := get_node_or_null("VisualRoot/AnimatedCharacterSprite") as AnimatedSprite2D
@onready var character_sprite := get_node_or_null("VisualRoot/CharacterSprite") as Sprite2D
@onready var character_visual_controller := get_node_or_null("VisualRoot/CharacterVisualController")
@onready var shadow_sprite := get_node_or_null("ShadowSprite") as Sprite2D
@onready var effect_layer := get_node_or_null("EffectLayer") as Node2D
@onready var idle_placeholder := get_node_or_null("VisualRoot/IdlePlaceholder") as Node2D
@onready var placeholder_body := get_node_or_null("VisualRoot/IdlePlaceholder/Body") as Polygon2D
@onready var placeholder_head := get_node_or_null("VisualRoot/IdlePlaceholder/Head") as Polygon2D


func _ready() -> void:
	current_hp = max_hp
	punch_area.area_entered.connect(_on_punch_hitbox_area_entered)
	kick_area.area_entered.connect(_on_kick_hitbox_area_entered)
	_setup_hit_audio()
	call_deferred("_setup_feel_effect_pools")
	_ensure_official_animation_placeholders()
	_setup_character_layering()
	_set_punch_hitbox_active(false, false)
	_set_kick_hitbox_active(false, false)
	was_on_floor_last_frame = is_on_floor()
	hp_changed.emit(current_hp, max_hp)


func _ensure_official_animation_placeholders() -> void:
	if animation_player == null:
		return
	var library := animation_player.get_animation_library("")
	if library == null:
		library = AnimationLibrary.new()
		animation_player.add_animation_library("", library)
	var animation_names := [
		"idle", "walk", "dash", "jump", "jump_start", "jump_air", "fall", "land",
		"punch1", "punch2", "kick1", "kick2", "guard",
		"damage", "down", "getup", "special", "ko", "victory",
		"Punch", "Kick", "Throw",
	]
	for animation_name in animation_names:
		if animation_player.has_animation(animation_name):
			continue
		var animation := Animation.new()
		animation.resource_name = animation_name
		animation.length = 0.35
		library.add_animation(animation_name, animation)


func apply_character_art(definition: Resource) -> void:
	var battle_texture: Texture2D = definition.get("battle_texture") if definition != null else null
	uses_animated_character_art = false
	if visual_root != null:
		visual_root.scale.x = 1.0
	if character_visual_controller != null and character_visual_controller.has_method("setup"):
		uses_animated_character_art = bool(character_visual_controller.call("setup", definition, animated_character_sprite, character_sprite))
		if character_visual_controller.has_method("set_facing"):
			character_visual_controller.call("set_facing", int(signf(facing_direction)))
	if character_sprite != null:
		character_sprite.texture = null if uses_animated_character_art else battle_texture
		character_sprite.visible = battle_texture != null and not uses_animated_character_art
		uses_official_character_art = uses_animated_character_art or battle_texture != null
		if battle_texture != null and not uses_animated_character_art:
			var target_height := float(definition.get("battle_sprite_height"))
			target_height *= battle_visual_scale_multiplier
			var texture_height := maxf(float(battle_texture.get_height()), 1.0)
			var sprite_scale := target_height / texture_height
			character_sprite.scale = Vector2(sprite_scale, sprite_scale)
			character_sprite.position = Vector2(0.0, -target_height * 0.5) + Vector2(definition.get("battle_sprite_offset")) * battle_visual_scale_multiplier
			if placeholder_body != null:
				placeholder_body.visible = false
			if placeholder_head != null:
				placeholder_head.visible = false
		else:
			uses_official_character_art = uses_animated_character_art
			if idle_placeholder != null:
				idle_placeholder.visible = not uses_animated_character_art
			if placeholder_body != null:
				placeholder_body.visible = not uses_animated_character_art
			if placeholder_head != null:
				placeholder_head.visible = not uses_animated_character_art

	if animation_player != null:
		animation_player.stop()
		animation_player.active = not uses_official_character_art

	var shadow_texture: Texture2D = definition.get("shadow_texture") if definition != null else null
	if shadow_sprite != null:
		shadow_sprite.texture = shadow_texture
		shadow_sprite.visible = shadow_texture != null
		if shadow_texture != null:
			var shadow_width := maxf(float(shadow_texture.get_width()), 1.0)
			var shadow_scale := 110.0 / shadow_width
			base_shadow_scale = Vector2(shadow_scale, shadow_scale * 0.75)
			shadow_sprite.scale = base_shadow_scale


func _setup_character_layering() -> void:
	z_as_relative = false
	_update_character_sort_order()
	if visual_root != null:
		visual_root.z_as_relative = true
		visual_root.z_index = 0
	if animated_character_sprite != null:
		animated_character_sprite.z_as_relative = true
		animated_character_sprite.z_index = 2
	if character_sprite != null:
		character_sprite.z_as_relative = true
		character_sprite.z_index = 1
	if shadow_sprite != null:
		shadow_sprite.z_as_relative = true
		shadow_sprite.z_index = -10
	if effect_layer != null:
		effect_layer.z_as_relative = true
		effect_layer.z_index = 10


func _update_character_sort_order() -> void:
	z_index = clampi(roundi(global_position.y + visual_sort_offset_y), -4096, 4096)


func _get_character_effect_parent() -> Node:
	if effect_layer != null and is_instance_valid(effect_layer):
		return effect_layer
	return self


func _prepare_character_effect_node(effect_root: Node2D, effect_name: String, relative_z_index := 0) -> void:
	if effect_root == null:
		return
	effect_root.name = effect_name
	effect_root.z_as_relative = true
	effect_root.z_index = relative_z_index
	effect_root.top_level = false
	effect_root.modulate = Color.WHITE


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
		_set_visual_facing()

	if not is_hit and not _is_throw_busy():
		velocity.x = direction * get_current_move_speed()

	var was_on_floor_before_move := is_on_floor()
	if is_on_floor():
		jump_pressed_this_airtime = false
		if input_enabled and current_attack_type == "" and Input.is_action_just_pressed("jump") and not jump_pressed_this_airtime and not is_crouching and not is_kicking and not is_guarding and not is_crouch_guarding and not is_hit and not is_guard_hit and not _is_throw_busy():
			_prepare_jump_visual_state()
			var jump_direction := _get_horizontal_input_direction()
			velocity.y = -jump_power
			if jump_direction != 0.0:
				velocity.x = jump_direction * jump_horizontal_speed
			_spawn_movement_dust(global_position + Vector2(0.0, -4.0), 1.0)
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
	_update_character_sort_order()
	_update_movement_feedback(direction, was_on_floor_before_move)

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
	return is_round_active and current_hp > 0 and is_on_floor() and throw_regrab_lock_timer <= 0.0 and current_attack_type == "" and not is_hit and not is_guard_hit and not _is_throw_busy() and not is_guarding and not is_crouching and not is_crouch_guarding and attack_active_timer <= 0.0 and kick_active_timer <= 0.0


func can_be_thrown(attacker: Node) -> bool:
	return is_round_active and current_hp > 0 and is_on_floor() and throw_regrab_lock_timer <= 0.0 and not is_hit and not is_guard_hit and not is_throwing and not is_throw_locked and not is_throw_escape_pending and not is_throw_escaping and not is_invincible


func _get_throw_gap_to(target: Node) -> float:
	return maxf(absf(global_position.x - target.global_position.x) - throw_body_width, 0.0)


func _is_throw_input_pressed() -> bool:
	return Input.is_action_just_pressed("throw_attack")


func _is_throw_input_held() -> bool:
	return Input.is_action_pressed("throw_attack")


func _is_throw_busy() -> bool:
	return is_throwing or is_throw_locked or is_throw_escape_pending or is_throw_escaping


func _update_throw_state(delta: float) -> void:
	if throw_regrab_lock_timer > 0.0:
		throw_regrab_lock_timer = maxf(throw_regrab_lock_timer - delta, 0.0)

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

	apply_throw_regrab_lock()
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
	apply_throw_regrab_lock()
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
	apply_throw_regrab_lock()
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
	apply_throw_regrab_lock()
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
	apply_throw_regrab_lock()
	if target.has_method("enter_throw_escape_recovery"):
		target.enter_throw_escape_recovery(self)


func apply_throw_regrab_lock() -> void:
	throw_regrab_lock_timer = maxf(throw_regrab_lock_timer, throw_regrab_lock_time)


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
	_play_visual_animation(StringName(animation_name), true)
	if uses_animated_character_art:
		if animation_player != null and animation_player.is_playing():
			animation_player.stop()
		return
	if animation_player == null:
		return
	if animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
	elif animation_player.has_animation("Throw"):
		animation_player.play("Throw")


func _play_attack_animation(animation_name: StringName) -> void:
	_play_visual_animation(animation_name, true)
	if uses_animated_character_art:
		if animation_player != null and animation_player.is_playing():
			animation_player.stop()
		return
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
	last_damage_animation = _get_damage_animation_from_attack(attack_data)
	_enter_hit_state()
	_play_visual_animation(last_damage_animation, true)
	if int(attack_data.get("combo_hit_index", 1)) < max_combo_hits:
		hit_reaction_timer = maxf(hit_reaction_timer, combo_hitstun_time)
	apply_damage(attack_data["damage"])
	damage_feedback_requested.emit(self, int(attack_data["damage"]), false, hit_position)
	_flash_damage()
	if attacker != null and attacker.has_method("register_combo_hit"):
		attacker.register_combo_hit(self)
		if current_hp == 0 and attacker.has_method("_finish_combo_after_ko"):
			attacker._finish_combo_after_ko()
	_apply_knockback(attack_data, attack_direction)
	_start_invincibility()
	_start_hit_stop_seconds(_get_defender_hitstop_duration_from_data(attack_data))
	_spawn_hit_effect(hit_position, attack_data["effect_size"])
	_play_hit_se(attack_data["se_type"])
	if attacker != null and attacker.has_method("start_hit_stop_seconds"):
		attacker.start_hit_stop_seconds(_get_attacker_hitstop_duration_from_data(attack_data))
	screen_shake_requested.emit(attack_data["screen_shake"])
	if current_hp <= 0:
		_play_ko_feedback(hit_position, attack_direction)
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
		"hit_stop_frames": 6,
		"effect_size": 1.5,
		"screen_shake": 4.5,
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
	throw_regrab_lock_timer = 0.0
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
	if has_method("reset_character_special_state"):
		call("reset_character_special_state", false)


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
	var guard_damage := _get_guard_damage_from_attack_data(attack_data)
	apply_damage(guard_damage)
	damage_feedback_requested.emit(self, guard_damage, true, hit_position)
	_flash_guard()
	_apply_guard_knockback(attack_data, attack_direction)
	_start_hit_stop_seconds(float(attack_data.get("guard_hitstop_defender", attack_data.get("guard_hit_stop_time", guard_hit_stop_time))))
	_spawn_guard_effect(hit_position)
	_play_guard_se()
	if attacker != null and attacker.has_method("start_hit_stop_seconds"):
		attacker.start_hit_stop_seconds(float(attack_data.get("guard_hitstop_attacker", attack_data.get("guard_hit_stop_time", guard_hit_stop_time))))
	if current_hp <= 0:
		_play_ko_feedback(hit_position, attack_direction)


func _enter_guard_hit_state() -> void:
	is_guard_hit = true
	is_hit = false
	guard_hit_timer = guard_hit_time
	_play_visual_animation(&"guard_hit", true)


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
	if _locks_visual_facing():
		return

	var direction_to_opponent := signf(opponent.global_position.x - global_position.x)
	if absf(opponent.global_position.x - global_position.x) < 12.0 or direction_to_opponent == 0.0:
		return
	facing_direction = direction_to_opponent
	_set_visual_facing()


func _locks_visual_facing() -> bool:
	return current_attack_type != "" or attack_active_timer > 0.0 or kick_active_timer > 0.0 or is_hit or is_guard_hit or _is_throw_busy() or _is_knockdown_state(&"KNOCKDOWN") or _is_knockdown_state(&"KNOCKBACK") or _is_knockdown_state(&"GET_UP") or current_hp <= 0


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
	invincible_flash_timer += delta
	if visual_root != null:
		visual_root.modulate.a = 0.45 if int(invincible_flash_timer * 18.0) % 2 == 0 else 1.0
	if invincibility_timer == 0.0:
		is_invincible = false
		invincible_flash_timer = 0.0
		if visual_root != null:
			visual_root.modulate.a = 1.0
		hurt_box.set_deferred("monitorable", true)


func _start_hit_stop(frame_count: int) -> void:
	hit_stop_timer = maxf(hit_stop_timer, (float(frame_count) / 60.0) * _hitstop_multiplier())


func _start_hit_stop_seconds(duration: float) -> void:
	hit_stop_timer = maxf(hit_stop_timer, duration * _hitstop_multiplier())


func _get_attacker_hitstop_duration_from_data(attack_data: Dictionary) -> float:
	if attack_data.has("hitstop_attacker"):
		return float(attack_data["hitstop_attacker"])
	return float(attack_data.get("hit_stop_frames", 4)) / 60.0


func _get_defender_hitstop_duration_from_data(attack_data: Dictionary) -> float:
	if attack_data.has("hitstop_defender"):
		return float(attack_data["hitstop_defender"])
	return float(attack_data.get("hit_stop_frames", 4)) / 60.0


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
	if hit_index <= 2:
		return 1.0
	if hit_index <= 4:
		return second_hit_damage_scale
	if hit_index <= 6:
		return third_hit_damage_scale
	if hit_index <= 8:
		return 0.70
	return 0.60


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


func _setup_feel_effect_pools() -> void:
	if not hit_effect_pool.is_empty() or not movement_dust_pool.is_empty() or not afterimage_pool.is_empty():
		return
	for index in range(feel_effect_pool_size):
		hit_effect_pool.append(_create_pooled_polygon_effect("PooledHitEffect"))
		movement_dust_pool.append(_create_pooled_polygon_effect("PooledDustEffect"))
		afterimage_pool.append(_create_pooled_polygon_effect("PooledAfterimage"))


func _create_pooled_polygon_effect(effect_name: String) -> Node2D:
	var effect_root := Node2D.new()
	_prepare_character_effect_node(effect_root, effect_name, 0)
	effect_root.visible = false
	var flash := Polygon2D.new()
	flash.name = "Flash"
	effect_root.add_child(flash)
	var ring := Polygon2D.new()
	ring.name = "Ring"
	effect_root.add_child(ring)
	_get_character_effect_parent().add_child(effect_root)
	return effect_root


func _get_pooled_effect(pool: Array[Node2D], effect_name: String) -> Node2D:
	for effect in pool:
		if effect != null and is_instance_valid(effect) and not effect.visible:
			return effect
	var fallback := _create_pooled_polygon_effect(effect_name)
	pool.append(fallback)
	return fallback


func _spawn_hit_effect(hit_position: Vector2, effect_size: float) -> void:
	var effect_root := _get_pooled_effect(hit_effect_pool, "PooledHitEffect")
	_prepare_character_effect_node(effect_root, "HitEffect", 20)
	effect_root.global_position = hit_position
	effect_root.scale = Vector2.ONE
	effect_root.visible = true

	var flash := effect_root.get_node("Flash") as Polygon2D
	var ring := effect_root.get_node("Ring") as Polygon2D
	var size := 18.0 * effect_size
	flash.color = _hit_effect_color(effect_size)
	flash.polygon = PackedVector2Array([
		Vector2(0, -size),
		Vector2(size, 0),
		Vector2(0, size),
		Vector2(-size, 0),
	])
	var ring_size := size * 1.35
	ring.color = Color(flash.color.r, flash.color.g, flash.color.b, 0.22)
	ring.polygon = _circle_points(18, ring_size)

	var tween := effect_root.create_tween()
	tween.tween_property(effect_root, "scale", Vector2(1.45, 1.45), 0.12)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.12)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.16)
	tween.tween_callback(_release_pooled_effect.bind(effect_root))


func _hit_effect_color(effect_size: float) -> Color:
	if effect_size >= 2.0:
		return Color(0.78, 0.35, 1.0, 0.86)
	if effect_size >= 1.5:
		return Color(1.0, 0.48, 0.14, 0.84)
	if effect_size > 1.0:
		return Color(1.0, 0.92, 0.25, 0.80)
	return Color(1.0, 1.0, 1.0, 0.78)


func _spawn_throw_success_effect(effect_position: Vector2) -> void:
	_spawn_throw_effect(effect_position, "ThrowSuccessEffect", Color(0.55, 0.95, 1.0, 0.7), 14.0)


func _spawn_throw_impact_effect(effect_position: Vector2) -> void:
	_spawn_throw_effect(effect_position, "ThrowImpactEffect", Color(1.0, 0.48, 0.14, 0.78), 24.0)


func _spawn_throw_effect(effect_position: Vector2, effect_name: String, effect_color: Color, radius: float) -> void:
	var effect_root := Node2D.new()
	_prepare_character_effect_node(effect_root, effect_name, 20)
	effect_root.global_position = effect_position

	var flash := Polygon2D.new()
	var points := PackedVector2Array()
	for point_index in range(12):
		var angle := TAU * float(point_index) / 12.0
		var point_radius := radius if point_index % 2 == 0 else radius * 0.45
		points.append(Vector2(cos(angle), sin(angle)) * point_radius)
	flash.color = effect_color
	flash.polygon = points
	effect_root.add_child(flash)
	_get_character_effect_parent().add_child(effect_root)

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

	ko_hit_se = AudioStreamPlayer2D.new()
	ko_hit_se.name = "KOHitSE"
	ko_hit_se.stream = _create_hit_stream(90.0)
	add_child(ko_hit_se)

	special_hit_se = AudioStreamPlayer2D.new()
	special_hit_se.name = "SpecialHitSE"
	special_hit_se.stream = _create_hit_stream(320.0)
	add_child(special_hit_se)


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
	_play_audio_manager_se("hit_%s" % se_type)
	if se_type == "ko":
		ko_hit_se.play()
	elif se_type == "special":
		special_hit_se.play()
	elif se_type == "strong":
		strong_hit_se.play()
	else:
		weak_hit_se.play()


func _play_guard_se() -> void:
	_play_audio_manager_se("guard")
	guard_hit_se.play()


func _play_throw_se() -> void:
	_play_audio_manager_se("throw")
	throw_se.play()


func _play_throw_escape_se() -> void:
	_play_audio_manager_se("throw_escape")
	throw_escape_se.play()


func _spawn_guard_effect(hit_position: Vector2) -> void:
	var effect_root := _get_pooled_effect(hit_effect_pool, "PooledGuardEffect")
	_prepare_character_effect_node(effect_root, "GuardEffect", 20)
	effect_root.global_position = hit_position
	effect_root.scale = Vector2.ONE
	effect_root.visible = true

	var flash := effect_root.get_node("Flash") as Polygon2D
	var ring := effect_root.get_node("Ring") as Polygon2D
	var radius := 16.0
	flash.color = Color(0.45, 0.9, 1.0, 0.65)
	flash.polygon = _circle_points(16, radius)
	ring.color = Color(0.75, 0.95, 1.0, 0.24)
	ring.polygon = _circle_points(24, radius * 1.8)

	var tween := effect_root.create_tween()
	tween.tween_property(effect_root, "scale", Vector2(1.7, 1.7), 0.12)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.12)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.12)
	tween.tween_callback(_release_pooled_effect.bind(effect_root))


func _spawn_movement_dust(effect_position: Vector2, dust_scale := 1.0) -> void:
	var effect_root := _get_pooled_effect(movement_dust_pool, "PooledDustEffect")
	_prepare_character_effect_node(effect_root, "DustEffect", -2)
	effect_root.global_position = effect_position
	effect_root.scale = Vector2.ONE * dust_scale
	effect_root.visible = true
	var flash := effect_root.get_node("Flash") as Polygon2D
	var ring := effect_root.get_node("Ring") as Polygon2D
	flash.color = Color(0.72, 0.68, 0.56, 0.42)
	flash.polygon = PackedVector2Array([
		Vector2(-18, 0),
		Vector2(-8, -7),
		Vector2(12, -5),
		Vector2(24, 0),
		Vector2(8, 6),
		Vector2(-14, 5),
	])
	ring.color = Color(0.72, 0.68, 0.56, 0.18)
	ring.polygon = _circle_points(14, 18.0)
	var tween := effect_root.create_tween()
	tween.tween_property(effect_root, "scale", Vector2(1.55, 1.15) * dust_scale, 0.16)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.16)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.16)
	tween.tween_callback(_release_pooled_effect.bind(effect_root))


func _spawn_afterimage() -> void:
	if uses_official_character_art:
		return
	var effect_root := _get_pooled_effect(afterimage_pool, "PooledAfterimage")
	_prepare_character_effect_node(effect_root, "Afterimage", -1)
	effect_root.global_position = global_position + Vector2(0.0, -54.0)
	effect_root.scale = Vector2(facing_direction, 1.0)
	effect_root.visible = true
	var flash := effect_root.get_node("Flash") as Polygon2D
	var ring := effect_root.get_node("Ring") as Polygon2D
	flash.color = Color(0.55, 0.85, 1.0, 0.22)
	flash.polygon = PackedVector2Array([
		Vector2(-18, -42),
		Vector2(18, -42),
		Vector2(18, 42),
		Vector2(-18, 42),
	])
	ring.color = Color.TRANSPARENT
	ring.polygon = PackedVector2Array()
	var duration := 0.22 if _is_speed_style_fighter() else 0.14
	var tween := effect_root.create_tween()
	tween.tween_property(effect_root, "position:x", effect_root.position.x - facing_direction * 16.0, duration)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, duration)
	tween.tween_callback(_release_pooled_effect.bind(effect_root))


func _release_pooled_effect(effect_root: Node2D) -> void:
	if effect_root == null or not is_instance_valid(effect_root):
		return
	effect_root.visible = false
	effect_root.modulate = Color.WHITE
	for child in effect_root.get_children():
		if child is CanvasItem:
			child.modulate = Color.WHITE


func _circle_points(point_count: int, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(point_count):
		var angle := TAU * float(point_index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _update_movement_feedback(direction: float, was_on_floor_before_move: bool) -> void:
	var moving_now := absf(direction) > 0.0 and is_on_floor() and not is_hit and not _is_throw_busy()
	if moving_now and not was_moving_last_frame:
		_spawn_movement_dust(global_position + Vector2(-facing_direction * 18.0, -4.0), 0.8)
		_spawn_afterimage()
		if _is_speed_style_fighter():
			_spawn_afterimage()
	was_moving_last_frame = moving_now

	if not was_on_floor_before_move and is_on_floor():
		_spawn_movement_dust(global_position + Vector2(0.0, -2.0), 1.0)
		screen_shake_requested.emit(landing_shake_strength)
	was_on_floor_last_frame = is_on_floor()


func _flash_damage() -> void:
	if uses_animated_character_art and character_visual_controller != null and character_visual_controller.has_method("show_damage_flash"):
		character_visual_controller.call("show_damage_flash")
		return
	if visual_root == null:
		return
	visual_root.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(visual_root, "modulate", Color(1.0, 0.72, 0.72, 1.0), 0.04)
	tween.tween_property(visual_root, "modulate", Color.WHITE, 0.08)


func _flash_guard() -> void:
	if uses_animated_character_art and animated_character_sprite != null:
		animated_character_sprite.modulate = Color(0.72, 0.9, 1.0, 1.0)
		var sprite_tween := create_tween()
		sprite_tween.tween_property(animated_character_sprite, "modulate", Color.WHITE, 0.12)
		return
	if visual_root == null:
		return
	visual_root.modulate = Color(0.72, 0.9, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(visual_root, "modulate", Color.WHITE, 0.12)


func _play_ko_feedback(hit_position: Vector2, attack_direction: float) -> void:
	_start_hit_stop(10)
	_spawn_hit_effect(hit_position, 3.0)
	_play_hit_se("ko")
	screen_shake_requested.emit(ko_shake_strength)
	velocity.x += attack_direction * 220.0
	velocity.y = minf(velocity.y, -180.0)


func _hitstop_multiplier() -> float:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and settings.has_method("get_hitstop_multiplier"):
		return float(settings.call("get_hitstop_multiplier"))
	return 1.0


func _play_audio_manager_se(se_id: String) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play_se"):
		audio.call("play_se", se_id)


func _is_speed_style_fighter() -> bool:
	var definition: Resource = get("fighter_definition")
	if definition != null:
		return String(definition.fighter_type).to_lower() == "speed"
	return move_speed >= 340.0


func _set_visual_facing() -> void:
	var facing := int(signf(facing_direction))
	if facing == 0:
		facing = 1
	if uses_animated_character_art and character_visual_controller != null and character_visual_controller.has_method("set_facing"):
		visual_root.scale.x = 1.0
		character_visual_controller.call("set_facing", facing)
	else:
		visual_root.scale.x = float(facing)


func _sync_single_character_visual() -> void:
	if not uses_animated_character_art:
		return
	if animated_character_sprite != null:
		animated_character_sprite.visible = true
	if character_sprite != null:
		character_sprite.visible = false
	if idle_placeholder != null:
		idle_placeholder.visible = false
	if placeholder_body != null:
		placeholder_body.visible = false
	if placeholder_head != null:
		placeholder_head.visible = false
	if guard_visual != null:
		guard_visual.visible = false
	if crouch_visual != null:
		crouch_visual.visible = false
	if crouch_guard_visual != null:
		crouch_guard_visual.visible = false
	if visual_root != null:
		visual_root.scale.y = 1.0


func _clear_motion_ghosts() -> void:
	for ghost in afterimage_pool:
		if ghost == null or not is_instance_valid(ghost):
			continue
		ghost.visible = false
		ghost.modulate.a = 0.0


func _get_horizontal_input_direction() -> float:
	if not input_enabled:
		return 0.0
	var input_value := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if absf(input_value) < 0.1:
		return 0.0
	return signf(input_value)


func _prepare_jump_visual_state() -> void:
	jump_pressed_this_airtime = true
	is_crouching = false
	is_crouch_guarding = false
	is_guarding = false
	is_guard_hit = false
	guard_type = "none"
	if animation_player != null and animation_player.is_playing():
		animation_player.stop()
	_set_punch_hitbox_active(false, false)
	_set_kick_hitbox_active(false, false)
	_clear_motion_ghosts()
	if has_method("restore_sprite_transform"):
		call("restore_sprite_transform")
	elif visual_root != null:
		visual_root.position = Vector2.ZERO
		visual_root.rotation = 0.0
		visual_root.scale.y = 1.0
	_sync_single_character_visual()
	_play_visual_animation(&"jump_start", true)


func _play_visual_animation(animation_name: StringName, force := false) -> void:
	if not uses_animated_character_art:
		return
	if character_visual_controller == null or not character_visual_controller.has_method("play_animation"):
		return
	character_visual_controller.call("play_animation", animation_name, force)


func _get_current_visual_animation() -> StringName:
	if current_hp <= 0:
		return &"ko"
	if _is_knockdown_state(&"KNOCKDOWN"):
		return &"knockdown"
	if _is_knockdown_state(&"GET_UP"):
		return &"stand_up"
	if _is_knockdown_state(&"KNOCKBACK"):
		return &"knockback"
	if throw_state == "THROW_STARTUP" or throw_state == "THROW_HOLD" or throw_state == "THROW_RECOVERY" or throw_state == "THROW_WHIFF":
		return &"throw"
	if throw_state == "THROWN" or is_throw_locked or is_throw_escape_pending:
		return &"thrown"
	if is_throw_escaping:
		return &"getup"
	if is_guard_hit:
		return &"guard_hit"
	if is_hit:
		return last_damage_animation
	if is_crouch_guarding or is_guarding:
		return &"guard"
	if is_crouching:
		return &"crouch_idle"
	if current_attack_type == "Punch":
		if not is_on_floor():
			return &"jump_punch"
		if is_crouching:
			return &"crouch_punch"
		return &"punch_2" if combo_step == 2 else &"punch_1"
	if current_attack_type == "Kick":
		if not is_on_floor():
			return &"jump_kick"
		if is_crouching:
			return &"crouch_kick"
		return &"kick_2" if combo_step >= max_combo_hits else &"kick_1"
	if not is_on_floor():
		return &"jump_up" if velocity.y < 0.0 else &"jump_fall"
	if absf(velocity.x) > move_speed * 1.05:
		return &"dash"
	if absf(velocity.x) > 0.0:
		return &"walk_forward"
	return &"idle"


func _get_damage_animation_from_attack(attack_data: Dictionary) -> StringName:
	var attack_type := String(attack_data.get("attack_type", "")).to_lower()
	var damage_value := float(attack_data.get("damage", 0))
	var knockback_x := absf(float(attack_data.get("knockback_x", 0.0)))
	var knockback_y := absf(float(attack_data.get("knockback_y", 0.0)))
	if attack_data.has("knockback"):
		var knockback_value: Vector2 = attack_data.get("knockback")
		knockback_x = maxf(knockback_x, absf(knockback_value.x))
		knockback_y = maxf(knockback_y, absf(knockback_value.y))
	if attack_type == "kick" or attack_type == "throw" or attack_type == "special" or attack_type == "ultimate":
		return &"damage_heavy"
	if damage_value >= maxf(float(kick_damage), float(punch_damage) + 3.0):
		return &"damage_heavy"
	if knockback_x >= 240.0 or knockback_y >= 70.0:
		return &"damage_heavy"
	return &"damage_light"


func _is_knockdown_state(state_name: StringName) -> bool:
	return get("knockdown_state") == state_name


func _update_visual_state() -> void:
	_set_visual_facing()
	_sync_single_character_visual()
	_play_visual_animation(_get_current_visual_animation())

	if not debug_state_label_enabled:
		state_label.visible = false
		if shadow_sprite != null and shadow_sprite.visible:
			var airborne_scale_no_debug := 0.72 if not is_on_floor() else 1.0
			shadow_sprite.scale = Vector2(base_shadow_scale.x * airborne_scale_no_debug, base_shadow_scale.y * airborne_scale_no_debug)
			shadow_sprite.modulate.a = 0.28 if not is_on_floor() else 0.42
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
	if uses_official_character_art and character_visual_controller != null and character_visual_controller.has_method("get_debug_source"):
		state_label.text += "\nVISUAL: %s" % String(character_visual_controller.call("get_debug_source")).to_upper()

	if uses_official_character_art:
		guard_visual.visible = false
		crouch_visual.visible = false
		crouch_guard_visual.visible = false
	else:
		guard_visual.visible = is_guarding and not is_crouch_guarding
		crouch_visual.visible = is_crouching
		crouch_guard_visual.visible = is_crouch_guarding
	var target_y_scale := 1.0 if uses_official_character_art else (0.7 if is_crouching or is_crouch_guarding else 1.0)
	visual_root.scale.y = target_y_scale
	if shadow_sprite != null and shadow_sprite.visible:
		var airborne_scale := 0.72 if not is_on_floor() else 1.0
		shadow_sprite.scale = Vector2(base_shadow_scale.x * airborne_scale, base_shadow_scale.y * airborne_scale)
		shadow_sprite.modulate.a = 0.28 if not is_on_floor() else 0.42
	queue_redraw()


func _draw() -> void:
	if not debug_state_label_enabled:
		return

	var range_x := facing_direction * (throw_range + throw_body_width)
	var rect_x := 0.0 if facing_direction > 0.0 else range_x
	var throw_rect := Rect2(rect_x, -96.0, absf(range_x), 96.0)
	draw_rect(throw_rect, Color(0.35, 0.8, 1.0, 0.12), true)
	draw_rect(throw_rect, Color(0.35, 0.8, 1.0, 0.45), false, 1.0)
