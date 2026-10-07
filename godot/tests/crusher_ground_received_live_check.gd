extends "res://tests/stage1_hero_throws_check.gd"
func run() -> void:
 var battle:Node=load("res://scenes/Battle.tscn").instantiate()
 root.add_child(battle)
 current_scene=battle
 await process_frame
 var manager:Node=battle.get_node("BattleManager")
 manager.select_player_by_id("player_02_gou")
 for i in range(400):
  await physics_frame
  if manager._enemy_intro_panel!=null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
  if manager.isRoundActive: break
 player=battle.get_node("Player")
 enemy=battle.get_node("Enemy")
 enemy.ai_enabled=false
 enemy.ai_profile=null
 enemy.ai_guard_enabled=false
 enemy.ai_throw_probability=0
 player.set_physics_process(false)
 var folder:=ProjectSettings.globalize_path("res://../audit_evidence/crusher_ground_received_live")
 DirAccess.make_dir_recursive_absolute(folder)
 for facing in [1.0,-1.0]:
  for clip in [&"damage_light",&"damage_heavy",&"damage_high",&"damage_low"]:
   reset_pair(facing)
   enemy.set_physics_process(true)
   await physics_frame
   var sprite:AnimatedSprite2D=enemy.animated_character_sprite
   var baseline:=sprite.scale
   var hp:int=enemy.current_hp
   # Damage pipeline fixture: explicit reaction, without forcing a visual state.
   var packet:Dictionary=player._get_punch_attack_data().duplicate()
   packet["damage"]=1
   packet["hit_reaction"]=clip
   packet["knockback_x"]=0.0
   packet["knockback_y"]=0.0
   packet["launch_velocity"]=Vector2.ZERO
   packet["knockdown"]=false
   packet["combo_hit_max"]=0
   packet["hitstun_time"]=0.4
   check(enemy.receive_attack(packet,facing,enemy.global_position,player),"accept ground reaction")
   check(enemy.current_hp==hp-1,"damage applied once")
   var seen:=false
   for tick in range(90):
    await physics_frame
    if sprite.animation==clip:
     var tex:Texture2D=sprite.sprite_frames.get_frame_texture(clip,sprite.frame)
     check(tex is AtlasTexture and "unified_ground_received_v10" in tex.atlas.resource_path,"authored ground source")
     check(sprite.scale.is_equal_approx(baseline),"fixed actor scale")
     if not seen and DisplayServer.get_name()!="headless":
      RenderingServer.force_draw(false)
      root.get_texture().get_image().save_png(folder.path_join("%s_%s.png"%[facing,clip]))
     seen=true
   check(seen,"ground reaction selected")
   check(not enemy.is_hit and enemy.knockdown_state==&"" and enemy.hurt_box.monitorable,"ground reaction returns to control")
 print("CRUSHER_GROUND_RECEIVED_CHECK failures=%s"%[failures])
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
