extends SceneTree
var review_actors: Array[Node] = []
var output := "res://../special_guard_evidence"
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
 current_scene = battle
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
 if String(player.fighter_definition.fighter_id) != "player_01_akky":
  var swapped: Node=player
  player=enemy
  enemy=swapped
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
  for actor in [player,enemy]:
   actor._cancel_current_action()
   actor.reset_knockdown_state()
   actor.current_hp=actor.max_hp
   actor.is_round_active=true
   actor.global_position.y=520
   actor.velocity=Vector2(0,40)
   actor.move_and_slide()
   actor.facing_direction=facing
   actor.input_enabled=false
   actor.is_guarding=true
   actor.guard_type="high"
  await snap("normal_guard_%s"%facing)
  for actor in [player,enemy]:
   var packet: Dictionary=(enemy if actor==player else player)._get_character_special_attack_dictionary()
   actor._select_special_guard_reaction(packet)
   actor._enter_guard_hit_state()
   actor.special_guard_duration=packet.guard_hit_time
  for phase in range(3):
   for actor in [player,enemy]:
    actor.guard_hit_timer=actor.special_guard_duration*(1.0-(phase+.10)/3.0)
   await snap("special_guard_%s_%s"%[facing,phase])
  for actor in [player,enemy]:
   actor.global_position.y=360
   actor.velocity=Vector2.ZERO
   actor.move_and_slide()
  await snap("special_guard_air_%s"%facing)
  for actor in [player,enemy]:
   actor._cancel_current_action()
   actor.is_guard_hit=false
   actor._clear_guard_state()
   actor.global_position.y=520
   actor.velocity=Vector2(0,40)
   actor.move_and_slide()
  await snap("standing_%s"%facing)
 print("SPECIAL_GUARD_VISUAL_EXPORT_OK")
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 quit()
