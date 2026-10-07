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
 current_scene = battle
 await process_frame
 var manager: Node = battle.get_node("BattleManager")
 await manager.select_player_by_id("player_01_akky")
 for i in range(360):
  await physics_frame
  if manager.isRoundActive: break
 player = battle.get_node("Enemy")
 enemy = battle.get_node("Player")
 player.ai_enabled = false
 player.ai_profile = null
 player.ai_throw_probability = 0.0
 player.ai_guard_enabled = false
 enemy.ai_enabled = false
 enemy.ai_throw_probability = 0.0
 enemy.ai_guard_enabled = false
 enemy.throw_escape_probability = 0.0
 enemy.ai_profile = null
 for i in range(3): await physics_frame
 player.set_physics_process(false)
 enemy.set_physics_process(false)
 for facing in [1.0,-1.0]:
  reset_pair(facing)
  player.ai_profile = load("res://data/enemy_ai/enemy_01_standard_ai.tres").duplicate()
  player.ai_enabled = true
  player.situation_observed_state = "idle"
  player.situation_observed_time = 0
  check(player._select_ai_throw_move()=="crusher_neutral_throw","neutral AI throw")
  var wall: float = player._stage_min_x()+5 if facing>0 else player._stage_max_x()-5
  player.global_position.x = wall
  enemy.global_position.x = wall+80*facing
  check(player._select_ai_throw_move()=="crusher_back_throw","AI wall escape chooses back")
  player.enter_throw()
  check(player.directional_throw_data!=null and player.directional_throw_data.attack_id=="crusher_back_throw","AI enters data throw")
  player._update_active_throw(.101)
  player._update_active_throw(.201)
  check((player.global_position.x-enemy.global_position.x)*facing>50,"wall side ordering reversed")
  check(enemy.global_position.x>=player._stage_min_x() and enemy.global_position.x<=player._stage_max_x(),"wall victim bounded")
  check(player.facing_direction==-facing and enemy.facing_direction==facing,"both face after swap")
  reset_pair(facing)
  enemy.global_position.x = player._stage_max_x()-5 if facing>0 else player._stage_min_x()+5
  player.global_position.x = enemy.global_position.x-80*facing
  check(player._select_ai_throw_move()=="crusher_forward_throw","AI opponent at wall chooses forward")
  reset_pair(facing)
  player.situation_observed_state = "attack"
  player.situation_observed_time = .05
  enemy.velocity.x = -150*facing
  check(player._select_ai_throw_move()=="crusher_neutral_throw","AI cannot instant counter")
  player.situation_observed_time = .30
  check(player._select_ai_throw_move()=="crusher_back_throw","AI observed approach chooses counter")
  player.situation_observed_state = "recovery"
  check(player._select_ai_throw_move()=="crusher_down_throw","AI punish chooses slam")
  # Counter reception remains a shared closing-velocity/short-window check.
  for case in ["closing","retreating","late"]:
   reset_pair(facing)
   enemy.global_position.x = 600+(player.throw_body_width+62)*facing
   enemy.velocity.x = (150 if case=="retreating" else -150)*facing
   check(player._request_directional_move("crusher_back_throw",true),"counter startup")
   player._update_active_throw(.16 if case=="late" else .101)
   if case=="closing":
    check(player.has_throw_connected,"closing counter connects")
   else:
    check(player.throw_state=="THROW_WHIFF" and player.throw_recovery_timer>=.59,"failed counter has recovery")
 # Normal decision loop must reach throws instead of always choosing a close jab.
 reset_pair(1)
 player.ai_enabled = true
 player.ai_profile = load("res://data/enemy_ai/enemy_01_standard_ai.tres").duplicate()
 player.ai_profile.throw_weight = 1.0
 player.ai_throw_cooldown_timer = 0
 player.ai_attack_cooldown_timer = 0
 player.ai_reaction_timer = .20
 player.situation_observed_state = "idle"
 player.situation_observed_time = 0
 player.last_ai_action = &""
 enemy.is_guarding = true
 check(not player._try_situation_throw(),"AI throw respects reaction timer")
 player.ai_reaction_timer = 0
 player.choose_next_action()
 check(player.is_throwing and player.ai_selected_move_id=="crusher_neutral_throw","AI decision loop chooses guard-breaking throw")
 check(player.ai_throw_cooldown_timer>0,"AI throw cooldown retained")
 # A fighter with no directional throw data uses its established legacy move.
 reset_pair(1)
 var saved_sequence: Array = player.attack_data_sequence.duplicate()
 player.attack_data_sequence.clear()
 check(player._select_ai_throw_move().is_empty(),"legacy throws stay unselected by directional resolver")
 check(player._start_ai_selected_throw() and player.directional_throw_data==null,"legacy fallback starts")
 player.attack_data_sequence.assign(saved_sequence)
 print("CRUSHER_THROW_AI_CHECK failures=%s"%[failures])
 root.get_node("AudioManager").stop_bgm()
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await create_timer(1).timeout
 quit(0 if failures.is_empty() else 1)
