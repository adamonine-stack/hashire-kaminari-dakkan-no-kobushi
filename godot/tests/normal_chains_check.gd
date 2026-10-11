extends "res://tests/directional_attacks_check.gd"

const Inventory := preload("res://tests/basic_moves_inventory.gd")
const COUNTS := [[3,2],[2,2],[4,3],[2,2],[4,3],[2,2],[3,2],[3,2],[4,3],[3,2],[4,3],[4,3]]
var cases := 0

func run() -> void:
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	battle.get_node("BattleManager").active_enemy_count_limit = 1
	root.add_child(battle)
	await process_frame
	player = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	for actor in [player,enemy]:
		actor.set_physics_process(false)
		actor.ai_enabled = false
		actor.ai_guard_enabled = false
		actor.ai_profile = null
		actor.input_enabled = true
	for n in [0,1,2,3,6,9,7,4,8,5,10,11]:
		var definition: Resource = load("res://data/"+Inventory.DEFINITIONS[n]+".tres")
		var actor: Node = enemy if definition.team_type == &"ENEMY" else player
		var victim: Node = player if actor == enemy else enemy
		actor.apply_fighter_definition(definition)
		actor.set_physics_process(false)
		var label := String(definition.fighter_id)
		var sprite: AnimatedSprite2D = actor.animated_character_sprite
		var scale_before := sprite.scale
		for kind in ["punch","kick"]:
			reset_pair()
			var move_id: String = actor.get_next_attack_id(kind)
			var names: Array = []
			var textures: Array = []
			var count: int = COUNTS[n][0 if kind == "punch" else 1]
			for rank in range(count):
				check(not move_id.is_empty(),label+kind+str(rank)+" route")
				if move_id.is_empty(): break
				actor.start_attack(move_id)
				var data: Resource = actor.current_attack_data
				check(data.launch_velocity == Vector2.ZERO,label+" horizontal normal")
				check(sprite.animation == StringName(data.animation_name),label+" actual playback")
				check(sprite.scale == scale_before,label+" invariant scale")
				names.append(data.animation_name)
				textures.append(hash(sprite.sprite_frames.get_frame_texture(data.animation_name,2).get_image().get_data()))
				actor.enter_attack_active()
				actor._apply_attack_to_target(victim,actor._get_attack_data_dictionary(kind.capitalize()))
				check(victim.is_hit,label+" hit received")
				var remaining: float = actor.attack_phase_timer+actor.attack_recovery_time_actual+actor.hit_stop_timer-victim.hit_stop_timer
				check(absf(victim.hit_reaction_timer-remaining)<0.018,label+" neutral recovery")
				move_id=actor.get_next_attack_id(kind)
				victim.is_hit=false
				victim.is_invincible=false
				victim.hit_stop_timer=0.0
				actor.hit_stop_timer=0.0
			check(move_id.is_empty(),label+kind+" exact hit count")
			check(names.size()==count,label+" clips present")
			for i in range(textures.size()):
					for j in range(i): check(textures[i]!=textures[j],label+kind+str(i)+str(j)+" distinct contact art")
			cases+=1
		reset_pair()
		actor.is_crouching = false
		actor.attack_cooldown_timer = 0.0
		actor.kick_cooldown_timer = 0.0
		actor.start_attack(actor.basic_move_ids.neutral_punch)
		check(not actor.get_next_attack_id("kick").is_empty(),label+" mixed P K preserved")
		actor.enter_attack_active()
		var packet: Dictionary = actor._get_attack_data_dictionary("Punch")
		packet.normal_chain=true
		actor.apply_guard_recoil(packet)
		check(actor.guard_recoil_timer >= float(packet.get("guard_hit_time",0.13))+0.17,label+" guard punish window")
		check(actor.dev_buffered_attack==&"" and actor.combo_count==0,label+" guard stops chain")
		var down: Resource = actor._get_attack_data(actor.basic_move_ids.down_punch)
		var back: Resource = actor._get_attack_data(actor.basic_move_ids.back_punch)
		check(down.launch_velocity.y<0 and down.command_direction=="down",label+" down launcher")
		check(back.attack_height=="overhead" and back.launch_velocity==Vector2.ZERO,label+" back overhead")
		check(sprite.sprite_frames.has_animation(back.animation_name),label+" overhead art")
		reset_pair()
		actor.is_crouching=false
		actor.start_attack(actor.basic_move_ids.neutral_punch)
		actor.enter_attack_active()
		actor.attack_cooldown_timer=actor.attack_phase_timer+actor.attack_recovery_time_actual
		actor._apply_attack_to_target(victim,actor._get_attack_data_dictionary("Punch"))
		var attacker_ready := -1
		var defender_ready := -1
		for frame in range(90):
			if not actor._update_hit_stop(1.0/60.0): actor._update_current_attack(1.0/60.0)
			if not victim._update_hit_stop(1.0/60.0): victim._update_hit_reaction(1.0/60.0)
			if attacker_ready<0 and actor.current_attack_id.is_empty(): attacker_ready=frame
			if defender_ready<0 and not victim.is_hit: defender_ready=frame
		check(attacker_ready>=0 and defender_ready>=0 and absi(attacker_ready-defender_ready)<=1,label+" final recovery within one physics frame")
	print("NORMAL_CHAINS_CHECK cases=%d failures=%s" % [cases,JSON.stringify(failures)])
	battle.get_node("BattleManager").cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
