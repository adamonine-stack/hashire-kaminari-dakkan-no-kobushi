from PIL import Image,ImageDraw
from pathlib import Path
root=Path('evidence/rei_reversal_final')
paths=sorted(root.glob('*.png'))
for page,start in enumerate(range(0,len(paths),12)):
    batch=paths[start:start+12]
    canvas=Image.new('RGB',(1920,4*260),'#141414')
    draw=ImageDraw.Draw(canvas)
    for i,p in enumerate(batch):
        im=Image.open(p).convert('RGB').crop((0,100,1280,580)).resize((640,240),Image.Resampling.LANCZOS)
        x=i%3*640;y=i//3*260
        canvas.paste(im,(x,y+20));draw.text((x+4,y+3),p.stem,fill='white')
    canvas.save(root/f'qa_page_{page+1:02d}.jpg',quality=92)
print('REI_REVIEW_PAGES',len(paths),(len(paths)+11)//12)
