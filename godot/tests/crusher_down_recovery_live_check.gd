extends "res://tests/stage1_hero_throws_check.gd"
func run() -> void:
 var battle: Node=load("res://scenes/Battle.tscn").instantiate()
 root.add_child(battle)
 current_scene=battle
 await process_frame
 var manager: Node=battle.get_node("BattleManager")
 if "--gou" in OS.get_cmdline_user_args(): hero="gou"
 manager.select_player_by_id("player_02_gou" if hero=="gou" else "player_03_seiya")
 for i in range(500):
  await physics_frame
  if manager._enemy_intro_panel!=null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
  if manager.isRoundActive: break
 player=battle.get_node("Player")
 enemy=battle.get_node("Enemy")
 enemy.ai_enabled=false
 enemy.ai_profile=null
 enemy.ai_guard_enabled=false
 enemy.ai_throw_probability=0
 enemy.throw_escape_probability=0
 player.throw_escape_probability=0
 for i in range(3): await physics_frame
 var mobile: Node=battle.find_child("MobileControls",true,false)
 mobile.visible=true
 for facing in [1.0,-1.0]:
  reset_pair(facing)
  player.set_physics_process(false)
  enemy.last_knockdown_animation=&""
  enemy.enter_knockdown()
  var scale: Vector2=enemy.animated_character_sprite.scale
  var seen_up:=false
  var captured: Dictionary={}
  for tick in range(120):
   await physics_frame
   var sprite: AnimatedSprite2D=enemy.animated_character_sprite
   check(sprite.scale.is_equal_approx(scale),"fixed down/recovery scale")
   seen_up=seen_up or enemy.knockdown_state==&"GET_UP"
   if sprite.animation in [&"knockdown",&"stand_up"]:
    var texture: Texture2D=sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
    check(texture is AtlasTexture and "unified_down_recovery_v8" in texture.atlas.resource_path,"new live down/recovery atlas")
    var key: String="%s_%s_%s"%[facing,sprite.animation,sprite.frame]
    if DisplayServer.get_name()!="headless" and not captured.has(key):
     captured[key]=true
     RenderingServer.force_draw(false)
     var folder:=ProjectSettings.globalize_path("res://../audit_evidence/crusher_down_recovery_live")
     DirAccess.make_dir_recursive_absolute(folder)
     root.get_texture().get_image().save_png(folder.path_join(key+".png"))
  check(seen_up and enemy.knockdown_state==&"" and enemy.hurt_box.monitorable,"down/wake-up returns to control")
 print("CRUSHER_DOWN_RECOVERY_LIVE_CHECK failures=%s"%[failures])
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
