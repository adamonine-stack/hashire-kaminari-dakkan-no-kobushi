"""Normalize complete Cross poses and pack dedicated Muei attacker/receiver art."""
from pathlib import Path
from PIL import Image
import json, re, math
import motion_packing as m

G=m.G; ROOT=m.ROOT; ART=ROOT/'art_sources/cross_motion_v2'
OUT=G/'assets/characters/enemy05/animations/cross_v2'
m.CELL=(384,288); m.COLS=8; m.BASELINE=270; m.REFERENCE_HEIGHT=213
old=G/'assets/characters/enemy05/animations/cross_v1'
sheet=Image.open(old/'motion_atlas.png').convert('RGBA')
clips=json.loads((old/'motion_atlas.tres').read_text().split('clips = ',1)[1])
poses=[]
for i in range(56):
    im=sheet.crop((i%8*384,i//8*288,i%8*384+384,i//8*288+288))
    parts=m.components(im,alpha_threshold=1)
    poses.append(max(parts,key=lambda x:m.area(x[1]))[1])
m.REFERENCE_AREA=m.area(poses[0]); assert poses[0].height==213
standing=set(range(6))|set(range(12,19))|{24,27,28,34,36,38,48,51,53}
scales=[]
for i,p in enumerate(poses):
    factor=213/p.height if i in standing else math.sqrt(m.REFERENCE_AREA/m.area(p))
    # A prone drawing has overlapping limbs: don't enlarge its physical length
    # just to recover the hidden silhouette area.
    if i==32: factor=min(factor,213*1.15/p.width)
    factor=min(factor,380/p.width,266/p.height)
    scales.append(factor)
items=m.components(Image.open(ART/'additional_actions.png').convert('RGBA'))
assert len(items)==8,('eight complete single actors',len(items))
items.sort(key=lambda item:item[0][1]+item[0][3])
ordered=[]
for row in range(2): ordered+=sorted(items[row*4:row*4+4],key=lambda item:item[0][0])
for box,p in ordered:
    poses.append(p); scales.append(min(math.sqrt(m.REFERENCE_AREA/m.area(p)),380/p.width,266/p.height))
# Replace the ambiguous kick drawing with its complete, blur-free equivalent.
poses[19]=poses[62]; scales[19]=scales[62]
def put(names,frames,fps=12,loop=False):
    for name in names.split(','): clips[name]=dict(frames=frames,fps=fps,loop=loop)
put('special_startup',[56,57],12)
put('special,special_attack,cross_muei',[57],12)
put('special_recovery',[61,0],10)
put('cross_muei_grip',[57],12)
put('cross_muei_hold',[58,59],8,False)
put('cross_muei_release',[60,61],10)
put('jump_kick',[9,63,10],10)
m.pack(poses,clips,OUT,[f'original_{i}' for i in range(56)]+['charge','reach','grip','pivot','release','recover','high_kick','air_kick'],scales)
fighter=G/'data/enemies/enemy_05_power.tres'
s=fighter.read_text(encoding='utf-8').replace('cross_v1/motion_atlas.tres','cross_v2/motion_atlas.tres')
# Repack Cross's reactions to ally specials in the same cell/pivot/density.
for family in ['special_received_v1','special_received_gou_v1','special_received_seiya_v1']:
    source=G/f'assets/characters/{family}/enemy_05_power/motion_atlas.tres'
    rs=source.read_text(); cell=tuple(map(int,re.search(r'cell_size = Vector2i\((\d+), (\d+)\)',rs).groups()))
    cols=int(re.search(r'columns = (\d+)',rs)[1]); texture=re.search(r'path="res://([^"]+\.png)"',rs)[1]
    im=Image.open(G/texture).convert('RGBA'); parts=[]
    for i in range(cols):
        p=im.crop((i*cell[0],0,(i+1)*cell[0],cell[1]));parts.append(p.crop(p.getchannel('A').getbbox()))
    factor=min(math.sqrt(m.REFERENCE_AREA/m.area(parts[0])),min(268/p.height for p in parts),min(380/p.width for p in parts))
    m.pack(parts,json.loads(rs.split('clips = ',1)[1]),OUT/family,[f'reaction_{i}' for i in range(cols)],[min(math.sqrt(m.REFERENCE_AREA/m.area(p)),factor*1.015,268/p.height,380/p.width) for p in parts])
    s=s.replace(f'{family}/enemy_05_power/motion_atlas.tres',f'enemy05/animations/cross_v2/{family}/motion_atlas.tres')
fighter.write_text(s,encoding='utf-8')
# Three new authored receiver sets, each normalized to that hero's standing art.
items=m.components(Image.open(ART/'received_actions.png').convert('RGBA'))
assert len(items)==9,('nine isolated receivers',len(items))
items.sort(key=lambda item:item[0][1]+item[0][3])
heroes=[('player01','akky_v3','ally_balance'),('player02','gou_v1','ally_power'),('player03','seiya_v1','ally_speed')]
for row,(hero,main,definition) in enumerate(heroes):
    primary=G/f'assets/characters/{hero}/animations/{main}';rs=(primary/'motion_atlas.tres').read_text()
    m.CELL=tuple(map(int,re.search(r'cell_size = Vector2i\((\d+), (\d+)\)',rs).groups()));m.COLS=3
    idle=Image.open(primary/'motion_atlas.png').convert('RGBA').crop((0,0,*m.CELL));bounds=idle.getchannel('A').getbbox()
    m.BASELINE=bounds[3];m.REFERENCE_HEIGHT=bounds[3]-bounds[1];m.REFERENCE_AREA=m.area(idle)
    parts=[item[1] for item in sorted(items[row*3:row*3+3],key=lambda item:item[0][0])]
    scales=[min(math.sqrt(m.REFERENCE_AREA/m.area(p)),(m.CELL[0]-8)/p.width,(m.BASELINE-8)/p.height) for p in parts]
    receive={name:dict(frames=[i],fps=10,loop=False) for i,name in enumerate(['cross_muei_held','cross_muei_air','cross_muei_down'])}
    dest=G/f'assets/characters/{hero}/animations/cross_muei_received_v1'
    m.pack(parts,receive,dest,['held','air','down'],scales)
    p=G/f'data/fighters/{definition}.tres';s=p.read_text(encoding='utf-8')
    if 'id="cross_muei_received"' in s: continue
    s=re.sub(r'load_steps=(\d+)',lambda v:f'load_steps={int(v[1])+1}',s,count=1)
    s=s.replace('[resource]',f'[ext_resource type="Resource" path="res://assets/characters/{hero}/animations/cross_muei_received_v1/motion_atlas.tres" id="cross_muei_received"]\n\n[resource]',1)
    s=re.sub(r'extra_motion_atlases = Array\[Resource\]\(\[(.*?)\]\)',lambda v:'extra_motion_atlases = Array[Resource](['+v[1]+', ExtResource("cross_muei_received")])',s)
    p.write_text(s,encoding='utf-8')
print('CROSS_MOTION_V2_PACK_OK standing_height=213 original_poses=56 dedicated_poses=8 receivers=9')
