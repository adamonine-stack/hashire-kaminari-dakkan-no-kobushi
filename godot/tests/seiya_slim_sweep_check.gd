extends "res://tests/directional_attacks_check.gd"
func run() -> void:
 var battle: Node=load("res://scenes/Battle.tscn").instantiate()
 root.add_child(battle)
 current_scene=battle
 await process_frame
 var manager: Node=battle.get_node("BattleManager")
 manager.select_player_by_id("player_03_seiya")
 for i in range(500):
  await physics_frame
  if manager._enemy_intro_panel!=null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
  if manager.isRoundActive: break
 player=battle.get_node("Player")
 enemy=battle.get_node("Enemy")
 enemy.ai_enabled=false
 enemy.ai_guard_enabled=false
 enemy.ai_profile=null
 await ticks(3)
 var sprite: AnimatedSprite2D=player.animated_character_sprite
 var scale_before:=sprite.scale
 player.set_physics_process(false)
 enemy.set_physics_process(false)
 for frame in range(6):
  player._play_visual_animation(&"crouch_kick",true)
  sprite.pause()
  sprite.frame=frame
  var texture:=sprite.sprite_frames.get_frame_texture(&"crouch_kick",frame)
  check(float(texture.get_meta("head_scale_override",-1))==1.0,"authored head metadata")
  check(float(sprite.material.get_shader_parameter("head_scale"))==1.0,"no second head reduction")
  check(sprite.scale.is_equal_approx(scale_before),"fixed actor scale")
  check(texture.get_image().get_used_rect().end.y<=270,"ground anchor")
 player._play_visual_animation(&"idle",true)
 check(is_equal_approx(float(sprite.material.get_shader_parameter("head_scale")),0.9),"legacy head correction restored")
 for facing in [1.0,-1.0]:
  for elevated in [false,true]:
   reset_pair()
   player.global_position=Vector2(600,520)
   enemy.global_position=Vector2(600+68*facing,320 if elevated else 520)
   player.facing_direction=facing
   enemy.facing_direction=-facing
   player.velocity=Vector2.ZERO
   enemy.velocity=Vector2.ZERO
   player.move_and_slide()
   enemy.move_and_slide()
   var hp:float=enemy.current_hp
   player.set_physics_process(true)
   check(player._request_directional_move("seiya_down_kick"),"sweep starts")
   var saw_down:=false
   for tick in range(35):
    await physics_frame
    saw_down=saw_down or enemy.knockdown_state in [&"KNOCKBACK",&"KNOCKDOWN"]
   check(enemy.current_hp==hp if elevated else enemy.current_hp<hp,"low collision ground/air facing=%s air=%s"%[facing,elevated])
   if not elevated: check(saw_down,"sweep knockdown")
   player.set_physics_process(false)
 print("SEIYA_SLIM_SWEEP_CHECK failures=",failures)
 for audio in root.find_children("*","AudioStreamPlayer",true,false): audio.stop()
 for audio in root.find_children("*","AudioStreamPlayer2D",true,false): audio.stop()
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await process_frame
 quit(0 if failures.is_empty() else 1)
