"""Pack inspected ImageGen kick/air-punch supplements at one anatomical scale."""
from pathlib import Path
from PIL import Image
from motion_packing import components
import json,math
root=Path(__file__).resolve().parents[1]
actors=json.loads((root/'audit_evidence/basic_moves_20261010/inventory/inventory.json').read_text(encoding='utf-8'))
for slug,fid in [('shadow','enemy_02_shadow_boxer'),('masato','enemy_03_masato_takahashi')]:
    actor=next(a for a in actors if a['id']==fid)
    folder=root/f'godot/assets/characters/basic_moves_v2/{slug}'
    source=Image.open(folder/'supplement.png').convert('RGBA')
    rows=[[],[]]
    for box,pose in components(source,minimum=1500,alpha_threshold=80):
        rows[min(1,int((box[1]+box[3])/source.height))].append((box,pose))
    for row in rows:row.sort(key=lambda p:p[0][0])
    assert [len(r) for r in rows]==[4,4]
    ratio=actor['idle_rect'][3]/rows[0][0][1].height
    w,h=actor['cell'];baseline=actor['idle_rect'][1]+actor['idle_rect'][3]
    w=max(w,math.ceil(max(p.width*ratio for row in rows for _,p in row)*2/64)*64)
    atlas=Image.new('RGBA',(w*4,h*2));clips={};contacts={};cells=[]
    world=actor['height']*(actor['height_cm']/175)*actor['scale_adjustment']/actor['body_px']
    for ri,key in enumerate(['neutral_kick','up_punch']):
        clips['basic_source_'+key]={'frames':list(range(ri*4,ri*4+4)),'fps':12,'loop':False}
        for ci,(box,pose) in enumerate(rows[ri]):
            p=pose.resize((round(pose.width*ratio),round(pose.height*ratio)),Image.Resampling.NEAREST)
            support=p.getchannel('A').crop((0,max(0,p.height-5),p.width,p.height)).getbbox()
            anchor=(support[0]+support[2])/2 if support else p.width/2
            x=round(w/2-anchor);y=baseline-p.height
            assert y>=0 and x>=0 and x+p.width<=w and y+p.height<=h
            atlas.alpha_composite(p,(ci*w+x,ri*h+y))
            cells.append({'box':box,'index':ri*4+ci,'offset':[x,y],'size':p.size,'scale':ratio})
            if ci==2:
                contacts[key]=[round((x+p.width-6-w/2)*world*actor['width_scale'],2),round((y+p.height*(.38 if ri==0 else .30)-baseline)*world,2)]
    atlas.save(folder/'supplement_atlas.png')
    res='[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n'+f'[ext_resource type="Texture2D" path="res://assets/characters/basic_moves_v2/{slug}/supplement_atlas.png" id="2"]\n[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\nhead_scale_override = 1.0\n'+f'cell_size = Vector2i({w}, {h})\ncolumns = 4\nclips = '+json.dumps(clips)+'\n'
    (folder/'supplement_atlas.tres').write_text(res,encoding='utf-8')
    manifest=json.loads((folder/'packing_manifest.json').read_text(encoding='utf-8'))
    manifest['contacts'].update(contacts);manifest['supplement']={'scale':ratio,'frames':cells,'cell':[w,h]}
    (folder/'packing_manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    print(slug,'8 supplementary poses')
