extends SceneTree
var failures:Array[String]=[]
func _initialize(): call_deferred("run")
func run():
 var viewport:=SubViewport.new()
 viewport.size=Vector2i(400,320)
 viewport.transparent_bg=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var folder:=ProjectSettings.globalize_path("res://../audit_evidence/stage1_heroes_received_review")
 DirAccess.make_dir_recursive_absolute(folder)
 var rows:Array[Dictionary]=[]
 for entry in [["gou","ally_power","received_v13","idle"],["seiya","ally_speed","slim_received_v15","idle_prebattle"]]:
  var actor:Node2D=load("res://scenes/Player.tscn").instantiate()
  viewport.add_child(actor)
  actor.set_physics_process(false)
  actor.position=Vector2(200,300)
  actor.apply_fighter_definition(load("res://data/fighters/"+entry[1]+".tres"))
  actor.shadow_sprite.visible=false
  var sprite:AnimatedSprite2D=actor.animated_character_sprite
  var baseline:=sprite.scale
  for facing in [1,-1]:
   var sheet:=Image.create(2000,1600,false,Image.FORMAT_RGBA8)
   sheet.fill(Color(.18,.2,.23,1))
   var index:=0
   var clips:Array=[entry[3],"damage_high","damage_low","launch_hit","air_hit","knockback","ground_impact","ground_bounce","wall_hit","wall_fall"]
   for clip in clips:
    for frame in range(1 if index==0 else sprite.sprite_frames.get_frame_count(clip)):
     actor._play_visual_animation(StringName(clip),true)
     sprite.pause()
     sprite.frame=frame
     sprite.flip_h=facing<0
     await process_frame
     RenderingServer.force_draw(false)
     var img:=viewport.get_texture().get_image()
     var tex:Texture2D=sprite.sprite_frames.get_frame_texture(clip,frame)
     if not sprite.scale.is_equal_approx(baseline): failures.append("scale "+clip)
     if img.get_used_rect().size==Vector2i.ZERO: failures.append("empty "+clip)
     if index>0 and (not tex is AtlasTexture or not entry[2] in tex.atlas.resource_path): failures.append("source "+clip)
     sheet.blend_rect(img,Rect2i(0,0,400,320),Vector2i(index%5*400,index/5*320))
     rows.append({"hero":entry[0],"clip":clip,"frame":frame,"facing":facing,"source":tex.atlas.resource_path if tex is AtlasTexture else tex.resource_path,"scale":str(sprite.scale),"visible":str(img.get_used_rect())})
     index+=1
   sheet.save_png(folder.path_join(entry[0]+("_right.png" if facing>0 else "_left.png")))
  actor.queue_free()
  await process_frame
 var file:=FileAccess.open(folder.path_join("inventory.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(rows,"  "))
 print("STAGE1_HEROES_RECEIVED_REVIEW poses=",rows.size()," failures=",failures)
 quit(0 if failures.is_empty() else 1)
