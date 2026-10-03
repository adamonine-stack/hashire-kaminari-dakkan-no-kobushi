extends SceneTree
# The previous single-hit headfirst move was replaced by the approved two-hit sequence.
var victim_definitions := ["enemy_01_standard","enemy_02_speed","enemy_03_guard","enemy_04_throw","enemy_05_power","enemy_06_combo","enemy_07_tricky","enemy_08_boss","enemy_09_seiya"]
var evidence_folder := "seiya_two_hit"
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var qa = load("res://tests/stage9_two_hit_qa.gd").new()
 qa.include_motion_audit = false
 qa.include_boss_cases = false
 qa.hero_enemies = victim_definitions
 root.add_child(qa)
