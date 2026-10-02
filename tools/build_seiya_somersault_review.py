"""Review actual Seiya runtime captures, excluding earlier stale preview frames."""
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'evidence/seiya_somersault_head_contact_final';out=ROOT/'evidence/seiya_somersault_release';out.mkdir(parents=True,exist_ok=True)
start=(ROOT/'evidence/seiya_somersault_head_contact_render.log').stat().st_birthtime
import shutil
for p in source.glob('*.png'):
 if p.stat().st_mtime>=start-1:shutil.copy2(p,out/p.name)
names=['enemy_01_standard','enemy_02_speed','enemy_03_guard','enemy_04_throw','enemy_05_power','enemy_06_combo','enemy_07_tricky','enemy_08_boss','enemy_09_seiya'];phases=['air','head_fall','head_impact','down']
sheet=Image.new('RGB',(1280,len(names)*202),(25,25,30));d=ImageDraw.Draw(sheet)
for row,n in enumerate(names):
 for col,phase in enumerate(phases):
  im=Image.open(out/(n+'_R_'+phase+'.png')).convert('RGB').resize((320,180));sheet.paste(im,(col*320,row*202+22));d.text((col*320+4,row*202+4),n+' / '+phase,fill='white')
sheet.save(out/'contact.jpg',quality=94)
for prefix,name,duration in [('attacker_flip_','attacker_preview',67),('preview_','victim_preview',67)]:
 paths=sorted(out.glob(prefix+'*.png'));frames=[Image.open(p).convert('RGB').resize((768,432)) for p in paths]
 if frames:frames[0].save(out/(name+'.gif'),save_all=True,append_images=frames[1:],duration=duration,loop=0)
print('SEIYA_RUNTIME_REVIEW_OK screenshots='+str(len(list(out.glob('*.png')))))
