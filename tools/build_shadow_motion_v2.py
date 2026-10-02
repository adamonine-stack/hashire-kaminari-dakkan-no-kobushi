from pathlib import Path
from PIL import Image, ImageChops
import re,json,math
import motion_packing as m
G=m.G;ROOT=m.ROOT
m.CELL=(320,256);m.BASELINE=240;m.COLS=8;m.REFERENCE_HEIGHT=149
OUT=G/'assets/characters/enemy05/animations/shadow_boxer_v2'
ART=ROOT/'art_sources/shadow_motion_v2'
old=(G/'assets/characters/enemy05/animations/shadow_boxer_v1/motion_atlas.tres').read_text()
clips=json.loads(old.split('clips = ',1)[1].split('\nframe_regions',1)[0])
regions=[tuple(map(int,x)) for x in re.findall(r'Rect2i\((\d+), (\d+), (\d+), (\d+)\)',old)]
source=Image.open(G/'assets/characters/enemy05/animations/shadow_boxer_v1/motion_atlas.png').convert('RGBA')
assert len(regions)==56
poses=[]
for x,y,w,h in regions:
 im=source.crop((x,y,x+w,y+h))
 # Measured legacy cells may include isolated pixels from neighboring poses.
 bodies=m.components(im,alpha_threshold=1);body=max(bodies,key=lambda item:m.area(item[1]))[1]
 poses.append(body)
m.REFERENCE_AREA=m.area(poses[0]);assert poses[0].height==151

# Preserve the current 149px idle and constant 190cm runtime scale.
factors=[149/p.height if i in set(range(16))|set(range(24,40))|{42,43,46,47} else math.sqrt(m.REFERENCE_AREA/m.area(p)) for i,p in enumerate(poses)]
factors=[min(f,316/p.width,238/p.height) for f,p in zip(factors,poses)]
m.REFERENCE_AREA=m.area(poses[0].resize((round(poses[0].width*factors[0]),149),Image.Resampling.NEAREST))
items=m.components(Image.open(ART/'additional_actions.png').convert('RGBA'));assert len(items)==8,len(items)
items.sort(key=lambda v:v[0][1]+v[0][3]);items=sorted(items[:4],key=lambda v:v[0][0])+sorted(items[4:],key=lambda v:v[0][0])
for box,p in items:poses.append(p);factors.append(min(math.sqrt(m.REFERENCE_AREA/m.area(p)),316/p.width,238/p.height))
def clip(keys,frames,fps=10,loop=False):
 for key in keys.split(','):clips[key]=dict(frames=frames,fps=fps,loop=loop)
clip('shadow_counter_startup,special_startup',[56],10)
clip('shadow_counter_active,special,special_attack',[57],10)
clip('shadow_counter_finish,special_recovery',[58,0],10)
clip('punch,punch_1',[24,27,29],12);clip('punch_2',[32,44,46],12)
clip('kick,kick_1',[32,57,58],12);clip('kick_2',[40,44,46],12)
clip('jump_kick',[18,59,23],12)
clip('crouch_kick,crouch_kick_sweep',[40,60,40],12)
clip('throw_start',[61]);clip('throw_hold',[62],8,True);clip('throw_release',[63]);clip('throw,grab',[61,62,63],12)
# Legacy rows use bare-hand overhead attacks; replace those with complete gloved art.
poses[35]=poses[57];factors[35]=factors[57];poses[36]=poses[57];factors[36]=factors[57];poses[37]=poses[58];factors[37]=factors[58]
m.pack(poses,clips,OUT,['source_%02d'%i for i in range(56)]+['slip','counter','recover','air_kick','sweep','grip','hold','release'],factors)
p=G/'data/enemies/enemy_02_speed.tres';text=p.read_text(encoding='utf-8').replace('shadow_boxer_v1/motion_atlas','shadow_boxer_v2/motion_atlas')
for family in ['special_received_v1','special_received_gou_v1','special_received_seiya_v1']:
 resource=G/f'assets/characters/{family}/enemy_02_speed/motion_atlas.tres';rs=resource.read_text();texture=re.search(r'path="res://([^\"]+\.png)"',rs)[1]
 cell=tuple(map(int,re.search(r'cell_size = Vector2i\((\d+), (\d+)\)',rs).groups()));cols=int(re.search(r'columns = (\d+)',rs)[1]);im=Image.open(G/texture).convert('RGBA');parts=[]
 for i in range(cols):
  p=im.crop((i*cell[0],0,(i+1)*cell[0],cell[1]));parts.append(p.crop(p.getchannel('A').getbbox()))
 scale=math.sqrt(m.REFERENCE_AREA/m.area(parts[0]));factors=[min(math.sqrt(m.REFERENCE_AREA/m.area(p)),scale*1.015,238/p.height,316/p.width) for p in parts]
 m.pack(parts,json.loads(rs.split('clips = ',1)[1]),OUT/family,[f'reaction_{i}' for i in range(cols)],factors)
 text=text.replace(f'{family}/enemy_02_speed/motion_atlas.tres',f'enemy05/animations/shadow_boxer_v2/{family}/motion_atlas.tres')
(G/'data/enemies/enemy_02_speed.tres').write_text(text,encoding='utf-8')
items=m.components(Image.open(ART/'received_actions.png').convert('RGBA'));assert len(items)==9,len(items)
items.sort(key=lambda v:v[0][1]+v[0][3])
for row,(hero,definition) in enumerate([('player01','ally_balance'),('player02','ally_power'),('player03','ally_speed')]):
 parts=[p for b,p in sorted(items[row*3:row*3+3],key=lambda v:v[0][0])]
 resource=G/f'data/fighters/{definition}.tres';text=resource.read_text(encoding='utf-8');atlaspath=re.search(r'path="res://([^\"]+motion_atlas\.tres)"',text)[1];rs=(G/atlaspath).read_text();cell=tuple(map(int,re.search(r'cell_size = Vector2i\((\d+), (\d+)\)',rs).groups()));im=Image.open(G/re.search(r'path="res://([^\"]+\.png)"',rs)[1]).convert('RGBA');idle=im.crop((0,0,cell[0],cell[1]));box=idle.getchannel('A').getbbox()
 m.CELL=cell;m.COLS=3;m.BASELINE=box[3];m.REFERENCE_HEIGHT=box[3]-box[1];m.REFERENCE_AREA=m.area(idle)
 factors=[min(math.sqrt(m.REFERENCE_AREA/m.area(p)),(cell[0]-8)/p.width,(m.BASELINE-8)/p.height) for p in parts]
 clips={f'received_shadow_counter_{name}':dict(frames=[i],fps=10,loop=False) for i,name in enumerate(['hit','air','down'])}
 m.pack(parts,clips,G/f'assets/characters/{hero}/animations/shadow_counter_received_v1',['hit','air','down'],factors)
 if 'id="shadow_counter_received"' not in text:
  text=re.sub(r'load_steps=(\d+)',lambda v:f'load_steps={int(v[1])+1}',text,count=1)
  text=text.replace('[resource]',f'[ext_resource type="Resource" path="res://assets/characters/{hero}/animations/shadow_counter_received_v1/motion_atlas.tres" id="shadow_counter_received"]\n\n[resource]',1)
  text=re.sub(r'extra_motion_atlases = Array\[Resource\]\(\[(.*?)\]\)',lambda v:'extra_motion_atlases = Array[Resource](['+v[1]+', ExtResource("shadow_counter_received")])',text)
  text=text.replace('special_damage_reactions = {','special_damage_reactions = {"shadow_slip_counter": {"hit":"received_shadow_counter_hit","airborne":"received_shadow_counter_air","down":"received_shadow_counter_down"},',1)
  resource.write_text(text,encoding='utf-8')
print('SHADOW_MOTION_V2_PACK_OK standing_height=149 original_poses=56 dedicated_poses=8 receivers=9')
