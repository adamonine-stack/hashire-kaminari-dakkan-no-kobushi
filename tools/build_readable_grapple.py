from pathlib import Path
from PIL import Image
import motion_packing as m
import json,re,math
G=m.G;ROOT=m.ROOT
m.CELL=(512,448);m.COLS=6;m.BASELINE=404;m.REFERENCE_HEIGHT=295
old=G/'assets/characters/enemy03/animations/masato_v2';out=old.with_name('masato_v3');sheet=Image.open(old/'motion_atlas.png').convert('RGBA')
poses=[]
for i in range(45):
 im=sheet.crop((i%6*512,i//6*448,i%6*512+512,i//6*448+448));poses.append(im.crop(im.getchannel('A').getbbox()))
m.REFERENCE_AREA=m.area(poses[0]);items=m.components(Image.open(ROOT/'art_sources/masato_grapple_v3/additional_actions.png').convert('RGBA'));items.sort(key=lambda v:v[0][0]);assert len(items)==3
scales=[1.0]*45
for i,(box,pose) in enumerate(items):poses[42+i]=pose;scales[42+i]=math.sqrt(m.REFERENCE_AREA/m.area(pose))
m.pack(poses,json.loads((old/'motion_atlas.tres').read_text().split('clips = ',1)[1]),out,[f'original_{i}' for i in range(45)],scales)
for family in ['special_received_v1','special_received_gou_v1','special_received_seiya_v1']:
 dest=out/family;dest.mkdir(parents=True,exist_ok=True)
 for p in (old/family).iterdir():
  if p.suffix=='.tres':(dest/p.name).write_text(p.read_text().replace('masato_v2','masato_v3'))
  elif p.suffix in ['.png','.json']:(dest/p.name).write_bytes(p.read_bytes())
p=G/'data/enemies/enemy_03_guard.tres';p.write_text(p.read_text(encoding='utf-8').replace('masato_v2','masato_v3'),encoding='utf-8')
for hero,main,definition in [('player01','akky_v3','ally_balance'),('player02','gou_v1','ally_power'),('player03','seiya_v1','ally_speed')]:
 primary=G/f'assets/characters/{hero}/animations/{main}';rs=(primary/'motion_atlas.tres').read_text();m.CELL=tuple(map(int,re.search(r'cell_size = Vector2i\((\d+), (\d+)\)',rs).groups()));m.COLS=3
 idle=Image.open(primary/'motion_atlas.png').convert('RGBA').crop((0,0,*m.CELL));bounds=idle.getchannel('A').getbbox();m.BASELINE=bounds[3];m.REFERENCE_HEIGHT=bounds[3]-bounds[1];m.REFERENCE_AREA=m.area(idle)
 received=G/f'assets/characters/{hero}/animations/cross_reactions';rs=(received/'reactions.tres').read_text();cell=tuple(map(int,re.search(r'cell_size = Vector2i\((\d+), (\d+)\)',rs).groups()));sheet=Image.open(received/'reactions.png').convert('RGBA');poses=[]
 for i in [0,2,4]:
  im=sheet.crop((i*cell[0],0,(i+1)*cell[0],cell[1]));poses.append(im.crop(im.getchannel('A').getbbox()))
 factor=math.sqrt(m.REFERENCE_AREA/m.area(poses[0]));clips={'grapple_held':dict(frames=[0],fps=8,loop=True),'grapple_air':dict(frames=[1],fps=8,loop=False),'grapple_down':dict(frames=[2],fps=5,loop=False)}
 dest=G/f'assets/characters/{hero}/animations/readable_grapple_v1';m.pack(poses,clips,dest,['held','air','down'],[factor]*3)
 p=G/f'data/fighters/{definition}.tres';text=p.read_text(encoding='utf-8')
 if 'id="readable_grapple"' in text: continue
 text=re.sub(r'load_steps=(\d+)',lambda v:f'load_steps={int(v[1])+1}',text, count=1)
 text=text.replace('[resource]',f'[ext_resource type="Resource" path="res://assets/characters/{hero}/animations/readable_grapple_v1/motion_atlas.tres" id="readable_grapple"]\n\n[resource]',1)
 text=re.sub(r'extra_motion_atlases = Array\[Resource\]\(\[(.*?)\]\)',lambda v:'extra_motion_atlases = Array[Resource](['+v[1]+', ExtResource("readable_grapple")])',text)
 p.write_text(text,encoding='utf-8')
print('READABLE_GRAPPLE_ORIGINALS_OK allies=3 actor_parts_only=true')
