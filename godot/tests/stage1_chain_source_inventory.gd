extends SceneTree
const Visual := preload("res://scripts/characters/character_visual_controller.gd")
const PATHS := ["fighters/ally_balance","fighters/ally_power","fighters/ally_speed","enemies/enemy_01_standard"]
var report: Array = []
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/normal_chains_20261011/official_sources")
	DirAccess.make_dir_recursive_absolute(folder)
	for path in PATHS:
		var definition: Resource = load("res://data/"+path+".tres").duplicate()
		var extras: Array[String] = []
		for value in definition.extra_motion_atlas_paths:
			if not value.contains("normal_chains_v1"): extras.append(value)
		definition.extra_motion_atlas_paths=extras
		var controller := Visual.new()
		controller.definition=definition
		var frames: SpriteFrames = controller._build_sprite_frames(definition.sprite_sheet,definition)
		var clips: Dictionary = {}
		for clip in frames.get_animation_names():
			if clip in ["special_attack","special_startup","special_recovery","throw_forward","throw_release","throw_start","special_finish","reversal_attack"]:
				var count := frames.get_frame_count(clip)
				var textures: Array = []
				for i in range(count):
					var texture: Texture2D = frames.get_frame_texture(clip,i)
					texture.get_image().save_png(folder+"/"+String(definition.fighter_id)+"__"+String(clip)+"__"+str(i)+".png")
					textures.append({"size":[texture.get_width(),texture.get_height()],"margin":[texture.margin.position.x,texture.margin.position.y] if texture is AtlasTexture else [0,0],"source":texture.get_meta("source_texture_path","")})
				clips[String(clip)]={"count":count,"frames":textures}
		report.append({"id":String(definition.fighter_id),"clips":clips})
		controller.free()
	var file:=FileAccess.open(folder+"/inventory.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("STAGE1_CHAIN_SOURCE_INVENTORY actors=%d" % report.size())
	quit()
