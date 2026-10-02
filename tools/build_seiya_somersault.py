"""Build Seiya's accepted, size-corrected in-place somersault originals."""
from pathlib import Path
from PIL import Image
import json, re, math, hashlib
ROOT=Path(__file__).resolve().parents[1]
GODOT=ROOT/'godot'
# Resolve the current corrected player's actual idle clip, never atlas cell zero.
reference_path=ROOT/'evidence/seiya_references/seiya_idle_size_corrected.png'
atlas_path=GODOT/'assets/characters/player03/animations/seiya_v1/motion_atlas.tres'
atlas_text=atlas_path.read_text(encoding='utf-8')
texture_path=re.search(r'type="Texture2D" path="res://([^\"]+)"',atlas_text)[1]
w,h=map(int,re.search(r'cell_size = Vector2i\((\d+),\s*(\d+)\)',atlas_text).groups())
index=int(re.search(r'"idle":\s*\{"frames":\s*\[(\d+)',atlas_text)[1])
columns=int(re.search(r'columns = (\d+)',atlas_text)[1])
ref=Image.open(GODOT/texture_path).convert('RGBA').crop(((index%columns)*w,(index//columns)*h,(index%columns+1)*w,(index//columns+1)*h))
reference_path.parent.mkdir(parents=True,exist_ok=True);ref.save(reference_path)
def area(im): return sum(v>=128 for v in im.getchannel('A').get_flattened_data())
def bounds(im): return im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
rb=bounds(ref); target_area=area(ref); reference_center=((rb[0]+rb[2])/2,(rb[1]+rb[3])/2)
names=['startup','kick','inverted_approved','return','finish']
cell=ref.size; atlas=Image.new('RGBA',(cell[0]*len(names),cell[1]));records=[]
for i,name in enumerate(names):
 path=ROOT/'art_sources/seiya_somersault_v1'/(name+'.png');im=Image.open(path).convert('RGBA');b=bounds(im)
 # Ignore isolated nearly-transparent generation dust outside the actor.
 im=im.crop(b); density=math.sqrt(target_area/area(im));im=im.resize((round(im.width*density),round(im.height*density)),Image.Resampling.NEAREST)
 if name in ['startup','finish']:
  origin=(round(cell[0]/2-im.width/2),rb[3]-im.height)
 else:
  origin=(round(cell[0]/2-im.width/2),round(reference_center[1]-im.height/2))
 assert origin[0]>=0 and origin[1]>=0 and origin[0]+im.width<=cell[0] and origin[1]+im.height<=cell[1]
 atlas.alpha_composite(im,(i*cell[0]+origin[0],origin[1]));records.append(dict(name=name,source=str(path.relative_to(ROOT)),density=density,opaque_area=area(im),relative_body_area=area(im)/target_area,origin=origin,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
folder=GODOT/'assets/characters/player03/animations/somersault_v1';folder.mkdir(parents=True,exist_ok=True);atlas.save(folder/'motion_atlas.png')
(folder/'motion_atlas.tres').write_text('''[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]
[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/characters/player03/animations/somersault_v1/motion_atlas.png" id="2"]
[resource]
script = ExtResource("1")
texture = ExtResource("2")
cell_size = Vector2i(384,288)
columns = 5
clips = {
"seiya_somersault_startup": {"frames": [0], "fps": 6.0, "loop": false},
"seiya_somersault_kick": {"frames": [1,2,3], "fps": 5.0, "loop": false},
"seiya_somersault_landing": {"frames": [4], "fps": 5.0, "loop": false}
}
''',encoding='utf-8')
(folder/'packing_manifest.json').write_text(json.dumps(dict(reference='evidence/seiya_references/seiya_idle_size_corrected.png',reference_area=target_area,accepted_inverted='inverted_approved.png',method='preserve opaque anatomical body area; runtime scale unchanged',frames=records),indent=2)+'\n')
def attach(file,path,id):
 s=file.read_text(encoding='utf-8');s=re.sub(r'load_steps=(\d+)',lambda m:'load_steps='+str(int(m[1])+1),s,count=1)
 s=s.replace('[resource]',f'[ext_resource type="Resource" path="{path}" id="{id}"]\n\n[resource]',1)
 if re.search(r'^extra_motion_atlases =',s,re.M):
  s=re.sub(r'^(extra_motion_atlases = Array\[Resource\]\(\[)(.*?)(\]\))$',lambda m:m[1]+m[2]+f', ExtResource("{id}")'+m[3],s,flags=re.M)
 else:s+='\nextra_motion_atlases = Array[Resource]([ExtResource("'+id+'")])\n'
 file.write_text(s,encoding='utf-8')
fighter=GODOT/'data/fighters/ally_speed.tres'
if 'id="seiya_somersault"' not in fighter.read_text(encoding='utf-8'):attach(fighter,'res://assets/characters/player03/animations/somersault_v1/motion_atlas.tres','seiya_somersault')
for folder in sorted((GODOT/'assets/characters/special_received_gou_v1').iterdir()):
 if not folder.is_dir():continue
 s=(folder/'motion_atlas.tres').read_text(encoding='utf-8').replace('received_gou_breaker','received_seiya_somersault')
 s=s.replace('"received_seiya_somersault_down":', '"received_seiya_somersault_fall": {"frames": [0], "fps": 60, "loop": false},\n"received_seiya_somersault_down":')
 destination=GODOT/'assets/characters/special_received_seiya_v1'/folder.name;destination.mkdir(parents=True,exist_ok=True);(destination/'motion_atlas.tres').write_text(s,encoding='utf-8')
 enemy=GODOT/'data/enemies'/(folder.name+'.tres')
 if 'id="received_seiya"' not in enemy.read_text(encoding='utf-8'):attach(enemy,'res://assets/characters/special_received_seiya_v1/'+folder.name+'/motion_atlas.tres','received_seiya')
 s=enemy.read_text(encoding='utf-8');m=re.search(r'^special_damage_reactions = (.+)$',s,re.M);reactions=json.loads(m[1]);reactions['player3_special_clear_counter']=dict(hit='received_seiya_somersault_hit',airborne='received_seiya_somersault_air',fall='received_seiya_somersault_fall',down='received_seiya_somersault_down');s=s[:m.start(1)]+json.dumps(reactions)+s[m.end(1):];enemy.write_text(s,encoding='utf-8')
print('SEIYA_SOMERSAULT_PACK_OK poses=5 enemies=9 approved_inverted=inverted_approved.png')
