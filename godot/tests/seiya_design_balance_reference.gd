extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var viewport := SubViewport.new()
 viewport.size = Vector2i(768,320)
 viewport.transparent_bg = true
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 for i in range(2):
  var actor: Node2D = load("res://scenes/Player.tscn").instantiate()
  viewport.add_child(actor)
  actor.set_physics_process(false)
  actor.position = Vector2(192+i*384,300)
  actor.apply_fighter_definition(load("res://data/fighters/"+("ally_balance" if i==0 else "ally_speed")+".tres"))
  actor.shadow_sprite.visible = false
  var sweep := "--sweep" in OS.get_cmdline_user_args()
  var clip := ("akky_down_kick" if i==0 else "crouch_kick") if sweep else ("idle" if i==0 else "idle_prebattle")
  actor._play_visual_animation(StringName(clip),true)
  actor.animated_character_sprite.pause()
  actor.animated_character_sprite.frame=2 if sweep else 0
  if i==1:
   var tex: Texture2D=actor.animated_character_sprite.sprite_frames.get_frame_texture(StringName(clip),actor.animated_character_sprite.frame)
   print("SEIYA_PROPORTION_FRAME_META ",tex.get_meta("head_scale_override",-9.0)," shader=",actor.animated_character_sprite.material.get_shader_parameter("head_scale")," texture=",tex.atlas.resource_path)
 await process_frame
 RenderingServer.force_draw(false)
 var folder := ProjectSettings.globalize_path("res://../art_sources/seiya_slim_v3")
 var img := viewport.get_texture().get_image()
 var suffix := "sweep" if "--sweep" in OS.get_cmdline_user_args() else "balance"
 img.save_png(folder.path_join("akky_seiya_"+suffix+"_reference.png"))
 img.get_region(Rect2i(0,0,384,320)).save_png(folder.path_join("akky_"+suffix+"_reference.png"))
 viewport.queue_free()
 await process_frame
 quit()
