"""Pack reviewed individual poses; keep runtime sprite scale and floor invariant."""
from pathlib import Path
from PIL import Image
import json, math, hashlib, re
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'art_sources/teki_reversal_v1'
GODOT=ROOT/'godot'
CELL=(512,448)
def area(im): return sum(a>=128 for a in im.getchannel('A').get_flattened_data())
def attach(file,path,key):
 s=file.read_text(encoding='utf-8')
 if f'id="{key}"' in s:return
 s=re.sub(r'load_steps=(\d+)',lambda m:f'load_steps={int(m[1])+1}',s,count=1)
 s=s.replace('[resource]',f'[ext_resource type="Resource" path="res://{path}" id="{key}"]\n\n[resource]',1)
 s=re.sub(r'^(extra_motion_atlases = Array\[Resource\]\(\[)(.*?)(\]\))$',lambda m:m[1]+m[2]+f', ExtResource("{key}")'+m[3],s,flags=re.M)
 file.write_text(s,encoding='utf-8')
def pack(name,files,clips,destination,ratios=None):
 reference=Image.open(ART/'references'/f'{name}.png').convert('RGBA'); ref_area=area(reference)
 rb=reference.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
 baseline=round(CELL[1]/2+rb[3]-reference.height/2)
 columns=4; atlas=Image.new('RGBA',(CELL[0]*columns,CELL[1]*math.ceil(len(files)/columns))); records=[]
 for i,file in enumerate(files):
  source=ART/'frames'/file; im=Image.open(source).convert('RGBA')
  bounds=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox(); im=im.crop(bounds)
  desired=(ratios or {}).get(file,1.0); factor=math.sqrt(ref_area*desired/area(im))
  im=im.resize((round(im.width*factor),round(im.height*factor)),Image.Resampling.NEAREST)
  origin=(round(CELL[0]/2-im.width/2),baseline-im.height)
  assert min(origin)>=4 and origin[0]+im.width<CELL[0]-4,(name,file,im.size,origin)
  atlas.alpha_composite(im,(i%columns*CELL[0]+origin[0],i//columns*CELL[1]+origin[1]))
  records.append(dict(file=file,sha256=hashlib.sha256(source.read_bytes()).hexdigest(),density=factor,origin=origin,size=list(im.size),relative_body_area=area(im)/ref_area))
 folder=GODOT/destination; folder.mkdir(parents=True,exist_ok=True); atlas.save(folder/'motion_atlas.png')
 clip_map={key:dict(frames=frames,fps=fps,loop=False) for key,(frames,fps) in clips.items()}
 (folder/'motion_atlas.tres').write_text('[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n'
 '[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n'
 f'[ext_resource type="Texture2D" path="res://{destination}/motion_atlas.png" id="2"]\n'
 f'[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i(512, 448)\ncolumns = {columns}\nclips = '+json.dumps(clip_map)+'\n',encoding='utf-8')
 (folder/'packing_manifest.json').write_text(json.dumps(dict(reference=f'art_sources/teki_reversal_v1/references/{name}.png',method='Reviewed individual poses; offline body-scale correction; fixed runtime transform and floor baseline; intentional prone overlap mass 0.85 for backflip receivers',baseline=baseline,frames=records),indent=2)+'\n',encoding='utf-8')
 return destination+'/motion_atlas.tres'
def copy_audit(source,dest):
 (ART/'frames'/dest).write_bytes((ROOT/'evidence/teki_audit'/source).read_bytes())
def build_damage():
 sources=[('damage_00.png','teki_hit.png'),('damage_heavy_01.png','teki_air.png'),('stand_up_01.png','teki_rise.png'),('stand_up_02.png','teki_crouch.png'),('idle_00.png','teki_idle.png'),('guard_00.png','teki_guard.png')]
 for src,dst in sources:copy_audit(src,dst)
 files=['teki_hit.png','teki_air.png','teki_down.png','teki_rise.png','teki_crouch.png','teki_idle.png','teki_guard.png']
 clips={}
 for key in ['damage','damage_high','damage_light','grabbed']:clips[key]=([0],10)
 clips['damage_low']=([7],10); files.append('teki_low_hit.png')
 for key in ['damage_heavy','knockback','air_hit','launch_hit']:clips[key]=([0,1],10)
 clips['knockdown']=([0,1,2],9)
 clips['down']=([2],5)
 for key in ['ko','defeat','thrown']:clips[key]=([1,2],8)
 for key in ['stand_up','getup','get_up']:clips[key]=([2,3,4,5],8)
 clips['guard_hit']=([6],10)
 # Preserve authored reaction semantics and opposite prone orientations.
 reaction_clips=json.loads((ROOT/'evidence/teki_audit/frames.json').read_text())
 names=sorted({r['clip'] for r in reaction_clips if r['clip'].startswith('received_')})
 ratios={}
 for key in names:
  indices=[]
  for r in [r for r in reaction_clips if r['clip']==key]:
   dest='teki_'+r['file'];copy_audit(r['file'],dest); indices.append(len(files));files.append(dest)
   if key in ['received_gou_breaker_down','received_seiya_two_down']:ratios[dest]=0.85
  clips[key]=(indices,12 if not key.endswith('_down') else 5)
 path=pack('teki',files,clips,'assets/characters/enemy07/animations/teki_damage_v2',ratios)
 attach(GODOT/'data/enemies/enemy_07_tricky.tres',path,'teki_damage_v2')
def build_special():
 path=pack('teki',[f'teki_{i:02d}_{pose}.png' for i,pose in enumerate(['anticipation','coil','step','strike','impact','retract','recover','finish'])],{
 'teki_deadly_startup':([0,1,2],3/.18),'teki_deadly_hand':([3,4],2/.20),'teki_deadly_finish':([5,6,7],3/.55)},'assets/characters/enemy07/animations/teki_reversal_v1')
 attach(GODOT/'data/enemies/enemy_07_tricky.tres',path,'teki_reversal_v1')
 for name,fighter in [('akky','ally_balance'),('gou','ally_power'),('seiya','ally_speed')]:
  path=pack(name,[f'{name}_{pose}_0.png' for pose in ['hit','air','down','guard']]+[f'{name}_guard_1.png'],{
  'received_teki_palm_hit':([0],10),'received_teki_palm_air':([0,1],12),'received_teki_palm_down':([2],5),'received_teki_palm_guard':([3,4],2/.28)},f'assets/characters/special_received_teki_v1/{fighter}')
  file=GODOT/f'data/fighters/{fighter}.tres';attach(file,path,'received_teki')
  s=file.read_text(encoding='utf-8');m=re.search(r'^special_damage_reactions = (.+)$',s,re.M);reactions=json.loads(m[1]) if m else {}
  reactions['teki_deadly_hand']=dict(hit='received_teki_palm_hit',airborne='received_teki_palm_air',down='received_teki_palm_down')
  if m:s=s[:m.start(1)]+json.dumps(reactions)+s[m.end(1):]
  else:s+='\nspecial_damage_reactions = '+json.dumps(reactions)+'\n'
  file.write_text(s,encoding='utf-8')
 attack=GODOT/'data/attacks/teki_deadly_hand.tres';s=attack.read_text(encoding='utf-8')
 for key,value in [('startup_time','0.18'),('active_time','0.20'),('hitbox_size','Vector2(84, 96)'),('hitbox_offset','Vector2(70, -116)'),('special_startup_animation','&"teki_deadly_startup"'),('special_finish_animation','&"teki_deadly_finish"'),('special_guard_reaction','&"received_teki_palm_guard"'),('keep_special_flight_in_view','true'),('special_launch_speed_cap','Vector2(420, 280)'),('special_launch_gravity','1000.0')]:
  if re.search(r'^'+key+r' =',s,re.M):s=re.sub(r'^'+key+r' =.*$',f'{key} = {value}',s,flags=re.M)
  else:s+=f'\n{key} = {value}\n'
 attack.write_text(s,encoding='utf-8')
if __name__=='__main__':
 import sys
 if '--damage-only' in sys.argv:build_damage()
 else:build_damage();build_special()
 print('TEKI_PACK_OK')
