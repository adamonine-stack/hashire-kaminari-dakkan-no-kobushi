from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/'audit_evidence/normal_chains_20261011/rendered'
actors=['player_01_akky','player_02_gou','player_03_seiya','enemy_01_crusher']
for actor in actors:
    files=[folder/f'{actor}__idle__00.png']+sorted(folder.glob(actor+'__normal_*__02.png'))
    files+=sorted(folder.glob(actor+'__normal_overhead__01.png'))
    canvas=Image.new('RGB',(500*len(files),420))
    draw=ImageDraw.Draw(canvas)
    for i,p in enumerate(files):
        canvas.paste(Image.open(p),(i*500,0))
        draw.text((i*500+5,5),p.stem.split('__')[1],fill='white')
    canvas.save(folder.parent/(actor+'_review.jpg'))
canvas=Image.new('RGB',(1500,1680))
draw=ImageDraw.Draw(canvas)
for row,actor in enumerate(actors):
    for col,(clip,frame) in enumerate([('idle',0),('normal_overhead',1),('normal_overhead',2)]):
        canvas.paste(Image.open(folder/f'{actor}__{clip}__{frame:02d}.png'),(col*500,row*420))
        draw.text((col*500+5,row*420+5),actor+' '+clip+'/'+str(frame),fill='white')
canvas.save(folder.parent/'stage1_design_comparison.jpg')
