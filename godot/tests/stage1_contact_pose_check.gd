extends "res://tests/stage1_hero_throws_check.gd"
func run() -> void:
 var battle: Node = load("res://scenes/Battle.tscn").instantiate()
 root.add_child(battle)
 current_scene = battle
 await process_frame
 var manager: Node = battle.get_node("BattleManager")
 manager.select_player_by_id("player_01_akky")
 for tick in range(400):
  await physics_frame
  if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
  if manager.isRoundActive: break
 player = battle.get_node("Player")
 enemy = battle.get_node("Enemy")
 enemy.ai_enabled = false
 enemy.ai_profile = null
 enemy.set_physics_process(false)
 player.set_physics_process(false)
 for entry in [["ally_power","player2"],["ally_speed","player3"]]:
  player.apply_character_data(load("res://data/fighters/"+entry[0]+".tres"))
  for facing in [1.0,-1.0]:
   for suffix in ["punch_1","punch_2","kick_finish"] + (["punch_3"] if entry[1]=="player3" else []):
    reset_pair(facing)
    var id: String = entry[1]+"_"+suffix
    player.start_attack(id)
    player.enter_attack_active()
    player._sync_attack_visual_phase()
    check(player.current_attack_data.contact_start_frame==3 and player.animated_character_sprite.frame==3,id+" data and runtime contact agree")
    # An authored field must also override the legacy fighter table.
    var original: Resource = player.current_attack_data
    player.current_attack_data = original.duplicate()
    player.current_attack_data.contact_start_frame = 2
    player.current_attack_data.contact_end_frame = 2
    player._sync_attack_visual_phase()
    check(player.animated_character_sprite.frame==2,id+" authored data overrides legacy default")
    player.current_attack_data = original
    player.finish_attack()
 player.apply_character_data(load("res://data/fighters/ally_balance.tres"))
 var folder := ProjectSettings.globalize_path("res://../audit_evidence/stage1_attack_contact_live")
 DirAccess.make_dir_recursive_absolute(folder)
 for facing in [1.0,-1.0]:
  reset_pair(facing)
  enemy.global_position.x = 600+75*facing
  player.set_physics_process(true)
  await physics_frame
  var hp: int = enemy.current_hp
  check(player._request_directional_move("akky_down_punch"),"launcher request")
  var active := false
  for tick in range(75):
   await physics_frame
   if player.current_attack_id=="akky_down_punch" and player.attack_phase==player.AttackPhase.ACTIVE:
    check(player.animated_character_sprite.frame==2,"launcher contact holds upward pose")
    var texture: AtlasTexture = player.animated_character_sprite.sprite_frames.get_frame_texture(&"akky_down_punch",2)
    check("launcher_contact_v2" in texture.atlas.resource_path,"launcher reviewed source")
    if not active and DisplayServer.get_name()!="headless":
     player.set_physics_process(false)
     player.animated_character_sprite.pause()
     await process_frame
     RenderingServer.force_draw(false)
     check(root.get_texture().get_image().save_png(folder.path_join("launcher_"+("right" if facing>0 else "left")+".png"))==OK,"native launcher capture")
     player.set_physics_process(true)
     player.animated_character_sprite.play()
    active = true
  check(active and enemy.current_hp<hp,"upward contact overlaps grounded enemy")
  check(enemy.velocity.y<0,"launcher applies upward physical force")
  player.set_physics_process(false)
 print("STAGE1_CONTACT_POSE_CHECK failures=%s"%[failures])
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await process_frame
 quit(0 if failures.is_empty() else 1)
