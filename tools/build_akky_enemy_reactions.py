"""Pack each receiving enemy's original poses at one anatomical density."""
from pathlib import Path
from PIL import Image
import json, re, hashlib, shutil, math
ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / 'godot'
refs = json.loads((ROOT/'evidence/special_reaction_refs/manifest.json').read_text())
source_manifest = ROOT/'evidence/special_reaction_sources.json'
sources = json.loads(source_manifest.read_text()) if source_manifest.exists() else {}
for ref in refs:
    name = ref['name']
    folder = GODOT/'assets/characters/special_received_v1'/name
    source_folder = ROOT/'art_sources/special_received_v1'/name
    source_folder.mkdir(parents=True,exist_ok=True)
    height = ref['cell'][1]
    bounds = ref['reference_bounds']
    baseline = min(height-2,bounds[3])
    # One calibration per character, shared by all poses; never fit each pose.
    poses = []
    for phase in ['hit','air','down']:
        target = source_folder/f'{phase}.png'
        if name in sources:
            original = Path(sources[name][phase])
            if original.exists(): shutil.copy2(original,target)
        image = Image.open(target).convert('RGBA')
        opaque = image.getchannel('A').point(lambda a: 255 if a>=128 else 0).getbbox()
        poses.append((phase,image,opaque,hashlib.sha256(target.read_bytes()).hexdigest()))
    # Calibrate once against the initial impact's slightly arched silhouette.
    # Air/down reuse this exact density, regardless of their bounding boxes.
    initial_bounds = poses[0][2]
    density = (bounds[3]-bounds[1])/((initial_bounds[3]-initial_bounds[1])*1.05)
    width = max(ref['cell'][0],math.ceil((max((b[2]-b[0])*density for _,_,b,_ in poses)+24)/32)*32)
    atlas = Image.new('RGBA',(width*3,height))
    manifest=[]
    for index,(phase,image,b,sha) in enumerate(poses):
        scaled = image.resize((round(image.width*density),round(image.height*density)),Image.Resampling.NEAREST)
        ox=round(width/2-(b[0]+b[2])*density/2)
        oy=baseline-round(b[3]*density)
        support=(round(ox+b[0]*density),round(oy+b[1]*density),round(ox+b[2]*density),baseline)
        if support[0]<4 or support[1]<0 or support[2]>width-4: raise ValueError((name,phase,support))
        cell=Image.new('RGBA',(width,height))
        cell.alpha_composite(scaled,(ox,oy))
        atlas.alpha_composite(cell,(index*width,0))
        manifest.append(dict(phase=phase,scale=density,offset=[ox,oy],support=support,sha256=sha))
    atlas.save(folder/'motion_atlas.png')
    resource_path=f'res://assets/characters/special_received_v1/{name}/motion_atlas.tres'
    (folder/'motion_atlas.tres').write_text(
        '[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n'
        '[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n'
        f'[ext_resource type="Texture2D" path="res://assets/characters/special_received_v1/{name}/motion_atlas.png" id="2"]\n'
        '[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\n'
        f'cell_size = Vector2i({width}, {height})\ncolumns = 3\n'
        'clips = {\n"received_akky_elbow_hit": {"frames": [0], "fps": 8.0, "loop": false},\n'
        '"received_akky_elbow_air": {"frames": [0,1], "fps": 10.0, "loop": false},\n'
        '"received_akky_elbow_down": {"frames": [2], "fps": 5.0, "loop": false}\n}\n',encoding='utf-8')
    (folder/'packing_manifest.json').write_text(json.dumps(dict(cell=[width,height],baseline=baseline,frames=manifest),indent=2)+'\n',encoding='utf-8')
    fighter=GODOT/ref['fighter']
    text=fighter.read_text(encoding='utf-8')
    if 'id="received_akky"' not in text:
        text=re.sub(r'load_steps=(\d+)',lambda m:f'load_steps={int(m[1])+1}',text,count=1)
        text=text.replace('[resource]',f'[ext_resource type="Resource" path="{resource_path}" id="received_akky"]\n\n[resource]',1)
        if re.search(r'^extra_motion_atlases =',text,re.M):
            text=re.sub(r'^(extra_motion_atlases = Array\[Resource\]\(\[)(.*?)(\]\))$',r'\1\2, ExtResource("received_akky")\3',text,flags=re.M)
        else: text+='\nextra_motion_atlases = Array[Resource]([ExtResource("received_akky")])\n'
        text+='special_damage_reactions = {"player1_special_thunder_drive": {"hit": "received_akky_elbow_hit", "airborne": "received_akky_elbow_air", "down": "received_akky_elbow_down"}}\n'
        fighter.write_text(text,encoding='utf-8')
print('AKKY_ENEMY_REACTIONS_PACK_OK enemies=9 original_poses=27')
