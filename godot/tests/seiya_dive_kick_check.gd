extends SceneTree
var failures: Array[String]=[]
var actors: Array=[]
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
 if not ok:
  failures.append(label)
  push_error(label)
func ticks(n: int):
 for i in range(n): await physics_frame
func reset_pair():
 for a in actors:
  a.set_physics_process(false)
  a.reset_knockdown_state()
  a._cancel_current_action()
  a.reset_attack_state()
  a.reset_combo()
  a.has_used_air_attack=false
  a.jump_pressed_this_airtime=false
  a.jump_combo_pending=false
  a.ai_jump_attack_used=false
  a.ai_jump_launch_pending=false
  a.is_hit=false
  a.is_guard_hit=false
  a.is_invincible=false
  a.hit_stop_timer=0
  a.guard_recoil_timer=0
  a.current_hp=a.max_hp
  a.is_round_active=true
  a._clear_guard_state()
  a.combat_commands.clear()
  a.velocity=Vector2.ZERO
func run():
 var battle: Node=load("res://scenes/Battle.tscn").instantiate()
 battle.get_node("BattleManager").active_enemy_count_limit=1
 root.add_child(battle)
 current_scene=battle
 await process_frame
 var manager: Node=battle.get_node("BattleManager")
 manager.select_player_by_id("player_03_seiya")
 for i in range(360):
  await physics_frame
  if manager._enemy_intro_panel!=null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
  if manager.isRoundActive: break
 actors=[battle.get_node("Player"),battle.get_node("Enemy")]
 for a in actors:
  a.ai_enabled=false
  a.ai_profile=null
  a.ai_guard_enabled=false
  a.ai_throw_probability=0
  a.input_enabled=false
 var packet={"damage":5,"attack_type":"punch","attack_height":"high","knockback_x":50.0,"knockback_y":0.0,"hit_stop_frames":0,"effect_size":1.0,"screen_shake":0.0,"se_type":"normal","is_guardable":true}
 for index in range(1):
  var a: Node=actors[index]
  var other: Node=actors[1-index]
  var prefix="seiya" if index==0 else "crusher"
  var id=prefix+"_dive_kick"
  for facing in [1.0,-1.0]:
   for outcome in ["whiff","hit","guard"]:
    reset_pair()
    a.global_position=Vector2(600,420)
    other.global_position=Vector2(600+(350 if outcome=="whiff" else 60)*facing,520)
    a.move_and_slide()
    other.move_and_slide()
    a.facing_direction=facing
    other.facing_direction=-facing
    if outcome=="guard":
     other.is_guarding=true
     other.guard_type="stand"
    var hp: int=other.current_hp
    var scale: Vector2=a.animated_character_sprite.scale
    var anchor: Vector2=a.animated_character_sprite.position
    check(a._request_directional_move(id,true),id+" starts "+outcome)
    a.velocity=Vector2.ZERO
    a._apply_dive_motion()
    check(a.velocity==Vector2.ZERO,"startup does not force dive")
    var data: Resource=a.current_attack_data
    check(data.is_guardable and data.cancel_targets.is_empty(),"guardable and no looping cancels")
    a.set_physics_process(true)
    var saw_land=false
    var saw_active=false
    for i in range(100):
     await physics_frame
     if a.current_attack_id==id and a.attack_phase==a.AttackPhase.ACTIVE:
      if not saw_active and DisplayServer.get_name()!="headless":
       RenderingServer.force_draw(false)
       var folder:=ProjectSettings.globalize_path("res://../audit_evidence/seiya_dive_live")
       DirAccess.make_dir_recursive_absolute(folder)
       root.get_texture().get_image().save_png(folder.path_join("%s_%s_active.png"%[facing,outcome]))
      saw_active=true
      var sprite:AnimatedSprite2D=a.animated_character_sprite
      check(sprite.animation==&"seiya_dive_kick","dedicated dive pose")
      var tex:Texture2D=sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
      check(tex is AtlasTexture and "slim_dive_kick_v11" in tex.atlas.resource_path,"dedicated dive source")
      check(a.velocity.y>=500,"active descent")
      check(signf(a.velocity.x)==facing,"mirrored dive movement")
     if a._is_landing_recovery_busy():
      saw_land=true
      a.set_physics_process(false)
      check(a.is_on_floor() and a.current_attack_type=="","landing clears attack")
      check(not a.punch_hitbox_active and not a.kick_hitbox_active,"landing disables hitboxes")
      check(not a._can_accept_attack_input(true) and not a._can_start_throw() and not a._can_start_guard_or_crouch() and not a.can_start_character_special(true),"landing cannot escape via P/K/throw/guard/special")
      check(a.hurt_box.monitorable,"landing remains punishable")
      a._update_visual_state()
      var sprite:AnimatedSprite2D=a.animated_character_sprite
      var tex:Texture2D=sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
      check(tex is AtlasTexture and "slim_dive_kick_v11" in tex.atlas.resource_path,"dedicated landing source")
      if DisplayServer.get_name()!="headless":
       await process_frame
       RenderingServer.force_draw(false)
       var folder:=ProjectSettings.globalize_path("res://../audit_evidence/seiya_dive_live")
       DirAccess.make_dir_recursive_absolute(folder)
       root.get_texture().get_image().save_png(folder.path_join("%s_%s_land.png"%[facing,outcome]))
      check(a.animated_character_sprite.animation==StringName(prefix+"_dive_land"),"dedicated landing pose")
      check(a.animated_character_sprite.scale==scale and a.animated_character_sprite.position==anchor,"fixed sprite scale and anchor")
      check(a.landing_recovery_remaining>.28,"full landing recovery")
      a.input_enabled=true
      var x: float=a.global_position.x
      Input.action_press("move_right")
      Input.action_press("jump")
      Input.action_press("guard")
      a.set_physics_process(true)
      await ticks(2)
      check(a.is_on_floor() and not a.is_guarding and absf(a.global_position.x-x)<1,"live landing blocks movement/jump/guard")
      for action in ["move_right","jump","guard"]: Input.action_release(action)
      a.set_physics_process(false)
      a.input_enabled=false
      break
    check(saw_active or outcome=="guard","active phase occurred")
    check(saw_land,id+" actual landing "+outcome+str(facing))
    if outcome=="hit": check(other.current_hp<hp,"actual hitbox damages target")
    else: check(other.current_hp==hp,"guard/whiff zero damage")
    if saw_land:
     a.set_physics_process(true)
     await ticks(24)
     check(not a._is_landing_recovery_busy(),"landing timer expires")
     a.set_physics_process(false)
   reset_pair()
   a.global_position=Vector2(600,200)
   other.global_position=Vector2(950,520)
   a.move_and_slide()
   a.facing_direction=facing
   check(a._request_directional_move(id,true),"high-altitude dive starts")
   a.finish_attack()
   check(a.pending_air_landing_data!=null,"expired air attack retains pending landing")
   a.set_physics_process(true)
   for i in range(100):
    await physics_frame
    if a._is_landing_recovery_busy(): break
   check(a._is_landing_recovery_busy(),"late landing still has recovery")
   a.set_physics_process(false)
   a.is_invincible=false
   var before: int=a.current_hp
   check(a.receive_attack(packet,-facing,a.global_position,other),"recovery can be punished")
   check(a.current_hp<before and a.pending_air_landing_data==null and not a._is_landing_recovery_busy(),"hit interruption cleans landing state")
 # Direction history resolves down-air before generic air K, in both facings.
 for index in range(1):
  var a: Node=actors[index]
  var prefix="seiya" if index==0 else "crusher"
  for facing in [1.0,-1.0]:
   reset_pair()
   a.global_position=Vector2(600,420)
   a.move_and_slide()
   a.facing_direction=facing
   a.input_enabled=true
   a.combat_commands.record("down",true,facing)
   a.combat_commands.advance(.12)
   a.combat_commands.record("down",false,facing)
   a.combat_commands.record("kick",true,facing)
   a._dispatch_combat_command()
   check(a.current_attack_id==prefix+"_dive_kick","120ms released direction selects dive "+prefix+str(facing))
   a.input_enabled=false
  reset_pair()
  a.global_position=Vector2(600,520)
  a.move_and_slide()
  check(not a._request_directional_move(prefix+"_dive_kick",true),"ground dive rejected")
 # Mobile UI event path, with naturally delayed action while direction held.
 var mobile: Node=battle.find_child("MobileControls",true,false)
 for facing in [1.0,-1.0]:
  reset_pair()
  var a: Node=actors[0]
  a.input_enabled=true
  a.global_position=Vector2(600,330)
  a.move_and_slide()
  a.facing_direction=facing
  actors[1].global_position=Vector2(950,520)
  a.set_physics_process(true)
  mobile._on_direction_button_down(mobile.left_controls.get_node("CrouchButton"),mobile.DIRECTION_BUTTONS["CrouchButton"])
  await ticks(7)
  mobile._on_tap_button_down(mobile.right_controls.get_node("KickButton"),"kick")
  await ticks(1)
  check(a.current_attack_id=="seiya_dive_kick","mobile down then K delayed "+str(facing))
  mobile.release_all_touch_inputs()
  Input.action_release("kick")
  Input.action_release("down")
  a.input_enabled=false
 print("SEIYA_DIVE_KICK_CHECK failures=%s"%[failures])
 root.get_node("AudioManager").stop_bgm()
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await create_timer(1).timeout
 quit(0 if failures.is_empty() else 1)
