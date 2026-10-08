extends SceneTree
var failures:Array[String]=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 if not ok:failures.append(label);push_error(label)
func run():
 var battle=load("res://scenes/Battle.tscn").instantiate()
 battle.get_node("BattleManager").active_enemy_count_limit=1
 root.add_child(battle);current_scene=battle
 await process_frame
 var manager=battle.get_node("BattleManager")
 manager.select_player_by_id("player_03_seiya")
 for i in range(420):
  await physics_frame
  if manager._enemy_intro_panel!=null and manager._enemy_intro_panel.visible:manager.enemy_intro_finished.emit()
  if manager.isRoundActive:break
 check(manager.isRoundActive,"round active")
 var actor=battle.get_node("Player")
 var enemy=battle.get_node("Enemy")
 enemy.ai_enabled=false;enemy.ai_profile=null;enemy.set_physics_process(false)
 var sprite:AnimatedSprite2D=actor.animated_character_sprite
 var scale=sprite.scale
 var anchor=sprite.position
 var folder=ProjectSettings.globalize_path("res://../audit_evidence/seiya_slim_jump_v16")
 DirAccess.make_dir_recursive_absolute(folder)
 for facing in [1.0,-1.0]:
  Input.action_release("jump")
  actor._cancel_current_action();actor.reset_attack_state();actor.reset_knockdown_state()
  manager.reset_active_fighter_state(actor,Vector2(600,520),facing,actor.max_hp)
  actor.input_enabled=true;actor.ai_enabled=false;actor.ai_profile=null;actor.is_round_active=true
  enemy.global_position=Vector2(600+350*facing,520)
  for i in range(4):await physics_frame
  var seen:Dictionary={}
  Input.action_press("jump")
  for i in range(105):
   await physics_frame
   if i==2:Input.action_release("jump")
   check(sprite.scale.is_equal_approx(scale),"jump fixed scale")
   check(sprite.position.is_equal_approx(anchor),"jump fixed sprite anchor")
   var clip:String=String(sprite.animation)
   if clip in ["jump_start","jump_ascent","jump_fall","jump_land"]:
    var texture:AtlasTexture=sprite.sprite_frames.get_frame_texture(clip,sprite.frame)
    check(texture.atlas.resource_path=="res://assets/characters/player03/animations/slim_jump_v16/motion_atlas.png","jump current design "+clip)
    check(sprite.flip_h == (facing<0),"jump mirrored")
    if not seen.has(clip):
     seen[clip]=true
     if DisplayServer.get_name()!="headless":
      actor.set_physics_process(false);sprite.pause()
      await process_frame;RenderingServer.force_draw(false)
      root.get_texture().get_image().save_png(folder.path_join("%s_%s.png"%[clip,"right" if facing>0 else "left"]))
      actor.set_physics_process(true);sprite.play()
  for clip in ["jump_start","jump_ascent","jump_fall","jump_land"]:check(seen.has(clip),"real jump phase "+clip+str(facing))
  check(actor.is_on_floor() and actor.current_attack_type.is_empty(),"jump returns grounded idle")
  print("SEIYA_JUMP_PHASES facing=",facing," seen=",seen)
 print("SEIYA_SLIM_JUMP_LIVE_CHECK failures=",failures)
 manager.cleanup_battle_before_transition();battle.queue_free();await process_frame
 quit(0 if failures.is_empty() else 1)
