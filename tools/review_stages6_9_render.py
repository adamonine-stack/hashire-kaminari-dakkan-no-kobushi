from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'audit_evidence/normal_chains_20261011/rendered'
folder=ROOT/'audit_evidence/normal_chains_stages6_9'
actors=['enemy_06_rio_flick_garcia','enemy_03_masato_takahashi','enemy_08_leon_crow','enemy_09_seiya']
canvas=Image.new('RGB',(1500,1680));draw=ImageDraw.Draw(canvas)
for row,actor in enumerate(actors):
    for col,(clip,frame) in enumerate([('idle',0),('normal_overhead',1),('normal_overhead',2)]):
        canvas.paste(Image.open(source/f'{actor}__{clip}__{frame:02d}.png'),(col*500,row*420))
        draw.text((col*500+5,row*420+5),actor+' '+clip+'/'+str(frame),fill='white')
    files=[source/f'{actor}__idle__00.png']+sorted(source.glob(actor+'__normal_*__02.png'))
    strip=Image.new('RGB',(500*len(files),420));labels=ImageDraw.Draw(strip)
    for col,path in enumerate(files):
        strip.paste(Image.open(path),(col*500,0))
        labels.text((col*500+5,5),path.stem.split('__')[1],fill='white')
    strip.save(folder/f'{actor}_contacts.jpg')
canvas.save(folder/'stages6_9_design_comparison.jpg')
