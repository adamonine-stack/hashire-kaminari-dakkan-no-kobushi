extends SceneTree
func _initialize():
 var src := Image.load_from_file(ProjectSettings.globalize_path("res://../art/dedicated_pair_v1/sources/dive_kick_strip.png"))
 var rows := [0,520,1090,1536]
 var feet := [490,1075,1510]
 for actor in ["akky","crusher"]:
  var cell := Vector2i(320,224) if actor=="akky" else Vector2i(400,280)
  var anchor := Vector2i(160,208) if actor=="akky" else Vector2i(200,260)
  var factor := .25 if actor=="akky" else .31
  var root_x := 280 if actor=="akky" else 790
  var atlas := Image.create(cell.x*3,cell.y,false,Image.FORMAT_RGBA8)
  for i in range(3):
   var x0 := 0 if actor=="akky" else 550
   var region := Rect2i(x0,rows[i],550 if actor=="akky" else src.get_width()-550,rows[i+1]-rows[i])
   var used := visible_rect(src.get_region(region))
   region = Rect2i(region.position+used.position,used.size)
   var crop := src.get_region(region)
   crop.resize(roundi(region.size.x*factor),roundi(region.size.y*factor),Image.INTERPOLATE_LANCZOS)
   var pos := anchor-Vector2i(roundi((root_x-region.position.x)*factor),roundi((feet[i]-region.position.y)*factor))
   if pos.x<0 or pos.y<0 or pos.x+crop.get_width()>cell.x or pos.y+crop.get_height()>cell.y:
    push_error("Dive crop outside cell %s/%s"%[actor,i])
    quit(1)
    return
   atlas.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i(i*cell.x,0)+pos)
  atlas.save_png(ProjectSettings.globalize_path("res://assets/characters/dedicated_pair_v1/"+actor+"_dive_kick.png"))
 print("DIVE_KICK_PACK_OK")
 quit()
func visible_rect(img: Image) -> Rect2i:
 var low := img.get_size()
 var high := Vector2i(-1,-1)
 for y in range(img.get_height()):
  for x in range(img.get_width()):
   if img.get_pixel(x,y).a>=.5:
    low.x=mini(low.x,x)
    low.y=mini(low.y,y)
    high.x=maxi(high.x,x)
    high.y=maxi(high.y,y)
 return Rect2i(low,high-low+Vector2i.ONE).grow(2).intersection(Rect2i(Vector2i.ZERO,img.get_size()))
