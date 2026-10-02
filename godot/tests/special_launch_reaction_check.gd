extends SceneTree

var failures: Array[String] = []
var output := ""
var screenshots := 0
var attacker_definition := "ally_balance"
var attacker_definition_folder := "fighters"
var victim_definition_folder := "enemies"
var attacker_node_name := "Player"
var victim_node_name := "Enemy"
var victim_definitions := ["enemy_01_standard","enemy_02_speed","enemy_03_guard","enemy_04_throw",
	"enemy_05_power","enemy_06_combo","enemy_07_tricky","enemy_08_boss","enemy_09_seiya"]
var reaction_prefix := "received_akky_elbow"
var evidence_folder := "special_launch"
var dedicated_attack_clips: Array[String] = []
var minimum_launch_velocity := 500.0
var maximum_flight_distance := 0.0
var minimum_flight_distance := 200.0
var attack_original_folder := "reversal_v1"
var minimum_flight_height := 55.0
var maximum_flight_height := 0.0
var minimum_contact_height := 80.0
var visible_outline_cache: Dictionary = {}

func check_visible_art(sprite: AnimatedSprite2D, label: String) -> void:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	var used := texture.get_image().get_used_rect()
	var left := float(used.position.x)-texture.get_width()*0.5
	var right := float(used.end.x)-texture.get_width()*0.5
	if sprite.flip_h:
		var old_left := left
		left = -right
		right = -old_left
	var top := float(used.position.y)-texture.get_height()*0.5
	var bottom := float(used.end.y)-texture.get_height()*0.5
	var transform := sprite.get_global_transform_with_canvas()
	var screen := root.get_visible_rect().size
	var points: Array = [Vector2(left,top),Vector2(right,top),Vector2(left,bottom),Vector2(right,bottom)]
	if not is_zero_approx(sprite.rotation):
		# A rotated opaque bounding rectangle includes empty corners. Validate
		# the convex hull of actual visible pixels instead of transparent padding.
		var id := texture.get_instance_id()
		if not visible_outline_cache.has(id):
			var image := texture.get_image()
			var outline := PackedVector2Array()
			for y in range(used.position.y,used.end.y):
				var first := -1
				var last := -1
				for x in range(used.position.x,used.end.x):
					if image.get_pixel(x,y).a >= 0.5:
						if first == -1: first = x
						last = x
				if first != -1:
					outline.append(Vector2(first,y)-texture.get_size()*0.5)
					outline.append(Vector2(last+1,y+1)-texture.get_size()*0.5)
			visible_outline_cache[id] = Geometry2D.convex_hull(outline)
		points.clear()
		for original_point in visible_outline_cache[id]:
			var point: Vector2 = original_point
			if sprite.flip_h: point.x = -point.x
			points.append(point)
	for point in points:
		var actual: Vector2 = transform * (point+sprite.offset)
		if actual.x < 0 or actual.x > screen.x or actual.y < 0 or actual.y > screen.y: print("ART_OUT %s point=%s pos=%s scale=%s clip=%s texture=%s image=%s used=%s" % [label,actual,sprite.global_position,sprite.scale,sprite.animation,texture.get_size(),texture.get_image().get_size(),used])
		check(actual.x >= 0 and actual.x <= screen.x and actual.y >= 0 and actual.y <= screen.y,label + " art inside rendered viewport")

func visible_body_center_y(sprite: AnimatedSprite2D) -> float:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	var center := Vector2(texture.get_image().get_used_rect().get_center())-texture.get_size()*0.5
	if sprite.flip_h: center.x = -center.x
	return (sprite.global_transform*(center+sprite.offset)).y

func opaque_body_area(texture: Texture2D) -> float:
	var image := texture.get_image()
	var area := 0.0
	var bounds := image.get_used_rect()
	for y in range(bounds.position.y,bounds.end.y):
		for x in range(bounds.position.x,bounds.end.x):
			if image.get_pixel(x,y).a >= 0.5: area += 1.0
	return area

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png(output.path_join(label + ".png")) == OK, "capture " + label)
	screenshots += 1

func reset(manager: Node, actor: Node, point: Vector2, facing: int) -> void:
	manager.reset_active_fighter_state(actor, point, facing, actor.max_hp)
	actor.ai_enabled = false
	actor.input_enabled = false
	actor.is_round_active = true
	actor.current_hp = actor.max_hp
	actor.is_invincible = false
	actor.invincibility_timer = 0.0
	actor.hit_stop_timer = 0.0
	actor.set_physics_process(true)
	for i in range(3): await physics_frame

func run() -> void:
	output = ProjectSettings.globalize_path("res://").path_join("../evidence/" + evidence_folder).simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager._hide_player_selection()
	manager._set_battle_active(true)
	paused = false
	var attacker: Node = battle.get_node(attacker_node_name)
	var target: Node = battle.get_node(victim_node_name)
	attacker.apply_character_data(load("res://data/%s/%s.tres" % [attacker_definition_folder,attacker_definition]))
	var attack_sprite: AnimatedSprite2D = attacker.animated_character_sprite
	var attack_scale := attack_sprite.scale
	var attack_pivot := attack_sprite.position
	for clip in dedicated_attack_clips:
		check(attack_sprite.sprite_frames.has_animation(clip),"dedicated attack clip " + clip)
		for frame in range(attack_sprite.sprite_frames.get_frame_count(clip)):
			var texture := attack_sprite.sprite_frames.get_frame_texture(clip,frame) as AtlasTexture
			check(texture != null and texture.atlas.resource_path.contains(attack_original_folder),"dedicated original " + clip)
			for direction in [1,-1]:
				attacker.set_physics_process(false)
				attacker.position = Vector2(520,520)
				attacker.facing_direction = direction
				attacker._set_visual_facing()
				attack_sprite.play(clip)
				attack_sprite.pause()
				attack_sprite.frame = frame
				check(attack_sprite.scale.is_equal_approx(attack_scale) and attack_sprite.position.is_equal_approx(attack_pivot),"authored frame scale/pivot " + clip)
				check_visible_art(attack_sprite,"authored frame " + clip)
				await capture("attack_%s_%d_%s" % [clip,frame,"R" if direction > 0 else "L"])
	for definition in victim_definitions:
		target.apply_character_data(load("res://data/%s/%s.tres" % [victim_definition_folder,definition]))
		for direction in [1,-1]:
			var label: String = definition + ("_R" if direction == 1 else "_L")
			await reset(manager, attacker, Vector2(640 - 120 * direction,520), direction)
			await reset(manager, target, Vector2(640,520), -direction)
			attacker.set_physics_process(false)
			var sprite: AnimatedSprite2D = target.animated_character_sprite
			var scale_before := sprite.scale
			var pivot_before := sprite.position
			var packet: Dictionary = attacker._get_character_special_attack_dictionary()
			check(packet.causes_knockdown, label + " special always launches on hit")
			check(target._get_damage_animation_from_attack(packet) == StringName(reaction_prefix + "_hit"), label + " attack-specific victim hit")
			check(target._get_knockdown_animation_from_attack(packet) == StringName(reaction_prefix + "_down"), label + " attack-specific victim down")
			var ordinary := packet.duplicate()
			ordinary.is_special = false
			ordinary.attack_id = "ordinary_punch"
			check(target._get_damage_animation_from_attack(ordinary) != StringName(reaction_prefix + "_hit"), label + " ordinary hit remains ordinary")
			attacker.set_special_gauge(100)
			await capture(label + "_before")
			attacker.input_enabled = true
			attacker.start_character_special()
			attacker._update_visual_state()
			if not dedicated_attack_clips.is_empty():
				check(attack_sprite.animation == StringName(dedicated_attack_clips[0]),label + " actual startup clip")
			await capture(label + "_startup")
			attacker.enter_character_special_active()
			attacker._update_visual_state()
			if not dedicated_attack_clips.is_empty():
				check(attack_sprite.animation == StringName(dedicated_attack_clips[1]),label + " actual active clip")
			attacker.input_enabled = false
			attacker.set_physics_process(true)
			var start: Vector2 = target.position
			check(attacker._get_character_special_hit_position(target).y < start.y-minimum_contact_height,label + " effect at special contact height")
			var camera_zoom_before: Vector2 = root.get_camera_2d().zoom
			attacker._on_character_special_hitbox_area_entered(target.get_node("HurtBox"))
			await process_frame
			await process_frame
			check(target.knockdown_state == &"KNOCKBACK", label + " actual contact enters flight")
			check(target.last_special_knockback_animation == StringName(reaction_prefix + "_air"), label + " victim airborne selection")
			check(target.velocity.x * direction > minimum_launch_velocity, label + " outward launch velocity")
			var wall_launch := bool(packet.get("wall_slam",false))
			if wall_launch: check(target.velocity.x * direction >= 1800,label + " faster wall launch")
			await capture(label + "_impact")
			var apex := start.y
			var distance := 0.0
			var captured_air := false
			var captured_wall := false
			var captured_fall := false
			var backflip := bool(packet.get("backflip_on_launch",false))
			var previous_turn := 0.0
			var previous_body_y := visible_body_center_y(sprite)
			var previous_body_frame := Engine.get_physics_frames()
			var captured_spin := false
			var captured_prone := false
			var headfirst := bool(packet.get("headfirst_on_launch",false))
			var captured_head_impact := false
			var captured_collapse := false
			var captured_head_fall := false
			if backflip:
				check(sprite.sprite_frames.get_frame_count(target.last_special_knockback_animation) == 1,label + " arched lightly bent-knee pose throughout flight")
				var idle_area := opaque_body_area(sprite.sprite_frames.get_frame_texture(&"idle",0))
				var air_area := opaque_body_area(sprite.sprite_frames.get_frame_texture(target.last_special_knockback_animation,0))
				var down_area := opaque_body_area(sprite.sprite_frames.get_frame_texture(target.last_knockdown_animation,0))
				check(air_area/idle_area >= 0.70 and air_area/idle_area <= 1.10,label + " received body keeps ordinary character size")
				check(down_area/air_area >= 0.80 and down_area/air_area <= 0.90,label + " prone body retains flight body mass")
			for frame in range(150):
				await physics_frame
				check(root.get_camera_2d().zoom.is_equal_approx(camera_zoom_before),label + " no camera enlargement during flight")
				if backflip and target.knockdown_state == &"KNOCKBACK":
					check(target.special_backflip_turn >= previous_turn and target.special_backflip_turn <= PI*1.5+0.001,label + " one continuous backward turn")
					if target.special_backflip_turn < PI*1.5:
						check(is_equal_approx(sprite.rotation,target.special_backflip_turn*direction),label + " backward rotation about body center")
					else:
						check(is_zero_approx(sprite.rotation),label + " prone drawing aligns after 270 degrees")
					check(sprite.flip_h == (direction > 0),label + " victim remains facing Gou")
					if target.special_backflip_turn > 0 and target.special_backflip_turn < PI/2:
						check(Vector2.UP.rotated(sprite.rotation).x*direction > 0,label + " head starts rotating away from Gou")
					previous_turn = target.special_backflip_turn
					var body_y := visible_body_center_y(sprite)
					if absf(body_y-previous_body_y) >= 45.0: print("BODY_STEP %s delta=%.2f turn=%.2f elapsed=%.3f clip=%s offset=%s" % [label,body_y-previous_body_y,target.special_backflip_turn,target.special_backflip_elapsed,sprite.animation,sprite.offset])
					check(absf(body_y-previous_body_y) < 45.0,label + " continuous visible body descent")
					previous_body_y = body_y
					if target.special_backflip_turn < PI*1.5:
						check(sprite.animation == target.last_special_knockback_animation and sprite.frame == 0,label + " stays arched without tucking")
					check(target.special_backflip_turn < PI*1.5,label + " rotation only completes at floor contact")
					if not captured_spin and target.special_backflip_turn > PI:
						check_visible_art(sprite,label + " rotating body")
						await capture(label + "_spin")
						captured_spin = true
				if headfirst and target.knockdown_state == &"KNOCKBACK":
					var body_y := visible_body_center_y(sprite)
					var sampled_frames := maxi(1,Engine.get_physics_frames()-previous_body_frame)
					check(absf(body_y-previous_body_y) < 30.0*sampled_frames+5.0,label + " continuous headfirst body position phase=%s previous=%.2f current=%.2f sampled=%d" % [target.special_headfirst_phase,previous_body_y,body_y,sampled_frames])
					previous_body_frame = Engine.get_physics_frames()
					previous_body_y = body_y
					check(sprite.flip_h == (direction > 0),label + " victim facing stays toward Seiya")
					if target.special_headfirst_phase == "fall" and not captured_head_fall:
						target._update_visual_state()
						check(is_equal_approx(absf(sprite.rotation),PI),label + " head points down during descent")
						check_visible_art(sprite,label + " high headfirst fall")
						await capture(label + "_head_fall")
						captured_head_fall = true
					if target.special_headfirst_phase == "head_impact":
						var head_point: Vector2 = sprite.global_transform*(target.special_headfirst_tip+sprite.offset)
						check(absf(head_point.y-target.global_position.y)<1.0,label + " head contacts floor before body")
						if not captured_head_impact:
							await capture(label + "_head_impact")
							captured_head_impact = true
					if target.special_headfirst_phase == "collapse" and target.special_headfirst_timer < 0.10 and not captured_collapse:
						check(captured_head_impact,label + " body collapses after head contact")
						await capture(label + "_collapse")
						captured_collapse = true
				if wall_launch and target.special_wall_phase == "impact":
					check(target.velocity == Vector2.ZERO,label + " wall contact stops motion")
					if not captured_wall:
						target._update_visual_state()
						check(sprite.animation == &"received_akky_elbow_wall",label + " wall recoil pose")
						check_visible_art(sprite,label + " wall")
						await capture(label + "_wall")
						captured_wall = true
				if wall_launch and target.special_wall_phase == "fall" and target.knockdown_state == &"KNOCKBACK":
					check(captured_wall and is_zero_approx(target.velocity.x),label + " drops after wall contact")
					if not captured_fall:
						target._update_visual_state()
						check(sprite.animation == &"received_akky_elbow_fall",label + " falling pose")
						await capture(label + "_fall")
						captured_fall = true
				if definition == "enemy_01_standard" and direction == 1 and frame % 4 == 0:
					await capture("preview_%03d" % frame)
				apex = minf(apex,target.position.y)
				distance = maxf(distance,(target.position.x - start.x) * direction)
				check(sprite.scale.is_equal_approx(scale_before), label + " constant sprite scale")
				check(sprite.position.is_equal_approx(pivot_before), label + " constant sprite pivot")
				check(attack_sprite.scale.is_equal_approx(attack_scale) and attack_sprite.position.is_equal_approx(attack_pivot),label + " constant attacker scale and pivot")
				if not captured_air and start.y-target.position.y > minimum_flight_height:
					check_visible_art(sprite,label + " airborne")
					await capture(label + "_air")
					captured_air = true
				if target.knockdown_state == &"KNOCKDOWN":
					if backflip:
						target._update_visual_state()
						check(sprite.animation == StringName(reaction_prefix + "_down"),label + " rotation ends in grounded prone pose")
						await capture(label + "_prone_landing")
						captured_prone = true
					break
			check(captured_air and start.y-apex > minimum_flight_height, label + " visible upward arc")
			if maximum_flight_height > 0:
				check(start.y-apex < maximum_flight_height,label + " stays close to contact height")
			if wall_launch: check(captured_wall and captured_fall and target.special_wall_contacts == 1,label + " wall then fall exactly once")
			check(distance > minimum_flight_distance, label + " visible outward flight distance")
			if maximum_flight_distance > 0:
				check(distance < maximum_flight_distance,label + " short ground launch")
				check(target.special_wall_contacts == 0,label + " Gou lands without wall slam")
			if headfirst:
				check(captured_head_fall and captured_head_impact and captured_collapse,label + " headfirst descent impact and collapse sequence")
				check(is_zero_approx(sprite.rotation) and sprite.offset.is_zero_approx(),label + " headfirst grounded transform restored")
				check(absf(visible_body_center_y(sprite)-previous_body_y) < 45.0,label + " no size or body-position jump into prone pose previous=%.2f current=%.2f" % [previous_body_y,visible_body_center_y(sprite)])
			if backflip:
				check(captured_spin and captured_prone and is_equal_approx(target.special_backflip_turn,PI*1.5),label + " completes backward 270-degree prone rotation")
				check(is_zero_approx(sprite.rotation),label + " grounded pose restores rotation")
				check(sprite.offset.is_zero_approx(),label + " grounded prone alignment restored")
				check(absf(visible_body_center_y(sprite)-previous_body_y) < 45.0,label + " no abrupt body drop at floor")
				if maximum_flight_height > 0:
					check(absf(target.special_backflip_elapsed-target.special_backflip_duration) <= 0.10,label + " rotation and landing finish together")
				check(sprite.flip_h == (direction > 0),label + " prone original head faces Gou at landing")
			check(target.knockdown_state == &"KNOCKDOWN", label + " lands in down state")
			target._update_visual_state()
			check(sprite.animation == StringName(reaction_prefix + "_down"), label + " grounded victim pose")
			check_visible_art(sprite,label + " down")
			await capture(label + "_down")
			print("SPECIAL_FLIGHT %s distance=%.1f height=%.1f" % [label,distance,start.y-apex])
			if not dedicated_attack_clips.is_empty():
				attacker.set_physics_process(false)
				attacker.enter_character_special_recovery()
				attacker._update_visual_state()
				check(attack_sprite.animation == StringName(dedicated_attack_clips[2]),label + " actual recovery clip")
				await capture(label + "_finish")
			attacker.finish_character_special()
			await reset(manager, target, Vector2(640,520), -direction)
			target.set_physics_process(false)
			target.is_guarding = true
			target.guard_type = "high"
			check(not target.receive_attack(packet,direction,target.global_position,attacker),label + " guard succeeds")
			check(target.knockdown_state == &"" and target.is_guard_hit,label + " guard never launches")
	await extra_checks(manager,attacker,target)
	# A lethal special must still fly, land, and remain defeated without getting up.
	await reset(manager, attacker, Vector2(520,520),1)
	await reset(manager, target, Vector2(640,520),-1)
	attacker.set_physics_process(false)
	target.current_hp = 1
	var lethal: Dictionary = attacker._get_character_special_attack_dictionary()
	check(target.receive_attack(lethal,1,target.global_position,attacker),"lethal special connects")
	check(target.current_hp == 0 and target.special_ko_flight,"lethal special retains KO and launch")
	for frame in range(180):
		await physics_frame
		if target.knockdown_state == &"KNOCKDOWN": break
	check(target.knockdown_state == &"KNOCKDOWN","lethal special lands")
	target.update_knockdown(2.0)
	check(target.current_hp == 0 and target.knockdown_state == &"KNOCKDOWN","KO never gets up")
	Engine.time_scale = 1.0
	print("SPECIAL_LAUNCH_REACTION_CHECK failures=%s screenshots=%d" % [failures,screenshots])
	for audio in root.find_children("*","AudioStreamPlayer",true,false): audio.stop()
	for audio in root.find_children("*","AudioStreamPlayer2D",true,false): audio.stop()
	OS.delay_msec(200)
	battle.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures.is_empty() else 1)

func extra_checks(_manager: Node, _attacker: Node, _target: Node) -> void:
	pass
