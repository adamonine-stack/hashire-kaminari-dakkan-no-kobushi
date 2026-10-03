extends "res://tests/cross_muei_check.gd"

func capture(label: String) -> void:
 output = ProjectSettings.globalize_path("res://../evidence/cross_stage4_special")
 DirAccess.make_dir_recursive_absolute(output)
 await super.capture(label)

func extra_reversal_checks(manager: Node, actor: Node, victim: Node) -> void:
 manager._flow_sequence_id += 1
 manager.flow_state = manager.BattleState.FIGHT
 for hero in ["ally_balance","ally_power","ally_speed"]:
  victim.apply_character_data(load("res://data/fighters/"+hero+".tres"))
  for direction in [1,-1]:
   for mode in ["hit","guard","whiff","escape"]:
    await clean_reset(manager,actor,Vector2(620,520),direction)
    await clean_reset(manager,victim,Vector2(620+(350 if mode=="whiff" else 70)*direction,520),-direction)
    manager._set_battle_active(true)
    actor.set_special_gauge(100)
    victim.throw_escape_probability = 0.0
    if mode == "guard":
     victim.is_guarding = true
     victim.guard_type = "high"
     victim.set_physics_process(false)
    if mode == "hit":
     victim.input_enabled = true
     victim.request_punch_attack()
     check(not victim.current_attack_type.is_empty(),hero+" begins ordinary attack")
     victim.set_physics_process(false)
    var hp: int = victim.current_hp
    var damage: int = int(actor._get_character_special_attack_dictionary()["damage"])
    actor.start_character_special()
    var seen := {}
    for tick in range(160):
     await physics_frame
     actor._update_visual_state()
     victim._update_visual_state()
     if victim.is_guard_hit and not seen.has("guard"):
      seen["guard"] = true
      check(victim.animated_character_sprite.animation==&"received_cross_muei_guard","dedicated heavy guard "+hero)
      check(not victim.is_throw_locked and victim.current_hp==hp-2,"guard never grips, only existing chip")
      await capture(hero+"_"+str(direction)+"_natural_guard")
     if actor.throw_state=="THROW_HOLD" and not seen.has("hold"):
      seen["hold"] = true
      check(victim.is_throw_locked and victim.current_attack_type.is_empty(),"natural hit interrupts ordinary attack")
      check(victim.pending_throw_damage==damage,"dedicated special pending damage")
      await capture(hero+"_"+str(direction)+"_natural_hold")
      if mode=="escape":
       victim._complete_throw_escape()
       check(actor.throw_recovery_timer>=0.5,"escaped Muei still has special recovery")
       await capture(hero+"_"+str(direction)+"_escape_recovery")
     if actor.throw_state=="THROW_RECOVERY" and not seen.has("release"):
      seen["release"] = true
      check(actor.throw_recovery_timer>=0.5,"confirmed Muei has special recovery")
      check(victim.current_hp==hp-damage,"release damages exactly once")
      await capture(hero+"_"+str(direction)+"_natural_release")
     if actor.character_special_state==actor.CharacterSpecialState.RECOVERY and not seen.has("special_recovery"):
      seen["special_recovery"] = true
      check(actor.character_special_timer>0.65 if mode=="whiff" else actor.character_special_timer>0.5,"full special recovery")
      await capture(hero+"_"+str(direction)+"_"+mode+"_recovery")
     if tick>70 and not actor.is_character_special_busy() and not actor._is_throw_busy():break
    check(seen.has("guard") if mode=="guard" else (seen.has("special_recovery") if mode=="whiff" else seen.has("hold")),"natural outcome "+hero+mode)
    check(victim.current_hp==hp if mode in ["whiff","escape"] else victim.current_hp==hp-(2 if mode=="guard" else damage),"outcome damage "+mode)
  # Reciprocal contacts trade, including when Cross contact is enqueued first.
  for order in [0,1]:
   await clean_reset(manager,actor,Vector2(620,520),1)
   await clean_reset(manager,victim,Vector2(690,520),-1)
   actor.set_physics_process(false)
   victim.set_physics_process(false)
   actor.set_special_gauge(100)
   victim.set_special_gauge(100)
   actor.start_character_special()
   victim.start_character_special()
   actor.enter_character_special_active()
   victim.enter_character_special_active()
   actor.reversal_elapsed=0.20
   victim.reversal_elapsed=0.20
   var ahp: int=actor.current_hp
   var vhp: int=victim.current_hp
   if order==0:
    actor._on_character_special_hitbox_area_entered(victim.hurt_box)
    victim._on_character_special_hitbox_area_entered(actor.hurt_box)
   else:
    victim._on_character_special_hitbox_area_entered(actor.hurt_box)
    actor._on_character_special_hitbox_area_entered(victim.hurt_box)
   await process_frame
   await process_frame
   check(actor.current_hp<ahp and victim.current_hp<vhp,"mutual hit trades in both queue orders "+hero)
   check(not actor.is_throw_locked and not victim.is_throw_locked,"mutual hit creates no priority grip")
   await capture(hero+"_trade_order_"+str(order))
 # Observation-based AI can reverse from hitstun, but cannot read immediate input.
 await clean_reset(manager,actor,Vector2(620,520),1)
 await clean_reset(manager,victim,Vector2(690,520),-1)
 actor.set_physics_process(false)
 victim.set_physics_process(false)
 actor.set_special_gauge(100)
 actor.ai_profile=actor.fighter_definition.ai_profile
 actor.reversal_cooldown=0.0
 manager.update_enemy_target()
 actor.ai_enabled=true
 actor.is_hit=true
 actor.special_ai_use_chance=10
 actor.reversal_ai_checked=false
 actor.reversal_ai_observation=0.11
 actor._try_observed_special_reversal()
 check(not actor.is_character_special_busy(),"AI waits observation boundary")
 actor.reversal_ai_observation=0.13
 actor._try_observed_special_reversal()
 check(actor.is_character_special_busy(),"observed hitstun reversal starts")
 await capture("cross_observed_ai_reversal")
 actor.ai_enabled=false
 actor.special_ai_use_chance=0.4
 await clean_reset(manager,actor,Vector2(620,520),1)
 await clean_reset(manager,victim,Vector2(690,390),-1)
 actor.set_physics_process(false)
 victim.set_physics_process(false)
 actor.set_special_gauge(100)
 actor.start_character_special()
 actor.enter_character_special_active()
 actor.reversal_elapsed=0.2
 var packet: Dictionary=actor._get_character_special_attack_dictionary()
 actor._on_character_special_hitbox_area_entered(victim.hurt_box)
 await process_frame
 await process_frame
 check(victim.knockdown_state==&"KNOCKBACK" and not victim.is_throw_locked,"airborne hit uses special reaction without impossible ground grip")
 await capture("cross_airborne_special_hit")
 await clean_reset(manager,victim,Vector2(690,520),-1)
 victim.enter_knockdown()
 check(not victim.receive_attack(packet,1,victim.global_position,actor),"down victim rejects hit")
 check(not victim.request_character_special(),"down victim cannot reverse")
 print("CROSS_STAGE4_REVERSAL_EXTRA_OK natural_hit guard whiff escape recovery trade ai airborne down failures="+str(failures))
