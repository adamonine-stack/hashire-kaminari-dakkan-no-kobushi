extends SceneTree
var failures:Array[String]=[]
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
 if not ok: failures.append(label); push_error(label)
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
 target.ai_enabled=false;target.ai_profile=null;target.input_enabled=false;target.set_physics_process(false)
 var sprite:AnimatedSprite2D=actor.animated_character_sprite
 var scale=sprite.scale
 var anchor=sprite.position
 var folder=ProjectSettings.globalize_path("res://../audit_evidence/crusher_air_attack_v11")
 DirAccess.make_dir_recursive_absolute(folder)
 for facing in [1.0,-1.0]:
  for clip in ["jump_punch_down","jump_kick"]:
   actor._cancel_current_action();actor.reset_attack_state();actor.reset_knockdown_state()
   manager.reset_active_fighter_state(actor,Vector2(650,330),facing,actor.max_hp)
   actor.input_enabled=false;actor.ai_enabled=false;actor.ai_profile=null;actor.is_round_active=true
   target.global_position=Vector2(650+400*facing,520)
   actor.velocity=Vector2.ZERO;actor.move_and_slide()
   check(not actor.is_on_floor(),"airborne fixture")
   if clip=="jump_kick": actor.request_air_kick_attack()
   else: actor.request_air_punch_down_attack()
   check(actor.is_air_attack_active,"air action starts "+clip)
   var seen=false
   for i in range(70):
    await physics_frame
    check(sprite.scale.is_equal_approx(scale),"fixed scale "+clip)
    check(sprite.position.is_equal_approx(anchor),"fixed sprite anchor "+clip)
    if String(sprite.animation)==clip:
     seen=true
     if actor.attack_phase == actor.AttackPhase.ACTIVE: check(sprite.frame==1,"active uses contact frame "+clip)
   check(seen,"runtime selects authored "+clip)
   check(sprite.flip_h == (facing<0),"runtime mirrored facing "+clip)
   check(actor.is_on_floor() and not actor.is_air_attack_active,"landing clears air attack "+clip)
   actor.set_physics_process(false)
   actor.position=Vector2(650,450)
   actor._play_visual_animation(StringName(clip),true);sprite.pause()
   var debug_box:Polygon2D
   if "--boxes" in OS.get_cmdline_user_args():
    var area=actor.kick_area if clip=="jump_kick" else actor.punch_area
    var shape=actor.kick_shape if clip=="jump_kick" else actor.punch_shape
    var half:Vector2=shape.shape.size/2
    debug_box=Polygon2D.new();debug_box.color=Color(1,0.2,0.2,0.3)
    debug_box.polygon=PackedVector2Array([Vector2(-half.x,-half.y),Vector2(half.x,-half.y),half,Vector2(-half.x,half.y)])
    area.show();area.add_child(debug_box)
   for frame in range(4):
    sprite.frame=frame
    var texture:AtlasTexture=sprite.sprite_frames.get_frame_texture(clip,frame)
    check(texture.atlas.resource_path=="res://assets/characters/enemy01/animations/unified_air_attack_v11/motion_atlas.png","correct source "+clip)
    check(texture.get_image().get_used_rect().has_area(),"nonblank frame "+clip)
    if DisplayServer.get_name()!="headless":
     await process_frame;RenderingServer.force_draw(false)
     root.get_texture().get_image().save_png(folder.path_join("%s_%s_%d.png"%[clip,"right" if facing>0 else "left",frame]))
   if debug_box!=null: debug_box.queue_free()
   actor._cancel_current_action();actor.reset_attack_state();actor.reset_knockdown_state()
   manager.reset_active_fighter_state(actor,Vector2(650,330),facing,actor.max_hp)
   actor.input_enabled=false;actor.ai_enabled=false;actor.ai_profile=null;actor.is_round_active=true
   actor.move_and_slide()
   manager.reset_active_fighter_state(target,Vector2(100,330),-facing,target.max_hp)
   target.input_enabled=false;target.ai_enabled=false;target.ai_profile=null;target.is_round_active=true
   if clip=="jump_kick": actor.request_air_kick_attack()
   else: actor.request_air_punch_down_attack()
   var data=actor.current_attack_data
   check(data.hitbox_offset.y<0,"air hitbox matches body height "+clip)
   var area=actor.kick_area if clip=="jump_kick" else actor.punch_area
   target.global_position=area.global_position-target.hurt_box.position
   var hp:int=target.current_hp
   actor.enter_attack_active()
   for i in range(3): await physics_frame
   check(target.current_hp<hp,"real Area2D air hit "+clip+str(facing))
   actor._cancel_current_action()
   actor.set_physics_process(true)
 print("CRUSHER_AIR_ATTACK_LIVE_CHECK failures=",failures)
 manager.cleanup_battle_before_transition();battle.queue_free();await process_frame
 quit(0 if failures.is_empty() else 1)
