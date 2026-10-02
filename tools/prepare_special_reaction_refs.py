from pathlib import Path
import re, json
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / 'godot'
OUT = ROOT / 'evidence/special_reaction_refs'
OUT.mkdir(parents=True, exist_ok=True)
records = []
for name in ['enemy_01_standard','enemy_02_speed','enemy_03_guard','enemy_04_throw',
             'enemy_05_power','enemy_06_combo','enemy_07_tricky','enemy_08_boss','enemy_09_seiya']:
    file = GODOT / f'data/enemies/{name}.tres'
    text = file.read_text(encoding='utf-8')
    resources = dict((m[1],m[0]) for m in re.findall(r'path="res://([^"]+)" id="([^"]+)"',text))
    atlas_id = re.search(r'^motion_atlas = ExtResource\("([^"]+)"\)', text,re.M)[1]
    atlas_path = GODOT / resources[atlas_id]
    atlas_text = atlas_path.read_text(encoding='utf-8')
    texture_path = re.search(r'type="Texture2D" path="res://([^"]+)"',atlas_text)[1]
    cell = tuple(map(int,re.search(r'cell_size = Vector2i\((\d+),\s*(\d+)\)',atlas_text).groups()))
    image = Image.open(GODOT/texture_path).convert('RGBA').crop((0,0,*cell))
    if 'frame_regions =' in atlas_text:
        x,y,w,h = map(int,re.search(r'frame_regions = .*?Rect2i\((\d+),\s*(\d+),\s*(\d+),\s*(\d+)\)',atlas_text).groups())
        ox,oy = map(int,re.search(r'frame_offsets = .*?Vector2i\((\d+),\s*(\d+)\)',atlas_text).groups())
        image = Image.new('RGBA',cell)
        image.alpha_composite(Image.open(GODOT/texture_path).convert('RGBA').crop((x,y,x+w,y+h)),(ox,oy))
    image.save(OUT/f'{name}.png')
    records.append(dict(name=name,fighter=str(file.relative_to(GODOT)),atlas=str(atlas_path.relative_to(GODOT)),cell=cell,
                        reference=str(OUT/f'{name}.png'),reference_bounds=image.getchannel('A').getbbox()))
(OUT/'manifest.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
print('SPECIAL_REACTION_REFS_OK count=9')
