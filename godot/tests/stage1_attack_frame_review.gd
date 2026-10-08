extends SceneTree
var failures: Array[String] = []
var rows: Array[Dictionary] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
 if not ok:
  failures.append(label)
  push_error(label)
func run() -> void:
 var viewport := SubViewport.new()
 viewport.size = Vector2i(400,320)
 viewport.transparent_bg = true
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var native := DisplayServer.get_name() != "headless"
 var folder := ProjectSettings.globalize_path("res://../audit_evidence/stage1_attack_frames")
 DirAccess.make_dir_recursive_absolute(folder)
 for entry in [["akky","fighters/ally_balance"],["crusher","enemies/enemy_01_standard"],["gou","fighters/ally_power"],["seiya","fighters/ally_speed"]]:
  var actor: Node = load("res://scenes/Player.tscn").instantiate()
  viewport.add_child(actor)
  actor.set_physics_process(false)
  actor.position = Vector2(200,300)
  var definition: Resource = load("res://data/"+entry[1]+".tres")
  actor.apply_character_data(definition)
  actor.shadow_sprite.visible = false
  var sprite: AnimatedSprite2D = actor.animated_character_sprite
  var scale := sprite.scale
  var origin := sprite.position
  var moves: Array[Resource] = []
  moves.assign(definition.attack_sequence)
  for move in [definition.air_punch_down_attack, definition.air_kick_attack, definition.crouch_kick_sweep_attack, actor.character_special_data]:
   if move != null: moves.append(move)
  var clips: Dictionary = {"idle": {"contact":0,"moves":["standing reference"]}}
  for move in moves:
   if String(move.attack_type) == "throw": continue
   var clip := String(move.animation_name)
   if clip.is_empty(): continue
   if not clips.has(clip): clips[clip] = {"contact":int(move.contact_start_frame),"moves":[]}
   clips[clip].moves.append(String(move.attack_id))
   if bool(move.is_special):
    for extra in [String(move.special_startup_animation),String(move.special_finish_animation)]:
     if not extra.is_empty() and not clips.has(extra): clips[extra] = {"contact":-1,"moves":[String(move.attack_id)]}
    if bool(move.somersault_sidekick): clips["seiya_two_sidekick"] = {"contact":1,"moves":[String(move.attack_id)]}
  for clip in clips:
   check(sprite.sprite_frames.has_animation(clip), entry[0]+" missing "+clip)
   if not sprite.sprite_frames.has_animation(clip): continue
   var count := sprite.sprite_frames.get_frame_count(clip)
   var contact: int = int(clips[clip].contact)
   check(contact < count, entry[0]+" contact frame bounds "+clip)
   for facing in [1,-1]:
    actor.facing_direction = facing
    actor._set_visual_facing()
    actor._play_visual_animation(StringName(clip),true)
    sprite.pause()
    for frame in range(count):
     sprite.frame = frame
     check(sprite.scale.is_equal_approx(scale),entry[0]+" scale "+clip)
     check(sprite.position.is_equal_approx(origin),entry[0]+" origin "+clip)
     check(sprite.flip_h == (facing < 0),entry[0]+" facing "+clip)
     var texture: Texture2D = sprite.sprite_frames.get_frame_texture(clip,frame)
     check(texture != null,entry[0]+" texture "+clip)
     if texture == null: continue
     if texture is AtlasTexture:
      check(Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region),entry[0]+" atlas bounds "+clip)
     var file := "%s_%s_%s_%02d.png"%[entry[0],"right" if facing>0 else "left",clip,frame]
     rows.append({"actor":entry[0],"clip":clip,"frame":frame,"facing":facing,"contact_frame":contact,"moves":clips[clip].moves,"source":texture.atlas.resource_path if texture is AtlasTexture else texture.resource_path,"file":file})
     if native:
      await process_frame
      RenderingServer.force_draw(false)
      check(viewport.get_texture().get_image().save_png(folder.path_join(file)) == OK,"save "+file)
  actor.queue_free()
  await process_frame
 var output := FileAccess.open(folder.path_join("inventory.json" if native else "headless_inventory.json"),FileAccess.WRITE)
 output.store_string(JSON.stringify(rows,"  "))
 print("STAGE1_ATTACK_FRAME_REVIEW frames=%d failures=%s"%[rows.size(),failures])
 viewport.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
