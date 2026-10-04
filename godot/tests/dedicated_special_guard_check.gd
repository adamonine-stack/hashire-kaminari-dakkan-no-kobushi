extends SceneTree
var failures: Array[String]=[]
func check(ok: bool,label: String):
 if not ok:
  failures.append(label); push_error(label)
func _initialize(): call_deferred("run")
func reset_actor(a: Node):
 a._cancel_current_action()
 a.reset_attack_state()
 a.reset_knockdown_state()
 a.is_invincible=false
 a.is_hit=false
 a.is_guard_hit=false
 a.hit_stop_timer=0
 a.current_hp=a.max_hp
 a.is_round_active=true
 a._clear_guard_state()
 a.velocity=Vector2.ZERO
func run():
 var battle: Node=load("res://scenes/Battle.tscn").instantiate()
 battle.get_node("BattleManager").active_enemy_count_limit=1
 root.add_child(battle)
 current_scene=battle
 await process_frame
 var manager: Node=battle.get_node("BattleManager")
 await manager.select_player_by_id("player_01_akky")
 for i in range(360):
  await physics_frame
  if manager.isRoundActive: break
 var actors=[battle.get_node("Player"),battle.get_node("Enemy")]
 for a in actors:
  a.set_physics_process(false)
  a.ai_enabled=false
  a.ai_profile=null
  a.input_enabled=false
 var inventory: Dictionary={}
 for a in actors:
  var clips: Dictionary={}
  for name in ["damage_light","damage_heavy","damage_high","damage_low","air_hit","launch_hit","knockback","knockdown","down","ground_bounce","wall_hit","special_hit","special_knockback","special_knockdown","special_guard","air_guard_hit"]:
   var frames: SpriteFrames=a.animated_character_sprite.sprite_frames
   var sources: Array=[]
   if frames.has_animation(name):
    for i in range(frames.get_frame_count(name)):
     var tex: Texture2D=frames.get_frame_texture(name,i)
     if tex is AtlasTexture:
      sources.append({"texture":tex.atlas.resource_path,"region":str(tex.region)})
   clips[name]={"exists":frames.has_animation(name),"frames":sources}
  inventory[String(a.fighter_definition.fighter_id)]=clips
 var file=FileAccess.open("res://../PAIR_REACTION_INVENTORY.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(inventory,"  "))
 file.close()
 for index in range(2):
  var victim: Node=actors[index]
  var attacker: Node=actors[1-index]
  var prefix="akky" if index==0 else "crusher"
  var sprite: AnimatedSprite2D=victim.animated_character_sprite
  var scale=sprite.scale
  var anchor=sprite.position
  for facing in [1.0,-1.0]:
   for air in [false,true]:
    reset_actor(victim); reset_actor(attacker)
    victim.global_position=Vector2(600,350 if air else 520)
    attacker.global_position=Vector2(665,350 if air else 520)
    victim.velocity.y=40
    attacker.velocity.y=40
    victim.move_and_slide(); attacker.move_and_slide()
    victim.facing_direction=facing
    attacker.global_position.x=600+65*facing
    attacker.facing_direction=-facing
    victim.is_guarding=true
    victim.guard_type="air" if air else "high"
    var packet: Dictionary=attacker._get_character_special_attack_dictionary()
    var hp: int=victim.current_hp
    check(not victim.receive_attack(packet,facing,victim.global_position,attacker),"special blocks "+prefix+str(facing)+str(air))
    check(hp-victim.current_hp==victim._get_guard_damage_from_attack_data(packet),"preserves authored guard damage")
    check(victim.is_guard_hit and not victim.is_hit and victim.knockdown_state==&"","guard never down/launch")
    check(absf(victim.velocity.x)<160 and victim.velocity.y<=40,"small guard push only")
    var duration: float=victim.guard_hit_timer
    for phase in range(3):
     victim.guard_hit_timer=duration*(1.0-(phase+.10)/3.0)
     victim._update_visual_state()
     var expected=&"air_guard_hit" if air else &"special_guard"
     check(sprite.animation==expected,"receiver/air appropriate dedicated guard")
     if not air:
      check(sprite.frame==phase,"three phases synchronized to guardstun")
      var tex: AtlasTexture=sprite.sprite_frames.get_frame_texture(expected,phase)
      check(tex.atlas.resource_path.ends_with(prefix+"_special_guard.png"),"dedicated source art")
     check(sprite.scale==scale and sprite.position==anchor,"fixed guard size/anchor")
    victim._update_guard_hit(duration+1)
    check(not victim.is_guard_hit and victim.special_guard_animation==&"" and victim.special_guard_duration==0,"end clears special guard")
    reset_actor(victim)
    victim.is_guarding=true
    victim.guard_type="air" if air else "high"
    var normal={"damage":5,"attack_type":"punch","attack_height":"high","knockback_x":40.0,"knockback_y":0.0,"hit_stop_frames":0,"effect_size":1.0,"screen_shake":0.0,"se_type":"normal","is_guardable":true}
    victim.receive_attack(normal,facing,victim.global_position,attacker)
    victim._update_visual_state()
    check(victim.special_guard_animation==&"" and sprite.animation!=&"special_guard","normal block does not inherit special pose")
    victim._cancel_current_action()
    check(victim.special_guard_duration==0,"damage/KO action cancel clears special guard")
 # Actual monitoring Area2D -> queued resolver -> defender guard reaction.
 for index in range(2):
  var victim: Node=actors[index]
  var attacker: Node=actors[1-index]
  for facing in [1.0,-1.0]:
   reset_actor(victim); reset_actor(attacker)
   victim.global_position=Vector2(600,520)
   attacker.global_position=Vector2(600+65*facing,520)
   victim.velocity.y=40; attacker.velocity.y=40
   victim.move_and_slide(); attacker.move_and_slide()
   victim.facing_direction=facing
   attacker.facing_direction=-facing
   victim.is_guarding=true; victim.guard_type="high"
   attacker.set_special_gauge(100)
   var hp: int=victim.current_hp
   attacker.start_character_special()
   attacker.enter_character_special_active()
   var packet: Dictionary=attacker._get_character_special_attack_dictionary()
   for i in range(5): await physics_frame
   check(victim.is_guard_hit and victim.special_guard_animation==&"special_guard","actual special hitbox -> dedicated guard "+str(index)+str(facing))
   check(hp-victim.current_hp==victim._get_guard_damage_from_attack_data(packet),"actual collision authored block damage")
   check(attacker.character_special_state==attacker.CharacterSpecialState.ACTIVE,"guard does not interrupt attacker recovery flow")
   attacker.finish_character_special()
 print("DEDICATED_SPECIAL_GUARD_CHECK failures=%s"%[failures])
 root.get_node("AudioManager").stop_bgm()
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await create_timer(1).timeout
 quit(0 if failures.is_empty() else 1)
