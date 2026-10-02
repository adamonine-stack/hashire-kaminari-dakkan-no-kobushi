"""Pack independently authored Iron Breaker poses with a single anatomical density."""
from pathlib import Path
from PIL import Image
import json, re, hashlib

ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / 'godot'
REFS = ROOT/'evidence/gou_references'
REFS.mkdir(parents=True,exist_ok=True)
for name,atlas in [('gou','assets/characters/player02/animations/gou_v1/motion_atlas.tres'),
                   ('crusher','assets/characters/enemy01/animations/crusher_v1/motion_atlas.tres')]:
    text = (GODOT/atlas).read_text(encoding='utf-8')
    texture = re.search(r'type="Texture2D" path="res://([^"]+)"',text)[1]
    width,height = map(int,re.search(r'cell_size = Vector2i\((\d+),\s*(\d+)\)',text).groups())
    Image.open(GODOT/texture).crop((0,0,width,height)).save(REFS/(name+'.png'))

def pack(source_folder, destination, reference, names, clips, calibration=1.0, anchors=None):
    reference = Image.open(reference).convert('RGBA')
    rb = reference.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
    poses = []
    for name in names:
        path = source_folder / (name + '.png')
        im = Image.open(path).convert('RGBA')
        bounds = im.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
        poses.append((im, bounds, path))
    initial = poses[0][1]
    density = (rb[3]-rb[1]) / ((initial[3]-initial[1])*calibration)
    width = max(reference.width, int((max((b[2]-b[0])*density for _,b,_ in poses)+31)//32)*32+32)
    if anchors:
        width = max(width, int((2*max(max(x-b[0],b[2]-x)*density for x,(_,b,_) in zip(anchors,poses))+31)//32)*32+32)
    height = reference.height
    baseline = min(height-2, rb[3])
    atlas = Image.new('RGBA', (width*len(poses),height))
    records = []
    for i,(im,b,path) in enumerate(poses):
        anchor = anchors[i] if anchors else (b[0]+b[2])/2
        ox = round(width/2-anchor*density)
        oy = baseline-round(b[3]*density)
        support = [round(ox+b[0]*density),round(oy+b[1]*density),round(ox+b[2]*density),baseline]
        assert support[0]>=4 and support[1]>=0 and support[2]<=width-4, (path,support)
        cell = Image.new('RGBA',(width,height))
        cell.alpha_composite(im.resize((round(im.width*density),round(im.height*density)),Image.Resampling.NEAREST),(ox,oy))
        atlas.alpha_composite(cell,(i*width,0))
        records.append(dict(source=str(path.relative_to(ROOT)),scale=density,source_anchor_x=anchor,support=support,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
    destination.mkdir(parents=True,exist_ok=True)
    atlas.save(destination/'motion_atlas.png')
    resource = str(destination.relative_to(GODOT)).replace('\\','/')
    clip_lines = ',\n'.join(f'"{name}": {{"frames": {frames}, "fps": {fps}, "loop": false}}' for name,(frames,fps) in clips.items())
    (destination/'motion_atlas.tres').write_text('[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n'
        '[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n'
        f'[ext_resource type="Texture2D" path="res://{resource}/motion_atlas.png" id="2"]\n'
        f'[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i({width}, {height})\ncolumns = {len(poses)}\nclips = {{\n{clip_lines}\n}}\n',encoding='utf-8')
    (destination/'packing_manifest.json').write_text(json.dumps(dict(cell=[width,height],baseline=baseline,frames=records),indent=2)+'\n',encoding='utf-8')
    return f'res://{resource}/motion_atlas.tres'

def attach(fighter, path, resource_id):
    text = fighter.read_text(encoding='utf-8')
    if f'id="{resource_id}"' in text: return
    text = re.sub(r'load_steps=(\d+)',lambda m:f'load_steps={int(m[1])+1}',text,count=1)
    text = text.replace('[resource]',f'[ext_resource type="Resource" path="{path}" id="{resource_id}"]\n\n[resource]',1)
    if re.search(r'^extra_motion_atlases =',text,re.M):
        text = re.sub(r'^(extra_motion_atlases = Array\[Resource\]\(\[)(.*?)(\]\))$',lambda m:m[1]+m[2]+f', ExtResource("{resource_id}")'+m[3],text,flags=re.M)
    else: text += f'\nextra_motion_atlases = Array[Resource]([ExtResource("{resource_id}")])\n'
    fighter.write_text(text,encoding='utf-8')

path = pack(ROOT/'art_sources/gou_reversal_v1',GODOT/'assets/characters/player02/animations/reversal_v1',
    REFS/'gou.png',['startup','step','active','finish'],
    {'gou_reversal_startup':([0,1],2/.14),'gou_reversal_breaker':([2],1/.20),'gou_reversal_finish':([3],1/.58)},1.08,[750,780,780,835])
attach(GODOT/'data/fighters/ally_power.tres',path,'gou_reversal')
path = pack(ROOT/'art_sources/gou_received_v1/enemy_01_standard',GODOT/'assets/characters/special_received_gou_v1/enemy_01_standard',
    REFS/'crusher.png',['hit','air','down'],
    {'received_gou_breaker_hit':([0],8),'received_gou_breaker_air':([0,1],10),'received_gou_breaker_down':([2],5)},1.12)
fighter = GODOT/'data/enemies/enemy_01_standard.tres'
attach(fighter,path,'received_gou')
text = fighter.read_text(encoding='utf-8')
if '"player2_special_iron_breaker":' not in text:
    text = re.sub(r'^(special_damage_reactions = \{)',r'\1"player2_special_iron_breaker": {"hit": "received_gou_breaker_hit", "airborne": "received_gou_breaker_air", "down": "received_gou_breaker_down"}, ',text,flags=re.M)
    fighter.write_text(text,encoding='utf-8')
attack = GODOT/'data/attacks/player2_special_iron_breaker.tres'
text = attack.read_text(encoding='utf-8').replace('animation_name = "special_iron_breaker"','animation_name = "gou_reversal_breaker"')
if 'special_startup_animation =' not in text:
    text += '\nspecial_startup_animation = &"gou_reversal_startup"\nspecial_finish_animation = &"gou_reversal_finish"\n'
attack.write_text(text,encoding='utf-8')
print('GOU_REVERSAL_PACK_OK attacker_poses=4 victim_poses=3')
