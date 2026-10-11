extends "res://tests/stages2_5_chain_sources.gd"

func run() -> void:
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/normal_chains_stages6_9/official_sources")
	DirAccess.make_dir_recursive_absolute(folder)
	var report: Array=[]
	for path in ["enemies/enemy_06_combo","enemies/enemy_03_guard","enemies/enemy_08_boss","enemies/enemy_09_seiya"]:
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
	print("STAGES6_9_CHAIN_SOURCES_OK")
	quit()
