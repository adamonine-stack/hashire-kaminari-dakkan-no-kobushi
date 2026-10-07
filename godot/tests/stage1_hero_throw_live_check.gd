extends "res://tests/stage1_hero_throws_check.gd"
func run() -> void:
 var battle: Node=load("res://scenes/Battle.tscn").instantiate()
 root.add_child(battle)
 current_scene=battle
 await process_frame
 var manager: Node=battle.get_node("BattleManager")
 if "--gou" in OS.get_cmdline_user_args(): hero="gou"
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
 enemy.ai_throw_probability=0
 enemy.throw_escape_probability=0
 player.throw_escape_probability=0
 for i in range(3): await physics_frame
 var mobile: Node=battle.find_child("MobileControls",true,false)
 mobile.visible=true
 for reverse in [false,true]:
  for facing in [1.0,-1.0]:
   for direction in ["neutral","forward","down","back"]:
    reset_pair(facing)
    player.move_and_slide()
    enemy.move_and_slide()
    var attacker: Node=enemy if reverse else player
    var victim: Node=player if reverse else enemy
    var prefix: String="crusher" if reverse else hero
    if reverse:
     check(attacker._request_directional_move(prefix+"_"+direction+"_throw",true),"Crusher reverse throw starts")
    else:
     if direction!="neutral":
      var button_name: String="CrouchButton" if direction=="down" else ("MoveRightButton" if (direction=="forward")== (facing>0) else "MoveLeftButton")
      mobile._on_direction_button_down(mobile.left_controls.get_node(button_name),mobile.DIRECTION_BUTTONS[button_name])
      for i in range(7): await physics_frame
      mobile._on_direction_button_up(mobile.left_controls.get_node(button_name),mobile.DIRECTION_BUTTONS[button_name])
     mobile._on_tap_button_down(mobile.right_controls.get_node("ThrowButton"),"throw_attack")
    var hp: int=victim.current_hp
    var changes:=0
    var held:=false
    var recovered:=false
    var captured: Dictionary={}
    for tick in range(90):
     await physics_frame
     Input.action_release("throw_attack")
     held=held or victim.is_throw_locked
     if reverse and victim.is_throw_locked and attacker.directional_throw_prepared:
      check(victim.animated_character_sprite.animation==&"grabbed","missing dedicated hold uses grabbed")
     recovered=recovered or attacker.throw_state=="THROW_RECOVERY"
     if victim.current_hp!=hp:
      changes+=1
      if reverse: check(victim.last_special_knockback_animation==&"thrown","missing dedicated flight uses thrown")
      hp=victim.current_hp
     if DisplayServer.get_name()!="headless" and attacker.throw_state in ["THROW_HOLD","THROW_RECOVERY"] and not captured.has(attacker.throw_state):
      captured[attacker.throw_state]=true
      RenderingServer.force_draw(false)
      var folder:=ProjectSettings.globalize_path("res://../audit_evidence/stage1_throw_live")
      DirAccess.make_dir_recursive_absolute(folder)
      root.get_texture().get_image().save_png(folder.path_join("%s_%s_%s_%s_%s.png"%[hero,reverse,facing,direction,attacker.throw_state]))
    mobile.release_all_touch_inputs()
    check(held and recovered,"live hold/release %s/%s/%s/%s"%[hero,reverse,facing,direction])
    check(changes==1,"one damage event in live release")
    check(not victim.is_throw_locked and not attacker._is_throw_busy(),"release unlocks both actors")
 print("STAGE1_HERO_THROW_LIVE_CHECK %s failures=%s"%[hero,failures])
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await process_frame
 quit(0 if failures.is_empty() else 1)
