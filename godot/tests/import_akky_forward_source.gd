extends SceneTree

func _initialize() -> void:
	var folder := "res://assets/characters/player01/animations/forward_leap_v1/"
	var source := Image.load_from_file(ProjectSettings.globalize_path(folder + "source.png"))
	if source == null:
		quit(1)
		return
	var texture := PortableCompressedTexture2D.new()
	texture.keep_compressed_buffer = true
	texture.create_from_image(source, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
	var error := ResourceSaver.save(texture, folder + "source_texture.res")
	print("AKKY_SOURCE_IMPORT size=", source.get_size(), " alpha=",source.detect_alpha()," error=", error)
	quit(0 if error == OK else 1)
