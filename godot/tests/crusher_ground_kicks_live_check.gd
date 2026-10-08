extends SceneTree
var failures:Array[String]=[]
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
 if not ok: failures.append(label);push_error(label)
func run():
 var battle=load("res://scenes/Battle.tscn").instantiate()
 battle.get_node("BattleManager").active_enemy_count_limit=1
 root.add_child(battle);current_scene=battle
 await process_frame
 var manager=battle.get_node("BattleManager")
 manager.select_player_by_id("player_01_akky")
 for i in range(420):
  await physics_frame
  if manager._enemy_intro_panel!=null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
  if manager.isRoundActive: break
 check(manager.isRoundActive,"round active")
 var actor=battle.get_node("Enemy")
 var target=battle.get_node("Player")
 actor.ai_enabled=false;actor.ai_profile=null;actor.input_enabled=false
 target.set_physics_process(false);target.ai_enabled=false;target.ai_profile=null;target.input_enabled=false
 var sprite:AnimatedSprite2D=actor.animated_character_sprite
 var scale=sprite.scale
 var anchor=sprite.position
 var folder=ProjectSettings.globalize_path("res://../audit_evidence/crusher_ground_kicks_live")
 DirAccess.make_dir_recursive_absolute(folder)
 for facing in [1.0,-1.0]:
  for move in ["crusher_forward_kick","crusher_back_kick"]:
   for mode in ["hit","guard","whiff"]:
    actor._cancel_current_action();actor.reset_attack_state();actor.reset_knockdown_state()
    manager.reset_active_fighter_state(actor,Vector2(650,520),facing,actor.max_hp)
    manager.reset_active_fighter_state(target,Vector2(650+400*facing,520),-facing,target.max_hp)
    actor.input_enabled=false;actor.ai_enabled=false;actor.ai_profile=null;actor.is_round_active=true
    target.input_enabled=false;target.ai_enabled=false;target.ai_profile=null;target.is_round_active=true
    target.set_physics_process(false)
    target.is_guarding=mode=="guard";target.guard_type="high"
    actor.set_physics_process(true)
    check(actor._request_directional_move(move,true),"request "+move)
    var source="unified_forward_kick_v12" if move=="crusher_forward_kick" else "unified_back_kick_v13"
    var hp:int=target.current_hp
    var active=false
    var recovery=false
    var start_x=actor.global_position.x
    for tick in range(95):
     await physics_frame
     check(sprite.scale.is_equal_approx(scale),"fixed scale "+move)
     check(sprite.position.is_equal_approx(anchor),"fixed anchor "+move)
     if actor.attack_phase==actor.AttackPhase.ACTIVE and not active:
      active=true
      check(sprite.frame==2,"contact frame "+move)
      check(sprite.flip_h==(facing<0),"mirrored "+move)
      var texture:AtlasTexture=sprite.sprite_frames.get_frame_texture(move,2)
      check(texture.atlas.resource_path.contains(source),"authored source "+move)
      if mode!="whiff": target.global_position=actor.kick_area.global_position-target.hurt_box.position
      if DisplayServer.get_name()!="headless":
       actor.set_physics_process(false);sprite.pause()
       await process_frame;RenderingServer.force_draw(false)
       root.get_texture().get_image().save_png(folder.path_join("%s_%s_%s.png"%[move,"right" if facing>0 else "left",mode]))
       actor.set_physics_process(true)
     if actor.attack_phase==actor.AttackPhase.RECOVERY or (mode=="guard" and actor.guard_recoil_timer>0): recovery=true
    check(active and recovery,"active and recovery "+move+mode)
    check(actor.current_attack_data==null,"finishes "+move+mode)
    check(target.current_hp<hp if mode=="hit" else target.current_hp==hp,"damage/guard/whiff "+move+mode)
    var displacement=(actor.global_position.x-start_x)*facing
    check(displacement>5 if move=="crusher_forward_kick" else displacement < -5,"approach/retreat "+move)
 print("CRUSHER_GROUND_KICKS_LIVE_CHECK failures=",failures)
 manager.cleanup_battle_before_transition();battle.queue_free();await process_frame
 quit(0 if failures.is_empty() else 1)
