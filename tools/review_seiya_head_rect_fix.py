"""Compare actual GPU frames before/after landmark corrections (analysis only)."""
from pathlib import Path
from PIL import Image, ImageDraw
import json, hashlib
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'audit_evidence/body_dimensions/heroes_canvas_native'
AFTER=ROOT/'audit_evidence/body_dimensions/seiya_head_rect_after'
OUT=ROOT/'audit_evidence/hero_design_20261010'
old=json.loads((BASE/'inventory.json').read_text(encoding='utf-8'))
new=json.loads((AFTER/'inventory.json').read_text(encoding='utf-8'))
lookup={(r['actor'],r['clip'],r['facing'],r['frame']):r for r in old}
rows=[]
for r in new:
    before=lookup[(r['actor'],r['clip'],r['facing'],r['frame'])]
    a=Image.open(BASE/r['actor']/before['render_file']).convert('RGBA')
    b=Image.open(AFTER/r['actor']/r['render_file']).convert('RGBA')
    changed=a.tobytes()!=b.tobytes()
    rows.append(dict(clip=r['clip'],frame=r['frame'],facing=r['facing'],
                     changed_pixels=changed,scale_unchanged=r['scale']==before['scale'],
                     position_unchanged=r['position']==before['position'],
                     before_head_rect=before['source_head_rect'],after_head_rect=r['source_head_rect'],
                     anatomy_2percent='未確認'))
    if r['clip']=='idle': assert not changed,'Formal Idle must remain pixel-identical'
    assert r['scale']==before['scale'] and r['position']==before['position']
changes=[r for r in rows if r['changed_pixels']]
assert len(changes)==6,changes
assert {(r['clip'],r['frame']) for r in changes}=={('punch_2',5),('idle_prebattle',2),('crouch_punch',2)}
sheet=Image.new('RGB',(768,3*340),'#30343c')
draw=ImageDraw.Draw(sheet)
for i,(clip,frame) in enumerate([('punch_2',5),('idle_prebattle',2),('crouch_punch',2)]):
    for j,folder in enumerate([BASE,AFTER]):
        im=Image.open(folder/'player_03_seiya'/f'{clip}_right_{frame:03}.png').convert('RGBA').crop((128,128,512,448))
        sheet.paste(im,(j*384,i*340),im)
        draw.text((j*384+4,i*340+324),f'{clip}/{frame} {"BEFORE" if j==0 else "AFTER"}',fill='white')
sheet.save(OUT/'seiya_head_rect_before_after.png')
(OUT/'head_rect_review.json').write_text(json.dumps(dict(frames=rows,changed=changes,
    formal_idle_identical=True,manual_visual_review='髪の分断と腕への矩形切込みを修正。身体寸法±2%は未確認。'),ensure_ascii=False,indent=2),encoding='utf-8')
print(f'SEIYA_HEAD_RECT_REVIEW frames={len(rows)} changed={len(changes)} idle_identical=true')
