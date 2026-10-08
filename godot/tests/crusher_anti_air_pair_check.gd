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
  if manager._enemy_intro_panel!=null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
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
  enemy.global_position = Vector2(600,520)
  player.global_position = Vector2(600+60*facing,435)
  player.facing_direction = -facing
  enemy.facing_direction = facing
  var original_scale: Vector2 = player.animated_character_sprite.scale
  var enemy_scale: Vector2 = enemy.animated_character_sprite.scale
  player.set_physics_process(true)
  enemy.set_physics_process(true)
  await ticks(2)
  check(enemy._request_directional_move("crusher_back_punch",true),"dedicated anti-air starts")
  var saw_hit := false
  for i in range(20):
   await physics_frame
   if player.current_hp<player.max_hp:
    saw_hit = true
    check(player.last_damage_animation == &"launch_hit","dedicated receiver selected")
    check(player.animated_character_sprite.scale.is_equal_approx(original_scale),"victim scale invariant")
    check(enemy.animated_character_sprite.scale.is_equal_approx(enemy_scale),"attacker scale invariant")
    break
  check(saw_hit,"uppercut real airborne contact %s"%facing)
  await ticks(70)
  check(player.is_on_floor() and not player.is_hit,"victim returns to floor/control")
  player.set_physics_process(false)
  enemy.set_physics_process(false)
 for facing in [1.0,-1.0]:
  reset_pair()
  enemy.global_position = Vector2(600,520)
  player.global_position = Vector2(600+55*facing,520)
  player.facing_direction = -facing
  enemy.facing_direction = facing
  player.set_physics_process(true)
  enemy.set_physics_process(true)
  await ticks(3)
  check(enemy._request_directional_move("crusher_down_punch",true),"ground launcher starts")
  var saw_launch := false
  for i in range(35):
   await physics_frame
   if player.current_hp<player.max_hp:
    saw_launch = player.velocity.y<0.0 and player.last_damage_animation == &"launch_hit"
    break
  check(saw_launch,"ground launcher real contact/launch %s"%facing)
  await ticks(85)
  check(player.is_on_floor() and not player.is_hit,"launcher victim returns")
  player.set_physics_process(false)
  enemy.set_physics_process(false)
 print("DEDICATED_PAIR_CHECK failures=%s"%[failures])
 root.get_node("AudioManager").stop_bgm()
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await create_timer(1).timeout
 quit(0 if failures.is_empty() else 1)
