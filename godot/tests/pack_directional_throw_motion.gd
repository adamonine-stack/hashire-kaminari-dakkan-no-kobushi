extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
 var folder := "res://assets/characters/directional_throw_v2/"
 var specs: Array = JSON.parse_string(FileAccess.get_file_as_string(folder+"packing.json"))
 var akky := Image.create(960,896,false,Image.FORMAT_RGBA8)
 var crusher := Image.create(1200,1120,false,Image.FORMAT_RGBA8)
 for row in range(specs.size()):
  var spec: Dictionary = specs[row]
  var src := Image.load_from_file(ProjectSettings.globalize_path(folder+"sources/"+spec.move+".png"))
  var cuts: Array = spec.cuts
  for i in range(3):
   pack(akky,src,Rect2i(int(cuts[i]),0,int(cuts[i+1]-cuts[i]),int(spec.split)),int(spec.akky_roots[i]),int(spec.akky_foot),float(spec.akky_scale),Vector2i(320,224),Vector2i(160,208),false,row*3+i)
   pack(crusher,src,Rect2i(int(cuts[i]),int(spec.split),int(cuts[i+1]-cuts[i]),int(spec.height-spec.split)),int(spec.crusher_roots[i]),int(spec.crusher_foot),float(spec.crusher_scale),Vector2i(400,280),Vector2i(200,260),true,row*3+i)
 if not failures.is_empty():
  push_error(str(failures))
  quit(1)
  return
 assert(akky.save_png(ProjectSettings.globalize_path(folder+"akky.png")) == OK)
 assert(crusher.save_png(ProjectSettings.globalize_path(folder+"crusher.png")) == OK)
 print("THROW_MOTION_PACK_OK")
 quit()
func pack(atlas: Image, source: Image, region: Rect2i, root_x: int, foot_y: int, factor: float, cell: Vector2i, anchor: Vector2i, flip: bool, index: int) -> void:
 var used := visible_rect(source.get_region(region))
 region = Rect2i(region.position+used.position,used.size)
 var pose := source.get_region(region)
 pose.convert(Image.FORMAT_RGBA8)
 var root_local := root_x-region.position.x
 if flip:
  pose.flip_x()
  root_local = region.size.x-root_local
 pose.resize(roundi(region.size.x*factor),roundi(region.size.y*factor),Image.INTERPOLATE_LANCZOS)
 var offset := anchor-Vector2i(roundi(root_local*factor),roundi((foot_y-region.position.y)*factor))
 if offset.x<0 or offset.y<0 or offset.x+pose.get_width()>cell.x or offset.y+pose.get_height()>cell.y:
  failures.append("packing clips pose %s/%s"%[cell,index])
  return
 atlas.blit_rect(pose,Rect2i(Vector2i.ZERO,pose.get_size()),Vector2i(index%3*cell.x,int(index/3)*cell.y)+offset)

func visible_rect(source: Image) -> Rect2i:
 # Measure visible source content, retaining antialias padding. This is only
 # rectangular atlas extraction; source pixels and anatomical scale are intact.
 var low := source.get_size()
 var high := Vector2i(-1,-1)
 for y in range(source.get_height()):
  for x in range(source.get_width()):
   if source.get_pixel(x,y).a >= .25:
    low.x = mini(low.x,x)
    low.y = mini(low.y,y)
    high.x = maxi(high.x,x)
    high.y = maxi(high.y,y)
 assert(high.x>=0)
 return Rect2i(low,high-low+Vector2i.ONE).grow(4).intersection(Rect2i(Vector2i.ZERO,source.get_size()))
