extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var viewport:=SubViewport.new()
 viewport.size=Vector2i(400,320)
 viewport.transparent_bg=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var folder:=ProjectSettings.globalize_path("res://../audit_evidence/crusher_victim_forward_review")
 DirAccess.make_dir_recursive_absolute(folder)
 var rows:Array[Dictionary]=[]
 for entry in [["crusher","enemies/enemy_01_standard"]]:
  var actor:Node2D=load("res://scenes/Player.tscn").instantiate()
  viewport.add_child(actor)
  actor.set_physics_process(false)
  actor.position=Vector2(200,300)
  actor.apply_fighter_definition(load("res://data/"+entry[1]+".tres"))
  actor.shadow_sprite.visible=false
  var sprite:AnimatedSprite2D=actor.animated_character_sprite
  var clips:Array[String]=["idle","throw_victim_forward_air","throw_victim_forward_air"]
  var sheet:=Image.create(1600,640,false,Image.FORMAT_RGBA8)
  sheet.fill(Color(.18,.2,.23,1))
  var baseline:=sprite.scale
  for index in range(5):
   var clip:=StringName(clips[index/2])
   if not sprite.sprite_frames.has_animation(clip):
    rows.append({"actor":entry[0],"clip":clip,"missing":true})
    continue
   actor._play_visual_animation(clip,true)
   sprite.pause()
   sprite.frame=0 if index<2 else (index-2)%3
   await process_frame
   RenderingServer.force_draw(false)
   var img:=viewport.get_texture().get_image()
   var file: String="%s_%02d_%s.png"%[entry[0],index,clip]
   img.save_png(folder.path_join(file))
   sheet.blend_rect(img,Rect2i(0,0,400,320),Vector2i(index%4*400,index/4*320))
   var tex:Texture2D=sprite.sprite_frames.get_frame_texture(clip,sprite.frame)
   assert(sprite.scale.is_equal_approx(baseline), "motion changed actor scale")
   if index >= 2:
    assert(tex is AtlasTexture and "unified_victim_forward_v5" in tex.atlas.resource_path, "old victim atlas still selected")
   rows.append({"actor":entry[0],"clip":clip,"frame":sprite.frame,"file":file,"source":tex.atlas.resource_path if tex is AtlasTexture else tex.resource_path,"visible":str(img.get_used_rect()),"fixed_scale":sprite.scale.is_equal_approx(baseline)})
  sheet.save_png(folder.path_join(entry[0]+"_review.png"))
  actor.queue_free()
  await process_frame
 var output:=FileAccess.open(folder.path_join("inventory.json"),FileAccess.WRITE)
 output.store_string(JSON.stringify(rows,"  "))
 print("CRUSHER_VICTIM_FORWARD_REVIEW poses=",rows.size())
 viewport.queue_free()
 await process_frame
 quit()
