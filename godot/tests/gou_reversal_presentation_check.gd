extends "res://tests/special_launch_reaction_check.gd"

func _initialize() -> void:
	attacker_definition = "ally_power"
	victim_definitions = ["enemy_01_standard"]
	reaction_prefix = "received_gou_breaker"
	evidence_folder = "gou_reversal"
	dedicated_attack_clips = ["gou_reversal_startup","gou_reversal_breaker","gou_reversal_finish"]
	super._initialize()
