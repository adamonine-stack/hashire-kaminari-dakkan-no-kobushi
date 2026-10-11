from pathlib import Path
from PIL import Image
import json,re
ROOT=Path(__file__).resolve().parents[1]
records=json.loads((ROOT/'audit_evidence/basic_moves_20261010/inventory/inventory.json').read_text(encoding='utf-8'))
slugs=['akky','gou','seiya','crusher','shadow','masato','rei','cross','rio','teki','leon','dark_seiya']
# Reference extraction only; preserve all subsequently implemented stages.
folder=ROOT/'audit_evidence/normal_chains_20261011/references'
folder.mkdir(parents=True,exist_ok=True)
for slug,atlas in [('akky','player01/animations/akky_v3'),('gou','player02/animations/gou_v1'),('seiya','player03/animations/seiya_v2'),('crusher','enemy01/animations/crusher_v1')]:
    path=ROOT/f'godot/assets/characters/{atlas}/motion_atlas.tres'
    text=path.read_text(encoding='utf-8')
    cell=tuple(map(int,re.search(r'cell_size = Vector2i\((\d+),\s*(\d+)\)',text).groups()))
    columns=int(re.search(r'columns = (\d+)',text)[1])
    frame=int(re.search(r'"idle":\s*\{"frames":\s*\[(\d+)',text)[1])
    source=Image.open(path.parent/'motion_atlas.png').convert('RGBA')
    x=(frame%columns)*cell[0];y=(frame//columns)*cell[1]
    pose=source.crop((x,y,x+cell[0],y+cell[1]))
    pose.save(folder/f'{slug}_current_idle.png')
    print(slug,atlas,cell,frame)
