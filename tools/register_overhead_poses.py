"""Preserve source pixels; use one head-to-floor scale for both overhead poses."""
from pathlib import Path
from PIL import Image
import json, shutil
ROOT=Path(__file__).resolve().parents[1]
GENERATED=Path('C:/Users/takas/.codex/generated_images/01a127fd-0975-76a0-8921-e50aa5c57e1a')
records=json.loads((ROOT/'audit_evidence/basic_moves_20261010/inventory/inventory.json').read_text(encoding='utf-8'))
sources=[('akky','ec5166d0-1fb1-44fe-a03e-4321401b84d1',170),('gou','889cd9fc-218d-4e0f-9f90-db9a4822a755',200),('seiya','7a2bad58-fda2-4607-941d-955891e74f11',126),('crusher','3836d9d5-a312-4c56-9c14-ce373f35917b',154)]
sources.append(('akky_cross','cb65c426-f186-4b7e-b0b6-48dfe4eb594f',90))
sources.extend([('rei','8dc55b1a-cff2-4805-92a0-72603b5d2647',96),('teki','2325dcfb-3856-42f2-955e-9959874b994f',127),('cross','0588dc14-7e37-47ae-8755-3ccb47856e67',224),('shadow','11745031-bc68-4234-a720-843ec043929c',195)])
sources.extend([('rio','ab1ff702-f569-4fa8-af8e-634f35ad3602',88),('masato','83d26500-00d3-4f9e-bccb-3385cc2b4d8a',154),('leon','9f6456cb-377a-458f-9302-6bfea1163fdd',104),('dark_seiya','10deb8d4-6f4c-4583-a0a3-dabe4eb718b7',112)])
for info,(slug,identifier,head_y) in zip(records[:4]+[records[0],records[6],records[9],records[7],records[4],records[8],records[5],records[10],records[11]],sources):
    folder=ROOT/f'godot/assets/characters/overhead_v1/{slug}'
    folder.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(GENERATED/f'exec-{identifier}.png',folder/'source.png')
    source=Image.open(folder/'source.png').convert('RGBA')
    regions=[]
    columns=3 if slug in ['rio','masato','leon','dark_seiya'] else 2
    for col in range(columns):
        left=col*source.width//columns; right=(col+1)*source.width//columns
        alpha=source.getchannel('A').crop((left,0,right,source.height))
        box=alpha.point(lambda x:255 if x>=80 else 0).getbbox()
        regions.append((left+box[0],box[1],box[2]-box[0],box[3]-box[1]))
    ratio=info['idle_rect'][3]/(regions[0][1]+regions[0][3]-head_y)
    w,h=info['cell']; floor=info['idle_rect'][1]+info['idle_rect'][3]
    if slug=='crusher':
        h+=32
        floor+=16  # symmetric transparent padding; never shrink the raised arm
    offsets=[]
    for x,y,pw,ph in regions:
        feet=source.getchannel('A').crop((x,y+ph-8,x+pw,y+ph)).getbbox()
        anchor=(feet[0]+feet[2])/2
        offset=[round(w/2-anchor*ratio),floor-round(ph*ratio)]
        assert offset[0]>=0 and offset[1]>=0 and offset[0]+round(pw*ratio)<=w and offset[1]+round(ph*ratio)<=h,(slug,offset)
        offsets.append(offset)
    resource='[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n'+f'[ext_resource type="Texture2D" path="res://assets/characters/overhead_v1/{slug}/source.png" id="2"]\n[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\nhead_scale_override = 1.0\n'+f'cell_size = Vector2i({w}, {h})\ncolumns = 2\nframe_offsets_are_display_pixels = true\nsource_alpha_threshold = 0.01\n'
    resource=resource.replace('columns = 2',f'columns = {columns}')
    resource+='frame_regions = Array[Rect2i](['+', '.join('Rect2i(%d, %d, %d, %d)'%r for r in regions)+'])\n'
    resource+='frame_offsets = Array[Vector2i](['+', '.join('Vector2i(%d, %d)'%tuple(o) for o in offsets)+'])\n'
    resource+='frame_source_scales = Array[float]('+json.dumps([ratio]*columns)+')\n'
    clips={'cross_contact':{'frames':[1],'fps':12,'loop':False}} if slug=='akky_cross' else {'overhead_windup':{'frames':[0],'fps':12,'loop':False},'overhead_contact':{'frames':[1],'fps':12,'loop':False}}
    if columns==3: clips['authored_normal_contact']={'frames':[2],'fps':12,'loop':False}
    resource+='clips = '+json.dumps(clips)+'\n'
    (folder/'motion_atlas.tres').write_text(resource,encoding='utf-8')
    (folder/'packing_manifest.json').write_text(json.dumps({'head_y':head_y,'single_source_scale':ratio,'regions':regions,'offsets':offsets,'floor':floor},indent=2),encoding='utf-8')
    print(slug,ratio,offsets)
