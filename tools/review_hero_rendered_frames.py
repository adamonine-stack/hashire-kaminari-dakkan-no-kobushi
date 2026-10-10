"""Review-only render inventory and master comparisons, no production image edits."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops
import json

root = Path(__file__).resolve().parents[1]
source = root/'audit_evidence/body_dimensions/heroes_canvas_native'
out = root/'audit_evidence/hero_design_20261010/render_review'
out.mkdir(parents=True,exist_ok=True)
inventory = json.loads((source/'inventory.json').read_text(encoding='utf-8'))
results = []
for actor in ['player_02_gou','player_03_seiya']:
    folder = source/actor
    selected = []
    seen = set()
    for row in inventory:
        if row['actor'] != actor or row['facing'] != 1: continue
        path = folder/row['render_file']
        im = Image.open(path).convert('RGBA')
        bounds = im.getchannel('A').point(lambda a:255 if a>=16 else 0).getbbox()
        assert bounds is not None, path
        margins = [bounds[0],bounds[1],im.width-bounds[2],im.height-bounds[3]]
        results.append({'actor':actor,'clip':row['clip'],'frame':row['frame'],
                        'render_bbox':bounds,'render_edge_contact':min(margins)<=1,
                        'anatomy_status':'unverified'})
        key = row['source'],row['region']
        if key not in seen:
            seen.add(key)
            selected.append(row)
    master = Image.open(folder/'idle_right_000.png').convert('RGBA')
    master.save(out/f'{actor}_master.png')
    # Each panel uses the same viewport, scale and camera, with no fit-to-box.
    for page in range((len(selected)+11)//12):
        sheet = Image.new('RGB',(1920,1560),'#30343c')
        d = ImageDraw.Draw(sheet)
        for slot,row in enumerate(selected[page*12:(page+1)*12]):
            im = Image.open(folder/row['render_file']).convert('RGBA')
            x,y = slot%3*640,slot//3*390
            # Fixed viewport crop includes the entire player's possible envelope.
            crop = im.crop((0,100,640,460))
            sheet.paste(crop,(x,y),crop)
            d.text((x+4,y+365),f"{row['clip']}/{row['frame']} | {row.get('render_head_scale','none')}",fill='white')
        sheet.save(out/f'{actor}_render_{page:02}.png')
    # Primary non-rotated standing examples alongside their master.
    for clip in ['punch_1','kick_1','damage_light','guard','throw','special_attack',
                 'walk_forward','gou_down_punch','seiya_down_punch']:
        poses = [r for r in inventory if r['actor']==actor and r['facing']==1 and r['clip']==clip]
        if not poses: continue
        panel = Image.new('RGB',(384*(len(poses)+1),340),'#30343c')
        d = ImageDraw.Draw(panel)
        master_crop = master.crop((128,128,512,448))
        panel.paste(master_crop,(0,0),master_crop)
        d.text((4,324),'OFFICIAL IDLE MASTER / fixed display scale',fill='white')
        for i,row in enumerate(poses,1):
            im=Image.open(folder/row['render_file']).convert('RGBA')
            crop = im.crop((128,128,512,448))
            panel.paste(crop,(i*384,0),crop)
            d.text((i*384+4,324),f'{clip}/{row["frame"]}',fill='white')
        panel.save(out/f'{actor}_{clip}_master_compare.png')
    print(actor,'refs',sum(r['actor']==actor for r in results),'unique',len(selected),
          'render_edge_contact',sum(r['render_edge_contact'] for r in results if r['actor']==actor))
(out/'render_inventory.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
