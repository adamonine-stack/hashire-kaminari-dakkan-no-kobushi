extends RefCounted

# Keep a very small, recoverable route marker until the user intentionally exits.
const SAVE_PATH := "user://save.cfg"
const SCENE := "res://scenes/EndingCredits.tscn"
const NORMAL := "normal"
const BAD := "bad"
const TRUE := "true"

static func save_pending(route: String) -> Error:
	if route not in [NORMAL, BAD, TRUE]:
		return ERR_INVALID_PARAMETER
	var cfg := ConfigFile.new()
	cfg.set_value("run", "version", 2)
	cfg.set_value("run", "scene", SCENE)
	cfg.set_value("run", "ending_route", route)
	# Dedicated end credits do not need any battle or character assets.
	return cfg.save(SAVE_PATH)

static func load_route() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return ""
	if cfg.get_value("run", "scene", "") != SCENE:
		return ""
	var route := String(cfg.get_value("run", "ending_route", ""))
	return route if route in [NORMAL, BAD, TRUE] else ""

static func is_pending() -> bool:
	return not load_route().is_empty()

static func clear() -> void:
	if not is_pending():
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
