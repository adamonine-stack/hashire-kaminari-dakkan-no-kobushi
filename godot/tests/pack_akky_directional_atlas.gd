extends SceneTree
# Technical atlas packing only. Every pose in a source strip shares one scale.
# Foot coordinates are measured; no per-frame bounding-box fitting.
func _initialize() -> void:
 var folder := "res://assets/characters/player01/animations/directional_v1/"
 var atlas := Image.create(1280, 896, false, Image.FORMAT_RGBA8)
 var strips := [
  {"file":"straight_punch.png", "cuts":[0,543,1086,1629,2172], "roots":[253,786,1292,1865], "top":160, "foot":647, "scale":172.0/468.0},
  {"file":"uppercut.png", "cuts":[0,596,1100,1629,2172], "roots":[350,866,1370,1900], "top":55, "foot":696, "scale":172.0/609.0},
  {"file":"standing_kick.png", "cuts":[0,543,1000,1720,2172], "roots":[290,690,1250,1880], "top":28, "foot":682, "scale":172.0/623.0},
  {"file":"akky_sweep_review_v4.png", "cuts":[0,458,930,1660,2171], "roots":[240,590,1125,1880], "top":38, "foot":665, "scale":172.0/610.0}
 ]
 for row in range(strips.size()):
  var info: Dictionary = strips[row]
  var source := Image.load_from_file(ProjectSettings.globalize_path(folder + "sources/" + info.file))
  for frame in range(4):
   var left: int = info.cuts[frame]
   var pose := source.get_region(Rect2i(left, info.top, info.cuts[frame+1]-left, info.foot+12-info.top))
   pose.convert(Image.FORMAT_RGBA8)
   pose.resize(roundi(pose.get_width()*info.scale), roundi(pose.get_height()*info.scale), Image.INTERPOLATE_LANCZOS)
   var offset := Vector2i(160-roundi((info.roots[frame]-left)*info.scale), 208-roundi((info.foot-info.top)*info.scale))
   assert(offset.x >= 0 and offset.y >= 0 and offset.x+pose.get_width() <= 320 and offset.y+pose.get_height() <= 224, "pose exceeds fixed cell")
   atlas.blit_rect(pose, Rect2i(Vector2i.ZERO, pose.get_size()), Vector2i(frame*320,row*224)+offset)
 var result := atlas.save_png(folder+"motion_atlas.png")
 print("DIRECTIONAL_ATLAS_PACK result=",result)
 quit(result)
