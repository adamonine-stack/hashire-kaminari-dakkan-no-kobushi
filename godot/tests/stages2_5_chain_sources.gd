extends SceneTree
const Visual := preload("res://scripts/characters/character_visual_controller.gd")
const PATHS := ["enemies/enemy_04_throw","enemies/enemy_07_tricky","enemies/enemy_05_power","enemies/enemy_02_speed"]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/normal_chains_stages2_5/official_sources")
	DirAccess.make_dir_recursive_absolute(folder)
	var report: Array=[]
	for path in PATHS:
		var definition: Resource=load("res://data/"+path+".tres")
		var controller := Visual.new()
		controller.definition=definition
		var frames: SpriteFrames=controller._build_sprite_frames(definition.sprite_sheet,definition)
		var clips: Dictionary={}
		for clip in frames.get_animation_names():
			if clip==&"idle" or String(clip).contains("punch") or String(clip).contains("kick") or clip==&"combo_finisher":
				var textures: Array=[]
				for i in range(frames.get_frame_count(clip)):
					var texture: Texture2D=frames.get_frame_texture(clip,i)
					texture.get_image().save_png(folder+"/"+String(definition.fighter_id)+"__"+String(clip)+"__"+str(i)+".png")
					textures.append({"hash":hash(texture.get_image().get_data()),"size":[texture.get_width(),texture.get_height()]})
				clips[String(clip)]={"count":textures.size(),"frames":textures}
		report.append({"id":String(definition.fighter_id),"clips":clips})
		controller.free()
	FileAccess.open(folder+"/inventory.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("STAGES2_5_CHAIN_SOURCES_OK")
	quit()
