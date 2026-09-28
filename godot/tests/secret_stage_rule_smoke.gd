extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	var battle_source := FileAccess.get_file_as_string("res://scripts/battle/battle_manager.gd")
	var title_source := FileAccess.get_file_as_string("res://scripts/ui/title_screen.gd")

	_check(not battle_source.contains("STAGE %d / %d"), "dialogue must not reveal total stage count")
	_check(not battle_source.contains("CAMPAIGN_STAGE_COUNT"), "legacy total-stage constant must stay removed")
	_check(battle_source.contains("SECRET_STAGE_ENEMY_PATH"), "secret boss must be loaded separately from normal enemies")
	_check(battle_source.contains("func _can_unlock_secret_stage()"), "secret-stage eligibility guard is missing")
	_check(battle_source.contains("current_enemy_index != NORMAL_STAGE_COUNT - 1"), "secret stage must unlock only after stage 8")
	_check(battle_source.contains("bool(data.get(\"is_defeated\", false))"), "all fighters must survive")
	_check(not title_source.contains("Stage 9: secret boss"), "title help must not disclose the secret stage")

	print("SECRET_STAGE_RULE_OK failures=%s" % [str(failures)])
	quit(1 if not failures.is_empty() else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
