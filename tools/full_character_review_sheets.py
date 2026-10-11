"""Build evidence sheets from runtime captures; never alter production assets."""
from pathlib import Path
from PIL import Image, ImageDraw
import json, collections, argparse

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'audit_evidence/full_character_review_20261011'
parser=argparse.ArgumentParser()
parser.add_argument('--source',default='rendered'); parser.add_argument('--output',default='sheets')
args=parser.parse_args()
SRC = BASE / args.source
OUT = BASE / args.output
OUT.mkdir(parents=True, exist_ok=True)
if (SRC / 'inventory.json').exists():
    inventory = json.loads((SRC / 'inventory.json').read_text(encoding='utf-8'))
else:
    inventory = [{'actor':p.parent.name, 'clip':p.stem.rsplit('_',1)[0], 'frame':int(p.stem.rsplit('_',1)[1]), 'file':p.relative_to(SRC).as_posix()} for p in sorted(SRC.glob('*/*.png'))]
groups = collections.defaultdict(list)
for row in inventory:
    groups[row['actor']].append(row)
index = []
for actor, rows in groups.items():
    reference_row = next((r for r in rows if r['clip'] == 'idle' and r['frame'] == 0), None)
    if reference_row is None:
        raw_dir = ROOT / 'audit_evidence/body_dimensions/full_review_20261011' / actor
        idle_path = raw_dir / 'idle_right_000_source.png'
        if not idle_path.exists(): continue
        idle = Image.open(idle_path).convert('RGBA')
        for r in rows:
            candidate = raw_dir / f"{r['clip']}_right_{r['frame']:03d}_source.png"
            if candidate.exists():
                img = Image.open(candidate).convert('RGBA')
                if img.size == idle.size and img.tobytes() == idle.tobytes():
                    reference_row = dict(r,clip='idle',frame=0)
                    break
        if reference_row is None: continue
    reference = Image.open(SRC / reference_row['file']).convert('RGBA')
    seen = set()
    unique = []
    for row in rows:
        if row['file'] not in seen:
            seen.add(row['file']); unique.append(row)
    # One common viewport reduction preserves relative scale between all poses.
    for start in range(0, len(unique), 30):
        batch = unique[start:start+30]
        sheet = Image.new('RGB', (1920, 6*268+42), '#343943')
        draw = ImageDraw.Draw(sheet)
        draw.text((12,12), f'{actor} | page {start//30+1} | IDLE is reference | common scale 0.5 | runtime GPU captures', fill='white')
        for n, row in enumerate([reference_row]+batch):
            if n >= 36: break
            x, y = (n%6)*320, 42+(n//6)*268
            image = Image.open(SRC/row['file']).convert('RGBA').resize((320,240),Image.Resampling.LANCZOS)
            sheet.paste(image,(x,y),image)
            draw.text((x+6,y+242), 'REFERENCE idle/0' if n==0 else f"{row['clip']}/{row['frame']}",fill='#ffd66b' if n==0 else 'white')
        name=f'{actor}__{start//30+1:02d}.jpg'
        sheet.save(OUT/name,quality=92)
        index.append({'actor':actor,'sheet':name,'frames':batch})
(OUT/'index.json').write_text(json.dumps(index,indent=2),encoding='utf-8')
print(json.dumps({actor: {'clips':len(set(r['clip'] for r in rows)), 'frames':len(rows), 'unique':len(set(r['file'] for r in rows))} for actor,rows in groups.items()},indent=2))
