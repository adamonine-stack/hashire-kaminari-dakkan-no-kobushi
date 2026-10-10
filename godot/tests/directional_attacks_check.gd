extends SceneTree
var failures: Array[String] = []
var player: Node
var enemy: Node
func _initialize() -> void:
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
 await process_frame
 var manager: Node = battle.get_node("BattleManager")
 await manager.select_player_by_id("player_01_akky")
 for i in range(360):
  await physics_frame
  if manager.isRoundActive: break
 player = battle.get_node("Player")
 enemy = battle.get_node("Enemy")
 enemy.ai_enabled = false
 enemy.ai_profile = null
 await ticks(3)
 player.set_physics_process(false)
 enemy.set_physics_process(false)
 var sprite: AnimatedSprite2D = player.animated_character_sprite
 var scale_before := sprite.scale
 check(player._get_attack_data("player1_punch_1").startup_time < player._get_attack_data("akky_forward_punch").startup_time,"normal P faster than forward P")
 check(player._get_attack_data("player1_punch_1").startup_time < player._get_attack_data("player1_kick_finish").startup_time,"P faster than K")
 var cases := ["forward_punch", "back_punch", "down_punch", "forward_kick", "back_kick", "down_kick"]
 for facing in [1.0,-1.0]:
  for key in cases:
   reset_pair()
   player.facing_direction = facing
   var direction: String = key.split("_")[0]
   var physical := "down" if direction == "down" else ("right" if (direction == "forward") == (facing > 0.0) else "left")
   player.combat_commands.record(physical,true,facing)
   player.combat_commands.record(physical,false,facing)
   player.combat_commands.advance(0.12)
   player.combat_commands.record("punch" if key.ends_with("punch") else "kick",true,facing)
   player._dispatch_combat_command()
   check(player.current_attack_id == "basic_akky_"+key,"delayed direction routing %s/%s"%[key,facing])
   check(not player.punch_hitbox_active and not player.kick_hitbox_active,"startup inactive "+key)
   player.enter_attack_active()
   player._sync_attack_visual_phase()
   check(sprite.animation == StringName("basic_"+key),"authored animation "+key)
   check(sprite.frame == player.current_attack_data.contact_start_frame,"contact pose "+key)
   var area: Area2D = player.punch_area if key.ends_with("punch") else player.kick_area
   check(signf(area.position.x) == facing,"mirrored hitbox "+key)
   player.command_attack_elapsed = float(player.current_attack_data.startup_time)
   player._update_pose_collision()
   check(sprite.scale.is_equal_approx(scale_before),"fixed sprite scale "+key)
   player.enter_attack_recovery()
   check(not player.punch_hitbox_active and not player.kick_hitbox_active,"recovery inactive "+key)
   check(not player._request_directional_move("akky_forward_kick"),"whiff cannot cancel "+key)
 # Exercise the existing mobile-button handlers through InputMap sampling.
 var mobile: Node = battle.find_child("MobileControls",true,false)
 mobile.visible = true
 for facing in [1.0,-1.0]:
  for key in cases:
   for hold in [false,true]:
    # Each synthetic test must start with the mobile pulse coroutine reset.
    # Otherwise a previous tap's deferred release can delay this case.
    mobile.release_all_touch_inputs()
    reset_pair()
    player.facing_direction = facing
    var direction: String = key.split("_")[0]
    var button_name := "CrouchButton" if direction == "down" else ("MoveRightButton" if (direction == "forward") == (facing > 0) else "MoveLeftButton")
    var button: Button = mobile.left_controls.get_node(button_name)
    var data: Dictionary = mobile.DIRECTION_BUTTONS[button_name]
    mobile._on_direction_button_down(button,data)
    player._sample_combat_commands(0.0)
    if not hold:
     mobile._on_direction_button_up(button,data)
     player._sample_combat_commands(0.0)
    player._sample_combat_commands(0.12)
    var action := "attack" if key.ends_with("punch") else "kick"
    mobile._on_tap_button_down(mobile.right_controls.get_node("PunchButton" if action == "attack" else "KickButton"),action)
    player._sample_combat_commands(0.0)
    player._dispatch_combat_command()
    if hold:
     check(player.current_attack_id == "basic_akky_"+key,"held mobile handler %s/%s"%[key,facing])
    else:
     check(player.last_combat_command.get("direction","") == "neutral","released mobile handler neutral %s/%s"%[key,facing])
     check(player.current_attack_data != null and String(player.current_attack_data.command_direction).is_empty(),"released mobile handler normal %s/%s"%[key,facing])
    mobile._on_direction_button_up(button,data)
    await ticks(2)
    await process_frame
    await process_frame
    Input.action_release(action)
 mobile.release_all_touch_inputs()
 # Real common damage receiver: launcher, sweep, guard and counter startup.
 reset_pair()
 player.start_attack("akky_down_punch")
 var packet: Dictionary = player._build_combo_scaled_attack_data(player._get_punch_attack_data(),enemy)
 check(enemy.receive_attack(packet,1.0,enemy.global_position,player),"launcher connects")
 check(enemy.velocity.y <= -410.0 and enemy.knockdown_state == &"","launcher floats without down lock")
 check(not enemy.is_invincible,"launcher leaves followup vulnerable")
 # Repeating the launcher alone must not add damage or combo hits.
 var launcher_hp: int = enemy.current_hp
 var launcher_combo_hits: int = player.combo_count
 player.start_attack("akky_down_punch")
 packet = player._build_combo_scaled_attack_data(player._get_punch_attack_data(),enemy)
 check(not enemy.receive_attack(packet,1.0,enemy.global_position,player),"same launcher blocked during hitstun")
 check(enemy.current_hp == launcher_hp and player.combo_count == launcher_combo_hits,"no free launcher spam combo")
 # A different air attack is still a legitimate follow-up.
 player.start_attack("akky_air_punch")
 packet = player._build_combo_scaled_attack_data(player._get_punch_attack_data(),enemy)
 check(enemy.receive_attack(packet,1.0,enemy.global_position,player),"different air punch may follow launcher")
 check(enemy.current_hp < launcher_hp and player.combo_count > launcher_combo_hits,"alternate air followup deals damage and scores combo")
 # Full neutral grounded recovery permits the NEXT independent launcher.
 enemy.reset_knockdown_state()
 enemy.is_hit = false
 enemy.is_guard_hit = false
 enemy.is_invincible = false
 enemy.hit_reaction_timer = 0.0
 enemy.global_position = Vector2(620,520)
 enemy.velocity = Vector2.ZERO
 enemy.move_and_slide()
 check(enemy.is_on_floor(),"launcher recovery test grounded")
 player.start_attack("akky_down_punch")
 packet = player._build_combo_scaled_attack_data(player._get_punch_attack_data(),enemy)
 check(enemy.receive_attack(packet,1.0,enemy.global_position,player),"new launcher allowed after full recovery")
 reset_pair()
 player.start_attack("akky_down_kick")
 packet = player._build_combo_scaled_attack_data(player._get_kick_attack_data(),enemy)
 check(enemy.receive_attack(packet,1.0,enemy.global_position,player),"sweep connects")
 check(enemy.knockdown_state == &"KNOCKBACK","sweep knocks down")
 reset_pair()
 player.start_attack("akky_forward_kick")
 packet = player._build_combo_scaled_attack_data(player._get_kick_attack_data(),enemy)
 enemy.is_guarding = true
 enemy.guard_type = "high"
 var hp: int = enemy.current_hp
 check(not enemy.receive_attack(packet,1.0,enemy.global_position,player),"forward kick guarded")
 check(enemy.current_hp == hp and enemy.is_guard_hit,"guard no chip")
 reset_pair()
 player.start_attack("akky_back_punch")
 packet = player._build_combo_scaled_attack_data(player._get_punch_attack_data(),enemy)
 enemy.request_punch_attack()
 check(enemy.receive_attack(packet,1.0,enemy.global_position,player),"counter damages armored Crusher")
 check(not enemy.current_attack_type.is_empty(),"existing Crusher armor preserved")
 reset_pair()
 player.start_attack("player1_punch_1")
 check(player.receive_attack(packet,-1.0,player.global_position,enemy),"counter connects without armor")
 check(player.hit_reaction_timer >= 0.41,"startup counter hitstun bonus")
 # Data targets and timing forbid arbitrary/self cancellation.
 reset_pair()
 player.start_attack("akky_back_kick")
 player.dev_current_attack_connected = true
 player.command_attack_elapsed = 0.05
 check(not player._request_directional_move("akky_forward_punch"),"early cancel forbidden")
 player.command_attack_elapsed = 0.26
 check(not player._request_directional_move("akky_down_punch"),"unlisted cancel forbidden")
 check(player._request_directional_move("akky_forward_punch"),"back K -> forward P confirm")
 player.dev_current_attack_connected = true
 player.command_attack_elapsed = 0.23
 check(player._request_directional_move("player1_kick_finish"),"forward P -> K confirm")
 # Live physics/Area2D damage, not a manually invoked contact callback.
 reset_pair()
 player.position = Vector2(500,520)
 enemy.position = Vector2(620,520)
 player.facing_direction = 1.0
 enemy.facing_direction = -1.0
 var collision_hp: int = enemy.current_hp
 player.set_physics_process(true)
 player.start_attack("akky_forward_kick")
 await ticks(40)
 check(enemy.current_hp < collision_hp,"real Area2D forward K hit")
 player.set_physics_process(false)
 reset_pair()
 player.position = Vector2(500,520)
 enemy.position = Vector2(620,320)
 collision_hp = enemy.current_hp
 player.set_physics_process(true)
 player.start_attack("akky_down_kick")
 await ticks(40)
 check(enemy.current_hp == collision_hp,"low sweep misses elevated hurtbox")
 player.set_physics_process(false)
 reset_pair()
 player.position = Vector2(player._stage_min_x()+2.0,520)
 enemy.position = Vector2(600,520)
 player.facing_direction = 1.0
 var wall_start: float = player.position.x
 player.set_physics_process(true)
 player.start_attack("akky_back_kick")
 await ticks(35)
 check(player.position.x >= player._stage_min_x()-0.01,"back K respects stage wall")
 check(wall_start-player.position.x <= 2.1,"wall limits retreat")
 player.set_physics_process(false)
 # Same actual jumping-kick geometry against ordinary P and anti-air P.
 for anti_air in [false,true]:
  reset_pair()
  player.position = Vector2(500,520)
  enemy.position = Vector2(610,435)
  player.facing_direction = 1.0
  enemy.facing_direction = -1.0
  var player_hp: int = player.current_hp
  var enemy_hp: int = enemy.current_hp
  enemy.start_attack(enemy._ensure_air_kick_attack_data())
  enemy.enter_attack_active()
  player.start_attack("akky_back_punch" if anti_air else "player1_punch_1")
  player.command_attack_elapsed = 0.10
  player._update_pose_collision()
  if anti_air:
   player.enter_attack_active()
  await ticks(3)
  if anti_air:
   check(enemy.current_hp < enemy_hp and player.current_hp == player_hp,"anti-air geometry beats elevated jump K")
  else:
   check(player.current_hp < player_hp and enemy.current_hp == enemy_hp,"ordinary P loses to elevated jump K reach")
 # A high jump kick has no invisible downward extension beyond its authored boot.
 reset_pair()
 player.position = Vector2(500,520)
 enemy.position = Vector2(610,360)
 player.facing_direction = 1.0
 enemy.facing_direction = -1.0
 var high_jump_hp: int = player.current_hp
 enemy.start_attack(enemy._ensure_air_kick_attack_data())
 enemy.enter_attack_active()
 await ticks(3)
 check(player.current_hp == high_jump_hp,"high jump K misses ground body beyond boot reach")
 # Prone/KO clips must never change the runtime scale or foot transform.
 reset_pair()
 var anchor := sprite.position
 for clip in [&"idle_ready",&"knockdown_high",&"knockdown_low",&"stand_up",&"ko"]:
  if not sprite.sprite_frames.has_animation(clip): continue
  player._play_visual_animation(clip,true)
  for frame in range(sprite.sprite_frames.get_frame_count(clip)):
   sprite.set_frame_and_progress(frame,0.0)
   check(sprite.scale.is_equal_approx(scale_before),"down scale %s/%s"%[clip,frame])
   check(sprite.position.is_equal_approx(anchor),"down foot transform %s/%s"%[clip,frame])
 print("DIRECTIONAL_ATTACKS_CHECK failures=%s"%[failures])
 root.get_node("AudioManager").stop_bgm()
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await create_timer(1.0).timeout
 quit(0 if failures.is_empty() else 1)
