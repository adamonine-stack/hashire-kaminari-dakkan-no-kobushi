from pathlib import Path
from PIL import Image,ImageDraw
import json
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'evidence/teki_audit'
def cell(path,index,columns=4):
 im=Image.open(path).convert('RGBA');return im.crop((index%columns*512,index//columns*448,index%columns*512+512,index//columns*448+448))
def plate(images,path,columns=4):
 page=Image.new('RGB',(columns*384,((len(images)+columns-1)//columns)*310),(35,40,45));draw=ImageDraw.Draw(page)
 for i,(label,im) in enumerate(images):
  if im.size==(384,288):
   padded=Image.new('RGBA',(512,448));padded.alpha_composite(im,(64,80));im=padded
  im=im.crop((64,80,448,390));x=i%columns*384;y=i//columns*310
  page.paste(im,(x,y),im);draw.text((x+4,y+4),label,fill='white')
 page.save(path)
damage=ROOT/'godot/assets/characters/enemy07/animations/teki_damage_v2/motion_atlas.png'
plate([('idle reference',Image.open(OUT/'idle_00.png')),('before damage',Image.open(OUT/'damage_00.png')),('after damage',cell(damage,0)),('new low damage',cell(damage,7)),('before down',Image.open(OUT/'down_00.png')),('after down',cell(damage,2)),('before rise',Image.open(OUT/'stand_up_01.png')),('after rise',cell(damage,3))],OUT/'damage-original-comparison.jpg')
special=ROOT/'godot/assets/characters/enemy07/animations/teki_reversal_v1/motion_atlas.png'
plate([(f'pose {i}',cell(special,i)) for i in range(8)],OUT/'special-original-comparison.jpg')
for folder in ['teki_damage_final','teki_reversal_final','teki_received_akky_final','teki_received_gou_final','stage9/runtime']:
 shots=sorted((ROOT/'evidence'/folder).glob('*.png'))
 for start in range(0,len(shots),16):
  page=Image.new('RGB',(1920,1120),(25,29,34));draw=ImageDraw.Draw(page)
  for i,path in enumerate(shots[start:start+16]):
   im=Image.open(path).convert('RGB').crop((0,180,1280,640));im.thumbnail((480,245));x=i%4*480;y=i//4*280
   page.paste(im,(x,y+28));draw.text((x+3,y+3),path.stem,fill='white')
  page.save(OUT/f'{folder.replace(chr(47), chr(95))}_page_{start//16+1:02d}.jpg')
 print(folder,len(shots))
