extends SceneTree
func _initialize():
 for kind in ["wall_hit","ground_bounce"]:
  var src=Image.load_from_file(ProjectSettings.globalize_path("res://../art/dedicated_pair_v1/sources/"+kind+"_strip.png"))
  var split=627 if kind=="wall_hit" else 640
  var rows=[0,655,1254] if kind=="wall_hit" else [0,800,1254]
  for actor in ["akky","crusher"]:
   var cell=Vector2i(320,224) if actor=="akky" else Vector2i(400,280)
   var anchor=Vector2i(160,208) if actor=="akky" else Vector2i(200,260)
   var factor=(.29 if actor=="akky" else .38) if kind=="wall_hit" else (.36 if actor=="akky" else .47)
   var root_x=(360 if actor=="akky" else 1000) if kind=="wall_hit" else (320 if actor=="akky" else 950)
   var atlas=Image.create(cell.x*2,cell.y,false,Image.FORMAT_RGBA8)
   for i in range(2):
    var x=0 if actor=="akky" else split
    var region=Rect2i(x,rows[i],split if actor=="akky" else src.get_width()-split,rows[i+1]-rows[i])
    var crop=src.get_region(region)
    var used=visible_rect(crop)
    crop=crop.get_region(used)
    crop.resize(roundi(used.size.x*factor),roundi(used.size.y*factor),Image.INTERPOLATE_LANCZOS)
    var pos=anchor-Vector2i(roundi((root_x-region.position.x-used.position.x)*factor),crop.get_height())
    if pos.x<0 or pos.y<0 or pos.x+crop.get_width()>cell.x:
     push_error("Reaction clipped "+actor+kind+str(i)); quit(1); return
    atlas.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i(i*cell.x,0)+pos)
   atlas.save_png(ProjectSettings.globalize_path("res://assets/characters/dedicated_pair_v1/"+actor+"_"+kind+".png"))
 print("WALL_BOUNCE_PACK_OK")
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
