extends SceneTree
var rows: Array[Dictionary] = []
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var viewport := SubViewport.new()
 viewport.size = Vector2i(384,288)
 viewport.transparent_bg = true
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var actor: Node2D = load("res://scenes/Player.tscn").instantiate()
 viewport.add_child(actor)
 actor.set_physics_process(false)
 actor.position = Vector2(192,278)
 actor.apply_fighter_definition(load("res://data/fighters/ally_speed.tres"))
 actor.shadow_sprite.visible = false
 var sprite: AnimatedSprite2D = actor.animated_character_sprite
 var output_name := "seiya_design_after" if "--after" in OS.get_cmdline_user_args() else "seiya_design_before"
 var folder := ProjectSettings.globalize_path("res://../audit_evidence/"+output_name)
 DirAccess.make_dir_recursive_absolute(folder)
 var seen := {}
 for clip in sprite.sprite_frames.get_animation_names():
  actor._play_visual_animation(clip,true)
  sprite.pause()
  for frame in range(sprite.sprite_frames.get_frame_count(clip)):
   sprite.frame = frame
   var tex: Texture2D = sprite.sprite_frames.get_frame_texture(clip,frame)
   var key: String = (tex.atlas.resource_path+str(tex.region)) if tex is AtlasTexture else str(tex.get_rid())
   if seen.has(key): continue
   seen[key]=true
   await process_frame
   RenderingServer.force_draw(false)
   var img := viewport.get_texture().get_image()
   var file := "%03d_%s_%02d.png" % [rows.size(),clip,frame]
   img.save_png(folder.path_join(file))
   var prop: Node = actor.get_node("SeiyaProportions")
   rows.append({"file":file,"clip":clip,"frame":frame,"texture":key,"head":str(prop.head_bounds),"body":str(img.get_used_rect())})
 for page in range(ceili(rows.size()/20.0)):
  var sheet := Image.create(384*5,320*4,false,Image.FORMAT_RGBA8)
  sheet.fill(Color(0.15,0.17,0.20,1))
  for slot in range(20):
   var index := page*20+slot
   if index>=rows.size(): break
   var img := Image.load_from_file(folder.path_join(rows[index].file))
   sheet.blend_rect(img,Rect2i(0,0,384,288),Vector2i(slot%5*384,slot/5*320))
  sheet.save_png(folder.path_join("page_%02d.png"%page))
 var out := FileAccess.open(folder.path_join("inventory.json"),FileAccess.WRITE)
 out.store_string(JSON.stringify(rows,"  "))
 print("SEIYA_DESIGN_AUDIT unique_frames=",rows.size())
 viewport.queue_free()
 await process_frame
 quit()
