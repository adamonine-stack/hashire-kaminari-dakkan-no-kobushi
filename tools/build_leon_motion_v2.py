"""Repack complete measured Leon originals; preserve one anatomical scale and floor."""
from pathlib import Path
from PIL import Image, ImageChops
from collections import deque
import json, math, re, hashlib
ROOT=Path(__file__).resolve().parents[1];G=ROOT/'godot'
ART=ROOT/'art_sources/leon_motion_v2';OUT=G/'assets/characters/enemy08/animations/leon_v2'
CELL=(512,448);BASELINE=404;COLS=6

def area(im):return sum(a>=128 for a in im.getchannel('A').get_flattened_data())

def components(im,minimum=1000):
 w,h=im.size;mask=bytearray(a>=100 for a in im.getchannel('A').get_flattened_data());result=[]
 for seed in range(len(mask)):
  if not mask[seed]:continue
  mask[seed]=0;q=deque([seed]);pixels=[]
  while q:
   p=q.popleft();pixels.append(p);x,y=p%w,p//w
   for dy in [-1,0,1]:
    for dx in [-1,0,1]:
     xx,yy=x+dx,y+dy
     if 0<=xx<w and 0<=yy<h and mask[yy*w+xx]:mask[yy*w+xx]=0;q.append(yy*w+xx)
  if len(pixels)<minimum:continue
  coverage=bytearray(w*h)
  for p in pixels:coverage[p]=255
  selection=Image.frombytes('L',im.size,bytes(coverage));pose=im.copy()
  pose.putalpha(ImageChops.multiply(im.getchannel('A'),selection));box=selection.getbbox()
  result.append((box,pose.crop(box)))
 return sorted(result,key=lambda v:(v[0][0]+v[0][2])/2)

def restore_original(i,records,source):
 r=records[i];box=r['box'];region=source.crop(box)
 mask=Image.open(ROOT/f'evidence/leon_source/pose_{i:02d}.png').getchannel('A')
 # Retain original colors inside the measured character contour, including the
 # purple jacket emblem. Purple effects outside the contour are separate VFX.
 w,h=mask.size;solid=bytearray(a>=100 for a in mask.get_flattened_data());outside=bytearray(w*h);q=deque()
 for x in range(w):q.extend([x,(h-1)*w+x])
 for y in range(h):q.extend([y*w,y*w+w-1])
 while q:
  p=q.popleft()
  if outside[p] or solid[p]:continue
  outside[p]=1;x,y=p%w,p//w
  for n in [p-1 if x else -1,p+1 if x<w-1 else -1,p-w if y else -1,p+w if y<h-1 else -1]:
   if n>=0 and not outside[n] and not solid[n]:q.append(n)
 contour=Image.frombytes('L',(w,h),bytes(255 if not v else 0 for v in outside))
 region.putalpha(ImageChops.multiply(region.getchannel('A'),contour))
 return region

def pack(poses,clips,folder,names,scales):
 folder.mkdir(parents=True,exist_ok=True)
 image=Image.new('RGBA',(CELL[0]*COLS,CELL[1]*math.ceil(len(poses)/COLS)));records=[]
 for i,(pose,name,factor) in enumerate(zip(poses,names,scales)):
  pose=pose.resize((round(pose.width*factor),round(pose.height*factor)),Image.Resampling.NEAREST)
  x=(CELL[0]-pose.width)//2;y=BASELINE-pose.height
  assert x>=8 and y>=8 and x+pose.width<=CELL[0]-8 and y+pose.height<CELL[1]-8,(name,pose.size)
  image.alpha_composite(pose,(i%COLS*CELL[0]+x,i//COLS*CELL[1]+y))
  records.append(dict(index=i,name=name,scale=factor,offset=[x,y],size=list(pose.size),opaque_area=area(pose),relative_area=area(pose)/REFERENCE_AREA))
 image.save(folder/'motion_atlas.png')
 path=(folder/'motion_atlas.png').relative_to(G).as_posix()
 (folder/'motion_atlas.tres').write_text('[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n'+f'[ext_resource type="Texture2D" path="res://{path}" id="2"]\n[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i(512, 448)\ncolumns = 6\nclips = '+json.dumps(clips)+'\n',encoding='utf-8')
 (folder/'packing_manifest.json').write_text(json.dumps(dict(cell=CELL,baseline=BASELINE,reference_area=REFERENCE_AREA,reference_height=296,frames=records),indent=2)+'\n',encoding='utf-8')

records=json.loads((ROOT/'evidence/leon_source/components.json').read_text())
source=Image.open(G/'assets/characters/enemy08/animations/leon_v1/sources/generated_atlas.png').convert('RGBA')
assert len(records)==41,'Expected 39 complete poses, one split spin pose, one truncated portrait'
original=[restore_original(i,records,source) for i in list(range(24))+[25]+list(range(26,40))]
assert len(original)==39
uniform_scale=296/original[0].height
REFERENCE_AREA=area(original[0].resize((round(original[0].width*uniform_scale),296),Image.Resampling.NEAREST))
new=components(Image.open(ART/'additional_actions.png').convert('RGBA'))
assert len(new)==6,('six authored full bodies',len(new))
generated=[pose for box,pose in new]
new_scales=[math.sqrt(REFERENCE_AREA/area(pose)) for pose in generated]
original[24]=generated[5]
original_scales=[uniform_scale]*39
original_scales[24]=new_scales[5]
poses=original+generated
old=(G/'assets/characters/enemy08/animations/leon_v1/motion_atlas.tres').read_text()
clips=json.loads(old.split('clips = ',1)[1])
def setclip(keys,frames,fps=10,loop=False):
 for key in keys.split(','):clips[key]=dict(frames=frames,fps=fps,loop=loop)
setclip('jump_start', [5]);setclip('jump,jump_air',[6,28]);setclip('jump_fall,fall',[28])
setclip('punch,punch_1,light_attack',[13,15,13],13);setclip('punch_2',[16,15,13],13)
setclip('kick,kick_1',[5,20,13],12);setclip('kick_2,heavy_attack,combo_finisher',[13,21,0],12)
setclip('crouch_punch',[39,40,39],11);setclip('crouch_kick,crouch_kick_sweep',[11,25,11],11)
setclip('damage,damage_high,damage_low,damage_light',[33,34],10)
setclip('guard',[10],6,True);setclip('crouch_guard',[11],5,True)
setclip('damage_heavy,knockback',[34],9);setclip('guard_hit',[10,1],9)
setclip('knockdown',[34,35],8);setclip('down,ko,defeat',[35],5)
setclip('stand_up,getup,get_up',[35,37,38,0],8)
setclip('throw,grab',[41,42,43],12);setclip('throw_start',[41],10);setclip('throw_hold',[42],8,True);setclip('throw_release',[43],12)
setclip('grabbed',[33]);setclip('thrown',[34,35],9)
setclip('special_startup',[1,13],8);setclip('special,special_attack',[13,15,16,15],12);setclip('special_recovery',[13,1,0],9)
setclip('special_charge',[13,15,13],12);setclip('special_spin_kick',[13,44,13],12)
setclip('ultimate_startup',[12,30],6);setclip('ultimate_attack',[31],10);setclip('ultimate_recovery',[32,1,0],9)
setclip('jump_punch,jump_punch_down',[6,18,28],11);setclip('jump_kick',[6,7,28],11);setclip('victory',[1,12,1],4)
names=['source_%02d'%i for i in range(39)]+['crouch_punch_start','crouch_punch_active','throw_start','throw_hold','throw_release','spin_kick']
pack(poses,clips,OUT,names,original_scales+new_scales)
fighter=G/'data/enemies/enemy_08_boss.tres';text=fighter.read_text(encoding='utf-8')
text=text.replace('enemy08/animations/leon_v1/motion_atlas.tres','enemy08/animations/leon_v2/motion_atlas.tres')
for family in ['special_received_v1','special_received_gou_v1','special_received_seiya_v1']:
 resource=G/f'assets/characters/{family}/enemy_08_boss/motion_atlas.tres';rs=resource.read_text(encoding='utf-8')
 texturepath=re.search(r'path="res://([^\"]+\.png)"',rs)[1]
 cell=tuple(map(int,re.search(r'cell_size = Vector2i\((\d+), (\d+)\)',rs).groups()))
 cols=int(re.search(r'columns = (\d+)',rs)[1]);sheet=Image.open(G/texturepath).convert('RGBA')
 received=[]
 for i in range(cols):
  im=sheet.crop((i*cell[0],0,(i+1)*cell[0],cell[1]));received.append(im.crop(im.getchannel('A').getbbox()))
 rc=json.loads(rs.split('clips = ',1)[1]);dest=OUT/family
 # One scale for a received-motion family: preserve limb lengths across flight
 # and prone. A lying body naturally has less visible area due to overlap.
 received_scale=math.sqrt(REFERENCE_AREA/area(received[0]))
 pack(received,rc,dest,[f'reaction_{i}' for i in range(cols)],[received_scale]*cols)
 text=text.replace(f'{family}/enemy_08_boss/motion_atlas.tres',f'enemy08/animations/leon_v2/{family}/motion_atlas.tres')
fighter.write_text(text,encoding='utf-8')
ART.mkdir(parents=True,exist_ok=True)
(ART/'reference_idle.png').write_bytes((ROOT/'evidence/leon_source/old_idle.png').read_bytes())
(ART/'generation_manifest.json').write_text(json.dumps(dict(tool='built-in image_gen',prompt='Exact Leon Crow reference, six separated complete right-facing full bodies: crouch punch anticipation/active, throw reach/hold/release, planted spinning roundhouse. Preserve black hair, leather biker jacket, trousers, gloves, lace boots, subtle purple wing emblem, anatomical head and limb proportions; transparent alpha, no effects, text or opponent.',source='additional_actions.png',sha256=hashlib.sha256((ART/'additional_actions.png').read_bytes()).hexdigest(),source_packing='Measured complete connected character contours; all recovered source poses use one uniform scale; generated/reaction body mass matches reference; fixed common canvas and floor.'),indent=2)+'\n',encoding='utf-8')
print('LEON_V2_PACK_OK complete_main_poses=45 received_poses=7 fixed_baseline=404 reference_height=296')
