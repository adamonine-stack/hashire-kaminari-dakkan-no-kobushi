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
 var scales := [player.animated_character_sprite.scale,enemy.animated_character_sprite.scale]
 var anchors := [player.animated_character_sprite.position,enemy.animated_character_sprite.position]
 for facing in [1.0,-1.0]:
  for direction in ["neutral","forward","down","back"]:
   reset_pair(facing)
   var move: PlayerAttackData = player._get_attack_data("crusher_%s_throw"%direction)
   check(player._request_directional_move(move.attack_id,true),"motion start %s"%direction)
   check(player.animated_character_sprite.animation == move.throw_start_animation,"dedicated startup %s"%direction)
   player._update_active_throw(move.startup_time+.001)
   var hp: int = enemy.current_hp
   var last_y: float = enemy.global_position.y
   var changes := 0
   for tick in range(23):
    player._update_active_throw(.01)
    if enemy.current_hp != hp:
     changes += 1
     hp = enemy.current_hp
    if direction == "down" and player.throw_state == "THROW_HOLD":
     check(enemy.global_position.y <= last_y+.001 and enemy.global_position.y >= enemy.stage_floor_y-32.01,"slam lift monotonic and bounded")
     check(last_y-enemy.global_position.y <= 4.1,"slam lifts gradually")
     last_y = enemy.global_position.y
    if player.throw_state == "THROW_RECOVERY": break
   check(changes == 1,"one release damage event")
   check(player.animated_character_sprite.animation == move.throw_release_animation,"dedicated release %s"%direction)
   check(enemy.animated_character_sprite.animation == move.throw_victim_air_animation,"dedicated victim %s"%direction)
   check(player.animated_character_sprite.frame == 0 and enemy.animated_character_sprite.frame == 0,"both motions start together")
   check(is_equal_approx(player.animated_character_sprite.sprite_frames.get_animation_speed(move.throw_release_animation),enemy.animated_character_sprite.sprite_frames.get_animation_speed(move.throw_victim_air_animation)),"paired cadence")
   for index in range(2):
    var actor: Node = [player,enemy][index]
    var sprite: AnimatedSprite2D = actor.animated_character_sprite
    for clip in [move.throw_start_animation,move.throw_release_animation] if index==0 else [move.throw_victim_air_animation,move.throw_victim_down_animation]:
     check(sprite.sprite_frames.has_animation(clip),"clip exists %s"%clip)
     if not sprite.sprite_frames.has_animation(clip): continue
     actor._play_visual_animation(clip,true)
     for frame in range(sprite.sprite_frames.get_frame_count(clip)):
      sprite.set_frame_and_progress(frame,0)
      check(sprite.scale.is_equal_approx(scales[index]) and sprite.position.is_equal_approx(anchors[index]),"fixed scale/foot transform %s/%s"%[clip,frame])
      var texture: AtlasTexture = sprite.sprite_frames.get_frame_texture(clip,frame)
      var image := texture.get_image()
      var bounds := visible_rect(image)
      check(bounds.size.x>30 and bounds.size.y>20,"nonempty frame %s/%s"%[clip,frame])
      check(bounds.position.x>0 and bounds.position.y>0 and bounds.end.x<image.get_width() and bounds.end.y<image.get_height(),"uncut frame %s/%s"%[clip,frame])
   enemy.enter_knockdown()
   check(enemy.animated_character_sprite.animation == move.throw_victim_down_animation,"landing uses designated ground pose")
   # Prevent a force/reaction from carrying into the next action.
   player._finish_throw()
   check(player.directional_throw_data == null and not player.directional_throw_prepared,"throw metadata clears")
 # Run the actual common physics flow, not just manual phase calls.
 for facing in [1.0,-1.0]:
  for direction in ["neutral","forward","down","back"]:
   reset_pair(facing)
   player.is_backstepping = false
   enemy.is_backstepping = false
   player.set_physics_process(true)
   enemy.set_physics_process(true)
   for i in range(12):
    await physics_frame
    if player.is_on_floor() and enemy.is_on_floor(): break
   print("LIVE_THROW_READY %s floor=%s hp=%s round=%s recoil=%s state=%s active=%s/%s guarding=%s crouch=%s hit=%s/%s regrab=%s input=%s"%[direction,player.is_on_floor(),player.current_hp,player.is_round_active,player.guard_recoil_timer,player.current_attack_type,player.attack_active_timer,player.kick_active_timer,player.is_guarding,player.is_crouching,player.is_hit,player.is_guard_hit,player.throw_regrab_lock_timer,player.input_enabled])
   check(player._request_directional_move("crusher_%s_throw"%direction,true),"live throw begins")
   var saw_release := false
   var saw_down := false
   var saw_wake := false
   for i in range(180):
    await physics_frame
    saw_release = saw_release or enemy.current_hp < enemy.max_hp
    saw_down = saw_down or enemy.knockdown_state == &"KNOCKDOWN"
    saw_wake = saw_wake or enemy.knockdown_state == &"GET_UP"
    check(player.animated_character_sprite.scale.is_equal_approx(scales[0]) and enemy.animated_character_sprite.scale.is_equal_approx(scales[1]),"live actor scales stay fixed")
   check(saw_release and saw_down and saw_wake,"live release/down/wakeup %s"%direction)
   check(not player._is_throw_busy() and not enemy._is_throw_busy(),"live throw locks clear")
   check(enemy.knockdown_state == &"" and not enemy.is_hit and enemy.hurt_box.monitorable,"live returns to control")
   player.set_physics_process(false)
   enemy.set_physics_process(false)
 print("CRUSHER_THROW_MOTION_CHECK failures=%s"%[failures])
 root.get_node("AudioManager").stop_bgm()
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await create_timer(1).timeout
 quit(0 if failures.is_empty() else 1)
func visible_rect(image: Image) -> Rect2i:
 var low := image.get_size()
 var high := Vector2i(-1,-1)
 for y in range(image.get_height()):
  for x in range(image.get_width()):
   if image.get_pixel(x,y).a>=.25:
    low.x = mini(low.x,x)
    low.y = mini(low.y,y)
    high.x = maxi(high.x,x)
    high.y = maxi(high.y,y)
 return Rect2i(low,high-low+Vector2i.ONE)
