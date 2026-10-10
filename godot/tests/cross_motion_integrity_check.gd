extends "res://tests/special_launch_reaction_check.gd"

var inspected_frames := 0
var captured_frames := {}

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var was_paused := paused
	paused = true
	await process_frame
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png(output.path_join(label+".png")) == OK,"save "+label)
	screenshots += 1
	print("CROSS_CAPTURE "+label)
	paused = was_paused

func clean_reset(manager: Node, actor: Node, point: Vector2, facing: int) -> void:
	actor.ai_profile = null
	actor.ai_throw_probability = -1.0
	actor.ai_guard_enabled = false
	await reset(manager,actor,point,facing)
	actor._finish_throw()
	actor.throw_regrab_lock_timer = 0.0
	actor.throw_escape_timer = 0.0
	actor._clear_guard_state()
	actor.is_guard_hit = false
	actor.is_hit = false
	actor.hit_reaction_timer = 0.0
	actor.guard_recoil_timer = 0.0
	actor.ai_enabled = false
	actor.input_enabled = false

func run() -> void:
	output = ProjectSettings.globalize_path("res://").path_join("../evidence/cross_runtime").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager._hide_player_selection()
	manager.current_enemy_index = 3
	manager._apply_current_stage_definition()
	manager._set_battle_active(true)
	paused = false
	var player: Node = battle.get_node("Player")
	var cross: Node = battle.get_node("Enemy")
	var definition: FighterDefinition = load("res://data/enemies/enemy_05_power.tres")
	cross.apply_character_data(definition)
	player.apply_character_data(load("res://data/fighters/ally_balance.tres"))
	player.visible = true
	cross.visible = true
	manager._update_battle_hud_enemy()
	manager._update_battle_hud_player()
	await clean_reset(manager,player,Vector2(460,520),1)
	await clean_reset(manager,cross,Vector2(860,520),-1)
	player.set_physics_process(false)
	cross.set_physics_process(false)
	var sprite: AnimatedSprite2D = cross.animated_character_sprite
	var fixed_scale := sprite.scale
	var fixed_position := sprite.position
	var frames := sprite.sprite_frames
	var idle := frames.get_frame_texture(&"idle",0)
	var idle_height := idle.get_image().get_used_rect().size.y
	var idle_area := opaque_body_area(idle)
	check(idle_height == 213,"approved visible standing height preserved")
	check(is_equal_approx(definition.character_height_cm,185.0),"185cm design preserved")
	check(frames.has_animation(&"special_attack"),"dedicated muei reversal exists")
	for clip in frames.get_animation_names():
		for frame in range(frames.get_frame_count(clip)):
			var texture := frames.get_frame_texture(clip,frame) as AtlasTexture
			check(texture != null,"authored texture "+clip)
			if texture == null: continue
			check((texture.atlas.resource_path.contains("cross_v2") or texture.atlas.resource_path.contains("cross_damage_v3")),"all Cross motions use repaired originals "+clip)
			check(texture.get_size() in [Vector2(384,288),Vector2(512,448)],"common complete cell "+clip)
			var used := texture.get_image().get_used_rect()
			var new_damage := texture.atlas.resource_path.contains("cross_damage_v3")
			check(used.position.x>=2 and used.position.y>=2 and used.end.x<=texture.get_width()-2 and used.end.y<=(350 if new_damage else 270),"no clipped hair limbs boots "+clip)
			check(used.end.y >= (349 if new_damage else 269) and used.end.y <= (350 if new_damage else 270),"common foot/prone contact baseline "+clip)
			var ratio := opaque_body_area(texture)/idle_area
			check(ratio>0.70 and ratio<1.70,"anatomical body mass "+clip+str(frame))
			for direction in [1,-1]:
				cross.facing_direction = direction
				cross._set_visual_facing()
				cross.character_visual_controller.play_animation(clip,true)
				sprite.pause()
				sprite.frame = frame
				check(sprite.scale.is_equal_approx(fixed_scale) and sprite.position.is_equal_approx(fixed_position),"no scale or pivot change "+clip)
				check(not cross.character_visual_controller.fallback_sprite.visible,"no duplicate fallback body")
				check_visible_art(sprite,"complete visible frame "+clip)
				var key := texture.atlas.resource_path+str(texture.region)+str(direction)
				if not captured_frames.has(key):
					captured_frames[key] = true
					await capture("frame_"+clip+"_"+str(frame)+("_R" if direction>0 else "_L"))
			inspected_frames += 1
	# Actual Area2D contact and state transitions in both directions.
	for direction in [1,-1]:
		await clean_reset(manager,player,Vector2(660-110*direction,520),direction)
		await clean_reset(manager,cross,Vector2(660,520),-direction)
		cross.set_physics_process(false)
		player.input_enabled = true
		var hp: int = cross.current_hp
		player.request_attack_input(&"Punch")
		var damaged := false
		for tick in range(75):
			await physics_frame
			if cross.current_hp<hp and not damaged:
				damaged = true
				cross._update_visual_state()
				check(String(sprite.animation).begins_with("damage"),"normal hit selects damage motion")
				await capture("contact_damage_"+str(direction))
		check(damaged,"player punch contacts Cross "+str(direction))
		await clean_reset(manager,player,Vector2(660-110*direction,520),direction)
		await clean_reset(manager,cross,Vector2(660,520),-direction)
		player.set_physics_process(false)
		cross.input_enabled = true
		hp = player.current_hp
		cross.request_attack_input(&"Kick",true)
		var attack_seen := false
		for tick in range(75):
			await physics_frame
			if cross.attack_phase == cross.AttackPhase.ACTIVE and not attack_seen:
				attack_seen = true
				check(sprite.frame == 1,"normal kick uses extended contact pose")
				await capture("contact_kick_"+str(direction))
		check(player.current_hp<hp,"Cross kick contacts player "+str(direction))
		check(attack_seen,"Cross kick contact pose was observed "+str(direction))
		await clean_reset(manager,player,Vector2(660-80*direction,520),direction)
		await clean_reset(manager,cross,Vector2(660,520),-direction)
		cross.set_physics_process(false)
		cross.is_guarding = true
		cross.guard_type = "high"
		hp = cross.current_hp
		var guard_packet := {"damage":5,"is_guardable":true,"attack_type":"punch","guard_damage_multiplier":0.0,"guard_hit_time":0.22}
		check(not cross.receive_attack(guard_packet,direction,cross.global_position,player),"Cross guard blocks attack")
		cross._update_visual_state()
		check(cross.current_hp==hp and sprite.animation==&"guard_hit","guard impact preserves HP and dedicated posture")
		await capture("contact_guard_"+str(direction))
		await clean_reset(manager,player,Vector2(660-55*direction,520),direction)
		await clean_reset(manager,cross,Vector2(660,520),-direction)
		manager.update_enemy_target()
		player.throw_escape_probability = 0.0 # Observe complete throw without random AI escape.
		hp = player.current_hp
		cross._start_throw()
		var throw_seen := {}
		for tick in range(140):
			await physics_frame
			cross._update_visual_state()
			var throw_phase: String = cross.throw_state
			if throw_phase.is_empty(): break
			var phase := "throw_start" if throw_phase=="THROW_STARTUP" else ("throw_hold" if throw_phase=="THROW_HOLD" else "throw_release")
			var throw_clip: String = cross._teki_throw_animation(phase)
			check(String(sprite.animation)==throw_clip,"throw phase survives runtime update "+throw_phase)
			if not throw_seen.has(throw_phase):
				throw_seen[throw_phase] = true
				await capture("contact_"+throw_clip+"_"+str(direction))
		check(throw_seen.has("THROW_HOLD") and throw_seen.has("THROW_RECOVERY") and player.current_hp<hp,"throw connects holds releases and damages player")
		await clean_reset(manager,player,Vector2(660-320*direction,520),direction)
		await clean_reset(manager,cross,Vector2(660,520),-direction)
		player.set_physics_process(false)
		hp = player.current_hp
		cross.set_special_gauge(100)
		cross.start_character_special()
		var seen := {}
		for tick in range(120):
			await physics_frame
			cross._update_visual_state()
			var state: int = cross.character_special_state
			if state == cross.CharacterSpecialState.NONE: break
			var expected := "special_startup" if state == cross.CharacterSpecialState.STARTUP else ("cross_muei" if state == cross.CharacterSpecialState.ACTIVE else "special_recovery")
			check(String(sprite.animation)==expected,"muei reversal dedicated phase "+expected)
			if not seen.has(state):
				seen[state] = true
				await capture("muei_"+expected+"_"+str(direction))
			if state == cross.CharacterSpecialState.ACTIVE and sprite.frame==0 and not seen.has("peak"):
				seen["peak"] = true
				await capture("muei_peak_"+str(direction))
		check(seen.has("peak") and seen.size()>=3 and player.current_hp==hp and cross.special_gauge==0,"muei complete phases and real contact")
	print("CROSS_MOTION_INTEGRITY_RESULT frames=%d unique_views=%d screenshots=%d failures=%s" % [inspected_frames,captured_frames.size(),screenshots,failures])
	for audio in root.find_children("*","AudioStreamPlayer",true,false):audio.stop()
	for audio in root.find_children("*","AudioStreamPlayer2D",true,false):audio.stop()
	OS.delay_msec(200)
	battle.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures.is_empty() else 1)

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
