"""Pack complete Seiya poses at the accepted body scale, no runtime pose fitting."""
from pathlib import Path
from PIL import Image, ImageDraw
import motion_packing as m
import re,json,math,hashlib
R=m.ROOT;G=m.G;A=R/'art_sources/seiya_two_hit_v1'
m.CELL=(384,288);m.BASELINE=270;m.COLS=8;m.REFERENCE_HEIGHT=195
old=G/'assets/characters/player03/animations/seiya_v1'
src=Image.open(old/'motion_atlas.png').convert('RGBA')
raw=[src.crop((i%8*384,i//8*288,i%8*384+384,i//8*288+288)) for i in range(104)]
poses=[max(m.components(p,minimum=30,alpha_threshold=32),key=lambda v:m.area(v[1]))[1] for p in raw]
m.REFERENCE_AREA=m.area(poses[2]);factors=[1.0]*104
# Original victory/intro and supplementary walking sheets had different density.
for i in range(90,104):
 factors[i]=195/poses[i].height
clips=json.loads((old/'motion_atlas.tres').read_text(encoding='utf-8').split('clips = ',1)[1])
out=G/'assets/characters/player03/animations/seiya_v2'
m.pack(poses,clips,out,[f'original_{i}' for i in range(104)],factors)
new=m.components(Image.open(A/'attacker.png').convert('RGBA'),minimum=2000,alpha_threshold=100)
assert len(new)==8,len(new)
new.sort(key=lambda v:(v[0][1]+v[0][3])/2)
new=sorted(new[:4],key=lambda v:v[0][0])+sorted(new[4:],key=lambda v:v[0][0])
parts=[p for b,p in new]
scales=[math.sqrt(m.REFERENCE_AREA/m.area(p)) for p in parts]
# Complete inverted pose is kept centered on the body; feet poses use baseline270.
atlas=Image.new('RGBA',(384*8,288));records=[]
refbox=raw[2].getchannel('A').getbbox();anchor=(refbox[1]+refbox[3])/2
for i,(p,f) in enumerate(zip(parts,scales)):
 p=p.resize((round(p.width*f),round(p.height*f)),Image.Resampling.NEAREST)
 x=(384-p.width)//2;y=round(anchor-p.height/2) if i in [1,2] else 270-p.height
 assert x>=4 and y>=4 and x+p.width<=380 and y+p.height<=284,(i,p.size,x,y)
 atlas.alpha_composite(p,(i*384+x,y));records.append(dict(index=i,scale=f,area=m.area(p),offset=[x,y]))
dest=G/'assets/characters/player03/animations/two_hit_v1';dest.mkdir(parents=True,exist_ok=True);atlas.save(dest/'motion_atlas.png')
special={
 'seiya_two_start':dict(frames=[0],fps=10,loop=False),
 'seiya_two_somersault':dict(frames=[1,2,3],fps=6,loop=False),
 'seiya_two_sidekick':dict(frames=[4,5,6,7],fps=12,loop=False),
 'seiya_two_finish':dict(frames=[7],fps=10,loop=False),
}
text='[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n[ext_resource type="Texture2D" path="res://assets/characters/player03/animations/two_hit_v1/motion_atlas.png" id="2"]\n[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i(384,288)\ncolumns = 8\nclips = '+json.dumps(special)+'\n'
(dest/'motion_atlas.tres').write_text(text,encoding='utf-8')
(dest/'packing_manifest.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
def attach(p,path,key):
 s=p.read_text(encoding='utf-8')
 if f'id="{key}"' in s:return s
 s=re.sub(r'load_steps=(\d+)',lambda v:f'load_steps={int(v[1])+1}',s,count=1)
 s=s.replace('[resource]',f'[ext_resource type="Resource" path="res://{path}" id="{key}"]\n\n[resource]',1)
 s=re.sub(r'extra_motion_atlases = Array\[Resource\]\(\[(.*?)\]\)',lambda v:'extra_motion_atlases = Array[Resource](['+v[1]+f', ExtResource("{key}")])',s)
 return s
for p in [G/'data/fighters/ally_speed.tres',G/'data/enemies/enemy_09_seiya.tres']:
 s=attach(p,'assets/characters/player03/animations/two_hit_v1/motion_atlas.tres','seiya_two_hit')
 s=s.replace('seiya_v1/motion_atlas.tres','seiya_v2/motion_atlas.tres');p.write_text(s,encoding='utf-8')
received=m.components(Image.open(A/'receivers_clean.png').convert('RGBA'),minimum=2000,alpha_threshold=100)
assert len(received)==12,len(received)
received.sort(key=lambda v:(v[0][1]+v[0][3])/2)
for row,(hero,fighter) in enumerate([('player01','ally_balance'),('player02','ally_power'),('player03','ally_speed')]):
 ps=[p.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for b,p in sorted(received[row*4:row*4+4],key=lambda v:v[0][0])]
 definition=G/f'data/fighters/{fighter}.tres';s=definition.read_text(encoding='utf-8')
 ref=G/re.search(r'path="res://([^\"]+motion_atlas.tres)"',s)[1];rt=ref.read_text(encoding='utf-8')
 m.CELL=tuple(map(int,re.search(r'cell_size = Vector2i\((\d+),\s*(\d+)\)',rt).groups()));cols=int(re.search(r'columns = (\d+)',rt)[1]);idx=int(re.search(r'"idle":\s*\{"frames":\s*\[(\d+)',rt)[1]);im=Image.open(G/re.search(r'path="res://([^\"]+png)"',rt)[1]);idle=im.crop((idx%cols*m.CELL[0],idx//cols*m.CELL[1],idx%cols*m.CELL[0]+m.CELL[0],idx//cols*m.CELL[1]+m.CELL[1]));box=idle.getchannel('A').getbbox();m.BASELINE=box[3];m.REFERENCE_HEIGHT=box[3]-box[1];m.REFERENCE_AREA=m.area(idle);m.COLS=4
 names=['lift','fall','fly','down'];cs={f'received_seiya_two_{name}':dict(frames=[i],fps=10,loop=False) for i,name in enumerate(names)}
 fs=[min(math.sqrt(m.REFERENCE_AREA/m.area(p)),(m.CELL[0]-8)/p.width,(m.BASELINE-8)/p.height) for p in ps]
 path=f'assets/characters/{hero}/animations/seiya_two_received_v1';m.pack(ps,cs,G/path,names,fs)
 s=attach(definition,path+'/motion_atlas.tres','seiya_two_received');definition.write_text(s,encoding='utf-8')
 if hero=='player03':
  ep=G/'data/enemies/enemy_09_seiya.tres';ep.write_text(attach(ep,path+'/motion_atlas.tres','seiya_two_received'),encoding='utf-8')
sheet=Image.new('RGB',(8*200,14*160),'#38454f');d=ImageDraw.Draw(sheet)
for i in range(104):
 im=Image.open(out/'motion_atlas.png').crop((i%8*384,i//8*288,i%8*384+384,i//8*288+288));im.thumbnail((192,144));x=i%8*200;y=i//8*160;sheet.paste(im,(x,y),im);d.text((x+3,y+144),str(i),fill='white')
sheet.save(R/'evidence/stage9/seiya_v2_all_104.png')
manifest={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in A.glob('*.png')}
(A/'generation_manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('SEIYA_TWO_HIT_PACK_OK original=104 new_attack=8 received=12 standing=195')
