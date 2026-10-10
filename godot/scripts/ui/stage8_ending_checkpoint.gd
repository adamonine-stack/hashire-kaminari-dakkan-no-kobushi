extends RefCounted

const SAVE_PATH := "user://save.cfg"
const SCENE := "res://scenes/Stage8Ending.tscn"
const META := &"stage8_ending_snapshot"
const IDS := ["player_01_akky", "player_02_gou", "player_03_seiya"]

static func save_snapshot(snapshot: Array) -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("run", "version", 2)
	cfg.set_value("run", "scene", SCENE)
	cfg.set_value("run", "current_enemy_index", 7)
	for index in range(snapshot.size()):
		for key in snapshot[index]:
			cfg.set_value("player_%d" % index, key, snapshot[index][key])
	return cfg.save(SAVE_PATH)

static func load_snapshot() -> Array:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK or cfg.get_value("run", "scene", "") != SCENE: return []
	var snapshot: Array = []
	for index in range(3):
		var section := "player_%d" % index
		if cfg.get_value(section, "character_id", "") != IDS[index]: return []
		var data := {}
		for key in cfg.get_section_keys(section): data[key] = cfg.get_value(section, key)
		snapshot.append(data)
	return snapshot

static func clear() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK and cfg.get_value("run", "scene", "") == SCENE:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
