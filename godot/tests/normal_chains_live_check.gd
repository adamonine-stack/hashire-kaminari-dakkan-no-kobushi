extends "res://tests/basic_moves_combat_check.gd"

const COUNTS := [[3,2],[2,2],[4,3],[2,2],[4,3],[2,2],[3,2],[3,2],[4,3],[3,2],[4,3],[4,3]]

func run() -> void:
	seed(28)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	battle.get_node("BattleManager").active_enemy_count_limit = 1
	root.add_child(battle)
	await process_frame
	var manager: Node = battle.get_node("BattleManager")
	manager.select_player_by_id("player_01_akky")
	for i in range(500):
		await physics_frame
		if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
		if manager.isRoundActive: break
	player=battle.get_node("Player")
	enemy=battle.get_node("Enemy")
	for n in [0,1,2,3,6,9,7,4,8,5,10,11]:
		var definition: Resource=load("res://data/"+Inventory.DEFINITIONS[n]+".tres")
		actor=enemy if definition.team_type==&"ENEMY" else player
		opponent=player if actor==enemy else enemy
		actor.apply_fighter_definition(definition)
		var punches: Array=[]
		var kicks: Array=[]
		for rank in range(COUNTS[n][0]): punches.append("punch")
		for rank in range(COUNTS[n][1]): kicks.append("kick")
		for route in [punches,kicks,["punch","punch","kick"]]:
			var kind: String=route[0]
			settle()
			actor.is_round_active=true
			opponent.is_round_active=true
			opponent.current_hp=10000
			actor.facing_direction=1.0
			var data: Resource=actor._get_attack_data(actor.basic_move_ids["neutral_"+kind])
			var reach: float=data.hitbox_offset.x*actor.battle_visual_scale_multiplier*definition.combat_geometry_scale
			opponent.global_position=Vector2(600+reach,520)
			opponent._update_pose_collision()
			actor.start_attack(String(data.attack_id))
			var attacks: Array[String]=[String(data.attack_id)]
			var peak := 0
			var elapsed := 0
			for frame in range(240):
				await physics_frame
				if actor.combo_count<route.size(): actor.buffer_attack(StringName(String(route[actor.combo_count]).capitalize()))
				actor._physics_process(1.0/60.0)
				opponent._physics_process(1.0/60.0)
				peak=maxi(peak,actor.combo_count)
				var current: String=actor.current_attack_id
				if peak>0 and peak<route.size() and not current.is_empty():
					check(opponent.is_hit,String(definition.fighter_id)+" next hit beats retaliation")
					if opponent.is_hit: check(not opponent.request_attack_input(&"Punch",true),String(definition.fighter_id)+" retaliation blocked in hitstun")
				if not current.is_empty() and not attacks.has(current): attacks.append(current)
				elapsed=frame
				if current.is_empty(): break
			check(peak==route.size(),String(definition.fighter_id)+str(route)+" collision hit count="+str(peak))
			check(attacks.size()==route.size(),String(definition.fighter_id)+str(route)+" buffered chain stages="+str(attacks))
			check(opponent.knockdown_state==&"",String(definition.fighter_id)+" no normal finisher knockdown")
			print("LIVE_CHAIN ",definition.fighter_id," ",route," hits=",peak," frames=",elapsed)
		settle()
		actor.is_round_active=true
		opponent.is_round_active=true
		opponent.input_enabled=false
		actor.facing_direction=1.0
		opponent.facing_direction=-1.0
		var jab: Resource=actor._get_attack_data(actor.basic_move_ids.neutral_punch)
		opponent.global_position=Vector2(600+jab.hitbox_offset.x*actor.battle_visual_scale_multiplier*definition.combat_geometry_scale,520)
		opponent.is_guarding=true
		opponent.guard_type="high"
		actor.start_attack(String(jab.attack_id))
		for frame in range(60):
			await physics_frame
			actor.buffer_attack(&"Punch")
			actor._physics_process(1.0/60.0)
			if opponent.is_guard_hit: break
		check(opponent.is_guard_hit,String(definition.fighter_id)+" guard collision")
		check(actor.current_attack_id.is_empty() and actor.guard_recoil_timer>opponent.guard_hit_timer,String(definition.fighter_id)+" guard stops combo and gives defender advantage")
		opponent.is_guarding=false
		opponent.guard_type=""
		for frame in range(60):
			await physics_frame
			actor._physics_process(1.0/60.0)
			opponent._physics_process(1.0/60.0)
			if not opponent.is_guard_hit and opponent.hit_stop_timer<=0.0: break
		var hp_before_counter: float=actor.current_hp
		check(not opponent.current_attack_id.is_empty() or opponent.request_attack_input(&"Punch",true),String(definition.fighter_id)+" counter starts after guard")
		for frame in range(60):
			await physics_frame
			actor._physics_process(1.0/60.0)
			opponent._physics_process(1.0/60.0)
			if actor.current_hp<hp_before_counter: break
		check(actor.current_hp<hp_before_counter,String(definition.fighter_id)+" guard counter connects")
		for key in ["back_punch","down_punch"]:
			settle()
			opponent.input_enabled=false
			actor.is_round_active=true
			opponent.is_round_active=true
			actor.facing_direction=1.0
			var move: Resource=actor._get_attack_data(actor.basic_move_ids[key])
			var reach: float=move.hitbox_offset.x*actor.battle_visual_scale_multiplier*definition.combat_geometry_scale
			opponent.global_position=Vector2(600+reach,520)
			opponent.is_crouching=key=="back_punch"
			opponent._update_pose_collision()
			var hp: float=opponent.current_hp
			Input.action_press("move_left" if key=="back_punch" else "down")
			Input.action_press("attack")
			actor._physics_process(1.0/60.0)
			check(actor.current_attack_id==move.attack_id,String(definition.fighter_id)+key+" actual input mapping")
			release_inputs()
			for frame in range(90):
				await physics_frame
				actor._physics_process(1.0/60.0)
				if opponent.current_hp<hp: break
			check(opponent.current_hp<hp,String(definition.fighter_id)+key+" grounded collision")
			if key=="down_punch": check(opponent.velocity.y<0,String(definition.fighter_id)+" launcher sends upward")
	print("NORMAL_CHAINS_LIVE_CHECK failures=",JSON.stringify(failures))
	manager.cleanup_battle_before_transition()
	battle.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
