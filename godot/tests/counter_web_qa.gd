extends "res://tests/crusher_web_qa_base.gd"

func _initialize() -> void:
	attacker_definition = "enemy_02_speed"
	attacker_definition_folder = "enemies"
	victim_definition_folder = "fighters"
	attacker_node_name = "Enemy"
	victim_node_name = "Player"
	victim_definitions = ["ally_balance","ally_power","ally_speed"]
	reaction_prefix = "received_shadow_counter"
	evidence_folder = "shadow_counter_final"
	dedicated_attack_clips = ["shadow_counter_startup","shadow_counter_active","shadow_counter_finish"]
	attack_original_folder = "shadow_boxer_v2"
	minimum_contact_height = 40.0
	super._initialize()

func reset(manager: Node, actor: Node, point: Vector2, facing: int) -> void:
	actor.ai_profile = null
	actor.ai_throw_probability = -1.0
	actor.ai_guard_enabled = false
	manager._flow_sequence_id += 1
	manager.flow_state = manager.BattleState.FIGHT
	manager.current_enemy_index = 4
	manager._apply_current_stage_definition()
	manager._update_battle_hud_enemy()
	await super.reset(manager,actor,point,facing)
	actor._clear_guard_state()
	actor.is_guard_hit = false
	actor.guard_recoil_timer = 0.0
	actor.is_hit = false
	actor.hit_reaction_timer = 0.0
	actor.ai_enabled = false
	actor.input_enabled = false

func capture(label: String) -> void:
	if OS.has_feature("web"):
		var previous_pause := paused
		paused = true
		await RenderingServer.frame_post_draw
		JavaScriptBridge.eval("window.counterQACaptureDone = ''",true)
		print("COUNTER_CAPTURE "+label)
		var deadline := Time.get_ticks_msec()+20000
		while JavaScriptBridge.eval("window.counterQACaptureDone",true) != label:
			if Time.get_ticks_msec()>deadline:
				check(false,"browser capture acknowledgement "+label)
				break
			await get_tree().create_timer(0.05,true,false,true).timeout
		screenshots += 1
		paused = previous_pause
	else:
		await super.capture(label)
		print("COUNTER_CAPTURE "+label)

func extra_checks(manager: Node, attacker: Node, target: Node) -> void:
	for definition in victim_definitions:
		target.apply_character_data(load("res://data/fighters/%s.tres" % definition))
		var sprite: AnimatedSprite2D = target.animated_character_sprite
		var idle_area := opaque_body_area(sprite.sprite_frames.get_frame_texture(&"idle",0))
		for clip in ["received_shadow_counter_hit","received_shadow_counter_air","received_shadow_counter_down"]:
			for frame in range(sprite.sprite_frames.get_frame_count(clip)):
				var ratio := opaque_body_area(sprite.sprite_frames.get_frame_texture(clip,frame))/idle_area
				check(ratio > 0.90 and ratio < 1.10,definition+" retains anatomical body mass "+clip)
		for direction in [1,-1]:
			await reset(manager,attacker,Vector2(640-180*direction,520),direction)
			attacker.set_physics_process(false)
			await reset(manager,target,Vector2(640,520),-direction)
			target.set_physics_process(false)
			target.is_guarding = true
			target.guard_type = "high"
			var hp: float = target.current_hp
			var packet: Dictionary = attacker._get_character_special_attack_dictionary()
			check(not target.receive_attack(packet,direction,target.global_position,attacker),definition+" blocks hammer")
			check(target.current_hp == hp,definition+" guard has zero chip damage")
			target._update_visual_state()
			check(sprite.animation == &"guard_hit",definition+" retains dedicated guard")
			check_visible_art(sprite,definition+" guard")
			await capture(definition+"_guard_"+str(direction))
	await reset(manager,attacker,Vector2(600,520),1)
	await reset(manager,target,Vector2(660,520),-1)
	attacker.set_physics_process(false)
	target.set_physics_process(false)
	attacker.set_special_gauge(100)
	attacker.reversal_cooldown = 0.0
	attacker.ai_profile = attacker.fighter_definition.ai_profile
	manager.update_enemy_target()
	attacker.ai_enabled = true
	attacker.is_hit = true
	attacker.special_ai_use_chance = 10.0 # Deterministic exercise of the real situational AI branch.
	attacker.reversal_ai_checked = false
	attacker.reversal_ai_observation = 0.11
	attacker._try_observed_special_reversal()
	check(not attacker.is_character_special_busy(),"Shadow AI waits for observed hit delay")
	attacker.reversal_ai_observation = 1.0
	attacker._try_observed_special_reversal()
	check(attacker.is_character_special_busy(),"Shadow AI reverses observed hitstun")
	attacker._update_visual_state()
	check(attacker.animated_character_sprite.animation == &"shadow_counter_startup","Shadow AI uses authored windup")
	await capture("shadow_ai_reversal")
	attacker.ai_enabled = false

var motion_area_cache := {}
var motion_bounds_cache := {}
func motion_key(texture: Texture2D) -> String:
	return texture.atlas.resource_path+str(texture.region) if texture is AtlasTexture else str(texture.get_instance_id())
func opaque_body_area(texture: Texture2D) -> float:
	var key := motion_key(texture)
	if not motion_area_cache.has(key): motion_area_cache[key] = super.opaque_body_area(texture)
	return motion_area_cache[key]
func check_visible_art(sprite: AnimatedSprite2D, label: String) -> void:
	if not is_zero_approx(sprite.rotation):
		super.check_visible_art(sprite,label)
		return
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	var key := motion_key(texture)
	if not motion_bounds_cache.has(key): motion_bounds_cache[key] = texture.get_image().get_used_rect()
	var bounds: Rect2i = motion_bounds_cache[key]
	var t := sprite.get_global_transform_with_canvas()
	var screen := root.get_visible_rect().size
	for point in [Vector2(bounds.position),Vector2(bounds.end),Vector2(bounds.position.x,bounds.end.y),Vector2(bounds.end.x,bounds.position.y)]:
		if texture is AtlasTexture: point += texture.margin.position
		point -= texture.get_size()*0.5
		if sprite.flip_h: point.x = -point.x
		var actual: Vector2 = t*(point+sprite.offset)
		check(actual.x>=0 and actual.x<=screen.x and actual.y>=0 and actual.y<=screen.y,label+" art inside rendered viewport")
