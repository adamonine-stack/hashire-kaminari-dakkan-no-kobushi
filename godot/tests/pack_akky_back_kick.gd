extends SceneTree
func _initialize():
 var folder := "res://assets/characters/dedicated_pair_v1/"
 for kind in ["back"]:
  var src := Image.load_from_file(ProjectSettings.globalize_path("res://../art/dedicated_pair_v1/sources/akky_"+kind+"_kick_strip.png"))
  var atlas := Image.create(1280,224,false,Image.FORMAT_RGBA8)
  var rects := [Rect2i(0,0,627,627),Rect2i(627,0,627,627),Rect2i(0,627,627,627),Rect2i(627,627,627,627)]
  if kind=="back":
   rects[2] = Rect2i(0,627,690,627)
   rects[3] = Rect2i(690,627,564,627)
  var roots := [318,945,318,945] if kind=="forward" else [318,945,318,980]
  var factor := .28
  for i in range(4):
   var region: Rect2i = rects[i]
   var crop := src.get_region(region)
   var used := visible_rect(crop)
   var foot: int = used.end.y-2
   region = Rect2i(region.position+used.position,used.size)
   crop = src.get_region(region)
   var root_x: int = roots[i]-region.position.x
   crop.resize(roundi(region.size.x*factor),roundi(region.size.y*factor),Image.INTERPOLATE_LANCZOS)
   var pos := Vector2i(160-roundi(root_x*factor),208-roundi((foot-used.position.y)*factor))
   if pos.x<0 or pos.y<0 or pos.x+crop.get_width()>320 or pos.y+crop.get_height()>224:
    push_error("Kick clips %s/%s %s"%[kind,i,pos])
    quit(1)
    return
   atlas.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i(i*320,0)+pos)
  atlas.save_png(ProjectSettings.globalize_path(folder+"akky_"+kind+"_kick.png"))
 print("AKKY_DIRECTION_KICK_PACK_OK")
 quit()
func visible_rect(img: Image) -> Rect2i:
 var low := img.get_size()
 var high := Vector2i(-1,-1)
 for y in range(img.get_height()):
  for x in range(img.get_width()):
   if img.get_pixel(x,y).a>=.5:
    low.x = mini(low.x,x)
    low.y = mini(low.y,y)
    high.x = maxi(high.x,x)
    high.y = maxi(high.y,y)
 return Rect2i(low,high-low+Vector2i.ONE).grow(2).intersection(Rect2i(Vector2i.ZERO,img.get_size()))
