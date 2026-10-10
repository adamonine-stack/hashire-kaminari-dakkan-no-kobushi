"""Analyze captured frames without rescaling source art or changing acceptance limits."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops
import json, csv, hashlib, sys

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / ('audit_evidence/body_dimensions/' + (sys.argv[1] if len(sys.argv)>1 else 'stage2_before_native'))
OUT = ROOT / 'audit_evidence/stage2_design_20261010'
rows = json.loads((FOLDER / 'inventory.json').read_text(encoding='utf-8'))
OUT.mkdir(parents=True, exist_ok=True)
groups, poses, issues = {}, {}, []
for row in rows:
    actor, clip = row['actor'], row['clip']
    p = FOLDER / actor / row['render_file']
    im = Image.open(p).convert('RGBA')
    alpha = im.getchannel('A')
    bounds = alpha.point(lambda a: 255 if a >= 128 else 0).getbbox()
    row['render_bounds'] = bounds
    row['capture_edge'] = bool(bounds and (bounds[0] == 0 or bounds[1] == 0 or bounds[2] == im.width or bounds[3] == im.height))
    if row['capture_edge'] or row['scale_status'] != 'pass' or row['flip_status'] != 'pass':
        issues.append(dict(actor=actor, clip=clip, frame=row['frame'], facing=row['facing'], bounds=bounds))
    groups.setdefault((actor, clip), []).append(row)
    if row['facing'] == 1:
        other = FOLDER / actor / row['render_file'].replace('_right_', '_left_')
        flipped = Image.open(other).convert('RGBA').transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        row['mirror_alpha_exact'] = ImageChops.difference(alpha, flipped.getchannel('A')).getbbox() is None
        digest = hashlib.sha256(im.tobytes()).hexdigest()
        poses.setdefault(actor, {}).setdefault(digest, (row, p))
for actor, unique in poses.items():
    entries = list(unique.values())
    for start in range(0, len(entries), 16):
        canvas = Image.new('RGB', (1600, 1400), '#252525')
        draw = ImageDraw.Draw(canvas)
        for i, (row, path) in enumerate(entries[start:start+16]):
            im = Image.open(path).convert('RGBA')
            # Every panel uses the same fixed 320x240 crop and magnification.
            im = im.crop((120, 110, 520, 440))
            x, y = i % 4 * 400, i // 4 * 350
            canvas.paste(im, (x, y+20), im)
            draw.text((x+5, y+5), row['clip']+' / '+str(row['frame']), fill='white')
        canvas.save(OUT / f'{actor}_poses_{start//16:02d}.png')
ledger = []
for (actor, clip), frames in groups.items():
    ledger.append(dict(actor=actor, motion=clip, frames=len(frames),
        display_scale='合格' if all(r['scale_status']=='pass' for r in frames) else '不合格',
        clipping='合格' if not any(r['capture_edge'] for r in frames) else '不合格',
        mirror='合格' if all(r.get('mirror_alpha_exact',True) for r in frames) else '不合格',
        design='未確認', anatomy_2_percent='未確認', continuous_gameplay='未確認'))
with (OUT/'motion_results.csv').open('w', encoding='utf-8-sig', newline='') as f:
    writer=csv.DictWriter(f, fieldnames=list(ledger[0]));writer.writeheader();writer.writerows(ledger)
summary=dict(frame_references=len(rows), motions=len(groups),
             unique_poses={a:len(p) for a,p in poses.items()}, issues=issues,
             mirror_failures=[dict(actor=r['actor'],clip=r['clip'],frame=r['frame']) for r in rows if r.get('mirror_alpha_exact') is False])
(OUT/'frame_summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2),encoding='utf-8')
print(json.dumps(summary, ensure_ascii=False))
