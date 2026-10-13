"""Run difficulty acceptance checks inside the exported, unmodified Web engine."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
tests = root / 'godot/tests'
source = (tests / 'difficulty_mode_check.gd').read_text(encoding='utf-8')
source = source.replace('extends SceneTree', 'extends Node').replace('func _initialize()', 'func _ready()')
source = re.sub(r'\broot\b', 'get_tree().root', source)
source = re.sub(r'\bprocess_frame\b', 'get_tree().process_frame', source)
source = source.replace('await create_timer(', 'await get_tree().create_timer(')
source = re.sub(r'\tif not DisplayServer.get_name\(\) == "headless":\n(?:\t\t[^\n]*\n)+', '', source)
source += '''
func quit(code: int) -> void:
\tvar difficulty = get_tree().root.get_node("DifficultyMode")
\tvar cfg := ConfigFile.new()
\tcfg.load("user://story_progress.cfg")
\tvar result := {"code":code, "failures":failures, "mode":difficulty.mode, "hard_unlocked":difficulty.hard_unlocked, "saved_normal_clear":bool(cfg.get_value("difficulty", "normal_cleared", false))}
\tif OS.has_feature("web"):
\t\tJavaScriptBridge.eval("window.difficultyQAResult=" + JSON.stringify(result), true)
\t\tget_tree().change_scene_to_file("res://scenes/Title.tscn")
\telse:
\t\tget_tree().quit(code)
'''
(tests / 'difficulty_web_qa.gd').write_text(source, encoding='utf-8')
(tests / 'difficulty_web_qa.tscn').write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://tests/difficulty_web_qa.gd" id="1"]
[node name="DifficultyWebQA" type="Node"]
script = ExtResource("1")
''', encoding='utf-8')
print('DIFFICULTY_WEB_QA_SCENE_OK')
