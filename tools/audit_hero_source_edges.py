"""Inspect existing runtime frame captures without editing production pixels."""
from pathlib import Path
from PIL import Image, ImageDraw
import json

root = Path(__file__).resolve().parents[1]
src = root / 'audit_evidence/body_dimensions/wall_all_headless'
out = root / 'audit_evidence/hero_design_20261010/before'
out.mkdir(parents=True, exist_ok=True)
rows = []
for actor in ['player_02_gou', 'player_03_seiya']:
    files = sorted((src / actor).glob('*_right_*_source.png'))
    selected = []
    for path in files:
        im = Image.open(path).convert('RGBA')
        bounds = im.getchannel('A').point(lambda a: 255 if a >= 16 else 0).getbbox()
        margins = [bounds[0], bounds[1], im.width-bounds[2], im.height-bounds[3]]
        edge = min(margins) <= 1
        row = {'actor': actor, 'frame': path.name, 'canvas': list(im.size),
               'alpha_bbox': list(bounds), 'margins': margins, 'edge_contact': edge,
               'anatomy_status': 'unverified'}
        rows.append(row)
        if edge or '_down_punch_' in path.name or path.name == 'idle_right_000_source.png':
            selected.append((path, row))
    for page in range((len(selected)+11)//12):
        sheet = Image.new('RGB', (1536, 1008), '#30343c')
        draw = ImageDraw.Draw(sheet)
        for slot, (path, row) in enumerate(selected[page*12:(page+1)*12]):
            x,y = slot%4*384, slot//4*336
            im = Image.open(path).convert('RGBA')
            sheet.paste(im, (x+(384-im.width)//2,y),im)
            draw.text((x+4,y+290),path.name,fill='white')
            draw.text((x+4,y+310),str(row['margins']),fill='orange' if row['edge_contact'] else 'white')
        sheet.save(out / f'{actor}_edges_launch_{page:02}.png')
    print(actor, 'frames',len(files), 'edge_contact',sum(r['edge_contact'] for r in rows if r['actor']==actor), 'sheets',(len(selected)+11)//12)
(out/'edge_inventory.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
