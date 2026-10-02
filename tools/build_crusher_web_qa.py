"""Adapt the same native battle checks to an ordinary Node scene for Web exports."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
tests=root/'godot/tests'
bridge='''extends Node

signal process_frame
signal physics_frame
var root: Window:
    get: return get_tree().root
var paused: bool:
    get: return get_tree().paused
    set(value): get_tree().paused = value

func _ready() -> void:
    print("CRUSHER_WEB_QA_READY")
    get_tree().process_frame.connect(func(): process_frame.emit())
    get_tree().physics_frame.connect(func(): physics_frame.emit())
    _initialize()

func quit(code: int) -> void:
    print("CRUSHER_WEB_QA_EXIT code="+str(code))
    if not OS.has_feature("web"): get_tree().quit(code)

'''
source=(tests/'special_launch_reaction_check.gd').read_text(encoding='utf-8')
(tests/'crusher_web_qa_base.gd').write_text(bridge.replace('    ','\t')+source.removeprefix('extends SceneTree\n'),encoding='utf-8')
source=(tests/'crusher_reversal_presentation_check.gd').read_text(encoding='utf-8')
(tests/'crusher_web_qa.gd').write_text(source.replace('res://tests/special_launch_reaction_check.gd','res://tests/crusher_web_qa_base.gd'),encoding='utf-8')
(tests/'crusher_web_qa.tscn').write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://tests/crusher_web_qa.gd" id="1"]
[node name="CrusherWebQA" type="Node"]
script = ExtResource("1")
''',encoding='utf-8')
print('CRUSHER_WEB_QA_SCENE_OK shared_checks=unchanged')
