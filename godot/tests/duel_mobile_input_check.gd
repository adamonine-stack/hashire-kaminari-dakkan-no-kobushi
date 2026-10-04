extends SceneTree
var failures: Array[String]=[]
var battle: Node
var manager: Node
var player: Node
var enemy: Node
var controls: Node
func _initialize(): call_deferred("run")
func check(ok: bool,label: String):
 if not ok: failures.append(label); push_error(label)
func ticks(count: int):
 for i in range(count): await physics_frame
func reset_pair(facing: float):
 controls.release_all_touch_inputs()
 for actor in [player,enemy]:
  actor._cancel_current_action()
  actor.reset_attack_state()
  manager.reset_active_fighter_state(actor,Vector2(500 if actor==player else 500+300*facing,520),facing if actor==player else -facing,actor.max_hp)
  actor.ai_enabled=false
  actor.ai_profile=null
  actor.input_enabled=actor==player
  actor.is_round_active=true
  actor.hit_stop_timer=0
  actor.combat_commands.clear()
 await ticks(4)
func run():
 battle=load("res://scenes/Battle.tscn").instantiate()
 battle.get_node("BattleManager").active_enemy_count_limit=1
 root.add_child(battle); current_scene=battle
 await process_frame
 manager=battle.get_node("BattleManager")
 manager.select_player_by_id("player_01_akky")
 for i in range(420):
  await physics_frame
  if manager._enemy_intro_panel!=null and manager._enemy_intro_panel.visible: manager.enemy_intro_finished.emit()
  if manager.isRoundActive: break
 check(manager.isRoundActive,"duel active")
 player=battle.get_node("Player"); enemy=battle.get_node("Enemy")
 if String(player.fighter_definition.fighter_id)!="player_01_akky":
  var temporary=player; player=enemy; enemy=temporary
 controls=manager.mobile_controls
 controls.show_touch_controls()
 for facing in [1.0,-1.0]:
  for direction in ["forward","back","down"]:
   for action in ["punch","kick"]:
    for held in [false,true]:
     await reset_pair(facing)
     var name="CrouchButton" if direction=="down" else ("MoveRightButton" if (direction=="forward")== (facing>0) else "MoveLeftButton")
     var button=controls.left_controls.get_node(name)
     button.button_down.emit()
     await ticks(2)
     if not held: button.button_up.emit()
     await ticks(6)
     controls.right_controls.get_node("PunchButton" if action=="punch" else "KickButton").button_down.emit()
     await ticks(2)
     var expected="akky_"+direction+"_"+action
     check(player.current_attack_id==expected,"UI direction/action "+expected+str(facing)+str(held)+" actual="+player.current_attack_id)
     check(player.last_combat_command.get("direction","")==direction,"logical facing "+direction)
     button.button_up.emit()
     await ticks(2)
  await reset_pair(facing)
  var button=controls.left_controls.get_node("MoveRightButton" if facing>0 else "MoveLeftButton")
  button.button_down.emit(); await ticks(2); button.button_up.emit()
  await ticks(13)
  controls.right_controls.get_node("PunchButton").button_down.emit(); await ticks(2)
  check(player.current_attack_id=="player1_punch_1","expired direction becomes neutral "+str(facing))
  await reset_pair(facing)
  controls.left_controls.get_node("UpButton").button_down.emit()
  await ticks(7)
  controls.right_controls.get_node("KickButton").button_down.emit(); await ticks(2)
  check(player.current_attack_id=="akky_air_kick","UI jump then air K "+str(facing))
 controls.right_controls.get_node("PunchButton").button_down.emit()
 check(Input.is_action_pressed("attack"),"tap pending before cleanup")
 controls.release_all_touch_inputs()
 for action in ["move_left","move_right","down","attack","kick","jump","guard","throw_attack","special_attack"]:
  check(not Input.is_action_pressed(action),"touch cleanup "+action)
 print("DUEL_MOBILE_INPUT_CHECK failures=",failures)
 manager.cleanup_battle_before_transition()
 battle.queue_free(); await process_frame
 quit(0 if failures.is_empty() else 1)
