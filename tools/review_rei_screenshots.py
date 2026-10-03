from PIL import Image,ImageDraw
from pathlib import Path
root=Path('evidence/rei_reversal_final')
groups={
'attack_frames':[p for p in sorted(root.glob('attack_*_R.png'))],
'received_flow':[root/(name+'_R_'+phase+'.png') for name in ['ally_balance','ally_power','ally_speed'] for phase in ['startup','impact','air','down','finish']],
'guard_and_whiff':[root/(name+'_'+str(direction)+'_'+phase+'.png') for name in ['ally_balance','ally_power','ally_speed'] for direction in [1,-1] for phase in ['natural_guard','whiff','wall_down']]}
for group,paths in groups.items():
    paths=[p for p in paths if p.exists()]
    cols=3;w=640;h=380
    canvas=Image.new('RGB',(cols*w,((len(paths)+cols-1)//cols)*h),'#141414')
    draw=ImageDraw.Draw(canvas)
    for i,p in enumerate(paths):
        im=Image.open(p).convert('RGB').resize((640,360),Image.Resampling.LANCZOS)
        x=i%cols*w;y=i//cols*h
        canvas.paste(im,(x,y+20));draw.text((x+4,y+4),p.stem,fill='white')
    canvas.save(root/(group+'_review.jpg'))
print('REI_SCREENSHOT_REVIEW_CONTACTS_OK')
