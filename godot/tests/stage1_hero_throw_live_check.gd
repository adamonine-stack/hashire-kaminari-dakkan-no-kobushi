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
    var stages:Dictionary={}
    var hero_scale:Vector2=player.animated_character_sprite.scale
    for tick in range(210):
     await physics_frame
     Input.action_release("throw_attack")
     held=held or victim.is_throw_locked
     check(player.animated_character_sprite.scale.is_equal_approx(hero_scale),"fixed hero scale throughout throw")
     for actor in [player]:
      if actor==player and actor.animated_character_sprite.animation in [&"throw_hold",&"throw_start",&"directional_throw_held",&"crusher_throw_held",&"down",&"stand_up"] or actor==player and (String(actor.animated_character_sprite.animation).begins_with(hero+"_throw_") or String(actor.animated_character_sprite.animation).begins_with("crusher_throw_") or String(actor.animated_character_sprite.animation).begins_with("throw_victim_")):
       var tex:AtlasTexture=actor.animated_character_sprite.sprite_frames.get_frame_texture(actor.animated_character_sprite.animation,actor.animated_character_sprite.frame)
       check(("throw_v11" if hero=="gou" else "slim_throw_v13") in tex.atlas.resource_path,"dedicated hero throw source")
     if reverse and victim.is_throw_locked and attacker.directional_throw_prepared:
      check(victim.animated_character_sprite.animation==&"crusher_throw_held","dedicated Crusher hold victim")
     recovered=recovered or attacker.throw_state=="THROW_RECOVERY"
     if victim.current_hp!=hp:
      changes+=1
      if reverse: check(victim.last_special_knockback_animation==StringName("crusher_throw_"+direction+"_air"),"dedicated Crusher flight victim")
      hp=victim.current_hp
     var stage:String=attacker.throw_state if attacker.throw_state!="" else String(victim.knockdown_state)
     if stage!="": stages[stage]=true
     if DisplayServer.get_name()!="headless" and stage in ["THROW_HOLD","THROW_RECOVERY","KNOCKDOWN","GET_UP"] and (stage!="THROW_HOLD" or attacker.directional_throw_prepared) and not captured.has(stage):
      captured[stage]=true
      attacker.set_physics_process(false)
      victim.set_physics_process(false)
      attacker.animated_character_sprite.pause()
      victim.animated_character_sprite.pause()
      await process_frame
      RenderingServer.force_draw(false)
      var folder:=ProjectSettings.globalize_path("res://../audit_evidence/stage1_heroes_throw_live")
      DirAccess.make_dir_recursive_absolute(folder)
      root.get_texture().get_image().save_png(folder.path_join("%s_%s_%s_%s_%s.png"%[hero,reverse,facing,direction,stage]))
      attacker.set_physics_process(true)
      victim.set_physics_process(true)
      attacker.animated_character_sprite.play()
      victim.animated_character_sprite.play()
    mobile.release_all_touch_inputs()
    check(held and recovered,"live hold/release %s/%s/%s/%s"%[hero,reverse,facing,direction])
    check(changes==1,"one damage event in live release")
    check(not victim.is_throw_locked and not attacker._is_throw_busy(),"release unlocks both actors")
    check(stages.has("KNOCKDOWN") and stages.has("GET_UP"),"live down and wakeup")
    check(victim.knockdown_state==&"" and victim.hurt_box.monitorable and not victim.is_hit,"victim restores control after down")
 # Real physics whiff: empty range must hold recovery and regain control.
 for facing in [1.0,-1.0]:
  for direction in ["neutral","forward","down","back"]:
   reset_pair(facing)
   enemy.global_position.x=600+450*facing
   check(player._request_directional_move(hero+"_"+direction+"_throw"),"whiff request")
   var seen_whiff:=false
   for tick in range(90):
    await physics_frame
    if player.throw_state=="THROW_WHIFF":
     seen_whiff=true
     check(player.animated_character_sprite.animation==StringName(hero+"_throw_whiff"),"dedicated whiff pose")
     check(not player._can_start_throw(),"cannot rethrow during whiff recovery")
   check(seen_whiff and not player._is_throw_busy(),"whiff recovers")
 print("STAGE1_HERO_THROW_LIVE_CHECK %s failures=%s"%[hero,failures])
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await process_frame
 quit(0 if failures.is_empty() else 1)
