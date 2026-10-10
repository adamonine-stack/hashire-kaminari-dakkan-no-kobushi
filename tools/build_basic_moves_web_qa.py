"""Run the same 240 combat cases through an exportable Node scene."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]; tests=root/'godot/tests'
bridge='''extends Node
signal process_frame
signal physics_frame
var root: Window:
    get: return get_tree().root
var current_scene: Node:
    get: return get_tree().current_scene
    set(value): get_tree().current_scene = value
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    if OS.has_feature("web"): Engine.physics_ticks_per_second = 240
    get_tree().process_frame.connect(func(): process_frame.emit())
    get_tree().physics_frame.connect(func(): physics_frame.emit())
    _initialize()
func create_timer(seconds: float) -> SceneTreeTimer:
    return get_tree().create_timer(seconds)
func quit(code: int) -> void:
    if OS.has_feature("web"):
        JavaScriptBridge.eval("window.basicMovesQAResult = "+JSON.stringify({"code":code,"cases":get("cases"),"failures":failures}),true)
        get_tree().paused = true
    else: get_tree().quit(code)
'''.replace('    ','\t')
source=(tests/'directional_attacks_check.gd').read_text(encoding='utf-8')
(tests/'basic_moves_web_qa_base.gd').write_text(bridge+'\n'.join(('\t'* (len(line)-len(line.lstrip(' ')))+line.lstrip(' ')) if line.startswith(' ') else line for line in source.removeprefix('extends SceneTree\n').split('\n')),encoding='utf-8')
source=(tests/'basic_moves_combat_check.gd').read_text(encoding='utf-8')
source=source.replace('res://tests/directional_attacks_check.gd','res://tests/basic_moves_web_qa_base.gd')
line='\tFileAccess.open(folder.path_join("combat_results.json"),FileAccess.WRITE).store_string(JSON.stringify(measurements,"\\t"))'
assert line in source
source=source.replace(line,'\tif not OS.has_feature("web"):\n\t'+line)
(tests/'basic_moves_web_qa.gd').write_text(source,encoding='utf-8')
(tests/'basic_moves_web_qa.tscn').write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://tests/basic_moves_web_qa.gd" id="1"]
[node name="BasicMovesWebQA" type="Node"]
script = ExtResource("1")
''',encoding='utf-8')
print('BASIC_MOVES_WEB_QA_SCENE_OK shared_cases=240')
