"""Build review sheets for every distinct current frame, with alias inventory."""
from pathlib import Path
from PIL import Image, ImageDraw
import argparse, hashlib, json

root = Path(__file__).resolve().parents[1] / 'audit_evidence/body_dimensions'
parser=argparse.ArgumentParser()
parser.add_argument('--actor',default='player_01_akky')
args=parser.parse_args()
source = root / 'wall_all_headless' / args.actor
out = root / 'landmark_review' / ('current_sheets' if args.actor=='player_01_akky' else args.actor+'_sheets')
out.mkdir(exist_ok=True)
groups = {}
for path in sorted(source.glob('*_right_*_source.png')):
    key = hashlib.sha256(path.read_bytes()).hexdigest()
    groups.setdefault(key, []).append(path.name)
rows = [{'index':i,'sha256':key,'files':files} for i,(key,files) in enumerate(groups.items())]
for page in range((len(rows)+19)//20):
    sheet = Image.new('RGB',(2048,2370),'#30343c')
    draw = ImageDraw.Draw(sheet)
    for slot,row in enumerate(rows[page*20:(page+1)*20]):
        x,y = slot%4*512,slot//4*474
        im=Image.open(source/row['files'][0]).convert('RGBA')
        assert im.width<=512 and im.height<=448, im.size
        # Pixel sizes preserved; canvas center aligned, not fit-to-cell scaled.
        sheet.paste(im,(x+(512-im.width)//2,y+(448-im.height)//2),im)
        draw.text((x+2,y+450),f"{row['index']}: {row['files'][0].replace('_right_','/').replace('_source.png','')}",fill='white')
        draw.text((x+2,y+462),f"{len(row['files'])} aliases; source canvas {im.width}x{im.height}; 1:1 pixels",fill='#aaaaaa')
    sheet.save(out/f'page_{page:02}.png')
(out/'index.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
print(f'{len(rows)} distinct images, {sum(len(r["files"]) for r in rows)} right frame references')
