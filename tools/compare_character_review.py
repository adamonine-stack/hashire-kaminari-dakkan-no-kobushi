"""Compare runtime captures, including all aliases and untouched actors."""
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw
import json,collections,argparse
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'audit_evidence/full_character_review_20261011'
parser=argparse.ArgumentParser()
parser.add_argument('--before',default='rendered_before'); parser.add_argument('--after',default='rendered'); parser.add_argument('--label',default='')
args=parser.parse_args()
before_dir=BASE/args.before; after_dir=BASE/args.after
before=json.loads((before_dir/'inventory.json').read_text())
after=json.loads((after_dir/'inventory.json').read_text())
lookup={(r['actor'],r['clip'],r['frame']):r for r in after}
result=[]; counts=collections.defaultdict(lambda:dict(frames=0,changed=0,transform_changes=0,idle_changes=0))
for old in before:
    key=(old['actor'],old['clip'],old['frame']); new=lookup[key]
    a=Image.open(before_dir/old['file']).convert('RGBA')
    b=Image.open(after_dir/new['file']).convert('RGBA')
    diff=ImageChops.difference(a,b)
    bbox=diff.convert('RGB').getbbox()
    alpha_bbox=diff.getchannel('A').getbbox()
    changed=bbox is not None or alpha_bbox is not None
    transform=old['scale']!=new['scale'] or old['position']!=new['position']
    c=counts[old['actor']]; c['frames']+=1; c['changed']+=int(changed); c['transform_changes']+=int(transform)
    if old['clip']=='idle': c['idle_changes']+=int(changed)
    result.append(dict(actor=old['actor'],clip=old['clip'],frame=old['frame'],changed=changed,transform_changed=transform,bbox=bbox,alpha_bbox=alpha_bbox,before_file=old['file'],after_file=new['file']))
(BASE/f'pixel_comparison{args.label}.json').write_text(json.dumps(result,indent=2))
(BASE/f'pixel_comparison_summary{args.label}.json').write_text(json.dumps(counts,indent=2))
choices=['idle','punch_1','kick_1','special_attack','normal_punch_4','throw']
sheet=Image.new('RGB',(6*320,640),'#343943'); draw=ImageDraw.Draw(sheet)
for i,clip in enumerate(choices):
    r=next(r for r in result if r['actor']=='player_03_seiya' and r['clip']==clip and r['frame']==0)
    for j,label in enumerate(['before','after']):
        root=before_dir if j==0 else after_dir
        img=Image.open(root/r[f'{label}_file']).convert('RGBA').crop((200,180,440,450))
        sheet.paste(img,(i*320+40,j*320),img)
        draw.text((i*320+8,j*320+275),f'{label} {clip}/0',fill='white')
sheet.save(BASE/f'seiya_before_after{args.label}.png')
print(json.dumps(counts,indent=2))
