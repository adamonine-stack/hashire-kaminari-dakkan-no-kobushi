extends "res://tests/special_launch_reaction_check.gd"

func run() -> void:
	check(FileAccess.file_exists("res://project.binary"),"public packed project loaded")
	print("CROSS_PUBLIC_PACK_PROJECT_BINARY=",FileAccess.file_exists("res://project.binary"))
	output = ProjectSettings.globalize_path("res://../evidence/cross_stage4_public_damage")
	DirAccess.make_dir_recursive_absolute(output)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager._hide_player_selection()
	manager._set_battle_active(true)
	manager.current_enemy_index = 3
	manager._apply_current_stage_definition()
	manager._update_battle_hud_enemy()
	paused = false
	var player: Node = battle.get_node("Player")
	var enemy: Node = battle.get_node("Enemy")
	enemy.apply_character_data(load("res://data/enemies/enemy_05_power.tres"))
	enemy.max_hp = int(manager.enemy_team[3].max_health)
	await reset(manager,enemy,Vector2(760,520),-1)
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	var sprite: AnimatedSprite2D = enemy.animated_character_sprite
	var fixed_scale := sprite.scale
	var fixed_pivot := sprite.position
	var corrected_frames := sprite.sprite_frames
	var original_frames: SpriteFrames = enemy.character_visual_controller._build_authored_motion_atlas(enemy.fighter_definition.motion_atlas)
	sprite.sprite_frames = original_frames
	for clip in ["damage","down","stand_up","ko"]:
		for frame in range(original_frames.get_frame_count(clip)):
			sprite.play(clip)
			sprite.pause()
			sprite.frame = frame
			await capture("before_%s_%s" % [clip,frame])
	sprite.sprite_frames = corrected_frames
	var idle_area := opaque_body_area(sprite.sprite_frames.get_frame_texture(&"idle",0))
	var idle_height := sprite.sprite_frames.get_frame_texture(&"idle",0).get_image().get_used_rect().size.y
	var checked_frames := 0
	for clip in sprite.sprite_frames.get_animation_names():
		var reaction: bool = String(clip).begins_with("damage") or String(clip).begins_with("received_") or clip in [&"down",&"ko",&"knockback",&"knockdown",&"stand_up",&"getup",&"get_up",&"grabbed",&"thrown",&"guard_hit"]
		for frame in range(sprite.sprite_frames.get_frame_count(clip)):
			var texture := sprite.sprite_frames.get_frame_texture(clip,frame)
			var prone: bool = clip == &"down" or String(clip).ends_with("_down") or (clip in [&"ko",&"defeat",&"thrown",&"knockdown"] and frame == sprite.sprite_frames.get_frame_count(clip)-1) or (clip in [&"stand_up",&"getup",&"get_up"] and frame==0)
			if prone:
				check(texture.get_image().get_used_rect().size.x <= idle_height*1.30,"prone body length stays proportional "+String(clip))
			check(texture != null and not texture.get_image().is_empty(),"valid image "+String(clip))
			for direction in [1,-1]:
				enemy.facing_direction = direction
				enemy._set_visual_facing()
				sprite.play(clip)
				sprite.pause()
				sprite.frame = frame
				check(sprite.scale.is_equal_approx(fixed_scale) and sprite.position.is_equal_approx(fixed_pivot),"all motions fixed transform "+String(clip))
				check_visible_art(sprite,"all motions "+String(clip))
				if reaction:
					var ratio := opaque_body_area(texture)/idle_area
					check(ratio >= 0.80 and ratio <= 1.12,"corrected body mass "+String(clip)+" ratio="+str(ratio))
					await capture("pose_%s_%02d_%s" % [clip,frame,"R" if direction>0 else "L"])
			checked_frames += 1
	# Actual damage -> knockback -> down -> get-up and ordinary high/low hits.
	for direction in [1,-1]:
		for kind in ["high","low","knockdown"]:
			await reset(manager,enemy,Vector2(760,520),-direction)
			await reset(manager,player,Vector2(690 if direction>0 else 830,520),direction)
			player.set_physics_process(false)
			var packet: Dictionary = player._get_punch_attack_data()
			packet["attack_height"] = "low" if kind=="low" else "high"
			packet["damage"] = 5
			packet["causes_knockdown"] = kind=="knockdown"
			if kind=="knockdown":packet["knockback"] = Vector2(240,-280)
			check(enemy.receive_attack(packet,direction,enemy.global_position,player),"natural damage accepted "+kind)
			var seen := {}
			for frame in range(200):
				enemy._update_visual_state()
				var phase: String = String(enemy.knockdown_state) if enemy.knockdown_state!=&"" else ("hit" if enemy.is_hit else "ready")
				if not seen.has(phase):
					seen[phase] = true
					await capture("natural_%s_%s_%s" % [kind,direction,phase])
				if phase=="GET_UP" and not seen.has("getup_frame_"+str(sprite.frame)):
					seen["getup_frame_"+str(sprite.frame)] = true
					await capture("natural_getup_%s_frame_%s" % [direction,sprite.frame])
				check(sprite.scale.is_equal_approx(fixed_scale),"natural damage fixed scale")
				check_visible_art(sprite,"natural damage "+kind)
				if phase=="ready" and frame>5:break
				await physics_frame
			check(seen.has("ready"),"damage recovers "+kind)
			if kind=="knockdown":
				check(seen.has("KNOCKBACK") and seen.has("KNOCKDOWN") and seen.has("GET_UP"),"natural air/down/getup complete")
				check(seen.has("getup_frame_3"),"getup naturally reaches final ready frame")
	# Dedicated protagonist specials received by Cross, including rotating Gou
	# and the Seiya two-hit sequence, are exercised by their existing tests too.
	await reset(manager,enemy,Vector2(760,520),-1)
	enemy.current_hp = 0
	enemy.is_hit = false
	enemy.is_invincible = false
	enemy.visual_root.modulate = Color.WHITE
	enemy._update_visual_state()
	check(sprite.animation==&"ko","KO selects dedicated corrected sequence")
	for frame in range(sprite.sprite_frames.get_frame_count(&"ko")):
		sprite.frame = frame
		await capture("ko_%s" % frame)
	check(not sprite.sprite_frames.get_animation_loop(&"ko"),"KO holds final down")
	print("CROSS_STAGE4_DAMAGE_PRESENTATION_OK frames=%d screenshots=%d failures=%s" % [checked_frames,screenshots,failures])
	for audio in root.find_children("*","AudioStreamPlayer",true,false):audio.stop()
	for audio in root.find_children("*","AudioStreamPlayer2D",true,false):audio.stop()
	OS.delay_msec(200)
	battle.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
