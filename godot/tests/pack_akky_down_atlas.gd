extends SceneTree
# Measured packing, never fit each pose to its own bounds.
# Fall/get-up use one scale per strip calibrated from standing height.
# The reviewed prone key uses anatomical head scale, not lying image height.
func _initialize() -> void:
 var folder := "res://assets/characters/player01/animations/down_v2/"
 var atlas := Image.create(1280,448,false,Image.FORMAT_RGBA8)
 var fall := Image.load_from_file(ProjectSettings.globalize_path(folder+"sources/fall.png"))
 var cuts := [390,860,1451,2172]
 var roots := [627,1160,1801]
 var feet := [679,684,685]
 for i in range(3):
  pack(atlas,fall,Rect2i(cuts[i],0,cuts[i+1]-cuts[i],724),roots[i],feet[i],172.0/655.0,i)
 var prone := Image.load_from_file(ProjectSettings.globalize_path(folder+"sources/prone_key.png"))
 pack(atlas,prone,Rect2i(100,150,1600,570),900,703,0.128,3)
 var getup := Image.load_from_file(ProjectSettings.globalize_path(folder+"sources/getup.png"))
 cuts = [0,696,1217,1660,2172]
 roots = [375,990,1435,1945]
 for i in range(4):
  pack(atlas,getup,Rect2i(cuts[i],0,cuts[i+1]-cuts[i],724),roots[i],699,172.0/683.0,4+i)
 var result := atlas.save_png(ProjectSettings.globalize_path(folder+"motion_atlas.png"))
 print("AKKY_DOWN_ATLAS_PACK result=",result)
 quit(result)
func pack(atlas: Image, source: Image, region: Rect2i, root_x: int, foot_y: int, scale_factor: float, index: int) -> void:
 var pose := source.get_region(region)
 pose.convert(Image.FORMAT_RGBA8)
 pose.resize(roundi(region.size.x*scale_factor),roundi(region.size.y*scale_factor),Image.INTERPOLATE_LANCZOS)
 var offset := Vector2i(160-roundi((root_x-region.position.x)*scale_factor),208-roundi((foot_y-region.position.y)*scale_factor))
 assert(offset.x>=0 and offset.y>=0 and offset.x+pose.get_width()<=320 and offset.y+pose.get_height()<=224,"pose exceeds fixed cell")
 atlas.blit_rect(pose,Rect2i(Vector2i.ZERO,pose.get_size()),Vector2i(index%4*320,int(index/4)*224)+offset)
