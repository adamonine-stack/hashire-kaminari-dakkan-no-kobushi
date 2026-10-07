extends SceneTree
var output := "res://../directional_evidence"
func _initialize() -> void:
 call_deferred("run")
func snap(label: String) -> void:
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output.path_join(label+".png"))
func mark_box(area: Area2D, shape: CollisionShape2D, color: Color) -> Node2D:
 var polygon := Polygon2D.new()
 var half: Vector2 = shape.shape.size*0.5
 polygon.polygon = PackedVector2Array([Vector2(-half.x,-half.y),Vector2(half.x,-half.y),half,Vector2(-half.x,half.y)])
 polygon.color = color
 area.add_child(polygon)
 polygon.position = shape.position
 return polygon
func run() -> void:
 if DisplayServer.get_name() == "headless":
  push_error("Rendering display required")
  quit(1)
  return
 output = ProjectSettings.globalize_path(output)
 DirAccess.make_dir_recursive_absolute(output)
 var battle: Node = load("res://scenes/Battle.tscn").instantiate()
 battle.get_node("BattleManager").active_enemy_count_limit = 1
 root.add_child(battle)
 await process_frame
 var manager: Node = battle.get_node("BattleManager")
 manager.select_player_by_id("player_01_akky")
 for i in range(360):
  await physics_frame
  if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible:
   manager.enemy_intro_finished.emit()
  if manager.isRoundActive: break
 var player: Node = battle.get_node("Player")
 var enemy: Node = battle.get_node("Enemy")
 player.set_physics_process(false)
 enemy.set_physics_process(false)
 enemy.ai_enabled = false
 player.position = Vector2(540,520)
 enemy.position = Vector2(820,520)
 battle.get_node("BattleCamera").position = Vector2(640,360)
 battle.get_node("BattleCamera").zoom = Vector2.ONE
 battle.get_node("BattleCamera").set_process(false)
 battle.get_node("BattleCamera").set_physics_process(false)
 battle.set_process(false)
 var sprite: AnimatedSprite2D = player.animated_character_sprite
 for facing in [1.0,-1.0]:
  player.facing_direction = facing
  player._set_visual_facing()
  var attack_keys := [] if "--down-only" in OS.get_cmdline_user_args() else ["forward_punch","back_punch","down_punch","forward_kick","back_kick","down_kick"]
  for key in attack_keys:
   player.start_attack("akky_"+key)
   player.enter_attack_active()
   player.command_attack_elapsed = player.current_attack_data.startup_time
   player._update_pose_collision()
   player._sync_attack_visual_phase()
   var area: Area2D = player.punch_area if key.ends_with("punch") else player.kick_area
   var shape: CollisionShape2D = player.punch_shape if key.ends_with("punch") else player.kick_shape
   var hit := mark_box(area,shape,Color(1,0.15,0.15,0.35))
   var hurt := mark_box(player.hurt_box,player.hurt_shape,Color(0.1,0.8,1,0.20))
   await snap("%s_%s_contact"%[key,"right" if facing>0 else "left"])
   hit.queue_free()
   hurt.queue_free()
   player.reset_attack_state()
   for frame in range(sprite.sprite_frames.get_frame_count("akky_"+key)):
    player._play_visual_animation(StringName("akky_"+key),true)
    sprite.pause()
    sprite.set_frame_and_progress(frame,0.0)
    await snap("%s_%s_frame_%02d"%[key,"right" if facing>0 else "left",frame])
 for facing in [1.0,-1.0]:
  player.facing_direction = facing
  player._set_visual_facing()
  for clip in [&"idle_ready",&"knockdown_high",&"knockdown_low",&"down",&"stand_up",&"ko",&"special_knockdown"]:
   player._play_visual_animation(clip,true)
   sprite.pause()
   for frame in range(sprite.sprite_frames.get_frame_count(clip)):
    sprite.set_frame_and_progress(frame,0.0)
    await snap("down_scale_%s_%s_%02d"%[clip,"right" if facing>0 else "left",frame])
 root.get_node("AudioManager").stop_bgm()
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await create_timer(1.0).timeout
 print("DIRECTIONAL_VISUAL_EXPORT_OK ",output)
 quit()
