extends SceneTree
func _initialize():
 var source := Image.load_from_file(ProjectSettings.globalize_path("res://../art/dedicated_pair_v1/sources/air_guard_pair.png"))
 var half := source.get_size()/2
 for actor in ["akky","crusher"]:
  var cell := Vector2i(320,224) if actor=="akky" else Vector2i(400,280)
  var anchor := Vector2i(160,208) if actor=="akky" else Vector2i(200,260)
  var factor := .28 if actor=="akky" else .4
  var row := 0 if actor=="akky" else 1
  var atlas := Image.create(cell.x*2,cell.y,false,Image.FORMAT_RGBA8)
  for i in range(2):
   var crop := source.get_region(Rect2i(Vector2i(i*half.x,row*half.y),half))
   crop.resize(roundi(half.x*factor),roundi(half.y*factor),Image.INTERPOLATE_LANCZOS)
   var pos := anchor-Vector2i(roundi(318*factor),roundi(580*factor))
   atlas.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i(i*cell.x,0)+pos)
  atlas.save_png(ProjectSettings.globalize_path("res://assets/characters/dedicated_pair_v1/"+actor+"_air_guard.png"))
 print("AIR_GUARD_PACK_OK")
 quit()
