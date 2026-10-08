extends SceneTree
var failures: Array[String] = []
var player: Node
var enemy: Node
var hit_moves: Array[String] = []
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
 current_scene = battle
 await process_frame
 var manager: Node = battle.get_node("BattleManager")
 manager.select_player_by_id("player_01_akky")
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
 enemy.ai_profile = load("res://data/enemy_ai/enemy_01_standard_ai.tres")
 enemy.ai_enabled = true
 for facing in [1.0,-1.0]:
  for pair in [[50,"crusher_neutral_punch"],[100,"crusher_neutral_kick"],[175,"crusher_forward_kick"]]:
   reset_pair()
   enemy.global_position = Vector2(600,520)
   player.global_position = Vector2(600+float(pair[0])*facing,520)
   enemy.facing_direction = facing
   enemy.move_and_slide()
   player.move_and_slide()
   enemy.situation_observed_state = "idle"
   enemy.situation_observed_time = .3
   check(enemy._select_situation_move() == pair[1],"distance selector %s/%s"%[pair[0],facing])
   enemy.ai_reaction_timer = .2
   check(not enemy._try_situation_move(),"AI reaction timer gates action")
   enemy.ai_reaction_timer = 0
   enemy.ai_attack_cooldown_timer = 0
   check(enemy._try_situation_move(),"AI executes selected data")
   check(enemy.current_attack_id == pair[1],"shared move id")
   check(enemy.animated_character_sprite.animation == enemy.current_attack_data.animation_name,"data routes existing motion")
  reset_pair()
  enemy.global_position = Vector2(600,520)
  player.global_position = Vector2(690,520)
  enemy.move_and_slide()
  player.move_and_slide()
  player.start_attack("player1_punch_1")
  player.attack_phase = player.AttackPhase.RECOVERY
  enemy.situation_observed_state = "idle"
  enemy._observe_situation_state(.1)
  enemy._observe_situation_state(.1)
  check(enemy._select_situation_move().is_empty(),"cannot punish immediately on recovery transition")
  enemy._observe_situation_state(.15)
  check(enemy._select_situation_move() == "crusher_forward_punch","observed recovery selects punish")
  player.attack_phase = player.AttackPhase.ACTIVE
  enemy._observe_situation_state(.3)
  enemy._observe_situation_state(.3)
  check(enemy._select_situation_move() == "crusher_back_kick","observed attack selects evasion")
  reset_pair()
  player.global_position.y = 390
  player.move_and_slide()
  check(enemy._select_situation_move().is_empty(),"unobserved airborne opponent does not trigger frame-perfect counter")
  enemy._observe_situation_state(.3)
  enemy._observe_situation_state(.3)
  check(enemy._select_situation_move() == "crusher_back_punch","observed air selects authored anti-air after reaction delay")
 var crusher_scale: Vector2 = enemy.animated_character_sprite.scale
 var hits: Array[String] = []
 enemy.attack_hit.connect(func(id,_target): hits.append(String(id)))
 for facing in [1.0,-1.0]:
  for id in ["crusher_neutral_punch","crusher_neutral_kick","crusher_forward_punch","crusher_forward_kick","crusher_back_kick","crusher_down_kick"]:
   reset_pair()
   enemy.ai_enabled = false
   enemy.ai_profile = null
   enemy.global_position = Vector2(600,520)
    # Long approach kick is tested inside its authored 115..205 range, rather than close-range overshoot.
   player.global_position = Vector2(600+(175 if id=="crusher_forward_kick" else (45 if id.ends_with("punch") else 90))*facing,520)
   enemy.facing_direction = facing
   player.facing_direction = -facing
   enemy.set_physics_process(true)
   player.set_physics_process(true)
   await ticks(3)
   hits.clear()
   check(enemy._request_directional_move(id,true),"enemy shared move request "+id)
   check(enemy.animated_character_sprite.scale.is_equal_approx(crusher_scale),"attack keeps sprite scale")
   await ticks(75)
   check(hits.has(id),"live collision hit %s/%s"%[id,facing])
   check(enemy.current_attack_type == "","move recovery finishes")
   player.set_physics_process(false)
   enemy.set_physics_process(false)
 reset_pair()
 enemy.ai_profile = load("res://data/enemy_ai/enemy_01_standard_ai.tres").duplicate()
 enemy.ai_profile.can_guard = false
 enemy.ai_profile.can_jump = false
 enemy.reset_ai_state()
 enemy.ai_enabled = true
 enemy.global_position = Vector2(600,520)
 player.global_position = Vector2(765,520)
 var selected: Array[String] = []
 enemy.ai_action_started.connect(func(id):
  if String(id).begins_with("crusher_"): selected.append(String(id)))
 player.set_physics_process(true)
 enemy.set_physics_process(true)
 for i in range(360): await physics_frame
 check(not selected.is_empty(),"live autonomous AI selects resource moves")
 print("CRUSHER_LIVE_AI selected=%s"%[selected])
 print("CRUSHER_SITUATION_CHECK failures=%s"%[failures])
 root.get_node("AudioManager").stop_bgm()
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await create_timer(1).timeout
 quit(0 if failures.is_empty() else 1)
