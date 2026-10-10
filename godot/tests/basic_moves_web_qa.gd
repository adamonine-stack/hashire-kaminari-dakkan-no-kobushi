extends "res://tests/basic_moves_web_qa_base.gd"

const Inventory := preload("res://tests/basic_moves_inventory.gd")
const CONTROLS := ["neutral_punch", "forward_punch", "down_punch", "back_punch", "up_punch", "neutral_kick", "forward_kick", "down_kick", "back_kick", "up_kick"]
var cases := 0
var actor: Node
var opponent: Node
var measurements: Array = []

func release_inputs() -> void:
	for action in ["move_left", "move_right", "down", "jump", "attack", "kick"]:
		Input.action_release(action)

func settle() -> void:
	release_inputs()
	reset_pair()
	for fighter in [player, enemy]:
		fighter.landing_recovery_remaining = 0.0
		fighter.clear_pending_air_landing()
		fighter.jump_pressed_this_airtime = false
		fighter.has_used_air_attack = false
		fighter.input_enabled = true
		fighter.ai_enabled = false
		fighter.ai_guard_enabled = false
		fighter._clear_guard_state()
		fighter.attack_cooldown_timer = 0.0
		fighter.kick_cooldown_timer = 0.0
		fighter.is_crouching = false
		fighter.global_position = Vector2(600 if fighter == actor else 900, 520)
		fighter.velocity = Vector2(0, 10)
		fighter.move_and_slide()
		fighter.velocity = Vector2.ZERO
		fighter.set_physics_process(false)
	actor.combat_commands.clear()
	actor._update_pose_collision()
	opponent._update_pose_collision()

func run() -> void:
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	battle.get_node("BattleManager").active_enemy_count_limit = 1
	root.add_child(battle)
	current_scene = battle
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager.select_player_by_id("player_01_akky")
	for i in range(500):
		await physics_frame
		if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible:
			manager.enemy_intro_finished.emit()
		if manager.isRoundActive: break
	player = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	await ticks(3)
	for path in Inventory.DEFINITIONS:
		var definition: Resource = load("res://data/"+path+".tres")
		actor = enemy if definition.team_type == &"ENEMY" else player
		opponent = player if actor == enemy else enemy
		actor.apply_fighter_definition(definition)
		actor.set_physics_process(false)
		opponent.set_physics_process(false)
		var label := String(definition.fighter_id)
		check(actor.basic_move_ids.size() == 10, label+" ten controls")
		var sprite: AnimatedSprite2D = actor.animated_character_sprite
		var scale_before := sprite.scale
		var p_recovery := 0.0
		var k_recovery := 100.0
		var p_damage := 0.0
		var k_damage := 100.0
		for key in CONTROLS:
			var data: Resource = actor._get_attack_data(actor.basic_move_ids[key])
			if key.ends_with("punch"):
				p_recovery = maxf(p_recovery, data.recovery_time)
				p_damage = maxf(p_damage, data.base_damage*actor.punch_damage)
			else:
				k_recovery = minf(k_recovery, data.recovery_time)
				k_damage = minf(k_damage, data.base_damage*actor.kick_damage)
		check(k_recovery > p_recovery, label+" kicks have longer recovery")
		check(k_damage > p_damage, label+" kicks have stronger damage")
		check(actor._get_attack_data(actor.basic_move_ids.forward_kick).startup_time < actor._get_attack_data(actor.basic_move_ids.neutral_kick).startup_time, label+" forward kick starts faster")
		check(actor._get_attack_data(actor.basic_move_ids.down_punch).hitbox_offset.y > actor._get_attack_data(actor.basic_move_ids.neutral_punch).hitbox_offset.y, label+" crouch fist below jab")
		for facing in [1.0, -1.0]:
			for key in CONTROLS:
				settle()
				actor.facing_direction = facing
				var data: Resource = actor._get_attack_data(actor.basic_move_ids[key])
				var direction: String = key.split("_")[0]
				var kind: String = key.split("_")[1]
				var scale: float = actor.battle_visual_scale_multiplier*definition.combat_geometry_scale
				var reach: float = data.hitbox_offset.x*scale
				if key == "back_punch":
					# A raised fist can lie over the torso. Keep the jumping target
					# in front, inside the box width, so auto-facing does not turn away.
					reach = maxf(12.0,reach)
				opponent.global_position = Vector2(600 + reach*facing, 520)
				if key == "back_punch":
					# Put the airborne torso at the raised fist, not a ground target.
					opponent.global_position.y = 520 + data.hitbox_offset.y*scale-opponent.hurt_box.position.y
				opponent.velocity = Vector2.ZERO
				opponent.move_and_slide()
				await physics_frame
				var hp: float = opponent.current_hp
				if direction != "neutral":
					var action := "jump" if direction == "up" else ("down" if direction == "down" else ("move_right" if (direction == "forward") == (facing > 0) else "move_left"))
					Input.action_press(action)
				Input.action_press("attack" if kind == "punch" else "kick")
				actor._physics_process(1.0/60.0)
				check(actor.current_attack_id == data.attack_id, label+" input "+key+" facing "+str(facing))
				check(not actor.punch_hitbox_active and not actor.kick_hitbox_active, label+" startup inactive "+key)
				if direction == "up":
					check(actor.velocity.y < 0.0 and actor.is_air_attack_active, label+" jump launches "+key)
				if direction == "down": check(actor.is_crouching, label+" crouching "+key)
				var began: Vector2 = actor.global_position
				var saw_contact := false
				var saw_recovery := false
				for frame in range(120):
					await physics_frame
					if direction == "up":
						opponent.global_position.y = actor.global_position.y + data.hitbox_offset.y*scale-opponent.hurt_box.position.y
					actor._physics_process(1.0/60.0)
					if actor.current_attack_id == data.attack_id:
						check(sprite.animation == StringName(data.animation_name), label+" dedicated visual "+key)
						check(sprite.scale.is_equal_approx(scale_before), label+" scale "+key)
						if actor.attack_phase == actor.AttackPhase.ACTIVE:
							saw_contact = true
							check(sprite.flip_h == (facing < 0.0),label+" mirrored visual "+key)
							check(sprite.frame == data.contact_start_frame, label+" synchronized contact "+key)
						if actor.attack_phase == actor.AttackPhase.RECOVERY:
							saw_recovery = true
							check(not actor.punch_hitbox_active and not actor.kick_hitbox_active, label+" recovery inactive "+key)
					if actor.current_attack_id.is_empty() and actor.is_on_floor(): break
				check(saw_contact, label+" contact reached "+key)
				check(saw_recovery or direction == "up", label+" recovery reached "+key)
				check(opponent.current_hp < hp, label+" actual collision damage "+key+" facing "+str(facing))
				if key == "forward_punch":
					check((actor.global_position.x-began.x)*facing > 10.0, label+" punch advances "+str(facing))
				if key == "back_kick":
					check(data.launch_velocity == Vector2.ZERO and not data.knockdown and absf(data.knockback.y) < .01, label+" spacing kick stays grounded")
					check(opponent.velocity.x*facing > 0.0 and absf(opponent.velocity.y) < .01, label+" spacing kick pushes victim horizontally")
				if direction == "up":
					check(actor.is_on_floor(), label+" jump lands "+key)
					check(not actor.punch_hitbox_active and not actor.kick_hitbox_active, label+" landing disables hitbox "+key)
				measurements.append({"actor":label,"key":key,"facing":facing,"damage":hp-opponent.current_hp,"source":data.animation_name})
				cases += 1
		settle()
		var jab: Resource = actor._get_attack_data(actor.basic_move_ids.neutral_punch)
		if not jab.next_attack_ids.is_empty():
			opponent.position.x = actor.position.x+jab.hitbox_offset.x*actor.battle_visual_scale_multiplier*definition.combat_geometry_scale
			actor.facing_direction = 1.0
			actor.request_attack_input(&"Punch")
			for frame in range(50):
				await physics_frame
				actor._physics_process(1.0/60.0)
				if actor.dev_current_attack_connected:
					break
			check(actor.dev_current_attack_connected,label+" neutral jab hits before combo")
			var followup := String(jab.next_attack_ids[0])
			actor.combat_commands.record("punch",true,1.0)
			for frame in range(30):
				actor._dispatch_combat_command()
				if actor.current_attack_id == followup: break
				await physics_frame
				actor._physics_process(1.0/60.0)
			check(actor.current_attack_id == followup,label+" neutral input keeps existing combo")
			settle()
		for tag in ["close", "middle", "approach", "punish", "evade", "low"]:
			check(not actor._select_basic_situation_move(tag, 55.0).is_empty(), label+" AI has "+tag)
		opponent.global_position = Vector2(650, 380)
		opponent.move_and_slide()
		actor.situation_observed_state = "air"
		actor.situation_observed_time = 1.0
		if definition.team_type == &"ENEMY":
			check(actor._select_situation_move() == actor.basic_move_ids.back_punch, label+" AI anti-air")
			for kind in ["punch", "kick"]:
				settle()
				actor.global_position.y = 380
				actor.move_and_slide()
				check(actor.request_attack_input(&"Punch" if kind == "punch" else &"Kick",true),label+" AI air request "+kind)
				check(actor.current_attack_id == actor.basic_move_ids["up_"+kind],label+" AI authored air move "+kind)
		release_inputs()
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/basic_moves_20261010")
	if not OS.has_feature("web"):
		FileAccess.open(folder.path_join("combat_results.json"),FileAccess.WRITE).store_string(JSON.stringify(measurements,"\t"))
	manager.cleanup_battle_before_transition()
	root.get_node("AudioManager").stop_bgm()
	battle.queue_free()
	await process_frame
	root.get_node("AudioManager").queue_free()
	await process_frame
	# Fixed-fps test time can finish before the audio thread releases playback.
	var audio_release_started := Time.get_ticks_msec()
	while Time.get_ticks_msec()-audio_release_started < 300:
		await process_frame
	print("BASIC_MOVES_COMBAT_CHECK cases=%d failures=%s" % [cases,failures])
	quit(0 if failures.is_empty() else 1)
