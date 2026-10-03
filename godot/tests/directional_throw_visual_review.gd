extends SceneTree
var output := "res://../throw_evidence"
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
 for facing in [1.0,-1.0]:
  for direction in ["neutral","forward","down","back"]:
   for actor in [player,enemy]:
    actor._finish_throw()
    actor.reset_knockdown_state()
    actor._cancel_current_action()
    actor.reset_attack_state()
    actor.is_hit = false
    actor.is_invincible = false
    actor.throw_regrab_lock_timer = 0.0
    actor.current_hp = actor.max_hp
    actor.is_round_active = true
    actor.velocity = Vector2.ZERO
   player.global_position = Vector2(600,520)
   enemy.global_position = Vector2(600+80*facing,520)
   player.facing_direction = facing
   enemy.facing_direction = -facing
   player._set_visual_facing()
   enemy._set_visual_facing()
   player._request_directional_move("akky_%s_throw"%direction)
   await snap("throw_%s_%s_start"%[direction,int(facing)])
   player._update_active_throw(player.directional_throw_data.startup_time+.001)
   await snap("throw_%s_%s_hold"%[direction,int(facing)])
   player._update_active_throw(player.directional_throw_data.throw_hold_seconds+.001)
   player._update_visual_state()
   enemy._update_visual_state()
   await snap("throw_%s_%s_release"%[direction,int(facing)])
 print("DIRECTIONAL_THROW_VISUAL_EXPORT_OK")
 root.get_node("AudioManager").stop_bgm()
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await create_timer(1.0).timeout
 quit()
