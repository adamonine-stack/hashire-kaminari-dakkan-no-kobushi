from pathlib import Path
from PIL import Image, ImageChops
import re,json,math
import motion_packing as m
G=m.G;ROOT=m.ROOT
m.CELL=(320,256);m.BASELINE=240;m.COLS=8;m.REFERENCE_HEIGHT=171
OUT=G/'assets/characters/enemy06/animations/rio_garcia_v2'
ART=ROOT/'art_sources/rio_motion_v2'
old=(G/'assets/characters/enemy06/animations/rio_garcia_v1/motion_atlas.tres').read_text()
clips=json.loads(old.split('clips = ',1)[1].split('\nframe_regions',1)[0])
regions=[tuple(map(int,x)) for x in re.findall(r'Rect2i\((\d+), (\d+), (\d+), (\d+)\)',old)]
source=Image.open(G/'assets/characters/enemy06/animations/rio_garcia_v1/motion_atlas.png').convert('RGBA')
assert len(regions)==56
poses=[]
for x,y,w,h in regions:
 im=source.crop((x,y,x+w,y+h))
 # Measured legacy cells may include isolated pixels from neighboring poses.
 bodies=m.components(im,alpha_threshold=1);body=max(bodies,key=lambda item:m.area(item[1]))[1]
 poses.append(body)
m.REFERENCE_AREA=m.area(poses[0]);assert poses[0].height==171
new=m.components(Image.open(ART/'additional_actions.png').convert('RGBA'))
# Sort the two sprite rows, then left to right.
new.sort(key=lambda v:(int(((v[0][1]+v[0][3])/2)//600),(v[0][0]+v[0][2])/2))
assert len(new)==6,('six single-actor originals required',len(new))
generated=[im for box,im in new];scales=[math.sqrt(m.REFERENCE_AREA/m.area(im)) for im in generated]
for i in range(48,54):poses[i]=generated[(i-48)%3]
main_scales=[1.0]*56
for i in range(48,54):main_scales[i]=scales[(i-48)%3]
rs=(G/'assets/characters/special_received_v1/enemy_06_combo/motion_atlas.tres').read_text()
received_sheet=Image.open(G/'assets/characters/special_received_v1/enemy_06_combo/motion_atlas.png').convert('RGBA')
received=[]
for i in range(3):
 im=received_sheet.crop((i*320,0,(i+1)*320,256));received.append(im.crop(im.getchannel('A').getbbox()))
received_scale=math.sqrt(m.REFERENCE_AREA/m.area(received[0]))
poses+=generated+received;main_scales+=scales+[received_scale]*3
def setclip(keys,frames,fps=10,loop=False):
 for key in keys.split(','):clips[key]=dict(frames=frames,fps=fps,loop=loop)
setclip('guard',[0,1],6,True);setclip('crouch,crouch_idle,crouch_guard',[59],6,True)
setclip('punch,punch_1,light_attack',[24,26,30],12);setclip('punch_2',[25,28,31],12)
setclip('kick,kick_1',[32,34,36],12);setclip('kick_2,heavy_attack,combo_finisher',[36,37,39],12)
setclip('crouch_punch',[59,60,59],12);setclip('crouch_kick,crouch_kick_sweep',[59,61,59],12)
setclip('jump_start',[33],9);setclip('jump,jump_air',[35],8);setclip('jump_fall,fall',[35],8)
setclip('jump_land,land,landing',[59,0],9);setclip('jump_punch,jump_punch_down',[35,26,35],11);setclip('jump_kick',[35,34,35],11)
setclip('damage,damage_high,damage_low,damage_light',[62],9);setclip('damage_heavy,knockback',[62,63],9)
setclip('guard_hit',[0,1],9);setclip('knockdown',[63,64],8);setclip('down,ko,defeat',[64],5)
setclip('getup,get_up,stand_up',[64,59,0],8);setclip('grabbed',[62],8);setclip('thrown',[63,64],8)
setclip('throw,grab',[56,57,58],12);setclip('throw_start',[56],10);setclip('throw_hold',[57],8,True);setclip('throw_release',[58],12)
setclip('special_startup',[24],10);setclip('special,special_attack',[24,26,30],16);setclip('special_recovery',[30,0],9)
setclip('special_01,tackle,flying_tackle',[16,18,56,16],13);setclip('special_02,grapple,backdrop,suplex,neck_throw,brainbuster,spinning_back_toss',[56,57,58],12)
setclip('arm_lock,foot_lock,front_choke,pin,ground_grapple,submission',[57],8)
names=['source_%02d'%i for i in range(56)]+['grip_start','grip_hold','grip_release','crouch_start','crouch_punch','crouch_sweep','damage','air','down']
m.pack(poses,clips,OUT,names,main_scales)
fighter=G/'data/enemies/enemy_06_combo.tres';text=fighter.read_text(encoding='utf-8').replace('rio_garcia_v1/motion_atlas.tres','rio_garcia_v2/motion_atlas.tres').replace('rio_garcia_v1/motion_atlas.png','rio_garcia_v2/motion_atlas.png')
for family in ['special_received_v1','special_received_gou_v1','special_received_seiya_v1']:
 resource=G/f'assets/characters/{family}/enemy_06_combo/motion_atlas.tres';rs=resource.read_text();texturepath=re.search(r'path="res://([^\"]+\.png)"',rs)[1]
 cell=tuple(map(int,re.search(r'cell_size = Vector2i\((\d+), (\d+)\)',rs).groups()));cols=int(re.search(r'columns = (\d+)',rs)[1]);sheet=Image.open(G/texturepath).convert('RGBA');received=[]
 for i in range(cols):
  im=sheet.crop((i*cell[0],0,(i+1)*cell[0],cell[1]));received.append(im.crop(im.getchannel('A').getbbox()))
 m.pack(received,json.loads(rs.split('clips = ',1)[1]),OUT/family,[f'reaction_{i}' for i in range(cols)],[math.sqrt(m.REFERENCE_AREA/m.area(received[0]))]*cols)
 text=text.replace(f'{family}/enemy_06_combo/motion_atlas.tres',f'enemy06/animations/rio_garcia_v2/{family}/motion_atlas.tres')
fighter.write_text(text,encoding='utf-8')
print('RIO_V2_SINGLE_ACTOR_PACK_OK reference_height=171 body_count=1')
