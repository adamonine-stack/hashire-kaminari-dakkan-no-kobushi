extends SceneTree
var review_actors: Array[Node] = []
var output := "res://../crusher_situation_evidence"
func _initialize() -> void:
 call_deferred("run")
func snap(label: String) -> void:
 for actor in review_actors:
  actor._update_visual_state()
  actor.animated_character_sprite.pause()
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
 review_actors.assign([player,enemy])
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
  for id in ["neutral_punch","neutral_kick","forward_punch","forward_kick","back_kick","down_kick"]:
   for actor in [player,enemy]:
    actor.reset_knockdown_state()
    actor._cancel_current_action()
    actor.reset_attack_state()
    actor.reset_combo()
    actor.is_hit = false
    actor.is_invincible = false
   enemy.global_position = Vector2(640,520)
   player.global_position = Vector2(640+270*facing,520)
   enemy.facing_direction = facing
   player.facing_direction = -facing
   enemy._set_visual_facing()
   player._set_visual_facing()
   enemy.start_attack("crusher_"+id)
   enemy.command_attack_elapsed = enemy.attack_startup_time_actual+.02
   enemy.enter_attack_active()
   await snap("crusher_%s_%s"%[id,facing])
   enemy.reset_attack_state()
 print("CRUSHER_SITUATION_VISUAL_EXPORT_OK")
 root.get_node("AudioManager").stop_bgm()
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await create_timer(1).timeout
 quit()
