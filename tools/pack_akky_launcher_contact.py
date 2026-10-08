"""Reuse accepted complete atlas cells; never reshape character anatomy."""
import json
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
CELL = (320,224)
source = ROOT / "godot/assets/characters/dedicated_pair_v1/akky_launcher.png"
upper = ROOT / "godot/assets/characters/player01/animations/directional_v1/motion_atlas.png"
folder = ROOT / "godot/assets/characters/player01/animations/launcher_contact_v2"
folder.mkdir(parents=True,exist_ok=True)
output = Image.new("RGBA",(1280,224))
manifest=[]
for target,(path,index) in enumerate([(source,0),(source,1),(upper,6),(upper,7)]):
    image=Image.open(path).convert("RGBA")
    x,y=index%4*320,index//4*224
    output.paste(image.crop((x,y,x+320,y+224)),(target*320,0))
    manifest.append({"frame":target,"source":str(path.relative_to(ROOT)),"source_cell":index,"scale":1.0})
output.save(folder / "motion_atlas.png")
(folder / "packing_manifest.json").write_text(json.dumps(manifest,indent=2),encoding="utf-8")
(folder / "motion_atlas.tres").write_text('''[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]
[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/characters/player01/animations/launcher_contact_v2/motion_atlas.png" id="2"]
[resource]
script = ExtResource("1")
texture = ExtResource("2")
cell_size = Vector2i(320, 224)
columns = 4
clips = {"akky_down_punch": {"frames": [0,1,2,3], "fps": 12.0, "loop": false}}
''',encoding="utf-8")
print("AKKY_LAUNCHER_CONTACT packed four original cells at 1:1")
