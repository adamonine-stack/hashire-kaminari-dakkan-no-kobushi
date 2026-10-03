extends Node2D

enum Phase { IDLE, CHARGE, SLAM, WARNING, ACTIVE, RECOVERY }
var fighter: Node
var data: Resource
var phase := Phase.IDLE
var elapsed := 0.0
var clock_time := 0.0
var cooldown := 0.0
var mid_cooldown := 0.0
var target_position := Vector2.ZERO
var strike_area: Area2D
var strike_shape: CollisionShape2D
var hit_targets := {}
var uses := 0
var actual_hits := 0
var proportions: Node
const PILLAR_TEXTURE = preload("res://assets/effects/dark_seiya_pillar.png")

func setup(actor: Node, attack: Resource) -> void:
	fighter = actor
	data = attack
	z_index = 4
	proportions = fighter.get_node_or_null("SeiyaProportions")
	strike_area = Area2D.new()
	strike_area.collision_layer = 0
	strike_area.collision_mask = fighter.punch_area.collision_mask
	strike_area.monitoring = false
	strike_area.monitorable = false
	strike_shape = CollisionShape2D.new()
	strike_shape.shape = RectangleShape2D.new()
	strike_shape.shape.size = data.hitbox_size
	strike_shape.disabled = true
	strike_area.add_child(strike_shape)
	add_child(strike_area)
	strike_area.area_entered.connect(on_contact)

func _process(delta: float) -> void:
	clock_time += delta
	queue_redraw()

func busy() -> bool:
	return phase != Phase.IDLE

func choose_distance_action(delta: float) -> bool:
	cooldown = maxf(0, cooldown-delta)
	mid_cooldown = maxf(0,mid_cooldown-delta)
	if not fighter.can_ai_act() or not fighter.is_on_floor(): return false
	var target = fighter._get_opponent()
	var distance: float = absf(target.global_position.x-fighter.global_position.x)
	if distance >= data.far_distance and cooldown == 0:
		return start_normal()
	if distance >= data.mid_distance and distance < data.far_distance and mid_cooldown == 0:
		fighter._face_opponent()
		fighter.start_attack(data.mid_attack_id)
		mid_cooldown = data.mid_cooldown
		return true
	return false

func start_special() -> bool:
	# Compatibility entry point: this is a cooldown-based normal distance move, no gauge.
	return start_normal()

func start_normal() -> bool:
	if busy() or cooldown > 0 or not fighter.is_round_active or fighter.current_hp <= 0 or not fighter.is_on_floor(): return false
	var target = fighter._get_opponent()
	if target == null: return false
	# Snapshot once. The marker and Area stay at this coordinate if target moves.
	target_position = Vector2(target.global_position.x, fighter.global_position.y)
	fighter._cancel_current_action()
	fighter.cancel_current_ai_action(false)
	fighter._face_opponent()
	fighter.velocity = Vector2.ZERO
	phase = Phase.CHARGE
	elapsed = 0
	cooldown = data.cooldown
	hit_targets.clear()
	uses += 1
	fighter._play_visual_animation(&"aura_charge",true)
	fighter.ai_action_started.emit(data.attack_id)
	print("DARK_AURA_START target=", target_position, " cooldown=", cooldown)
	return true

func advance(delta: float) -> void:
	if not fighter.is_round_active or fighter.current_hp <= 0 or fighter._is_knockdown_busy() or fighter.is_hit:
		cancel()
		return
	if fighter._update_hit_stop(delta): return
	cooldown = maxf(0,cooldown-delta)
	elapsed += delta
	fighter.velocity.x = 0
	if not fighter.is_on_floor(): fighter.velocity.y += fighter.gravity*delta
	fighter.move_and_slide()
	match phase:
		Phase.CHARGE:
			if elapsed >= data.charge_time*0.6:
				fighter._play_visual_animation(&"aura_charge_max")
			if elapsed >= data.charge_time: enter_phase(Phase.SLAM,&"aura_slam")
		Phase.SLAM:
			if elapsed >= data.slam_time:
				enter_phase(Phase.WARNING,&"aura_contact")
				fighter.screen_shake_requested.emit(2.0)
				fighter._play_audio_manager_se("hit_strong")
				print("DARK_AURA_WARNING target=",target_position)
		Phase.WARNING:
			if elapsed >= data.warning_time:
				enter_phase(Phase.ACTIVE,&"aura_contact")
				strike_area.global_position = target_position + Vector2(0,-data.hitbox_size.y*0.5)
				strike_area.set_deferred("monitoring",true)
				strike_shape.set_deferred("disabled",false)
				fighter._play_audio_manager_se("hit_special")
				print("DARK_AURA_ACTIVE size=",data.hitbox_size)
		Phase.ACTIVE:
			for area in strike_area.get_overlapping_areas(): on_contact(area)
			if elapsed >= data.active_time:
				deactivate_hitbox()
				enter_phase(Phase.RECOVERY,&"aura_recovery")
		Phase.RECOVERY:
			if elapsed >= data.recovery_time:
				cancel()
				fighter.enter_idle()
				fighter._play_visual_animation(&"idle",true)

func enter_phase(next: Phase, animation: StringName) -> void:
	phase = next
	elapsed = 0
	fighter._play_visual_animation(animation,true)

func deactivate_hitbox() -> void:
	strike_area.set_deferred("monitoring",false)
	strike_shape.set_deferred("disabled",true)

func cancel() -> void:
	if is_instance_valid(strike_area): deactivate_hitbox()
	if busy(): fighter.ai_action_finished.emit(data.attack_id)
	phase = Phase.IDLE
	elapsed = 0
	queue_redraw()

func on_contact(area: Area2D) -> void:
	if phase != Phase.ACTIVE: return
	var target = fighter._get_valid_hurtbox_target(area)
	if target == null or hit_targets.has(target.get_instance_id()): return
	if target != fighter._get_opponent(): return
	hit_targets[target.get_instance_id()] = true
	actual_hits += 1
	var direction: float = signf(target.global_position.x-fighter.global_position.x)
	target.receive_attack({"damage":data.damage,"base_damage":data.damage,"attack_type":"normal",
		"attack_category":"normal","is_special":false,
		"attack_id":data.attack_id,"attack_height":"low","is_guardable":true,"guard_damage_multiplier":0.15,
		"knockback_x":150.0,"knockback_y":80.0,"hitstun_time":0.3,"hitstop_time":0.06,
		"hit_stop_frames":4,"effect_size":1.8,"screen_shake":2.0,"se_type":"strong"},
		direction,target.global_position+Vector2(0,-75),fighter)
	print("DARK_AURA_HIT count=",actual_hits)

func _draw() -> void:
	if fighter == null or fighter.current_hp <= 0: return
	var height: float = fighter.default_hurt_box_size.y / 0.88
	var intensity := 0.4
	if fighter.is_dashing: intensity = 0.65
	if not fighter.is_on_floor(): intensity = 0.55
	if fighter.current_attack_type != "": intensity = 0.8
	if fighter.is_hit: intensity = 0.22
	if busy(): intensity = 0.8 + minf(elapsed/data.charge_time,1.0)*0.45
	# Keep the smoke on its own layer, following the pose's head-to-ground span.
	if proportions != null:
		var body_sprite: AnimatedSprite2D = fighter.animated_character_sprite
		var body_texture = body_sprite.sprite_frames.get_frame_texture(body_sprite.animation,body_sprite.frame)
		height = maxf(40,-body_sprite.position.y-(proportions.head_bounds.position.y-body_texture.get_height()*0.5)*body_sprite.scale.y)
	for side in [-1,1]:
		draw_texture_rect(PILLAR_TEXTURE,Rect2(Vector2(-66 if side<0 else 35,-height*0.87),Vector2(32,height*0.87)),false,Color(1,1,1,intensity*0.7))
		for j in range(5):
			var pos := Vector2(side*(30+sin(clock_time*2+j)*10),-height*(0.18+j*0.16))
			if phase == Phase.CHARGE: pos.x *= 0.7
			draw_texture_rect(PILLAR_TEXTURE,Rect2(pos-Vector2(12,26),Vector2(24,52)),false,Color(1,0.8,1,intensity*0.65))
	for j in range(12):
		var y := -fmod(clock_time*36+j*19,height)
		var x := sin(clock_time*1.8+j*1.7)*55
		draw_rect(Rect2(Vector2(x,y),Vector2(2,3)*intensity),Color(0.62,0.19,0.95,0.65))
	# Eye glow follows the current head landmark and sprite facing each frame.
	if proportions != null:
		var sprite: AnimatedSprite2D = fighter.animated_character_sprite
		var eye: Vector2 = Vector2(proportions.head_bounds.get_center().x+proportions.head_bounds.size.x*0.16,proportions.head_bounds.position.y+proportions.head_bounds.size.y*0.72)
		eye = proportions.head_anchor+(eye-proportions.head_anchor)*fighter.fighter_definition.head_scale
		var texture = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
		eye -= texture.get_size()*0.5
		if sprite.flip_h: eye.x *= -1
		eye = sprite.position + eye*sprite.scale
		draw_rect(Rect2(eye-Vector2(4,2),Vector2(8,4)),Color(0.5,0.0,0.8,0.35*intensity))
		draw_rect(Rect2(eye-Vector2(2.5,1),Vector2(5,2)),Color(0.87,0.45,1,0.9))
	# Normal aura coverage derives from the actual active rectangle, not a guess.
	if fighter.attack_phase == fighter.AttackPhase.ACTIVE:
		var area: Area2D = fighter.kick_area if fighter.current_attack_type == "Kick" else fighter.punch_area
		var shape: CollisionShape2D = fighter.kick_shape if fighter.current_attack_type == "Kick" else fighter.punch_shape
		var rect := Rect2(area.position-shape.shape.size*0.5,shape.shape.size)
		draw_texture_rect(PILLAR_TEXTURE,rect,false,Color(1,0.9,1,0.95))
		for j in range(4):
			var y: float = rect.position.y+rect.size.y*(float(j)+0.5)/4
			draw_rect(Rect2(Vector2(rect.position.x,y),Vector2(rect.size.x,2)),Color(0.67,0.21,0.9,0.65))
	if phase in [Phase.WARNING,Phase.ACTIVE]:
		var local_target := to_local(target_position)
		var half: float = data.hitbox_size.x*0.5
		# Horizontal ground warning uses exactly the future damage width.
		draw_texture_rect(PILLAR_TEXTURE,Rect2(local_target-Vector2(half,12),Vector2(data.hitbox_size.x,12)),false,Color(1,0.7,1,0.9))
		draw_rect(Rect2(local_target-Vector2(half,3),Vector2(data.hitbox_size.x,3)),Color(0.83,0.37,1,0.9))
		if phase == Phase.WARNING:
			for j in range(7):
				draw_rect(Rect2(local_target+Vector2(-half+j*half/3,-8-fmod(clock_time*30+j*4,25)),Vector2(2,4)),Color(0.7,0.2,1,0.8))
		else:
			var rect := Rect2(local_target-Vector2(half,data.hitbox_size.y),data.hitbox_size)
			draw_texture_rect(PILLAR_TEXTURE,rect,false,Color(1,0.85+sin(clock_time*28)*0.1,1,1))
	if phase == Phase.WARNING:
		var fist := Vector2(34*fighter.facing_direction,-2)
		draw_texture_rect(PILLAR_TEXTURE,Rect2(fist-Vector2(36,14),Vector2(72,16)),false,Color(1,0.7,1,maxf(0,1-elapsed/data.warning_time)))
		var destination := to_local(target_position)
		draw_rect(Rect2(Vector2(minf(fist.x,destination.x),-3),Vector2(absf(destination.x-fist.x),2)),Color(0.3,0.04,0.5,maxf(0,0.7-elapsed)))
