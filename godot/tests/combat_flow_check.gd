extends SceneTree
var failures: Array[String]=[]
var battle: Node
var manager: Node
var actors: Array=[]
var output: String
func _initialize(): call_deferred("run")
func check(ok: bool,label: String):
 if not ok: failures.append(label); push_error(label)
func snap(label: String):
 if DisplayServer.get_name()=="headless": return
 var running: Array[bool]=[]
 for actor in actors:
  running.append(actor.is_physics_processing())
  actor.set_physics_process(false)
  actor._update_visual_state()
 await process_frame
 await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(output.path_join(label+".png"))==OK,"capture "+label)
 for i in range(actors.size()): actors[i].set_physics_process(running[i])
func reset_actor(a: Node,point: Vector2,facing: float):
 a._cancel_current_action()
 a.reset_attack_state()
 manager.reset_active_fighter_state(a,point,facing,a.max_hp)
 a.ai_enabled=false
 a.ai_profile=null
 a.input_enabled=false
 a.is_round_active=true
 a.set_physics_process(true)
 a.hit_stop_timer=0
 a.combat_commands.clear()
func run():
 seed(53)
 output=ProjectSettings.globalize_path("res://../combat_flow_evidence")
 if DisplayServer.get_name()!="headless": DirAccess.make_dir_recursive_absolute(output)
 battle=load("res://scenes/Battle.tscn").instantiate()
 battle.get_node("BattleManager").active_enemy_count_limit=1
 root.add_child(battle); current_scene=battle
 await process_frame
 manager=battle.get_node("BattleManager")
 manager.select_player_by_id("player_01_akky")
 for i in range(420):
  await physics_frame
  if manager._enemy_intro_panel!=null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
  if manager.isRoundActive: break
 check(manager.isRoundActive,"battle active")
 actors=[battle.get_node("Player"),battle.get_node("Enemy")]
 if String(actors[0].fighter_definition.fighter_id)!="player_01_akky": actors.reverse()
 var moves=[["player1_punch_1","akky_forward_punch","player1_kick_finish","akky_down_kick"],["crusher_neutral_punch","crusher_forward_punch","crusher_neutral_kick","crusher_down_kick"]]
 for index in range(2):
  var attacker: Node=actors[index]
  var victim: Node=actors[1-index]
  for facing in [1.0,-1.0]:
   for move in moves[index]:
    reset_actor(attacker,Vector2(640-100*facing,520),facing)
    reset_actor(victim,Vector2(640,520),-facing)
    for i in range(4): await physics_frame
    var hp: int=victim.current_hp
    var scale: Vector2=victim.animated_character_sprite.scale
    var pivot: Vector2=victim.animated_character_sprite.position
    attacker.start_attack(move)
    check(attacker.current_attack_id==move,"move starts "+move)
    var expected: StringName=victim._get_damage_animation_from_attack(attacker._get_kick_attack_data() if attacker.current_attack_type=="Kick" else attacker._get_punch_attack_data())
    var saw_hit=false
    var saw_reaction=false
    var saw_down=false
    var saw_wake=false
    var captures: Dictionary={}
    for tick in range(220):
     await physics_frame
     saw_hit=saw_hit or victim.current_hp<hp
     saw_reaction=saw_reaction or victim.animated_character_sprite.animation==expected
     saw_down=saw_down or victim.knockdown_state==&"KNOCKDOWN"
     saw_wake=saw_wake or victim.knockdown_state==&"GET_UP"
     check(victim.animated_character_sprite.scale.is_equal_approx(scale) and victim.animated_character_sprite.position.is_equal_approx(pivot),"constant receiver transform "+move)
     var phase=String(victim.knockdown_state) if victim.knockdown_state!=&"" else ("hit" if victim.is_hit else "ready")
     if saw_hit and not captures.has(phase):
      captures[phase]=true
      await snap("%s_%s_%s"%[move,facing,phase])
    check(saw_hit,"real Area2D contact "+move+str(facing))
    check(saw_reaction,"authored receiver appears "+move+str(facing))
    if move.ends_with("down_kick"): check(saw_down and saw_wake,"sweep down/wake "+move)
    check(victim.current_hp>0 and not victim.is_hit and victim.knockdown_state==&"" and victim.hurt_box.monitorable,"normal recovery "+move)
    check(attacker.current_attack_type=="" and not attacker.punch_hitbox_active and not attacker.kick_hitbox_active,"attacker cleanup "+move)
 # Two receiving enemies share a single actual attack active interval.
 var extra: Node=load("res://scenes/Player.tscn").instantiate()
 extra.name="CombatExtraCrusher"
 battle.add_child(extra)
 extra.apply_character_data(load("res://data/enemies/enemy_01_standard.tres"))
 actors.append(extra)
 for facing in [1.0,-1.0]:
  reset_actor(actors[0],Vector2(540,520),facing)
  reset_actor(actors[1],Vector2(540+90*facing,520),-facing)
  reset_actor(extra,Vector2(540+110*facing,520),-facing)
  for i in range(4): await physics_frame
  var hp1: int=actors[1].current_hp
  var hp2: int=extra.current_hp
  actors[0].start_attack("akky_forward_punch")
  for tick in range(90): await physics_frame
  check(actors[1].current_hp<hp1 and extra.current_hp<hp2,"multi-target actual contact "+str(facing))
  check(not actors[1].is_hit and not extra.is_hit,"independent hitstun recovery")
  await snap("multiple_%s"%facing)
 # KO a test-owned enemy through a real hitbox without changing campaign progress.
 reset_actor(actors[0],Vector2(540,520),1)
 reset_actor(actors[1],Vector2(1000,520),-1)
 reset_actor(extra,Vector2(630,520),-1)
 extra.set_health(1)
 for i in range(4): await physics_frame
 actors[0].start_attack("player1_punch_1")
 for i in range(180): await physics_frame
 check(extra.current_hp==0 and not extra.hurt_box.monitorable,"KO disables HurtBox")
 check(not extra.can_receive_attack() and not extra._can_start_throw(),"KO rejects combat")
 check(not extra.punch_hitbox_active and not extra.kick_hitbox_active,"KO no active attacks")
 await snap("extra_ko")
 extra.queue_free()
 for a in actors.slice(0,2): a._cancel_current_action()
 print("COMBAT_FLOW_CHECK failures=",failures)
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
