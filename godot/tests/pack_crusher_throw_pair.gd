extends SceneTree
func _initialize():
 var folder := "res://assets/characters/dedicated_pair_v1/"
 for kind in ["grab","neutral","forward"]:
  var src := Image.load_from_file(ProjectSettings.globalize_path("res://../art/dedicated_pair_v1/sources/crusher_"+("grab_strip" if kind=="grab" else "throw_"+kind+"_strip")+".png"))
  var rows := [0,473,930] if kind=="grab" else ([0,550,1050] if kind=="neutral" else [0,532,1024])
  var splits := [500,500] if kind=="grab" else ([570,575,500] if kind=="neutral" else [800,800])
  var feet := [461,921] if kind=="grab" else ([530,1046,1507] if kind=="neutral" else [530,975])
  for who in ["crusher","akky"]:
   var cell := Vector2i(400,280) if who=="crusher" else Vector2i(320,224)
   var anchor := Vector2i(200,260) if who=="crusher" else Vector2i(160,208)
   var factor := (.48 if who=="crusher" else .42) if kind=="grab" else ((.42 if who=="crusher" else .36) if kind=="neutral" else (.38 if who=="crusher" else .30))
   var root_x := (200 if who=="crusher" else 700) if kind=="grab" else ((220 if who=="crusher" else 800) if kind=="neutral" else (370 if who=="crusher" else 1230))
   var atlas := Image.create(cell.x*(rows.size()-1),cell.y,false,Image.FORMAT_RGBA8)
   for i in range(rows.size()-1):
    var x0: int = 0 if who=="crusher" else splits[i]
    var region := Rect2i(x0,rows[i],splits[i] if who=="crusher" else src.get_width()-splits[i],rows[i+1]-rows[i])
    var crop := src.get_region(region)
    var used := visible_rect(crop)
    region = Rect2i(region.position+used.position,used.size)
    crop = src.get_region(region)
    var local_root: int = root_x-region.position.x
    if who=="akky":
     crop.flip_x()
     local_root = region.size.x-local_root
    crop.resize(roundi(region.size.x*factor),roundi(region.size.y*factor),Image.INTERPOLATE_LANCZOS)
    var pos := anchor-Vector2i(roundi(local_root*factor),roundi((feet[i]-region.position.y)*factor))
    if pos.x<0 or pos.y<0 or pos.x+crop.get_width()>cell.x or pos.y+crop.get_height()>cell.y:
     push_error("Throw clips %s/%s/%s %s"%[kind,who,i,pos])
     quit(1)
     return
    atlas.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i(i*cell.x,0)+pos)
   atlas.save_png(ProjectSettings.globalize_path(folder+who+"_crusher_throw_"+kind+".png"))
 print("CRUSHER_THROW_PAIR_PACK_OK")
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
