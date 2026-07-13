extends Node

const CONFIG_PATH := "user://settings.cfg"

var bgm_volume := 0.80
var se_volume := 0.90
var screen_shake_mode := "NORMAL"
var hitstop_mode := "NORMAL"
var fullscreen_enabled := false


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		save_settings()
		return
	bgm_volume = clampf(float(config.get_value("audio", "bgm_volume", bgm_volume)), 0.0, 1.0)
	se_volume = clampf(float(config.get_value("audio", "se_volume", se_volume)), 0.0, 1.0)
	screen_shake_mode = String(config.get_value("feel", "screen_shake_mode", screen_shake_mode))
	hitstop_mode = String(config.get_value("feel", "hitstop_mode", hitstop_mode))
	fullscreen_enabled = bool(config.get_value("display", "fullscreen_enabled", fullscreen_enabled))
	_apply_window_mode()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "bgm_volume", bgm_volume)
	config.set_value("audio", "se_volume", se_volume)
	config.set_value("feel", "screen_shake_mode", screen_shake_mode)
	config.set_value("feel", "hitstop_mode", hitstop_mode)
	config.set_value("display", "fullscreen_enabled", fullscreen_enabled)
	config.save(CONFIG_PATH)


func set_bgm_volume(value: float) -> void:
	bgm_volume = clampf(value, 0.0, 1.0)
	save_settings()
	_apply_audio_manager_volumes()


func set_se_volume(value: float) -> void:
	se_volume = clampf(value, 0.0, 1.0)
	save_settings()
	_apply_audio_manager_volumes()


func cycle_screen_shake_mode() -> void:
	screen_shake_mode = _next_mode(screen_shake_mode, ["NORMAL", "LIGHT", "OFF"])
	save_settings()


func cycle_hitstop_mode() -> void:
	hitstop_mode = _next_mode(hitstop_mode, ["NORMAL", "LIGHT", "OFF"])
	save_settings()


func toggle_fullscreen() -> void:
	fullscreen_enabled = not fullscreen_enabled
	_apply_window_mode()
	save_settings()


func get_screen_shake_multiplier() -> float:
	match screen_shake_mode:
		"OFF":
			return 0.0
		"LIGHT":
			return 0.45
	return 1.0


func get_hitstop_multiplier() -> float:
	match hitstop_mode:
		"OFF":
			return 0.0
		"LIGHT":
			return 0.50
	return 1.0


func _next_mode(current: String, modes: Array[String]) -> String:
	var index := modes.find(current)
	if index == -1:
		return modes[0]
	return modes[(index + 1) % modes.size()]


func _apply_window_mode() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled else DisplayServer.WINDOW_MODE_WINDOWED
	)


func _apply_audio_manager_volumes() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager == null:
		return
	if audio_manager.has_method("set_bgm_volume"):
		audio_manager.call("set_bgm_volume", bgm_volume)
	if audio_manager.has_method("set_se_volume"):
		audio_manager.call("set_se_volume", se_volume)
