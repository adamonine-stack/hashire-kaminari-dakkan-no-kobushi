"""Ensure final GPU pixel changes remain inside reviewed head regions."""
from pathlib import Path
import json,re,math
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'audit_evidence/full_character_review_20261011'
rows=json.loads((ROOT/'audit_evidence/body_dimensions/full_review_20261011/inventory.json').read_text())
lookup={(r['actor'],r['clip'],r['frame']):r for r in rows if r['facing']==1}
head_lookup={(r['source'],r['region']):r['source_head_rect'] for r in rows if 'source_head_rect' in r}
changes=json.loads((BASE/'pixel_comparison_final.json').read_text())
def nums(s): return list(map(float,re.findall(r'-?\d+(?:\.\d+)?',s)))
checked=0; failures=[]
for c in changes:
    if not c['changed']: continue
    r=lookup[(c['actor'],c['clip'],c['frame'])]
    head=nums(r.get('source_head_rect',head_lookup[(r['source'],r['region'])])); region=nums(r['region']); margin=nums(r['margin'])
    scale=nums(r['scale']); pos=nums(r['position']); canvas=nums(r['canvas'])
    x=320+pos[0]+(head[0]-3-region[0]+margin[0]-canvas[0]/2)*scale[0]
    y=430+pos[1]+(head[1]-3-region[1]+margin[1]-canvas[1]/2)*scale[1]
    roi=(math.floor(x)-1,math.floor(y)-1,math.ceil(x+(head[2]+6)*scale[0])+1,math.ceil(y+(head[3]+3)*scale[1])+1)
    for bbox in [c['bbox'],c['alpha_bbox']]:
        if bbox and not (roi[0]<=bbox[0] and roi[1]<=bbox[1] and roi[2]>=bbox[2] and roi[3]>=bbox[3]):
            failures.append(dict(actor=c['actor'],clip=c['clip'],frame=c['frame'],bbox=bbox,roi=roi))
    checked+=1
result=dict(changed_alias_frames=checked,failures=failures)
(BASE/'head_region_integrity.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result))
raise SystemExit(bool(failures))
