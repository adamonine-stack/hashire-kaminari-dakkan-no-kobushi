extends "res://tests/special_launch_reaction_check.gd"

func _initialize() -> void:
	attacker_definition = "ally_power"
	victim_definitions = ["enemy_01_standard","enemy_02_speed","enemy_03_guard","enemy_04_throw",
		"enemy_05_power","enemy_06_combo","enemy_07_tricky","enemy_08_boss","enemy_09_seiya"]
	reaction_prefix = "received_gou_breaker"
	evidence_folder = "gou_reversal_270_final"
	dedicated_attack_clips = ["gou_reversal_startup","gou_reversal_breaker","gou_reversal_finish"]
	minimum_launch_velocity = 300.0
	maximum_flight_distance = 360.0
	super._initialize()
