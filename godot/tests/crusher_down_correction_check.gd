extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
 call_deferred("run")
func check(ok: bool, label: String) -> void:
 if not ok:
  failures.append(label)
  push_error(label)
func opaque_bounds(image: Image) -> Rect2i:
 var low := Vector2i(image.get_width(),image.get_height())
 var high := Vector2i(-1,-1)
 for y in range(image.get_height()):
  for x in range(image.get_width()):
   if image.get_pixel(x,y).a >= 0.5:
    low = Vector2i(mini(low.x,x),mini(low.y,y))
    high = Vector2i(maxi(high.x,x),maxi(high.y,y))
 return Rect2i(low,high-low+Vector2i.ONE)
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
 var player: Node = battle.get_node("Enemy")
 var enemy: Node = battle.get_node("Player")
 player.ai_enabled = false
 player.ai_profile = null
 enemy.ai_enabled = false
 enemy.ai_profile = null
 enemy.set_physics_process(false)
 var sprite: AnimatedSprite2D = player.animated_character_sprite
 var frames: SpriteFrames = sprite.sprite_frames
 var original_scale := sprite.scale
 var original_anchor := sprite.position
 var texture_path := "res://assets/characters/enemy01/animations/unified_down_recovery_v8/motion_atlas.png"
 for clip in [&"knockdown",&"ko",&"stand_up",&"down",&"getup"]:
  check(frames.has_animation(clip),"reaction exists "+String(clip))
  for frame in range(frames.get_frame_count(clip)):
   var tex: AtlasTexture = frames.get_frame_texture(clip,frame)
   check(tex.atlas.resource_path == texture_path,"uses corrected art %s/%s"%[clip,frame])
   var bounds := opaque_bounds(tex.get_image())
   check(bounds.position.x>0 and bounds.end.x<400 and bounds.position.y>0,"no clipped reaction %s/%s"%[clip,frame])
   check(absi(bounds.end.y-261)<=3,"shared ground anchor %s/%s"%[clip,frame])
 var prone: AtlasTexture = frames.get_frame_texture(&"down",0)
 var getup_first: AtlasTexture = frames.get_frame_texture(&"stand_up",0)
 check(prone.region == getup_first.region and prone.atlas == getup_first.atlas,"down/getup reuse exact prone frame")
 var prone_bounds := opaque_bounds(prone.get_image())
 check(prone_bounds.size.x >= 265 and prone_bounds.size.x <= 271,"prone remains full adult scale without stretched legs")
 print("CRUSHER_DOWN_PRONE_BOUNDS ",prone_bounds)
 # Real down -> wake-up flow, with both mirrored facings, retains scale.
 for facing in [1.0,-1.0]:
  player.reset_knockdown_state()
  player._cancel_current_action()
  player.reset_attack_state()
  player.current_hp = player.max_hp
  player.is_invincible = false
  player.is_hit = false
  player.position = Vector2(500,520)
  player.facing_direction = facing
  enemy.position = Vector2(850,520) if facing>0 else Vector2(150,520)
  player.last_knockdown_animation = &"knockdown"
  player.enter_knockback(enemy,Vector2(50,-100))
  var saw_down := false
  var saw_getup := false
  for i in range(150):
   await physics_frame
   saw_down = saw_down or player.knockdown_state == &"KNOCKDOWN"
   saw_getup = saw_getup or player.knockdown_state == &"GET_UP"
   check(sprite.scale.is_equal_approx(original_scale),"runtime down scale "+str(facing))
   check(sprite.position.is_equal_approx(original_anchor),"runtime down anchor "+str(facing))
  check(saw_down and saw_getup and player.knockdown_state == &"","complete recovery flow "+str(facing))
  check(player.hurt_box.monitorable,"wake-up restores hurtbox")
 print("CRUSHER_DOWN_MOTION_CHECK failures=%s"%[failures])
 root.get_node("AudioManager").stop_bgm()
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await create_timer(1.0).timeout
 quit(0 if failures.is_empty() else 1)
