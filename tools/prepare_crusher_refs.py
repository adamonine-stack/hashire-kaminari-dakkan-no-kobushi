from pathlib import Path
from PIL import Image
import re
root = Path(__file__).resolve().parents[1]
out = root/'art_sources/crusher_reversal_v1/references'
out.mkdir(parents=True,exist_ok=True)
for name,folder,atlas in [('crusher','enemy01','crusher_v1'),('akky','player01','akky_v3'),('gou','player02','gou_v1'),('seiya','player03','seiya_v1')]:
    p=root/f'godot/assets/characters/{folder}/animations/{atlas}/motion_atlas.tres'
    s=p.read_text(encoding='utf-8')
    texture=re.search(r'type="Texture2D" path="res://([^"]+)"',s)[1]
    w,h=map(int,re.search(r'cell_size = Vector2i\((\d+),\s*(\d+)\)',s).groups())
    columns=int(re.search(r'columns = (\d+)',s)[1])
    index=int(re.search(r'"idle":\s*\{"frames":\s*\[(\d+)',s)[1])
    Image.open(root/'godot'/texture).crop(((index%columns)*w,(index//columns)*h,(index%columns+1)*w,(index//columns+1)*h)).save(out/(name+'.png'))
print('CRUSHER_REFS_OK corrected_idle=4')
