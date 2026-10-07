extends SceneTree
var failures: Array[String] = []
var player: Node
var enemy: Node
var hero := "seiya"
func _initialize() -> void:
 call_deferred("run")
func check(ok: bool, label: String) -> void:
 if not ok:
  failures.append(label)
  push_error(label)
func reset_pair(facing: float) -> void:
 for actor in [player, enemy]:
  actor._finish_throw()
  actor.reset_knockdown_state()
  actor._cancel_current_action()
  actor.reset_combo()
  actor.reset_attack_state()
  actor.is_hit = false
  actor.is_guard_hit = false
  actor.is_invincible = false
  actor.hit_stop_timer = 0.0
  actor.guard_recoil_timer = 0.0
  actor.throw_regrab_lock_timer = 0.0
  actor.directional_throw_down_remaining = 0.0
  actor.current_hp = actor.max_hp
  actor.is_round_active = true
  actor._clear_guard_state()
  actor.velocity = Vector2.ZERO
 player.combat_commands.clear()
 player.global_position = Vector2(600,520)
 enemy.global_position = Vector2(600+80*facing,520)
 player.facing_direction = facing
 enemy.facing_direction = -facing
func run() -> void:
 var battle: Node = load("res://scenes/Battle.tscn").instantiate()
 battle.get_node("BattleManager").active_enemy_count_limit = 1
 root.add_child(battle)
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
 enemy.ai_profile = null
 for i in range(3): await physics_frame
 player.set_physics_process(false)
 enemy.set_physics_process(false)
 for facing in [1.0,-1.0]:
  for direction in ["neutral","forward","down","back"]:
   reset_pair(facing)
   var id := "%s_%s_throw"%[hero,direction]
   check(player._resolve_directional_move({"kind":"throw","direction":direction}) == id,"throw command %s/%s"%[direction,facing])
   player.is_crouching = direction == "down"
   check(player._request_directional_move(id),"throw starts %s"%direction)
   check(not player.is_crouching,"throw leaves crouch")
   player._update_active_throw(player.directional_throw_data.startup_time + .001)
   check(enemy.is_throw_locked and enemy.is_throw_escape_pending,"victim held %s"%direction)
   check(player.animated_character_sprite.animation == &"throw_hold", "existing grab contact")
   check(enemy.animated_character_sprite.animation == &"directional_throw_held", "standing held victim")
   check(is_equal_approx(enemy.global_position.y,player.stage_floor_y),"held foot baseline")
   var hp: int = enemy.current_hp
   var old_player_x: float = 600
   var old_enemy_x: float = 600 + 80*facing
   player._update_active_throw(player.directional_throw_data.throw_hold_seconds + .001)
   check(enemy.current_hp < hp,"release damages %s"%direction)
   check(enemy.knockdown_state == &"KNOCKBACK","release down reaction %s"%direction)
   check(player.throw_state == "THROW_RECOVERY","attacker recovery %s"%direction)
   if direction == "back":
    check(is_equal_approx(player.global_position.x,old_enemy_x) and is_equal_approx(enemy.global_position.x,old_player_x),"back swaps positions")
    check(enemy.velocity.x*facing < 0,"back trajectory")
   elif direction == "down":
    check(is_zero_approx(enemy.velocity.x),"slam stays near release")
    enemy.enter_knockdown()
    check(enemy.knockdown_timer >= 1.1,"slam longer down")
   elif direction == "forward":
    check(enemy.velocity.x*facing > 300,"forward long trajectory")
   player._release_throw()
   check(enemy.current_hp == hp - roundi(player.throw_damage*player.directional_throw_data.damage_multiplier),"no duplicate release damage")
  # Buffered touch-equivalent command, direction released before action.
  reset_pair(facing)
  player.combat_commands.record("left" if facing > 0 else "right",true,facing)
  player.combat_commands.record("left" if facing > 0 else "right",false,facing)
  player.combat_commands.advance(.12)
  player.combat_commands.record("throw",true,facing)
  player._dispatch_combat_command()
  check(player.directional_throw_data != null and player.directional_throw_data.throw_swap_positions,"120ms buffered back throw")
  # Wall exit preserves ordering and stage bounds.
  reset_pair(facing)
  var wall: float = player._stage_min_x()+5 if facing > 0 else player._stage_max_x()-5
  player.global_position.x = wall
  enemy.global_position.x = wall+80*facing
  player._request_directional_move((hero+"_back_throw"))
  player._update_active_throw(.101)
  player._update_active_throw(.201)
  check((player.global_position.x-enemy.global_position.x)*facing > 50,"wall back throw exits")
  check(enemy.global_position.x >= player._stage_min_x() and enemy.global_position.x <= player._stage_max_x(),"wall victim in bounds")
  # Counter extension only observes closing velocity in a short window.
  reset_pair(facing)
  enemy.global_position.x = 600+(player.throw_body_width+62)*facing
  enemy.velocity.x = -150*facing
  player._request_directional_move((hero+"_back_throw"))
  player._update_active_throw(.101)
  check(player.has_throw_connected,"closing motion counter connects")
  reset_pair(facing)
  enemy.global_position.x = 600+(player.throw_body_width+62)*facing
  enemy.velocity.x = 150*facing
  player._request_directional_move((hero+"_back_throw"))
  player._update_active_throw(.101)
  check(player.throw_state == "THROW_WHIFF" and player.throw_recovery_timer >= .59,"retreating motion counter whiffs")
  reset_pair(facing)
  enemy.global_position.x = 600+(player.throw_body_width+62)*facing
  enemy.velocity.x = -150*facing
  player._request_directional_move((hero+"_back_throw"))
  player._update_active_throw(.16)
  check(player.throw_state == "THROW_WHIFF","late counter outside window")
 var mobile: Node = battle.find_child("MobileControls",true,false)
 mobile.visible = true
 for facing in [1.0,-1.0]:
  for direction in ["forward","back","down"]:
   for hold in [false,true]:
    reset_pair(facing)
    var button_name := "CrouchButton" if direction == "down" else ("MoveRightButton" if (direction == "forward") == (facing > 0) else "MoveLeftButton")
    var button: Button = mobile.left_controls.get_node(button_name)
    var data: Dictionary = mobile.DIRECTION_BUTTONS[button_name]
    mobile._on_direction_button_down(button,data)
    player._sample_combat_commands(0.0)
    if not hold:
     mobile._on_direction_button_up(button,data)
     player._sample_combat_commands(0.0)
    player._sample_combat_commands(.12)
    mobile._on_tap_button_down(mobile.right_controls.get_node("ThrowButton"),"throw_attack")
    player._sample_combat_commands(0.0)
    player._dispatch_combat_command()
    check(player.directional_throw_data != null and player.directional_throw_data.command_direction == direction,"mobile direction throw %s/%s/%s"%[direction,facing,hold])
    mobile._on_direction_button_up(button,data)
    for i in range(2): await physics_frame
    await process_frame
    await process_frame
    Input.action_release("throw_attack")
 mobile.release_all_touch_inputs()
 reset_pair(1)
 enemy.is_guarding = true
 check(player._request_directional_move((hero+"_neutral_throw")),"throw can start into guard")
 player._update_active_throw(.121)
 check(enemy.is_throw_locked,"throw breaks guard")
 player._update_active_throw(.201)
 check(not enemy.can_be_thrown(player),"release regrab protection")
 reset_pair(1)
 var definition: Resource = enemy.fighter_definition.duplicate()
 enemy.fighter_definition = definition
 definition.throw_received_damage_scale = .5
 player._request_directional_move((hero+"_neutral_throw"))
 player._update_active_throw(.121)
 player._update_active_throw(.201)
 check(enemy.max_hp-enemy.current_hp == roundi(player.throw_damage*.5),"data throw resistance")
 definition.throw_received_damage_scale = 1.0
 reset_pair(1)
 player.is_backstepping = true
 check(not player._request_directional_move((hero+"_back_throw")),"backstep cannot bypass input restrictions")
 player.is_backstepping = false
 enemy.global_position.y -= 120
 enemy.set_physics_process(true)
 for i in range(2): await physics_frame
 enemy.set_physics_process(false)
 check(not enemy.can_be_thrown(player),"airborne victim prohibited")
 reset_pair(1)
 enemy.is_hit = true
 check(not enemy.can_be_thrown(player),"hitstun throw prohibited")
 enemy.is_hit = false
 enemy.is_invincible = true
 check(not enemy.can_be_thrown(player),"invincible throw prohibited")
 enemy.is_invincible = false
 enemy.knockdown_state = &"KNOCKDOWN"
 check(not enemy.can_be_thrown(player),"down throw prohibited")
 enemy.knockdown_state = &""
 enemy.current_hp = 0
 check(not enemy.can_be_thrown(player),"KO throw prohibited")
 print("STAGE1_HERO_THROWS_CHECK %s failures=%s"%[hero,failures])
 root.get_node("AudioManager").stop_bgm()
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await create_timer(1).timeout
 quit(0 if failures.is_empty() else 1)
