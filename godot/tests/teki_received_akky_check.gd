extends "res://tests/akky_wall_launch_check.gd"
func _initialize() -> void:
	super._initialize()
	victim_definitions = ["enemy_07_tricky"]
	evidence_folder = "teki_received_akky_final"
func reset(manager: Node, actor: Node, point: Vector2, facing: int) -> void:
	manager.current_enemy_index = 2
	manager._apply_current_stage_definition()
	manager._update_battle_hud_enemy()
	await	super.reset(manager,actor,point,facing)
