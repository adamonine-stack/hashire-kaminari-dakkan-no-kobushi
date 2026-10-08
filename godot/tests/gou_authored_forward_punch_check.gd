extends "res://tests/directional_attacks_check.gd"
func run() -> void:
 var hero := "gou"
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
  enemy.global_position=Vector2(600+95*facing,520)
  player.facing_direction=facing
  player.move_and_slide()
  enemy.move_and_slide()
  var hp:float=enemy.current_hp
  check(player._request_directional_move(hero+"_forward_punch"),"stepping punch starts")
  var saw_authored:=false
  for i in range(40):
   await ticks(1)
   var sprite: AnimatedSprite2D=player.animated_character_sprite
   if sprite.animation==&"gou_forward_punch":
    saw_authored=true
    var tex:Texture2D=sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
    check(tex is AtlasTexture and "forward_punch_v5" in tex.atlas.resource_path,"dedicated source during stepping punch")
    if sprite.frame==2 and DisplayServer.get_name()!="headless":
     RenderingServer.force_draw(false)
     var folder:=ProjectSettings.globalize_path("res://../audit_evidence/gou_forward_punch_live")
     DirAccess.make_dir_recursive_absolute(folder)
     root.get_texture().get_image().save_png(folder.path_join("contact_%s.png"%facing))
  check((player.global_position.x-600)*facing > 10,"confirmed punch steps towards opponent")
  check(saw_authored,"dedicated stepping punch animation used")
  check(enemy.current_hp<hp,"stepping punch reaches ground target facing=%s"%facing)
  reset_pair()
  player.global_position=Vector2(600,520)
  enemy.global_position=Vector2(600+95*facing,520)
  player.facing_direction=facing
  player.move_and_slide()
  enemy.move_and_slide()
  check(player._request_directional_move(hero+"_forward_punch"),"confirmed cancel setup starts")
  var cancelled:=false
  for i in range(60):
   await ticks(1)
   if player.dev_current_attack_connected and player.command_attack_elapsed>=0.36 and player.command_attack_elapsed<=0.48:
    cancelled=player._request_directional_move(hero+"_forward_kick")
    break
  check(cancelled,"confirmed stepping punch permits configured forward kick cancel")
  reset_pair()
  player.global_position=Vector2(600,520)
  enemy.global_position=Vector2(1100,520)
  player.facing_direction=facing
  player.move_and_slide()
  enemy.move_and_slide()
  check(player._request_directional_move(hero+"_forward_punch"),"stepping punch starts")
  await ticks(24)
  check((player.global_position.x-600)*facing > 10,"stepping punch moves towards facing")
  check(not player.dev_current_attack_connected,"whiff remains unconfirmed")
  check(not player._request_directional_move(hero+"_forward_kick"),"whiff cancel rejected inside cancel window")
 print("GOU_AUTHORED_FORWARD_PUNCH_CHECK %s failures=%s"%[hero,failures])
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await process_frame
 quit(0 if failures.is_empty() else 1)
