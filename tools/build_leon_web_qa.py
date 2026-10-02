"""Run the exact Leon runtime audit through an ordinary Web-compatible Node scene."""
from pathlib import Path
root=Path(__file__).resolve().parents[1];tests=root/'godot/tests'
s=(tests/'leon_motion_integrity_check.gd').read_text(encoding='utf-8')
s=s.replace('res://tests/special_launch_reaction_check.gd','res://tests/crusher_web_qa_base.gd')
s=s.replace('func capture(label: String) -> void:\n', '''func capture(label: String) -> void:
\tif OS.has_feature("web"):
\t\tvar was_paused := paused
\t\tpaused = true
\t\tawait RenderingServer.frame_post_draw
\t\tJavaScriptBridge.eval("window.leonQACaptureDone = ''", true)
\t\tprint("LEON_CAPTURE "+label)
\t\tvar deadline := Time.get_ticks_msec()+20000
\t\twhile JavaScriptBridge.eval("window.leonQACaptureDone", true) != label:
\t\t\tif Time.get_ticks_msec() > deadline:
\t\t\t\tcheck(false, "browser capture acknowledgement "+label)
\t\t\t\tbreak
\t\t\tawait get_tree().create_timer(0.05, true, false, true).timeout
\t\tscreenshots += 1
\t\tpaused = was_paused
\t\treturn
''')
(tests/'leon_web_qa.gd').write_text(s,encoding='utf-8')
(tests/'leon_web_qa.tscn').write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://tests/leon_web_qa.gd" id="1"]
[node name="LeonWebQA" type="Node"]
script = ExtResource("1")
''',encoding='utf-8')
print('LEON_WEB_QA_SCENE_OK shared_native_checks=true')
