from pathlib import Path
root=Path(__file__).resolve().parents[1];tests=root/"godot/tests"
parent=(tests/"masato_motion_integrity_check.gd").read_text()
reset="func base_clean_reset("+parent.split("func clean_reset(",1)[1].split("func run()",1)[0]
s=(tests/"readable_grapple_check.gd").read_text().split("\n",1)[1].replace("await super.clean_reset","await base_clean_reset")
s='extends "res://tests/crusher_web_qa_base.gd"\n'+reset+s
s=s.replace('func capture(label: String) -> void:\n','func capture(label: String) -> void:\n\tif OS.has_feature("web"):\n\t\tvar was_paused := paused\n\t\tpaused = true\n\t\tawait RenderingServer.frame_post_draw\n\t\tJavaScriptBridge.eval("window.grappleQACaptureDone = \'\'", true)\n\t\tprint("GRAPPLE_CAPTURE "+label)\n\t\tvar deadline := Time.get_ticks_msec()+20000\n\t\twhile JavaScriptBridge.eval("window.grappleQACaptureDone", true) != label:\n\t\t\tif Time.get_ticks_msec() > deadline:\n\t\t\t\tcheck(false, "browser capture acknowledgement "+label)\n\t\t\t\tbreak\n\t\t\tawait get_tree().create_timer(0.05, true, false, true).timeout\n\t\tscreenshots += 1\n\t\tpaused = was_paused\n\t\treturn\n')
(tests/"grapple_web_qa.gd").write_text(s)
(tests/"grapple_web_qa.tscn").write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://tests/grapple_web_qa.gd" id="1"]\n[node name="GrappleWebQA" type="Node"]\nscript = ExtResource("1")\n')
print("GRAPPLE_WEB_QA_SCENE_OK")
