extends "res://tests/directional_attacks_check.gd"
func run() -> void:
 var hero := "gou" if "--gou" in OS.get_cmdline_user_args() else "seiya"
 var battle: Node=load("res://scenes/Battle.tscn").instantiate()
 root.add_child(battle)
 current_scene=battle
 await process_frame
 var manager: Node=battle.get_node("BattleManager")
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
 await ticks(3)
 enemy.set_physics_process(false)
 for facing in [1.0,-1.0]:
  reset_pair()
  player.global_position=Vector2(600,520)
  enemy.global_position=Vector2(600+62*facing,520)
  player.facing_direction=facing
  player.move_and_slide()
  enemy.move_and_slide()
  var hp:float=enemy.current_hp
  check(player._request_directional_move(hero+"_down_punch"),"anti-air starts")
  var saw_authored:=false
  for i in range(40):
   await ticks(1)
   var sprite: AnimatedSprite2D=player.animated_character_sprite
   if sprite.animation==&"seiya_down_punch":
    saw_authored=true
    check(float(sprite.material.get_shader_parameter("head_scale"))==1.0,"no duplicate head shrink")
    if sprite.frame==2 and DisplayServer.get_name()!="headless":
     RenderingServer.force_draw(false)
     var folder:=ProjectSettings.globalize_path("res://../audit_evidence/seiya_launcher_live")
     DirAccess.make_dir_recursive_absolute(folder)
     root.get_texture().get_image().save_png(folder.path_join("contact_%s.png"%facing))
  check(saw_authored,"dedicated anti-air animation used")
  check(enemy.current_hp<hp,"launcher reaches ground target facing=%s"%facing)
  reset_pair()
  player.global_position=Vector2(600,520)
  enemy.global_position=Vector2(1100,520)
  player.facing_direction=facing
  player.move_and_slide()
  enemy.move_and_slide()
  check(player._request_directional_move(hero+"_back_kick"),"retreat kick starts")
  await ticks(18)
  check((player.global_position.x-600)*facing < -10,"retreat moves away from facing")
  check(not player.dev_current_attack_connected,"whiff remains unconfirmed")
  check(not player._request_directional_move(hero+"_forward_punch"),"whiff cancel rejected inside cancel window")
 print("SEIYA_AUTHORED_LAUNCHER_CHECK %s failures=%s"%[hero,failures])
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await process_frame
 quit(0 if failures.is_empty() else 1)
