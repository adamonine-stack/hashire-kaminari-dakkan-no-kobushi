extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var viewport:=SubViewport.new()
 viewport.size=Vector2i(400,320)
 viewport.transparent_bg=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var folder:=ProjectSettings.globalize_path("res://../audit_evidence/stage1_full_motion_inventory")
 DirAccess.make_dir_recursive_absolute(folder)
 var rows:Array[Dictionary]=[]
 var failures:Array[String]=[]
 for entry in [["akky","fighters/ally_balance"],["gou","fighters/ally_power"],["seiya","fighters/ally_speed"],["crusher","enemies/enemy_01_standard"]]:
  var actor:Node2D=load("res://scenes/Player.tscn").instantiate()
  viewport.add_child(actor)
  actor.set_physics_process(false)
  actor.position=Vector2(200,300)
  actor.apply_fighter_definition(load("res://data/"+entry[1]+".tres"))
  actor.shadow_sprite.visible=false
  var sprite:AnimatedSprite2D=actor.animated_character_sprite
  var clips:Array[String]=[]
  for clip in sprite.sprite_frames.get_animation_names():
   clips.append(String(clip))
  clips.sort()
  var sheet:=Image.create(1600,ceili(clips.size()/4.0)*320,false,Image.FORMAT_RGBA8)
  sheet.fill(Color(.18,.2,.23,1))
  var baseline:=sprite.scale
  for index in range(clips.size()):
   var clip:=StringName(clips[index])
   if not sprite.sprite_frames.has_animation(clip):
    rows.append({"actor":entry[0],"clip":clip,"missing":true})
    continue
   for frame in range(sprite.sprite_frames.get_frame_count(clip)):
    var texture:Texture2D=sprite.sprite_frames.get_frame_texture(clip,frame)
    if texture == null: failures.append(entry[0]+"/"+clip+" missing texture"); continue
    if texture is AtlasTexture and not Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region):
     failures.append(entry[0]+"/"+clip+" atlas bounds")
   actor._play_visual_animation(clip,true)
   sprite.pause()
   var contact:=sprite.sprite_frames.get_frame_count(clip)/2
   sprite.frame=mini(contact,sprite.sprite_frames.get_frame_count(clip)-1)
   await process_frame
   RenderingServer.force_draw(false)
   var img:=viewport.get_texture().get_image()
   var file: String="%s_%02d_%s.png"%[entry[0],index,clip]
   img.save_png(folder.path_join(file))
   sheet.blend_rect(img,Rect2i(0,0,400,320),Vector2i(index%4*400,index/4*320))
   var tex:Texture2D=sprite.sprite_frames.get_frame_texture(clip,sprite.frame)
   if not sprite.scale.is_equal_approx(baseline): failures.append(entry[0]+"/"+clip+" scale changed")
   rows.append({"actor":entry[0],"clip":clip,"frame":sprite.frame,"file":file,"source":tex.atlas.resource_path if tex is AtlasTexture else tex.resource_path,"visible":str(img.get_used_rect()),"fixed_scale":sprite.scale.is_equal_approx(baseline)})
  sheet.save_png(folder.path_join(entry[0]+"_review.png"))
  actor.queue_free()
  await process_frame
 var output:=FileAccess.open(folder.path_join("inventory.json"),FileAccess.WRITE)
 output.store_string(JSON.stringify(rows,"  "))
 print("STAGE1_FULL_MOTION_INVENTORY poses=",rows.size()," failures=",failures)
 viewport.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
