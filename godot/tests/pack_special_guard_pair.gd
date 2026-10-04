extends SceneTree
func _initialize():
 var src=Image.load_from_file(ProjectSettings.globalize_path("res://../art/dedicated_pair_v1/sources/special_guard_strip.png"))
 for actor in ["akky","crusher"]:
  var cell=Vector2i(320,224) if actor=="akky" else Vector2i(400,280)
  var anchor=Vector2i(160,208) if actor=="akky" else Vector2i(200,260)
  var factor=.36 if actor=="akky" else .47
  var root_x=265 if actor=="akky" else 795
  var atlas=Image.create(cell.x*3,cell.y,false,Image.FORMAT_RGBA8)
  for i in range(3):
   var region=Rect2i(0 if actor=="akky" else 512,i*512,512,512)
   var crop=src.get_region(region)
   var used=visible_rect(crop)
   crop=crop.get_region(used)
   crop.resize(roundi(used.size.x*factor),roundi(used.size.y*factor),Image.INTERPOLATE_LANCZOS)
   var pos=anchor-Vector2i(roundi((root_x-region.position.x-used.position.x)*factor),crop.get_height())
   if pos.x<0 or pos.y<0 or pos.x+crop.get_width()>cell.x:
    push_error("Special guard clipped "+actor+str(i)); quit(1); return
   atlas.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i(i*cell.x,0)+pos)
  atlas.save_png(ProjectSettings.globalize_path("res://assets/characters/dedicated_pair_v1/"+actor+"_special_guard.png"))
 print("SPECIAL_GUARD_PACK_OK")
 quit()
func visible_rect(img: Image) -> Rect2i:
 var low=img.get_size()
 var high=Vector2i(-1,-1)
 for y in range(img.get_height()):
  for x in range(img.get_width()):
   if img.get_pixel(x,y).a>=.5:
    low.x=mini(low.x,x); low.y=mini(low.y,y)
    high.x=maxi(high.x,x); high.y=maxi(high.y,y)
 return Rect2i(low,high-low+Vector2i.ONE).grow(2).intersection(Rect2i(Vector2i.ZERO,img.get_size()))
