extends SceneTree
func _initialize() -> void:
 var folder := "res://assets/characters/directional_throw_v1/"
 var source := Image.load_from_file(ProjectSettings.globalize_path(folder+"contact_key.png"))
 pack(source,Rect2i(0,0,1000,801),400,765,172.0/650.0,Vector2i(320,224),Vector2i(160,208),false,folder+"akky.png")
 pack(source,Rect2i(1000,0,964,801),1610,769,228.0/724.0,Vector2i(400,280),Vector2i(200,260),true,folder+"crusher.png")
 quit()
func pack(source: Image, region: Rect2i, root_x: int, foot_y: int, scale_factor: float, cell: Vector2i, anchor: Vector2i, flip: bool, path: String) -> void:
 var pose := source.get_region(region)
 pose.convert(Image.FORMAT_RGBA8)
 var root_local := root_x-region.position.x
 if flip:
  pose.flip_x()
  root_local = region.size.x-root_local
 pose.resize(roundi(region.size.x*scale_factor),roundi(region.size.y*scale_factor),Image.INTERPOLATE_LANCZOS)
 var offset := anchor-Vector2i(roundi(root_local*scale_factor),roundi(foot_y*scale_factor))
 assert(offset.x>=0 and offset.y>=0 and offset.x+pose.get_width()<=cell.x and offset.y+pose.get_height()<=cell.y)
 var atlas := Image.create(cell.x,cell.y,false,Image.FORMAT_RGBA8)
 atlas.blit_rect(pose,Rect2i(Vector2i.ZERO,pose.get_size()),offset)
 assert(atlas.save_png(ProjectSettings.globalize_path(path)) == OK)
 print("THROW_KEY_PACK ",path)
