extends SceneTree
func _initialize():
 var folder := "res://assets/characters/dedicated_pair_v1/"
 var src := Image.load_from_file(ProjectSettings.globalize_path("res://../art/dedicated_pair_v1/sources/crusher_launcher_strip.png"))
 var atlas := Image.create(1600,280,false,Image.FORMAT_RGBA8)
 var factor := .36
 for i in range(4):
  var source_pos := Vector2i((i%2)*627,(i/2)*627)
  var crop := src.get_region(Rect2i(source_pos,Vector2i(627,627)))
  crop.resize(roundi(627*factor),roundi(627*factor),Image.INTERPOLATE_LANCZOS)
  var pos := Vector2i(i*400+200-roundi(318*factor),260-roundi(588*factor))
  if pos.y<0 or pos.y+crop.get_height()>280:
   push_error("Launcher crop outside cell")
   quit(1)
   return
  atlas.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),pos)
 atlas.save_png(ProjectSettings.globalize_path(folder+"crusher_launcher.png"))
 print("CRUSHER_LAUNCHER_PACK_OK")
 quit()
