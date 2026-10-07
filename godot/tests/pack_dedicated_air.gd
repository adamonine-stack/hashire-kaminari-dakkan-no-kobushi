extends SceneTree
func _initialize():
 var folder := "res://assets/characters/dedicated_pair_v1/"
 var src := Image.load_from_file(ProjectSettings.globalize_path("res://../art/dedicated_pair_v1/sources/air_strip.png"))
 var cuts := [0,443,872,1325,1774]
 for who in ["crusher","akky"]:
  var cell := Vector2i(400,280) if who=="crusher" else Vector2i(320,224)
  var anchor := Vector2i(200,260) if who=="crusher" else Vector2i(160,208)
  var atlas := Image.create(cell.x*4,cell.y,false,Image.FORMAT_RGBA8)
  var roots := [225,680,1120,1560] if who=="crusher" else [240,680,1120,1560]
  var foot := 868 if who=="crusher" else 430
  var factor := .52 if who=="crusher" else .44
  for i in range(4):
   var y0 := 425 if who=="crusher" else 0
   var region := Rect2i(cuts[i],y0,cuts[i+1]-cuts[i],src.get_height()-425 if who=="crusher" else 425)
   var crop := src.get_region(region)
   var used := visible_rect(crop)
   region = Rect2i(region.position+used.position,used.size)
   crop = src.get_region(region)
   var root_x: int = roots[i]-region.position.x
   if who=="crusher":
    crop.flip_x()
    root_x = region.size.x-root_x
   crop.resize(roundi(region.size.x*factor),roundi(region.size.y*factor),Image.INTERPOLATE_LANCZOS)
   var pos := anchor-Vector2i(roundi(root_x*factor),roundi((foot-region.position.y)*factor))
   if pos.x<0 or pos.y<0 or pos.x+crop.get_width()>cell.x or pos.y+crop.get_height()>cell.y:
    push_error("Pose clips %s/%s %s"%[who,i,pos])
    quit(1)
    return
   atlas.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i(i*cell.x,0)+pos)
  atlas.save_png(ProjectSettings.globalize_path(folder+who+"_air.png"))
 print("DEDICATED_AIR_PACK_OK")
 quit()

func visible_rect(img: Image) -> Rect2i:
 var low := img.get_size()
 var high := Vector2i(-1,-1)
 for y in range(img.get_height()):
  for x in range(img.get_width()):
   if img.get_pixel(x,y).a>=.25:
    low.x = mini(low.x,x)
    low.y = mini(low.y,y)
    high.x = maxi(high.x,x)
    high.y = maxi(high.y,y)
 return Rect2i(low,high-low+Vector2i.ONE).grow(2).intersection(Rect2i(Vector2i.ZERO,img.get_size()))
