extends SceneTree
var failures: Array[String] = []
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
 if not ok:
  failures.append(label)
  push_error(label)
func run():
 var battle: Node = load("res://scenes/Battle.tscn").instantiate()
 battle.get_node("BattleManager").active_enemy_count_limit=1
 root.add_child(battle)
 current_scene=battle
 await process_frame
 var manager: Node=battle.get_node("BattleManager")
 manager.select_player_by_id("player_01_akky")
 for tick in range(420):
  await physics_frame
  if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible:
   manager.enemy_intro_finished.emit()
  if manager.isRoundActive: break
 check(manager.isRoundActive,"battle initialized")
 var actors=[battle.get_node("Player"),battle.get_node("Enemy")]
 for a in actors:
  a.set_physics_process(false)
  a.input_enabled=false
  a.ai_enabled=false
  a.ai_profile=null
 battle.get_node("BattleCamera").position=Vector2(640,360)
 battle.get_node("BattleCamera").zoom=Vector2.ONE
 battle.get_node("BattleCamera").set_process(false)
 battle.get_node("BattleCamera").set_physics_process(false)
 var cases=[
  {"label":"light", "packet":{"damage":2,"attack_type":"punch","attack_height":"middle"},"clip":&"damage_light"},
  {"label":"heavy", "packet":{"damage":2,"attack_type":"kick","attack_height":"middle"},"clip":&"damage_heavy"},
  {"label":"high", "packet":{"damage":2,"attack_type":"punch","attack_height":"high"},"clip":&"damage_high"},
  {"label":"low", "packet":{"damage":2,"attack_type":"punch","attack_height":"low"},"clip":&"damage_low"},
  {"label":"force", "packet":{"damage":2,"attack_type":"punch","attack_height":"middle","knockback":Vector2(250,0)},"clip":&"damage_heavy"},
  {"label":"authored", "packet":{"damage":2,"attack_type":"kick","attack_height":"low","hit_reaction":&"launch_hit"},"clip":&"launch_hit"},
  {"label":"missing_authored", "packet":{"damage":2,"attack_type":"punch","hit_reaction":&"absent_clip"},"clip":&"damage_light"}
 ]
 var output=ProjectSettings.globalize_path("res://../receiver_routing_evidence")
 if DisplayServer.get_name()!="headless": DirAccess.make_dir_recursive_absolute(output)
 for idx in range(2):
  var victim: Node=actors[idx]
  var attacker: Node=actors[1-idx]
  var sprite: AnimatedSprite2D=victim.animated_character_sprite
  var scale=sprite.scale
  var pivot=sprite.position
  for facing in [1.0,-1.0]:
   for item in cases:
    for a in actors:
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
    victim.global_position=Vector2(540,520)
    attacker.global_position=Vector2(820,520)
    victim.velocity=Vector2(0,40)
    victim.move_and_slide()
    victim.facing_direction=facing
    victim._set_visual_facing()
    var packet: Dictionary=item.packet.duplicate(true)
    packet.attack_id="routing_"+item.label
    packet.hitstun_time=0.30
    packet.knockdown_power=0.0
    packet.causes_knockdown=false
    packet.knockback_x=0.0
    packet.knockback_y=0.0
    packet.effect_size=1.0
    packet.screen_shake=0.0
    packet.se_type="normal"
    packet.hit_stop_frames=0
    check(victim._get_damage_animation_from_attack(packet)==item.clip,String(victim.fighter_definition.fighter_id)+item.label+" selection")
    check(victim.receive_attack(packet,-facing,victim.global_position,attacker),item.label+" accepted")
    victim._update_visual_state()
    check(victim.last_damage_animation==item.clip,item.label+" recorded")
    check(sprite.animation==item.clip,item.label+" actual sprite")
    if item.clip in [&"damage_light",&"damage_heavy",&"damage_high",&"damage_low"]:
     var source_name={&"damage_light":"light_hit",&"damage_heavy":"heavy_hit",&"damage_high":"high_hit",&"damage_low":"low_hit"}[item.clip]
     var actor_name="akky" if String(victim.fighter_definition.fighter_id)=="player_01_akky" else "crusher"
     check(sprite.sprite_frames.get_frame_count(item.clip)==3,"dedicated reaction three phases")
     for i in range(3):
      var tex: AtlasTexture=sprite.sprite_frames.get_frame_texture(item.clip,i)
      check(tex.atlas.resource_path.ends_with(actor_name+"_"+source_name+".png"),"dedicated actor/reaction source")
    for frame in range(sprite.sprite_frames.get_frame_count(item.clip)):
     sprite.pause()
     sprite.frame=frame
     check(sprite.scale.is_equal_approx(scale) and sprite.position.is_equal_approx(pivot),item.label+" invariant scale/pivot")
     if DisplayServer.get_name()!="headless":
      await RenderingServer.frame_post_draw
      check(root.get_texture().get_image().save_png(output.path_join("%s_%s_%s_%s.png"%[victim.fighter_definition.fighter_id,item.label,facing,frame]))==OK,"capture")
 print("RECEIVER_ROUTING_CHECK failures=",failures)
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
