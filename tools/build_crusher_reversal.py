"""Pack authored Crusher originals against corrected idle body mass, without runtime fitting."""
from pathlib import Path
from PIL import Image, ImageOps
import json, re, math, hashlib
from collections import deque

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'art_sources/crusher_reversal_v1'
GODOT=ROOT/'godot'

def area(im):
    return sum(a>=128 for a in im.getchannel('A').get_flattened_data())

def extract_poses(sheet,count):
    # Generated sheets have a wider prone pose; never split width by pose count.
    width,height=sheet.size
    alpha=sheet.getchannel('A')
    mask=bytearray(1 if a>=128 else 0 for a in alpha.get_flattened_data())
    components=[]
    for seed in range(len(mask)):
        if not mask[seed]:continue
        mask[seed]=0
        queue=deque([seed]);pixels=[]
        while queue:
            p=queue.popleft();pixels.append(p)
            x,y=p%width,p//width
            for dy in [-1,0,1]:
                for dx in [-1,0,1]:
                    nx,ny=x+dx,y+dy
                    if 0<=nx<width and 0<=ny<height:
                        n=ny*width+nx
                        if mask[n]:mask[n]=0;queue.append(n)
        if len(pixels)>1000:components.append(pixels)
    assert len(components)==count,('connected full-body poses',len(components),count)
    components.sort(key=lambda points:sum(p%width for p in points)/len(points))
    poses=[]
    for pixels in components:
        coverage=bytearray(width*height)
        for p in pixels:coverage[p]=255
        selection=Image.frombytes('L',sheet.size,bytes(coverage))
        im=sheet.copy()
        from PIL import ImageChops
        im.putalpha(ImageChops.multiply(alpha,selection))
        poses.append(im.crop(selection.getbbox()))
    return poses

def attach(file,path,key):
    s=file.read_text(encoding='utf-8')
    if f'id="{key}"' in s:return
    s=re.sub(r'load_steps=(\d+)',lambda m:f'load_steps={int(m[1])+1}',s,count=1)
    s=s.replace('[resource]',f'[ext_resource type="Resource" path="res://{path}" id="{key}"]\n\n[resource]',1)
    if re.search(r'^extra_motion_atlases =',s,re.M):
        s=re.sub(r'^(extra_motion_atlases = Array\[Resource\]\(\[)(.*?)(\]\))$',lambda m:m[1]+m[2]+f', ExtResource("{key}")'+m[3],s,flags=re.M)
    else:s+=f'\nextra_motion_atlases = Array[Resource]([ExtResource("{key}")])\n'
    file.write_text(s,encoding='utf-8')

def pack(name,names,clips,destination,mirror=False):
    source=ART/(name+'_sheet.png')
    sheet=Image.open(source).convert('RGBA')
    reference=Image.open(ART/'references'/(name+'.png')).convert('RGBA')
    rb=reference.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
    reference_area=area(reference)
    # Fixed generous canvas permits arms above the head and horizontal down poses.
    cell=(512,384)
    baseline=round(cell[1]/2+rb[3]-reference.height/2)
    atlas=Image.new('RGBA',(cell[0]*len(names),cell[1]))
    records=[]
    poses=extract_poses(sheet,len(names))
    for i,pose in enumerate(names):
        im=poses[i]
        bounds=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
        assert bounds is not None,(name,pose)
        im=im.crop(bounds)
        if mirror:im=ImageOps.mirror(im)
        factor=math.sqrt(reference_area/area(im))
        im=im.resize((round(im.width*factor),round(im.height*factor)),Image.Resampling.NEAREST)
        origin=(round(cell[0]/2-im.width/2),baseline-im.height)
        assert min(origin)>=4 and origin[0]+im.width<cell[0]-4,(name,pose,im.size,origin)
        atlas.alpha_composite(im,(i*cell[0]+origin[0],origin[1]))
        records.append(dict(pose=pose,density=factor,origin=origin,size=list(im.size),relative_body_area=area(im)/reference_area))
    folder=GODOT/destination
    folder.mkdir(parents=True,exist_ok=True)
    atlas.save(folder/'motion_atlas.png')
    clip_map={key:dict(frames=frames,fps=fps,loop=False) for key,(frames,fps) in clips.items()}
    (folder/'motion_atlas.tres').write_text('[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n'
      '[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n'
      f'[ext_resource type="Texture2D" path="res://{destination}/motion_atlas.png" id="2"]\n'
      f'[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i(512, 384)\ncolumns = {len(names)}\nclips = '+json.dumps(clip_map)+'\n',encoding='utf-8')
    (folder/'packing_manifest.json').write_text(json.dumps(dict(reference=f'art_sources/crusher_reversal_v1/references/{name}.png',sheet_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),method='corrected idle opaque anatomical body area; common canvas and baseline; constant runtime scale',baseline=baseline,frames=records),indent=2)+'\n',encoding='utf-8')
    return destination+'/motion_atlas.tres'

path=pack('crusher',['anticipation','windup','hammer','finish'],{
    'crusher_hammer_startup':([0,1],2/.14),
    'crusher_hammer_active':([2],1/.14),
    'crusher_hammer_finish':([3],1/.60)},'assets/characters/enemy01/animations/reversal_v1')
attach(GODOT/'data/enemies/enemy_01_standard.tres',path,'crusher_reversal')
for name,fighter in [('akky','ally_balance'),('gou','ally_power'),('seiya','ally_speed')]:
    path=pack(name,['hit','air','down','guard_impact','guard_hold'],{
        'received_crusher_hammer_hit':([0],8),
        'received_crusher_hammer_air':([1],8),
        'received_crusher_hammer_down':([2],5),
        'received_crusher_hammer_guard':([3,4],2/.22)},f'assets/characters/special_received_crusher_v1/{fighter}',True)
    file=GODOT/f'data/fighters/{fighter}.tres'
    attach(file,path,'received_crusher')
    s=file.read_text(encoding='utf-8')
    m=re.search(r'^special_damage_reactions = (.+)$',s,re.M)
    reactions=json.loads(m[1]) if m else {}
    reactions['crusher_fault_break']=dict(hit='received_crusher_hammer_hit',airborne='received_crusher_hammer_air',down='received_crusher_hammer_down')
    if m:s=s[:m.start(1)]+json.dumps(reactions)+s[m.end(1):]
    else:s+='\nspecial_damage_reactions = '+json.dumps(reactions)+'\n'
    file.write_text(s,encoding='utf-8')
attack=GODOT/'data/attacks/crusher_fault_break.tres'
s=attack.read_text(encoding='utf-8').replace('animation_name = "special_attack"','animation_name = "crusher_hammer_active"')
for key,value in [('special_startup_animation','crusher_hammer_startup'),('special_finish_animation','crusher_hammer_finish'),('special_guard_reaction','received_crusher_hammer_guard')]:
    if re.search(r'^'+key+r' =',s,re.M):s=re.sub(r'^'+key+r' =.*$',f'{key} = &"{value}"',s,flags=re.M)
    else:s+=f'\n{key} = &"{value}"\n'
attack.write_text(s,encoding='utf-8')
print('CRUSHER_REVERSAL_PACK_OK attacker=4 player_reactions=15')
