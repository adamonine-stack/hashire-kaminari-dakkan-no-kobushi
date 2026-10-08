extends SceneTree
var failures: Array[String] = []
var player: Node
var enemy: Node
var hit_moves: Array[String] = []
var hero := "gou"
var reaction_seen: Dictionary = {}
func _initialize() -> void:
 if "--seiya" in OS.get_cmdline_user_args(): hero="seiya"
 call_deferred("run")
func check(ok: bool, label: String) -> void:
 if not ok:
  failures.append(label)
  push_error(label)
func reset_pair() -> void:
 for actor in [player, enemy]:
  actor.reset_knockdown_state()
  actor._cancel_current_action()
  actor.reset_combo()
  actor.reset_attack_state()
  actor.is_hit = false
  actor.is_guard_hit = false
  actor.is_invincible = false
  actor.hit_stop_timer = 0.0
  actor.guard_recoil_timer = 0.0
  actor.current_hp = actor.max_hp
  actor.is_round_active = true
  actor._clear_guard_state()
  actor.velocity = Vector2.ZERO
 player.combat_commands.clear()
func ticks(count: int) -> void:
 for i in range(count):
  await physics_frame
func run() -> void:
 var battle: Node = load("res://scenes/Battle.tscn").instantiate()
 battle.get_node("BattleManager").active_enemy_count_limit = 1
 root.add_child(battle)
 current_scene = battle
 await process_frame
 var manager: Node = battle.get_node("BattleManager")
 if "--gou" in OS.get_cmdline_user_args(): hero = "gou"
 manager.select_player_by_id("player_02_gou" if hero == "gou" else "player_03_seiya")
 for i in range(360):
  await physics_frame
  if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
  if manager.isRoundActive: break
 player = battle.get_node("Player")
 enemy = battle.get_node("Enemy")
 enemy.ai_enabled = false
 enemy.ai_throw_probability = 0.0
 enemy.throw_escape_probability = 0.0
 enemy.ai_guard_enabled = false
 enemy.ai_profile = null
 await ticks(3)
 player.set_physics_process(false)
 enemy.set_physics_process(false)
 for facing in [1.0,-1.0]:
  reset_pair()
  player.global_position = Vector2(600,520)
  enemy.global_position = Vector2(600+62*facing,520)
  player.facing_direction = facing
  enemy.facing_direction = -facing
  player.velocity = Vector2.ZERO
  player.move_and_slide()
  check(player._combo_hit_limit() == int(player.fighter_definition.max_attack_chain_count),"normal chain limit preserved")
  check(player._request_directional_move((hero+"_down_punch")),"launcher starts")
  check(player._combo_hit_limit() == (3 if hero == "gou" else int(player.fighter_definition.max_attack_chain_count)),"bounded launcher route")
  player.command_attack_elapsed = .30
  check(not player._request_jump_cancel(),"launcher whiff cannot jump cancel")
  player.dev_current_attack_connected = true
  player.command_attack_elapsed = .20
  check(not player._request_jump_cancel(),"early jump cancel rejected")
  player.combat_commands.record("jump",true,facing)
  player.combat_commands.advance(.10)
  player.command_attack_elapsed = .30
  player._dispatch_combat_command()
  check(player.jump_combo_pending,"buffered jump enters hit-confirm window")
  check(player.velocity.y < 0 and player.current_attack_type == "","jump removes old hitbox and starts ascent")
  player.global_position.y = 420
  player.move_and_slide()
  player.combat_commands.record("right" if facing>0 else "left",true,facing)
  player.combat_commands.record("punch",true,facing)
  player._dispatch_combat_command()
  check(player.current_attack_id == (hero+"_air_punch"),"air P while holding direction")
  player.command_attack_elapsed = .16
  check(not player._request_directional_move((hero+"_air_kick")),"air P whiff cannot cancel")
  player.dev_current_attack_connected = true
  check(player._request_directional_move((hero+"_air_kick")),"hit air P permits air K")
  check(player.is_air_attack_active,"cancel keeps air classification")
  check(not player._request_directional_move((hero+"_air_punch")),"air K cannot loop to air P")
  player._finish_air_attack_on_landing()
  check(player.current_attack_type == "" and not player.punch_hitbox_active and not player.kick_hitbox_active,"landing clears attack")
 player.attack_hit.connect(func(id, _target): hit_moves.append(String(id)))
 var mobile: Node = battle.find_child("MobileControls",true,false)
 mobile.visible = true
 # Actual mobile handlers + collision + physics flow. No injected connected flags.
 for facing in [1.0,-1.0]:
  reset_pair()
  player.global_position = Vector2(600,520)
  enemy.global_position = Vector2(600+62*facing,520)
  player.facing_direction = facing
  enemy.facing_direction = -facing
  player.set_physics_process(true)
  enemy.set_physics_process(true)
  await ticks(3)
  mobile._on_direction_button_down(mobile.left_controls.get_node("CrouchButton"),mobile.DIRECTION_BUTTONS["CrouchButton"])
  await ticks(7)
  mobile._on_tap_button_down(mobile.right_controls.get_node("PunchButton"),"attack")
  await ticks(1)
  Input.action_release("attack")
  mobile._on_direction_button_up(mobile.left_controls.get_node("CrouchButton"),mobile.DIRECTION_BUTTONS["CrouchButton"])
  hit_moves.clear()
  var launcher_hit := false
  var saw_authored := false
  var captured := false
  var air_p_started := false
  var air_p_hit := false
  var air_k_started := false
  var air_k_hit := false
  var pressed_jump := false
  var pressed_p := false
  var pressed_k := false
  for i in range(110):
   await physics_frame
   var victim:AnimatedSprite2D=enemy.animated_character_sprite
   if victim.animation in [&"launch_hit",&"air_hit",&"knockback"]:
    reaction_seen[victim.animation]=true
    var victim_tex:Texture2D=victim.sprite_frames.get_frame_texture(victim.animation,victim.frame)
    check(victim_tex is AtlasTexture and "unified_air_received_v9" in victim_tex.atlas.resource_path,"new live air reaction source")
   if player.current_attack_id == (hero+"_down_punch") and player.dev_current_attack_connected:
    launcher_hit = true
    if not pressed_jump and player.command_attack_elapsed >= .27:
     mobile._on_direction_button_down(mobile.left_controls.get_node("UpButton"),mobile.DIRECTION_BUTTONS["UpButton"])
     pressed_jump = true
   if not player.is_on_floor() and player.current_attack_type == "" and not pressed_p:
    Input.action_release("jump")
    mobile._on_tap_button_down(mobile.right_controls.get_node("PunchButton"),"attack")
    pressed_p = true
   if player.current_attack_id == (hero+"_air_punch"):
    air_p_started = true
    Input.action_release("attack")
    if player.dev_current_attack_connected:
     air_p_hit = true
     if not pressed_k:
      mobile._on_tap_button_down(mobile.right_controls.get_node("KickButton"),"kick")
      pressed_k = true
   if player.current_attack_id == (hero+"_air_kick"):
    air_k_started = true
    var sprite:AnimatedSprite2D=player.animated_character_sprite
    if sprite.animation==StringName(hero+"_air_kick"):
     saw_authored=true
     var tex:Texture2D=sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
     check(tex is AtlasTexture and ("air_kick_v8" if hero=="gou" else "slim_air_kick_v10") in tex.atlas.resource_path,"dedicated air K source")
     if sprite.frame==2 and not captured and DisplayServer.get_name()!="headless":
      RenderingServer.force_draw(false)
      var folder:=ProjectSettings.globalize_path("res://../audit_evidence/crusher_air_received_live_"+hero+"")
      DirAccess.make_dir_recursive_absolute(folder)
      root.get_texture().get_image().save_png(folder.path_join("contact_%s.png"%facing))
      captured=true
    Input.action_release("kick")
    air_k_hit = hit_moves.has((hero+"_air_kick"))
  check(saw_authored,"dedicated air K displayed both facings")
  mobile.release_all_touch_inputs()
  for action in ["down","attack","jump","kick"]: Input.action_release(action)
  print("AIR_ROUTE facing=%s launcher=%s P=%s/%s K=%s/%s hp=%s"%[facing,launcher_hit,air_p_started,air_p_hit,air_k_started,air_k_hit,enemy.current_hp])
  check(launcher_hit and air_p_started and air_p_hit and air_k_started and air_k_hit,"live 3-hit launcher route %s"%facing)
  check(player.is_on_floor() and player.current_attack_type == "","live landing restores control")
  player.set_physics_process(false)
  enemy.set_physics_process(false)
 check(reaction_seen.has(&"launch_hit") and (hero!="gou" or reaction_seen.has(&"knockback")),"launcher and finishing knockback seen")
 print("CRUSHER_AIR_RECEIVED_CHECK %s reactions=%s failures=%s"%[hero,reaction_seen,failures])
 root.get_node("AudioManager").stop_bgm()
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await create_timer(1).timeout
 quit(0 if failures.is_empty() else 1)
