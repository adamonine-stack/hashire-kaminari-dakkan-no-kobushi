"""Pack ImageGen originals at one scale per actor, retaining existing foot origin."""
from pathlib import Path
from PIL import Image
import json, math
from motion_packing import components

ROOT = Path(__file__).resolve().parents[1]
INV = ROOT/'audit_evidence/basic_moves_20261010/inventory'
records = json.loads((INV/'inventory.json').read_text(encoding='utf-8'))
keys = {'shadow':'enemy_02_shadow_boxer', 'masato':'enemy_03_masato_takahashi',
        'rei':'enemy_04_rei_kageyama', 'cross':'enemy_05_cross_murasame',
        'rio':'enemy_06_rio_flick_garcia', 'teki':'enemy_07_teki_fighter',
        'leon':'enemy_08_leon_crow'}
keys['crusher']='enemy_01_crusher'
clip_keys = ['forward_punch','back_punch','forward_kick','back_kick']
for key, fid in keys.items():
    info = next(x for x in records if x['id']==fid)
    folder = ROOT/f'godot/assets/characters/basic_moves_v2/{key}'
    source = Image.open(folder/'source.png').convert('RGBA')
    found = components(source, minimum=1500, alpha_threshold=80)
    rows = [[] for _ in range(4)]
    for box, pose in found:
        row = min(3, int((box[1]+box[3])/2/(source.height/4)))
        rows[row].append((box,pose))
    for row in rows: row.sort(key=lambda item:(item[0][0]+item[0][2])/2)
    if key=='shadow' and len(rows[0])==5:
        rows[0] = [rows[0][i] for i in [0,1,3,4]]
    assert [len(row) for row in rows] == [4]*4, (key,[len(row) for row in rows],len(found))
    if rows[0][0][0][1]<=1:
        rows[0][0]=rows[0][3] # Do not integrate a pose cropped by the canvas edge.
    w,h = map(int,info['cell']); rect=info['idle_rect'];baseline=rect[1]+rect[3]
    # Establish a single anatomical scale from the recovered standing pose.
    ratio = rect[3]/rows[0][3][1].height
    max_reach = 0
    for row in rows:
        for box,pose in row:
            scaled=pose.resize((round(pose.width*ratio),round(pose.height*ratio)),Image.Resampling.NEAREST)
            support=scaled.getchannel('A').crop((0,max(0,scaled.height-5),scaled.width,scaled.height)).getbbox()
            anchor=(support[0]+support[2])/2 if support else scaled.width/2
            max_reach=max(max_reach,anchor,scaled.width-anchor)
    # Wider display cells retain complete reach, without shrinking individual poses.
    w=max(w,math.ceil(2*max_reach/64)*64)
    packed=Image.new('RGBA',(w*4,h*4))
    manifest={'actor':fid,'cell':[w,h],'baseline':baseline,'anatomical_scale':ratio,'frames':[],'contacts':{}}
    clips={}
    world=info['height']*(info['height_cm']/175)*info['scale_adjustment']/info['body_px']
    for row, name in enumerate(clip_keys):
        clips['basic_source_'+name]={'frames':list(range(row*4,row*4+4)),'fps':12.0,'loop':False}
        for col,(box,pose) in enumerate(rows[row]):
            scaled=pose.resize((round(pose.width*ratio),round(pose.height*ratio)),Image.Resampling.NEAREST)
            # Align supporting shoes, not the silhouette midpoint of a long kick.
            mask=scaled.getchannel('A')
            support=mask.crop((0,max(0,scaled.height-5),scaled.width,scaled.height)).getbbox()
            anchor=(support[0]+support[2])/2 if support else scaled.width/2
            x=round(w/2-anchor);y=baseline-scaled.height
            assert x>=0 and y>=0 and x+scaled.width<=w and y+scaled.height<=h,(key,name,col,scaled.size,(x,y),(w,h))
            packed.alpha_composite(scaled,(col*w+x,row*h+y))
            manifest['frames'].append({'source_box':list(box),'index':row*4+col,'offset':[x,y],'size':list(scaled.size),'scale':ratio})
            if col==2:
                if name=='back_punch':
                    point=(scaled.width*.58, min(8,scaled.height*.03))
                elif name.endswith('kick'):
                    point=(scaled.width-6,scaled.height*(.40 if name=='forward_kick' else .30))
                else:
                    point=(scaled.width-6,scaled.height*.28)
                manifest['contacts'][name]=[round((x+point[0]-w/2)*world*info['width_scale'],2),round((y+point[1]-baseline)*world,2)]
    packed.save(folder/'motion_atlas.png')
    resource='[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n'+f'[ext_resource type="Texture2D" path="res://assets/characters/basic_moves_v2/{key}/motion_atlas.png" id="2"]\n[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\nhead_scale_override = 1.0\ncell_size = Vector2i({w}, {h})\ncolumns = 4\nclips = '+json.dumps(clips)+'\n'
    (folder/'motion_atlas.tres').write_text(resource,encoding='utf-8')
    (folder/'packing_manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    print(key,'16 poses', 'fixed scale',round(ratio,4),'contacts',manifest['contacts'])
