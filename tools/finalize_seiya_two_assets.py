from pathlib import Path
from PIL import Image
import re,json
import motion_packing as m
R=m.ROOT;G=m.G
for p in sorted((G/'data/enemies').glob('enemy_*.tres')):
 s=p.read_text(encoding='utf-8');line=re.search(r'^special_damage_reactions = (.+)$',s,re.M)
 if not line or 'player3_special_clear_counter' not in line[1]:continue
 if p.stem=='enemy_09_seiya':continue
 resource=G/f'assets/characters/special_received_seiya_v1/{p.stem}/motion_atlas.tres'
 # Use the character's repaired supplementary atlas if its definition overrides it.
 actual=re.search(r'path="res://([^\"]+)" id="received_seiya"',s)
 if actual:resource=G/actual[1]
 rs=resource.read_text(encoding='utf-8');clips=json.loads(rs.split('clips = ',1)[1]);old='received_seiya_somersault'
 for a,b in [('lift','hit'),('fall','air'),('fly','air'),('down','down')]:clips['received_seiya_two_'+a]=clips[old+'_'+b]
 rs=rs.split('clips = ',1)[0]+'clips = '+json.dumps(clips)+'\n'
 dest=G/f'assets/characters/seiya_two_received_v1/{p.stem}';dest.mkdir(parents=True,exist_ok=True);(dest/'motion_atlas.tres').write_text(rs,encoding='utf-8')
 key='seiya_two_received';path=dest.relative_to(G).as_posix()+'/motion_atlas.tres'
 if f'id="{key}"' not in s:
  s=re.sub(r'load_steps=(\d+)',lambda v:f'load_steps={int(v[1])+1}',s,count=1)
  s=s.replace('[resource]',f'[ext_resource type="Resource" path="res://{path}" id="{key}"]\n\n[resource]',1)
  s=re.sub(r'extra_motion_atlases = Array\[Resource\]\(\[(.*?)\]\)',lambda v:'extra_motion_atlases = Array[Resource](['+v[1]+f', ExtResource("{key}")])',s)
 line=re.search(r'^special_damage_reactions = (.+)$',s,re.M);reactions=json.loads(line[1]);reactions['player3_special_clear_counter']=dict(hit='received_seiya_two_lift',airborne='received_seiya_two_lift',down='received_seiya_two_down',wall='received_seiya_two_fly',fall='received_seiya_two_fly')
 # Stage-specific contact uses the packet's pose; select per-hit below in runtime.
 s=s[:line.start(1)]+json.dumps(reactions)+s[line.end(1):];p.write_text(s,encoding='utf-8')
# Precompute hair landmarks for every new atlas: widest connected golden hair
# cluster is tracked even when inverted; the beige legs are never head candidates.
f=G/'assets/characters/player03/animations/dark_seiya_v1/head_landmarks.json';landmarks=json.loads(f.read_text(encoding='utf-8'))
for folder in ['seiya_v2','two_hit_v1','seiya_two_received_v1']:
 p=G/f'assets/characters/player03/animations/{folder}/motion_atlas.png';im=Image.open(p).convert('RGBA');count=104 if folder=='seiya_v2' else (8 if folder=='two_hit_v1' else 4);cols=8 if folder!='seiya_two_received_v1' else 4
 for i in range(count):
  frame=im.crop((i%cols*384,i//cols*288,i%cols*384+384,i//cols*288+288));mask=frame.copy();pix=[]
  for r,g,b,a in frame.get_flattened_data():pix.append((r,g,b,a if a>150 and r>160 and g>95 and b<r*.48 and g<r*.9 else 0))
  mask.putdata(pix);parts=m.components(mask,minimum=12,alpha_threshold=100)
  if not parts:continue
  box,body=max(parts,key=lambda v:m.area(v[1]));x,y,x2,y2=box
  # Hair, cheeks and neck are one local rectangle; never a horizontal full strip.
  body=frame.getchannel('A').getbbox();dx=(x+x2-body[0]-body[2])/2;dy=(y+y2-body[1]-body[3])/2
  if abs(dx)>abs(dy): rect=[x-15 if dx>0 else x-4,y-4,x2-x+19,y2-y+8]
  elif dy>0: rect=[x-4,y-15,x2-x+8,y2-y+19]
  else: rect=[x-4,y-4,x2-x+8,y2-y+19]
  landmarks[f'{folder}/motion_atlas.png:{i%cols*384}:{i//cols*288}']=rect
f.write_text(json.dumps(landmarks),encoding='utf-8')
print('SEIYA_TWO_ASSET_REGISTRATION_OK enemies=9 hair_landmarks=true')
