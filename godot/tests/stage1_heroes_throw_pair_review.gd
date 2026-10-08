extends "res://tests/stage1_hero_throws_check.gd"
func run():
 var folder:=ProjectSettings.globalize_path("res://../audit_evidence/stage1_heroes_throw_pair_review")
 DirAccess.make_dir_recursive_absolute(folder)
 var rows:Array[Dictionary]=[]
 for id in ["gou","seiya"]:
  hero=id
  var battle:Node=load("res://scenes/Battle.tscn").instantiate()
  root.add_child(battle)
  current_scene=battle
  await process_frame
  var manager:Node=battle.get_node("BattleManager")
  manager.select_player_by_id("player_02_gou" if hero=="gou" else "player_03_seiya")
  for i in range(500):
   await physics_frame
   if manager._enemy_intro_panel!=null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
   if manager.isRoundActive:break
  player=battle.get_node("Player")
  enemy=battle.get_node("Enemy")
  for actor in [player,enemy]:
   actor.ai_enabled=false
   actor.ai_profile=null
   actor.ai_guard_enabled=false
   actor.throw_escape_probability=0
   actor.set_physics_process(false)
  for reverse in [false,true]:
   for facing in [1.0,-1.0]:
    for direction in ["neutral","forward","down","back"]:
     reset_pair(facing)
     player.move_and_slide()
     enemy.move_and_slide()
     var attacker:Node=enemy if reverse else player
     var victim:Node=player if reverse else enemy
     check(attacker._request_directional_move(("crusher" if reverse else hero)+"_"+direction+"_throw",reverse),"pair request")
     var data:Resource=attacker.directional_throw_data
     attacker._update_active_throw(data.startup_time+.001)
     attacker._update_active_throw(data.throw_hold_seconds-.04)
     attacker._update_active_throw(.01)
     check(victim.is_throw_locked and attacker.directional_throw_prepared,"pair hold synchronized")
     check(is_equal_approx(absf(attacker.global_position.x-victim.global_position.x),75),"contact hold offset")
     for stage in ["hold","release"]:
      if stage=="release":attacker._update_active_throw(.04)
      attacker._update_visual_state()
      victim._update_visual_state()
      attacker.animated_character_sprite.pause()
      victim.animated_character_sprite.pause()
      attacker.animated_character_sprite.frame=0
      victim.animated_character_sprite.frame=0
      await process_frame
      RenderingServer.force_draw(false)
      var file: String="%s_%s_%s_%s_%s.png"%[hero,reverse,facing,direction,stage]
      var img:=root.get_texture().get_image()
      img.save_png(folder.path_join(file))
      rows.append({"hero":hero,"reverse":reverse,"facing":facing,"direction":direction,"stage":stage,"attacker":String(attacker.animated_character_sprite.animation),"victim":String(victim.animated_character_sprite.animation),"attacker_position":str(attacker.global_position),"victim_position":str(victim.global_position),"file":file})
  manager.cleanup_battle_before_transition()
  battle.queue_free()
  await process_frame
 var output:=FileAccess.open(folder.path_join("inventory.json"),FileAccess.WRITE)
 output.store_string(JSON.stringify(rows,"  "))
 print("STAGE1_HEROES_THROW_PAIR_REVIEW poses=",rows.size()," failures=",failures)
 quit(0 if failures.is_empty() else 1)
