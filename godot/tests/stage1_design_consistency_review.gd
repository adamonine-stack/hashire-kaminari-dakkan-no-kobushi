extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var viewport:=SubViewport.new()
 viewport.size=Vector2i(400,320)
 viewport.transparent_bg=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var folder:=ProjectSettings.globalize_path("res://../audit_evidence/stage1_design_consistency")
 DirAccess.make_dir_recursive_absolute(folder)
 var rows:Array[Dictionary]=[]
 for entry in [["akky","fighters/ally_balance"],["gou","fighters/ally_power"],["seiya","fighters/ally_speed"],["crusher","enemies/enemy_01_standard"]]:
  var actor:Node2D=load("res://scenes/Player.tscn").instantiate()
  viewport.add_child(actor)
  actor.set_physics_process(false)
  actor.position=Vector2(200,300)
  actor.apply_fighter_definition(load("res://data/"+entry[1]+".tres"))
  actor.shadow_sprite.visible=false
  var sprite:AnimatedSprite2D=actor.animated_character_sprite
  var clips:Array[String]=["idle_prebattle" if entry[0]=="seiya" else "idle","punch_1","punch_2","kick_1","crouch_kick","jump_punch","jump_kick","guard","throw_start","throw_hold","throw_release","damage_heavy","grabbed","thrown","knockdown","get_up"]
  if entry[0]=="akky":
   clips[8]="akky_throw_neutral_start"
   clips[9]="directional_throw_hold"
   clips[10]="akky_throw_neutral_release"
   clips[12]="crusher_throw_held"
   clips[13]="crusher_throw_neutral_air"
  if entry[0]=="crusher":
   clips[15]="stand_up"
   clips[8]="crusher_throw_start"
   clips[9]="crusher_throw_hold"
   clips[10]="crusher_throw_down_release"
  var sheet:=Image.create(1600,1280,false,Image.FORMAT_RGBA8)
  sheet.fill(Color(.18,.2,.23,1))
  var baseline:=sprite.scale
  for index in range(clips.size()):
   var clip:=StringName(clips[index])
   if not sprite.sprite_frames.has_animation(clip):
    rows.append({"actor":entry[0],"clip":clip,"missing":true})
    continue
   actor._play_visual_animation(clip,true)
   sprite.pause()
   var contact:=3 if index==3 and entry[0] in ["akky","gou","seiya"] else (1 if index in [1,3] and entry[0]=="crusher" else 2)
   sprite.frame=0 if index in [0,8,9,10] else mini(contact,sprite.sprite_frames.get_frame_count(clip)-1)
   await process_frame
   RenderingServer.force_draw(false)
   var img:=viewport.get_texture().get_image()
   var file: String="%s_%02d_%s.png"%[entry[0],index,clip]
   img.save_png(folder.path_join(file))
   sheet.blend_rect(img,Rect2i(0,0,400,320),Vector2i(index%4*400,index/4*320))
   var tex:Texture2D=sprite.sprite_frames.get_frame_texture(clip,sprite.frame)
   rows.append({"actor":entry[0],"clip":clip,"frame":sprite.frame,"file":file,"source":tex.atlas.resource_path if tex is AtlasTexture else tex.resource_path,"visible":str(img.get_used_rect()),"fixed_scale":sprite.scale.is_equal_approx(baseline)})
  sheet.save_png(folder.path_join(entry[0]+"_review.png"))
  actor.queue_free()
  await process_frame
 var output:=FileAccess.open(folder.path_join("inventory.json"),FileAccess.WRITE)
 output.store_string(JSON.stringify(rows,"  "))
 print("STAGE1_DESIGN_REVIEW poses=",rows.size())
 viewport.queue_free()
 await process_frame
 quit()
