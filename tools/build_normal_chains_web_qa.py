"""Expose the actual normal-chain physics check in the exported Web runtime."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
tests=root/'godot/tests'
source=(tests/'normal_chains_live_check.gd').read_text(encoding='utf-8')
source=source.replace('res://tests/basic_moves_combat_check.gd','res://tests/basic_moves_web_qa.gd')
source+='''
func quit(code: int) -> void:
\tif OS.has_feature("web"):
\t\tJavaScriptBridge.eval("window.normalChainsQAResult = "+JSON.stringify({"code":code,"fighters":12,"failures":failures}),true)
\t\tget_tree().paused = true
\telse:
\t\tget_tree().quit(code)
'''
(tests/'normal_chains_web_qa.gd').write_text(source,encoding='utf-8')
(tests/'normal_chains_web_qa.tscn').write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://tests/normal_chains_web_qa.gd" id="1"]
[node name="NormalChainsWebQA" type="Node"]
script = ExtResource("1")
''',encoding='utf-8')
print('NORMAL_CHAINS_WEB_QA_SCENE_OK fighters=12')
