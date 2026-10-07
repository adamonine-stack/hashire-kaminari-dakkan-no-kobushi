extends "res://tests/directional_attacks_check.gd"

func run() -> void:
 var battle: Node = load("res://scenes/Battle.tscn").instantiate()
 battle.get_node("BattleManager").active_enemy_count_limit = 1
 root.add_child(battle)
 current_scene = battle
 await process_frame
 var manager: Node = battle.get_node("BattleManager")
 for hero in ["gou", "seiya"]:
  var number := 2 if hero == "gou" else 3
  manager.select_player_by_id("player_02_gou" if number == 2 else "player_03_seiya")
  for i in range(500):
   await physics_frame
   if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible:
    manager.enemy_intro_finished.emit()
   if manager.isRoundActive: break
  player = battle.get_node("Player")
  enemy = battle.get_node("Enemy")
  enemy.ai_enabled = false
  enemy.ai_profile = null
  await ticks(3)
  player.set_physics_process(false)
  enemy.set_physics_process(false)
  var sprite: AnimatedSprite2D = player.animated_character_sprite
  var baseline := sprite.scale
  for facing in [1.0, -1.0]:
   for suffix in ["forward_punch", "forward_kick", "down_kick"]:
    reset_pair()
    player.facing_direction = facing
    var direction := "down" if suffix == "down_kick" else ("right" if facing > 0 else "left")
    player.combat_commands.record(direction, true, facing)
    player.combat_commands.record(direction, false, facing)
    player.combat_commands.advance(0.12)
    player.combat_commands.record("punch" if suffix.ends_with("punch") else "kick", true, facing)
    player._dispatch_combat_command()
    check(player.current_attack_id == hero+"_"+suffix, hero+" delayed direction "+suffix)
    check(not player.punch_hitbox_active and not player.kick_hitbox_active, "startup inactive")
    player.enter_attack_active()
    player._sync_attack_visual_phase()
    check(sprite.sprite_frames.has_animation(StringName(player.current_attack_data.animation_name)), "existing authored clip")
    check(sprite.scale.is_equal_approx(baseline), "fixed character scale")
    if DisplayServer.get_name() != "headless":
     sprite.pause()
     await process_frame
     await RenderingServer.frame_post_draw
     var output := ProjectSettings.globalize_path("res://../audit_evidence/stage1_heroes")
     DirAccess.make_dir_recursive_absolute(output)
     root.get_texture().get_image().save_png(output.path_join("%s_%s_%s.png" % [hero,suffix,facing]))
    var area: Area2D = player.punch_area if suffix.ends_with("punch") else player.kick_area
    check(signf(area.position.x) == facing, "mirrored collision")
    player.enter_attack_recovery()
    check(not player.punch_hitbox_active and not player.kick_hitbox_active, "recovery inactive")
   reset_pair()
   player.global_position = Vector2(600, 420)
   player.facing_direction = facing
   player.velocity = Vector2.ZERO
   player.move_and_slide()
   player.combat_commands.record("punch",true,facing)
   player._dispatch_combat_command()
   check(player.current_attack_id == hero+"_air_punch", "air P routing")
   player.command_attack_elapsed = .17
   check(not player._request_directional_move(hero+"_air_kick"), "whiff cancel forbidden")
   player.dev_current_attack_connected = true
   check(player._request_directional_move(hero+"_air_kick"), "air P hit-confirm to K")
   check(not player._request_directional_move(hero+"_air_punch"), "no air loop")
   player._finish_air_attack_on_landing()
   player.global_position = Vector2(600,520)
   player.move_and_slide()
  player.set_physics_process(true)
  enemy.set_physics_process(true)
 print("STAGE1_REMAINING_HEROES_CHECK failures=",failures)
 battle.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)

