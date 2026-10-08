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
  enemy.global_position=Vector2(600+30*facing,360)
  player.facing_direction=facing
  player.move_and_slide()
  enemy.move_and_slide()
  var hp:float=enemy.current_hp
  check(player._request_directional_move(hero+"_back_punch"),"anti-air starts")
  await ticks(40)
  check(enemy.current_hp<hp,"upper hitbox reaches airborne target facing=%s"%facing)
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
 print("STAGE1_HERO_DEFENSE_CHECK %s failures=%s"%[hero,failures])
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await process_frame
 quit(0 if failures.is_empty() else 1)
