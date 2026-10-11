"""Expose the exact Akky movement/contact audit as an exported QA scene."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
tests = root / "godot/tests"
s = (tests / "akky_diagonal_special_check.gd").read_text(encoding="utf-8")
s = s.replace("extends SceneTree", "extends Node\n\nvar root: Node:\n\tget: return get_tree().root")
s = s.replace("func _initialize()", "func _ready()")
s = s.replace("await physics_frame", "await get_tree().physics_frame")
s = s.replace("await process_frame", "await get_tree().process_frame")
s = s.replace('ProjectSettings.globalize_path("res://../audit_evidence/akky_diagonal_special")', 'ProjectSettings.globalize_path("user://akky_forward_qa")')
s = s.replace("quit(0 if failures.is_empty() else 1)", '''if OS.has_feature("web"):
\t\tJavaScriptBridge.eval("window.akkyForwardQAResult = " + JSON.stringify(failures), true)
\telse:
\t\tget_tree().quit(0 if failures.is_empty() else 1)''')
(tests / "akky_forward_web_qa.gd").write_text(s, encoding="utf-8")
(tests / "akky_forward_web_qa.tscn").write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://tests/akky_forward_web_qa.gd" id="1"]
[node name="AkkyForwardWebQA" type="Node"]
script = ExtResource("1")
''', encoding="utf-8")
