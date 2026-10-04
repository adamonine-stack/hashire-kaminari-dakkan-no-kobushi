extends SceneTree
var failures: Array[String] = []
func check(ok: bool, label: String):
 if not ok:
  failures.append(label)
  push_error(label)
func _initialize():
 call_deferred("run")
func run():
 var battle: Node = load("res://scenes/Battle.tscn").instantiate()
 battle.get_node("BattleManager").active_enemy_count_limit = 1
 root.add_child(battle)
 current_scene = battle
 await process_frame
 var manager: Node = battle.get_node("BattleManager")
 await manager.select_player_by_id("player_01_akky")
 for i in range(360):
  await physics_frame
  if manager.isRoundActive: break
 var actors: Array = [battle.get_node("Player"),battle.get_node("Enemy")]
 for actor in actors:
  actor.ai_enabled = false
  actor.ai_profile = null
  actor.set_physics_process(false)
 for index in range(2):
  var defender: Node = actors[index]
  var attacker: Node = actors[1-index]
  var scale: Vector2 = defender.animated_character_sprite.scale
  var anchor: Vector2 = defender.animated_character_sprite.position
  for facing in [1.0,-1.0]:
   defender.reset_knockdown_state()
   defender._cancel_current_action()
   defender.is_round_active = true
   defender.current_hp = defender.max_hp
   defender.global_position = Vector2(600,350)
   defender.velocity = Vector2.ZERO
   defender.move_and_slide()
   defender.facing_direction = facing
   attacker.global_position = Vector2(600+80*facing,350)
   attacker._cancel_current_action()
   check(not defender.is_on_floor(),"airborne setup")
   Input.action_press("guard")
   defender._update_defensive_state(.016)
   check(defender.is_guarding and defender.guard_type=="air" and not defender.is_crouch_guarding,"G establishes air guard")
   defender._update_visual_state()
   check(defender.animated_character_sprite.animation==&"air_guard","dedicated hold")
   var packet := {"damage":15,"base_damage":15,"attack_type":"kick","attack_height":"overhead","knockback_x":120.0,"knockback_y":-100.0,"hit_stop_frames":3,"effect_size":1.0,"screen_shake":0.0,"se_type":"normal","is_guardable":true}
   defender.velocity.y = 80
   var hp: int = defender.current_hp
   check(not defender.receive_attack(packet,facing,defender.global_position,attacker),"air attack blocks")
   check(defender.current_hp==hp and defender.is_guard_hit and not defender.is_hit,"normal block zero damage")
   check(is_equal_approx(defender.velocity.y,80.0),"guard does not freeze vertical movement")
   defender._update_visual_state()
   check(defender.animated_character_sprite.animation==&"air_guard_hit","dedicated block impact")
   defender._update_defensive_state(.016)
   check(defender._can_guard_attack(packet,attacker),"air blockstun retains protection")
   Input.action_release("guard")
   defender._update_guard_hit(1)
   check(not defender.is_guarding and not defender.is_guard_hit,"release returns control")
   Input.action_press("guard")
   defender._update_defensive_state(.016)
   attacker.global_position.x = 600-80*facing
   check(not defender._can_guard_attack(packet,attacker),"back attacks cannot be guarded")
   attacker.global_position.x = 600+80*facing
   packet.is_guardable = false
   check(not defender._can_guard_attack(packet,attacker),"unblockable respected")
   packet.is_guardable = true
   packet.attack_height = "throw"
   check(not defender._can_guard_attack(packet,attacker),"throw excluded")
   packet.attack_height = "overhead"
   packet.attack_type = "special"
   packet.guard_damage_multiplier = 0.0
   defender.special_guard_animation = &""
   check(not defender.receive_attack(packet,facing,defender.global_position,attacker),"special can air block")
   check(defender.current_hp==hp,"special zero authored chip")
   defender._update_guard_hit(1)
   defender._clear_guard_state()
   defender.input_enabled = false
   defender.enter_guard()
   check(defender.is_guarding and defender.guard_type=="air","AI uses same air guard")
   defender._clear_guard_state()
   defender.knockdown_state = &"KNOCKDOWN"
   check(not defender._can_start_guard_or_crouch(),"down cannot guard")
   defender.reset_knockdown_state()
   defender.throw_state = "THROWN"
   defender.is_throw_locked = true
   check(not defender._can_start_guard_or_crouch(),"throw hold cannot guard")
   defender._finish_throw()
   defender.current_hp = 0
   check(not defender._can_start_guard_or_crouch(),"KO cannot guard")
   defender.current_hp = hp
   check(defender.animated_character_sprite.scale.is_equal_approx(scale) and defender.animated_character_sprite.position.is_equal_approx(anchor),"fixed scale/anchor")
   # Real gravity and landing flow with G held; no input-generated attack.
   defender._cancel_current_action()
   defender.global_position = Vector2(600,400)
   defender.velocity = Vector2(0,100)
   defender.input_enabled = true
   defender.set_physics_process(true)
   var landed := false
   for i in range(120):
    await physics_frame
    if defender.is_on_floor():
     landed = true
     break
   check(landed,"air guard lands under gravity")
   await physics_frame
   check(defender.guard_type=="high" and defender._get_current_visual_animation()==&"guard","landing returns ground guard")
   Input.action_release("guard")
   for i in range(20): await physics_frame
   check(not defender.is_guarding and not defender.is_guard_hit,"landing release clears")
   defender.set_physics_process(false)
 Input.action_release("guard")
 var bot: Node = actors[1]
 var target: Node = actors[0]
 bot._cancel_current_action()
 bot.ai_profile = load("res://data/enemy_ai/enemy_01_standard_ai.tres").duplicate()
 bot.ai_profile.reactive_guard_rate = 1.0
 bot.ai_profile.reaction_time_min = .18
 bot.input_enabled = false
 bot.global_position = Vector2(600,350)
 target.global_position = Vector2(660,350)
 target.facing_direction = -1
 target.current_attack_type = "Punch"
 target.current_attack_data = load("res://data/attacks/player1_punch_1.tres")
 bot.move_and_slide()
 bot.ai_air_guard_observed = 0
 bot.ai_air_guard_decided = false
 check(not bot._try_ai_air_guard(.05),"AI cannot instantly guard input/startup")
 check(bot._try_ai_air_guard(.15),"AI observes threat then air guards")
 check(bot.guard_type=="air","observed AI air guard state")
 bot._clear_guard_state()
 check(not bot._try_ai_air_guard(.3),"one guard roll per jump")
 target.reset_attack_state()
 print("AIR_GUARD_CHECK failures=%s"%[failures])
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
