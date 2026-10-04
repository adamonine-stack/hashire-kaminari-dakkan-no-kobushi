extends SceneTree
func _initialize():
 var path="res://assets/characters/enemy01/animations/crusher_v1/motion_atlas.png"
 var atlas=Image.load_from_file(ProjectSettings.globalize_path(path))
 var src=Image.load_from_file(ProjectSettings.globalize_path("res://../art/dedicated_pair_v1/sources/crusher_down_corrected.png"))
 var crop=src.get_region(Rect2i(103,647,1220,325))
 crop.resize(331,88,Image.INTERPOLATE_LANCZOS)
 var cell=Image.create(400,280,false,Image.FORMAT_RGBA8)
 cell.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i(27,174))
 atlas.blit_rect(cell,Rect2i(0,0,400,280),Vector2i(1200,1120))
 atlas.save_png(ProjectSettings.globalize_path(path))
 cell.save_png(ProjectSettings.globalize_path("res://../art/dedicated_pair_v1/sources/crusher_down_packed.png"))
 print("CRUSHER_DOWN_PACK_OK span=331 baseline=262 torso_scale=0.271")
 quit()
