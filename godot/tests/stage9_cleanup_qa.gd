extends "res://tests/stage9_two_hit_qa.gd"
func _initialize() -> void:
	include_motion_audit = false
	include_boss_cases = false
	include_cleanup_cases = true
	hero_enemies = []
	super._initialize()
