from pathlib import Path
from PIL import Image,ImageDraw
import json,sys
ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/(sys.argv[1] if len(sys.argv)>1 else 'audit_evidence/normal_chains_stages2_5/official_sources')
records=json.loads((folder/'inventory.json').read_text(encoding='utf-8'))
for record in records:
    clips=record['clips']; actor=record['id']
    selected=[name for name in clips if name in ['idle','punch_1','punch_2','punch_3','kick_1','kick_2','combo_finisher','crouch_punch'] or name.startswith('basic_source_')]
    canvas=Image.new('RGB',(1000,230*len(selected)),'#27303b');draw=ImageDraw.Draw(canvas)
    for row,name in enumerate(selected):
        for col,index in enumerate(range(min(4,clips[name]['count']))):
            pose=Image.open(folder/f'{actor}__{name}__{index}.png').convert('RGBA')
            box=pose.getchannel('A').getbbox()
            if box:pose=pose.crop(box)
            pose.thumbnail((235,195))
            x=col*250;y=row*230
            canvas.paste(pose,(x+(250-pose.width)//2,y+220-pose.height),pose)
            draw.text((x+6,y+8),name+'/'+str(index),fill='white')
    canvas.save(folder/(actor+'_review.jpg'))
    print(actor,[(name,clips[name]['count']) for name in selected])
