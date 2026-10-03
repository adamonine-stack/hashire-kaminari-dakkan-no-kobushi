extends "res://tests/teki_reversal_presentation_check.gd"
func _initialize() -> void:
 print("TEKI_PUBLIC_PACK_PROJECT_BINARY=",FileAccess.file_exists("res://project.binary"))
 super._initialize()
 evidence_folder = "teki_public_reversal"
