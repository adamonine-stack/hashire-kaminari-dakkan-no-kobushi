"""Pack individually reviewed Rei poses with fixed runtime scale and floor alignment."""
from pathlib import Path
from PIL import Image
import json, math, hashlib, re
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'art_sources/rei_reversal_v1'
GODOT=ROOT/'godot'
CELL=(512,448)
def area(im):
    return sum(a>=128 for a in im.getchannel('A').get_flattened_data())
def attach(file,path,key):
    s=file.read_text(encoding='utf-8')
    if f'id="{key}"' in s:return
    s=re.sub(r'load_steps=(\d+)',lambda m:f'load_steps={int(m[1])+1}',s,count=1)
    s=s.replace('[resource]',f'[ext_resource type="Resource" path="res://{path}" id="{key}"]\n\n[resource]',1)
    s=re.sub(r'^(extra_motion_atlases = Array\[Resource\]\(\[)(.*?)(\]\))$',lambda m:m[1]+m[2]+f', ExtResource("{key}")'+m[3],s,flags=re.M)
    file.write_text(s,encoding='utf-8')
def pack(name,files,clips,destination,columns):
    reference=Image.open(ART/'references'/f'{name}.png').convert('RGBA')
    ref_area=area(reference)
    rb=reference.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
    baseline=round(CELL[1]/2+rb[3]-reference.height/2)
    atlas=Image.new('RGBA',(CELL[0]*columns,CELL[1]*math.ceil(len(files)/columns)))
    records=[]
    for i,file in enumerate(files):
        source=ART/'frames'/file
        im=Image.open(source).convert('RGBA')
        bounds=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
        im=im.crop(bounds)
        factor=math.sqrt(ref_area/area(im))
        im=im.resize((round(im.width*factor),round(im.height*factor)),Image.Resampling.NEAREST)
        origin=(round(CELL[0]/2-im.width/2),baseline-im.height)
        assert min(origin)>=4 and origin[0]+im.width<CELL[0]-4,(name,file,im.size,origin)
        atlas.alpha_composite(im,(i%columns*CELL[0]+origin[0],i//columns*CELL[1]+origin[1]))
        records.append(dict(file=file,sha256=hashlib.sha256(source.read_bytes()).hexdigest(),density=factor,origin=origin,size=list(im.size),relative_body_area=area(im)/ref_area))
    folder=GODOT/destination
    folder.mkdir(parents=True,exist_ok=True)
    atlas.save(folder/'motion_atlas.png')
    clip_map={key:dict(frames=frames,fps=fps,loop=False) for key,(frames,fps) in clips.items()}
    (folder/'motion_atlas.tres').write_text('[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n'
        '[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n'
        f'[ext_resource type="Texture2D" path="res://{destination}/motion_atlas.png" id="2"]\n'
        f'[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i(512, 448)\ncolumns = {columns}\nclips = '+json.dumps(clip_map)+'\n',encoding='utf-8')
    (folder/'packing_manifest.json').write_text(json.dumps(dict(reference=f'art_sources/rei_reversal_v1/references/{name}.png',method='Individual reviewed originals; idle opaque body area; fixed canvas and floor baseline; unchanged runtime scale',baseline=baseline,frames=records),indent=2)+'\n',encoding='utf-8')
    return destination+'/motion_atlas.tres'
path=pack('rei',[f'rei_{i:02d}_{pose}.png' for i,pose in enumerate(['anticipation','load','coil','rise','impact','return','recover','finish'])]+['rei_prebattle.png','rei_idle.png'],{
    'rei_uppercut_startup':([0,1,2],3/.18),
    'rei_dragon_uppercut':([3,4],2/.20),
    'rei_uppercut_finish':([5,6,7],3/.55),
    'idle_prebattle':([8,9],3)},'assets/characters/enemy04/animations/rei_reversal_v1',4)
attach(GODOT/'data/enemies/enemy_04_throw.tres',path,'rei_reversal')
for name,fighter in [('akky','ally_balance'),('gou','ally_power'),('seiya','ally_speed')]:
    path=pack(name,[name+'_'+pose+'.png' for pose in ['hit','air','down','guard_impact','guard_hold']],{
        'received_rei_uppercut_hit':([0],12),
        'received_rei_uppercut_air':([0,1],12),
        'received_rei_uppercut_down':([2],5),
        'received_rei_uppercut_guard':([3,4],2/.28)},f'assets/characters/special_received_rei_v1/{fighter}',5)
    file=GODOT/f'data/fighters/{fighter}.tres'
    attach(file,path,'received_rei')
    s=file.read_text(encoding='utf-8')
    m=re.search(r'^special_damage_reactions = (.+)$',s,re.M)
    reactions=json.loads(m[1]) if m else {}
    reactions['rei_dragon_uppercut']=dict(hit='received_rei_uppercut_hit',airborne='received_rei_uppercut_air',down='received_rei_uppercut_down')
    if m:s=s[:m.start(1)]+json.dumps(reactions)+s[m.end(1):]
    else:s+='\nspecial_damage_reactions = '+json.dumps(reactions)+'\n'
    file.write_text(s,encoding='utf-8')
attack=GODOT/'data/attacks/rei_dragon_uppercut.tres'
s=attack.read_text(encoding='utf-8')
for key,value in [('startup_time','0.18'),('active_time','0.20'),('recovery_time','0.55'),
    ('special_startup_animation','&"rei_uppercut_startup"'),('special_finish_animation','&"rei_uppercut_finish"'),
    ('special_guard_reaction','&"received_rei_uppercut_guard"'),('keep_special_flight_in_view','true'),
    ('special_launch_speed_cap','Vector2(420, 560)'),('special_launch_gravity','1200.0')]:
    if re.search(r'^'+key+r' =',s,re.M):s=re.sub(r'^'+key+r' =.*$',f'{key} = {value}',s,flags=re.M)
    else:s+=f'\n{key} = {value}\n'
attack.write_text(s,encoding='utf-8')
print('REI_REVERSAL_PACK_OK attacker=8 player_reactions=15')
