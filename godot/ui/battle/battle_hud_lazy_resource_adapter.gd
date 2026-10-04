extends "res://ui/battle/battle_hud.gd"


func update_enemy_information(enemy_data: Dictionary, enemy_index: int) -> void:
	var resolved_enemy_data := enemy_data.duplicate()
	if resolved_enemy_data.get("definition", null) == null and battle_manager != null:
		var active_definition: Resource = battle_manager.get("_current_enemy_definition")
		if active_definition != null:
			resolved_enemy_data["definition"] = active_definition
	super.update_enemy_information(resolved_enemy_data, enemy_index)
