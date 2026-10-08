extends "res://tests/stage1_hero_throws_check.gd"

func run() -> void:
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	battle.get_node("BattleManager").active_enemy_count_limit = 1
	root.add_child(battle)
	current_scene = battle
	await process_frame
	hero = "gou" if "--gou" in OS.get_cmdline_user_args() else "seiya"
	var manager: Node = battle.get_node("BattleManager")
	manager.select_player_by_id("player_02_gou" if hero == "gou" else "player_03_seiya")
	for i in range(400):
		await physics_frame
		if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
		if manager.isRoundActive: break
	player = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	enemy.ai_enabled = false
	enemy.ai_profile = null
	enemy.set_physics_process(false)
	player.input_enabled = false
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/stage1_hero_received_live/" + hero)
	DirAccess.make_dir_recursive_absolute(folder)
	for facing in [1.0, -1.0]:
		for reaction in ["damage_high", "damage_low", "launch_hit", "air_hit", "knockback", "ground_bounce", "wall_hit"]:
			reset_pair(facing)
			player.input_enabled = false
			player.set_physics_process(true)
			await physics_frame
			var sprite: AnimatedSprite2D = player.animated_character_sprite
			var baseline := sprite.scale
			var hp: int = player.current_hp
			var packet: Dictionary = enemy._get_punch_attack_data().duplicate()
			packet.merge({"damage":1,"base_damage":1,"knockback_x":0.0,"knockback_y":0.0,"launch_velocity":Vector2.ZERO,"causes_knockdown":false,"combo_hit_max":0,"hitstun_time":0.7,"attack_height":"middle","hit_stop_frames":0,"hitstop_defender":0.0,"hitstop_attacker":0.0}, true)
			packet.erase("hit_reaction")
			if reaction in ["damage_high", "damage_low"]:
				packet["attack_height"] = "high" if reaction == "damage_high" else "low"
			elif reaction in ["launch_hit", "air_hit"]:
				packet["launch_velocity"] = Vector2(20, -300)
				if reaction == "air_hit":
					packet["hit_reaction"] = &"air_hit"
					player.position.y = 400
			else:
				packet["causes_knockdown"] = true
				packet["knockback_x"] = 180.0
				packet["knockback_y"] = 160.0
				if reaction == "ground_bounce":
					packet["ground_bounces"] = 4 # Production caps this to one.
					packet["ground_bounce_velocity"] = Vector2(0,-150)
				elif reaction == "wall_hit":
					packet["is_special"] = true
					packet["wall_slam"] = true
					packet["special_knockdown_reaction"] = &"down"
					packet["special_knockback_reaction"] = &"knockback"
					packet["keep_special_flight_in_view"] = true
					player.position.x = 1000 if facing < 0 else 280
			check(player.receive_attack(packet, -facing, player.global_position, enemy), reaction + " accepted")
			check(player.current_hp == hp - 1, reaction + " damage once")
			var seen: Dictionary = {}
			var bounce_contacts := 0
			for tick in range(240):
				await physics_frame
				bounce_contacts = maxi(bounce_contacts,player.ground_bounce_contacts)
				var clip := String(sprite.animation)
				if clip in [reaction,"ground_impact","ground_bounce","wall_hit","wall_fall","down","knockdown_high","knockdown_low","stand_up"]:
					var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
					check(sprite.scale.is_equal_approx(baseline), reaction + " fixed actor scale")
					if clip in [reaction,"ground_impact","ground_bounce","wall_hit","wall_fall"]:
						check(texture is AtlasTexture and ("received_v13" if hero == "gou" else "slim_received_v15") in texture.atlas.resource_path, reaction + " authored source")
					if not seen.has(clip) and DisplayServer.get_name() != "headless":
						player.set_physics_process(false)
						sprite.pause()
						await process_frame
						RenderingServer.force_draw(false)
						root.get_texture().get_image().save_png(folder.path_join("%s_%s_%s.png" % [facing,reaction,clip]))
						player.set_physics_process(true)
						sprite.play()
					seen[clip] = true
			check(seen.has(reaction), reaction + " selected in physics")
			if reaction == "ground_bounce":
				check(seen.has("ground_impact"), "bounce ground impact")
				check(bounce_contacts == 1, "bounce limited to one")
			if reaction in ["knockback", "ground_bounce", "wall_hit"]:
				check(seen.has("stand_up"), reaction + " wakeup seen")
			check(not player.is_hit and player.knockdown_state == &"" and player.hurt_box.monitorable, reaction + " control/hurtbox restored")
			print("HERO_RECEIVED_CASE ",hero," ",facing," ",reaction," seen=",seen.keys())
	print("STAGE1_HERO_RECEIVED_LIVE_CHECK ",hero," failures=",failures)
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
