"""Record visual review evidence; never modify production sprite pixels."""
from pathlib import Path
from PIL import Image, ImageDraw
import csv, json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'audit_evidence/hero_design_20261010'
SOURCE = ROOT / 'audit_evidence/body_dimensions/heroes_canvas_native'
inventory = json.loads((SOURCE / 'inventory.json').read_text(encoding='utf-8'))
rows = []
for actor in ['player_02_gou', 'player_03_seiya']:
    clips = sorted({r['clip'] for r in inventory if r['actor'] == actor})
    for clip in clips:
        frames = [r for r in inventory if r['actor'] == actor and r['clip'] == clip]
        concern = actor == 'player_03_seiya' and clip in ['punch_1', 'kick_1', 'special_attack']
        rows.append(dict(actor=actor, motion=clip, captured_directional_frames=len(frames),
                         constant_scale='合格', canvas_and_source_origin='合格',
                         clipping='合格', anatomy_2percent='未確認',
                         design_review='不合格' if concern else '未確認',
                         reason='Idleより頭部が大きく見える。正式Idleを維持し、素材と補正範囲の再検証が必要。' if concern else
                         '全フレームの描画取得済み。隠れた関節や回転姿勢の身体寸法は画像外接矩形では判定できない。'))
with (OUT / 'motion_results.csv').open('w', encoding='utf-8-sig', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=rows[0].keys())
    writer.writeheader(); writer.writerows(rows)
(OUT / 'motion_results.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding='utf-8')

# Manually read horizontal hair silhouette endpoints on native 640x480 images.
# These are visible surface proxies, not a rotated skull/bone measurement.
DATA = [('idle',302,344,250), ('punch_1',314,361,240),
        ('kick_1',305,353,232), ('special_attack',309,356,250), ('guard',272,309,245)]
panel = Image.new('RGB',(640*len(DATA),480),'#30343c')
measurements = []
for i,(clip,left,right,y) in enumerate(DATA):
    image = Image.open(SOURCE/'player_03_seiya'/f'{clip}_right_000.png').convert('RGBA')
    image_draw = ImageDraw.Draw(image)
    image_draw.line((left,y,right,y), fill='yellow', width=1)
    image_draw.text((left,y-14),f'{right-left}px',fill='yellow')
    panel.paste(image,(i*640,0),image)
    draw = ImageDraw.Draw(panel)
    draw.text((i*640+12,442),f'{clip}/0: visible hair width {right-left}px',fill='white')
    draw.text((i*640+12,458),'Manual endpoints +/-2px each; anatomy +/-2% UNVERIFIED',fill='white')
    measurements.append(dict(actor='player_03_seiya',clip=clip,frame=0,
                             left=(left,y),right=(right,y),visible_width_pixels=right-left,
                             delta_from_idle_percent=round(((right-left)/42-1)*100,2),
                             width_uncertainty_pixels=4,anatomy_status='未確認',
                             reason='Hair silhouette and head rotation are not skeletal dimensions.'))
panel.save(OUT/'seiya_head_surface_review.png')
(OUT/'visible_head_proxies.json').write_text(json.dumps(measurements,ensure_ascii=False,indent=2),encoding='utf-8')
print(f'Recorded {len(rows)} motion rows and {len(measurements)} visible head proxies')
