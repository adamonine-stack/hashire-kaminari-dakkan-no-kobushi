extends SceneTree

const Visual := preload("res://scripts/characters/character_visual_controller.gd")
const DEFINITIONS := [
	"fighters/ally_balance", "fighters/ally_power", "fighters/ally_speed",
	"enemies/enemy_01_standard", "enemies/enemy_02_speed", "enemies/enemy_03_guard",
	"enemies/enemy_04_throw", "enemies/enemy_05_power", "enemies/enemy_06_combo",
	"enemies/enemy_07_tricky", "enemies/enemy_08_boss", "enemies/enemy_09_seiya"]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var records: Array = []
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/basic_moves_20261010/inventory")
	DirAccess.make_dir_recursive_absolute(folder)
	for path in DEFINITIONS:
		var definition: Resource = load("res://data/"+path+".tres")
		var controller := Visual.new()
		controller.definition = definition
		var frames: SpriteFrames = controller._build_sprite_frames(definition.sprite_sheet, definition)
		var id := String(definition.fighter_id)
		var record := {"id": id, "path": path, "description": definition.description, "height": definition.battle_sprite_height, "body_px": definition.sprite_body_height_px, "clips": {}}
		var idle := frames.get_frame_texture("idle", 0)
		var rect := controller._get_visible_content_rect(idle.get_image())
		if idle is AtlasTexture:
			rect.position += Vector2i(idle.margin.position)
		record.cell = [idle.get_width(), idle.get_height()]
		record.idle_rect = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
		record.height_cm = definition.character_height_cm
		record.width_scale = definition.body_width_scale
		record.scale_adjustment = definition.visual_scale_adjustment
		for clip in frames.get_animation_names():
			var tex := frames.get_frame_texture(clip, 0)
			record.clips[clip] = {"count": frames.get_frame_count(clip), "source": tex.get_meta("source_texture_path", tex.atlas.resource_path if tex is AtlasTexture else tex.resource_path)}
			var contact := 3 if frames.get_frame_count(clip) == 6 else (2 if frames.get_frame_count(clip) >= 4 else 1)
			record.clips[clip].contact_frame = contact
			if frames.get_frame_count(clip) > contact:
				var contact_tex := frames.get_frame_texture(clip, contact)
				record.clips[clip].margin = [contact_tex.margin.position.x, contact_tex.margin.position.y] if contact_tex is AtlasTexture else [0, 0]
			if frames.get_frame_count(clip) >= 2 and ("punch" in clip or "kick" in clip or "sweep" in clip):
				var pose := frames.get_frame_texture(clip, contact).get_image()
				pose.save_png(folder.path_join(id+"__"+clip+".png"))
		var image := Image.create(1280, 10 * 256, false, Image.FORMAT_RGBA8)
		var prefix := "akky" if "akky" in id else ("gou" if "gou" in id else ("seiya" if "seiya" in id else ("crusher" if "crusher" in id else "")))
		var choices := ["punch_1", prefix+"_forward_punch", "crouch_punch", prefix+"_back_punch", "jump_punch", "kick_1", prefix+"_forward_kick", "crouch_kick_sweep", prefix+"_back_kick", "jump_kick"]
		for row in range(choices.size()):
			var clip: String = choices[row]
			if not frames.has_animation(clip):
				continue
			var count := frames.get_frame_count(clip)
			for col in range(4):
				var index := mini(col, count-1)
				var texture := frames.get_frame_texture(clip, index)
				var pose := texture.get_image()
				pose.convert(Image.FORMAT_RGBA8)
				var ratio := minf(300.0/pose.get_width(), 240.0/pose.get_height())
				pose.resize(roundi(pose.get_width()*ratio), roundi(pose.get_height()*ratio), Image.INTERPOLATE_NEAREST)
				image.blit_rect(pose, Rect2i(Vector2i.ZERO, pose.get_size()), Vector2i(col*320 + (320-pose.get_width())/2, row*256 + 256-pose.get_height()))
		image.save_png(folder.path_join(id+".png"))
		frames.get_frame_texture("idle", 0).get_image().save_png(folder.path_join(id+"_reference.png"))
		records.append(record)
		controller.free()
	FileAccess.open(folder.path_join("inventory.json"), FileAccess.WRITE).store_string(JSON.stringify(records, "\t"))
	print("BASIC_MOVES_INVENTORY definitions=%d" % records.size())
	quit()
