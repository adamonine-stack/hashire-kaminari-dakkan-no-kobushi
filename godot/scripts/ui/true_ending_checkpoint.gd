extends RefCounted

const SAVE_PATH := "user://save.cfg"
const SCENE := "res://scenes/TrueEnding.tscn"

static func save_pending() -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("run", "version", 2)
	cfg.set_value("run", "scene", SCENE)
	cfg.set_value("run", "current_enemy_index", 8)
	return cfg.save(SAVE_PATH)

static func clear() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK and cfg.get_value("run", "scene", "") == SCENE:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
