extends Node

const PROGRESS_PATH := "user://story_progress.cfg"
var mode := "normal"
var hard_unlocked := false

func _ready() -> void:
	reload_progress()

func reload_progress() -> void:
	var cfg := ConfigFile.new()
	hard_unlocked = cfg.load(PROGRESS_PATH) == OK and bool(cfg.get_value("difficulty", "normal_cleared", false))

func is_hard() -> bool:
	return mode == "hard"

func select_mode(value: String) -> void:
	mode = "hard" if value == "hard" and hard_unlocked else "normal"
	print("[Difficulty] selected=%s unlocked=%s" % [mode, hard_unlocked])

func persist_run_mode() -> void:
	var cfg := ConfigFile.new()
	cfg.load(PROGRESS_PATH)
	cfg.set_value("difficulty", "run_mode", mode)
	if cfg.save(PROGRESS_PATH) != OK: push_warning("Could not save difficulty")

func restore_run_mode() -> void:
	var cfg := ConfigFile.new()
	cfg.load(PROGRESS_PATH)
	var saved := String(cfg.get_value("difficulty", "run_mode", "normal"))
	var run := ConfigFile.new()
	if run.load("user://save.cfg") == OK:
		saved = String(run.get_value("run", "difficulty", saved))
	select_mode(saved)

func complete_normal() -> void:
	if is_hard(): return
	var cfg := ConfigFile.new()
	cfg.load(PROGRESS_PATH)
	cfg.set_value("difficulty", "normal_cleared", true)
	if cfg.save(PROGRESS_PATH) == OK:
		hard_unlocked = true
	else:
		push_warning("Could not save Hard mode unlock")
