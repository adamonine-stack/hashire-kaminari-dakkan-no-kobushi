extends SceneTree
var failures: Array[String]=[]
var actors: Array=[]
func _initialize(): call_deferred("run")
func check(ok: bool,label: String):
 if not ok:
  failures.append(label); push_error(label)
func reset_pair():
 for a in actors:
  a.set_physics_process(false)
  a.reset_knockdown_state()
  a._cancel_current_action()
  a.reset_attack_state()
  a.reset_combo()
  a.is_hit=false
  a.is_guard_hit=false
  a.is_invincible=false
  a.hit_stop_timer=0
  a.guard_recoil_timer=0
  a.current_hp=a.max_hp
  a.is_round_active=true
  a.throw_escape_probability=0
  a.throw_regrab_lock_timer=0
  a._clear_guard_state()
  a.velocity=Vector2.ZERO
func run():
 var battle: Node=load("res://scenes/Battle.tscn").instantiate()
 battle.get_node("BattleManager").active_enemy_count_limit=1
 root.add_child(battle)
 current_scene=battle
 await process_frame
 var manager: Node=battle.get_node("BattleManager")
 await manager.select_player_by_id("player_01_akky")
 for i in range(360):
  await physics_frame
  if manager.isRoundActive: break
 actors=[battle.get_node("Player"),battle.get_node("Enemy")]
 for a in actors:
  a.ai_enabled=false
  a.ai_profile=null
  a.ai_guard_enabled=false
  a.input_enabled=false
 for index in range(2):
  var attacker: Node=actors[index]
  var victim: Node=actors[1-index]
  var prefix="akky" if index==0 else "crusher"
  for facing in [1.0,-1.0]:
   reset_pair()
   attacker.global_position=Vector2(600,520)
   victim.global_position=Vector2(600+56*facing,520)
   attacker.velocity.y=40; victim.velocity.y=40
   attacker.move_and_slide(); victim.move_and_slide()
   attacker.facing_direction=facing
   victim.facing_direction=-facing
   var scale: Vector2=victim.animated_character_sprite.scale
   var anchor: Vector2=victim.animated_character_sprite.position
   var hp: int=victim.current_hp
   check(attacker._request_directional_move(prefix+"_down_throw",true),"live down throw starts "+prefix+str(facing))
   attacker.set_physics_process(true); victim.set_physics_process(true)
   var impact=false
   var rebound=false
   var down=false
   var wake=false
   var max_contacts=0
   var lowest_y=520.0
   for i in range(260):
    await physics_frame
    max_contacts=maxi(max_contacts,victim.ground_bounce_contacts)
    if victim.ground_bounce_phase!="":
     lowest_y=minf(lowest_y,victim.global_position.y)
     check(not victim.can_receive_attack() and not victim.can_be_thrown(attacker),"bounce excludes re-hit/re-throw")
     check(victim.animated_character_sprite.scale==scale and victim.animated_character_sprite.position==anchor,"fixed bounce scale/anchor")
     if victim.ground_bounce_phase=="impact":
      impact=true
      check(victim._get_current_visual_animation()==&"ground_impact","impact dedicated pose")
     if victim.ground_bounce_phase=="air":
      rebound=true
      check(victim._get_current_visual_animation()==&"ground_bounce","rebound dedicated pose")
    down=down or victim.knockdown_state==&"KNOCKDOWN"
    wake=wake or victim.knockdown_state==&"GET_UP"
   check(impact and rebound and down and wake and victim.knockdown_state==&"","complete throw/bounce/down/wake "+prefix+str(facing))
   check(max_contacts==1 and lowest_y>=490,"one bounded low bounce")
   check(victim.current_hp<hp,"throw still damages")
   check(victim.hurt_box.monitorable,"wake restores hurtbox")
   print("BOUNCE_ROUTE ",prefix," facing=",facing," contacts=",max_contacts," min_y=",lowest_y)
 # Existing special wall pipeline, with wall option enabled on the debug packet
 # for AKKY as a receiver; Crusher's normal special design remains unchanged.
 for index in range(2):
  var victim: Node=actors[index]
  var attacker: Node=actors[1-index]
  for direction in [1.0,-1.0]:
   reset_pair()
   victim.global_position=Vector2(640,520)
   attacker.global_position=Vector2(640-65*direction,520)
   victim.velocity.y=40; attacker.velocity.y=40
   victim.move_and_slide(); attacker.move_and_slide()
   victim.facing_direction=-direction
   attacker.facing_direction=direction
   var packet: Dictionary=attacker._get_character_special_attack_dictionary()
   packet.wall_slam=true
   packet.damage=1
   var scale: Vector2=victim.animated_character_sprite.scale
   check(victim.receive_attack(packet,direction,victim.global_position,attacker),"special wall launch")
   victim.set_physics_process(true)
   var impact=false
   var fall=false
   var wake=false
   var contacts=0
   for i in range(320):
    await physics_frame
    contacts=maxi(contacts,victim.special_wall_contacts)
    if victim.special_wall_phase=="impact":
     impact=true
     check(victim._get_current_visual_animation()==&"wall_hit","dedicated physical wall impact")
    if victim.special_wall_phase=="fall":
     fall=true
     check(victim._get_current_visual_animation()==&"wall_fall" or victim.knockdown_state!=&"KNOCKBACK","dedicated wall fall")
    wake=wake or victim.knockdown_state==&"GET_UP"
    check(victim.animated_character_sprite.scale==scale,"fixed wall scale")
   check(impact and fall and wake and contacts==1 and victim.knockdown_state==&"","complete wall/down/wake "+str(index)+str(direction))
 # Limits and KO/reset cannot leave a bounce pending.
 reset_pair()
 for a in actors:
  a._configure_ground_bounce(99,Vector2(900,-900))
  check(a.ground_bounces_remaining==1 and a.ground_bounce_velocity==Vector2(80,-200),"data bounded bounce count/velocity")
  a.current_hp=0
  check(not a._try_begin_ground_bounce(),"KO never bounces")
  a.reset_knockdown_state()
  check(a.ground_bounces_remaining==0 and a.ground_bounce_phase=="","reset clears bounce")
 print("WALL_BOUNCE_CHECK failures=%s"%[failures])
 root.get_node("AudioManager").stop_bgm()
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await create_timer(1).timeout
 quit(0 if failures.is_empty() else 1)
