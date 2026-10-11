from pathlib import Path
from PIL import Image,ImageDraw
import json
ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/'audit_evidence/normal_chains_20261011/official_sources'
records=json.loads((folder/'inventory.json').read_text())
for record in records:
    clips=record['clips'];id=record['id']
    selected=[name for name in clips if name in ['idle','punch_1','punch_2','punch_3','kick_1','kick_2','combo_finisher','crouch_punch','jump_punch_down'] or (('forward_punch' in name or 'forward_kick' in name or 'back_kick' in name) and not name.startswith('basic_'))]
    canvas=Image.new('RGB',(250*5,285*len(selected)),'#27303b');draw=ImageDraw.Draw(canvas)
    for row,name in enumerate(selected):
        count=clips[name]['count']
        indices=list(range(min(5,count)))
        for col,index in enumerate(indices):
            pose=Image.open(folder/(id+'__'+name+'__'+str(index)+'.png')).convert('RGBA')
            box=pose.getchannel('A').getbbox()
            if box:pose=pose.crop(box)
            pose.thumbnail((235,250))
            x=col*250;y=row*285
            canvas.paste(pose,(x+(250-pose.width)//2,y+270-pose.height),pose)
            draw.text((x+6,y+8),name+'/'+str(index),fill='white')
    canvas.save(folder/(id+'_contact_review.jpg'))
    print(id,len(selected))
