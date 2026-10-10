"""Record rendered evidence without modifying production bitmap assets."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops, ImageOps
import csv, hashlib, json, re, subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'audit_evidence/seiya_completion_20261010'
CAPTURE = ROOT / 'audit_evidence/body_dimensions/seiya_completion_final_native'
BEFORE = ROOT / 'audit_evidence/body_dimensions/heroes_canvas_native'
inventory = json.loads((CAPTURE / 'inventory.json').read_text(encoding='utf-8'))
assert len(inventory) == 846
assert len({r['clip'] for r in inventory}) == 156
landmarks = json.loads((ROOT / 'godot/assets/characters/player03/animations/dark_seiya_v1/head_landmarks.json').read_text(encoding='utf-8'))
for r in inventory:
    if r['render_head_scale'] == 1.0:
        continue  # Untransformed authored artwork has no head-ROI resampling.
    region = [float(n) for n in re.findall(r'-?\d+(?:\.\d+)?', r['region'])]
    key = '/'.join(r['source'].split('/')[-2:]) + f':{int(region[0])}:{int(region[1])}'
    if key not in landmarks:
        continue  # The source-basis test covers automatic landmark detection.
    rect = landmarks[key]
    expected = [region[0]+rect[0],region[1]+rect[1],rect[2],rect[3]]
    rendered = [float(n) for n in re.findall(r'-?\d+(?:\.\d+)?', r['source_head_rect'])]
    assert rendered == expected, f'Capture is stale for {key}'
rows = []
for clip in sorted({r['clip'] for r in inventory}):
    frames = [r for r in inventory if r['clip'] == clip]
    assert all(r['scale_status'] == 'pass' for r in frames)
    for frame in sorted({r['frame'] for r in frames}):
        pair = [r for r in frames if r['frame'] == frame]
        assert len(pair) == 2 and {r['facing'] for r in pair} == {1, -1}
        right, left = sorted(pair, key=lambda r: -r['facing'])
        def alpha(row):
            return Image.open(CAPTURE / row['actor'] / row['render_file']).getchannel('A')
        a, b = alpha(right), alpha(left)
        assert ImageChops.difference(ImageOps.mirror(a), b).getbbox() is None
        box = a.getbbox()
        assert box and box[0] > 0 and box[1] > 0 and box[2] < a.width and box[3] < a.height
    rows.append(dict(actor='player_03_seiya', motion=clip, directional_frames=len(frames),
        constant_scale='合格', display_canvas='合格', source_coordinate_regression='合格',
        clipping='合格', alpha_mirror='合格',
        rendered_pose_review='合格', anatomy_2percent='未確認',
        all_transitions_manual_play='未確認',
        notes='188 distinct source poses reviewed in all_poses_00..15; visual review is not skeletal measurement.'))
with (OUT / 'motion_results.csv').open('w', encoding='utf-8-sig', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=rows[0].keys())
    writer.writeheader(); writer.writerows(rows)
(OUT / 'motion_results.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding='utf-8')

# Same camera and crop on both sides: never fit individual bodies to a box.
poses = [('idle',0),('idle',3),('punch_1',0),('punch_2',5),('kick_1',4),
         ('crouch_punch',0),('crouch_punch',2),('crouch_punch',4),
         ('special_attack',0),('throw',3),('thrown',0),('seiya_two_somersault',1)]
panel = Image.new('RGB', (1280, 360 * len(poses)), '#30343c')
draw = ImageDraw.Draw(panel)
for index, (clip, frame) in enumerate(poses):
    filename = f'{clip}_right_{frame:03}.png'
    for column, folder in enumerate([BEFORE, CAPTURE]):
        sprite = Image.open(folder / 'player_03_seiya' / filename).convert('RGBA').crop((0,100,640,460))
        panel.paste(sprite, (640*column,360*index), sprite)
        draw.text((640*column+8,360*index+8), f'{"BEFORE" if column == 0 else "AFTER"}: {clip}/{frame} | same scale/camera', fill='white')
panel.save(OUT / 'before_after.png')

distinct = {}
for r in inventory:
    if r['facing'] == 1:
        distinct.setdefault((r['source'],r['region']),r)
unique = list(distinct.values())
for page in range((len(unique)+11)//12):
    sheet = Image.new('RGB',(1920,1560),'#30343c')
    draw = ImageDraw.Draw(sheet)
    for i,r in enumerate(unique[page*12:page*12+12]):
        sprite = Image.open(CAPTURE / r['actor'] / r['render_file']).convert('RGBA').crop((0,100,640,460))
        x,y = (i%3)*640,(i//3)*390
        sheet.paste(sprite,(x,y),sprite)
        draw.text((x+8,y+365),f"{r['clip']}/{r['frame']}",fill='white')
    sheet.save(OUT / f'all_poses_{page:02}.png')

previous = ROOT / 'audit_evidence/body_dimensions/seiya_completion_native'
changed = []
for r in unique:
    name = Path(r['actor']) / r['render_file']
    old = Image.open(previous / name).convert('RGBA')
    new = Image.open(CAPTURE / name).convert('RGBA')
    delta = ImageChops.difference(old,new)
    if any(channel.getbbox() is not None for channel in delta.split()):
        changed.append(r)
for page in range((len(changed)+5)//6):
    sheet = Image.new('RGB',(1280,2340),'#30343c')
    draw = ImageDraw.Draw(sheet)
    for i,r in enumerate(changed[page*6:page*6+6]):
        for column,folder in enumerate([previous,CAPTURE]):
            sprite = Image.open(folder / r['actor'] / r['render_file']).convert('RGBA').crop((0,100,640,460))
            sheet.paste(sprite,(column*640,i*390),sprite)
            draw.text((column*640+8,i*390+365),f"{'BEFORE' if column == 0 else 'AFTER'} fallback basis: {r['clip']}/{r['frame']}",fill='white')
    sheet.save(OUT / f'fallback_basis_delta_{page:02}.png')
(OUT / 'render_scope.json').write_text(json.dumps(dict(frames=len(inventory),unique_poses=len(unique),edge_contacts=[],alpha_mirror_differences=[],final_fallback_changed_poses=[dict(clip=r['clip'],frame=r['frame'],source=r['source']) for r in changed]),indent=2),encoding='utf-8')

# Pose-aware face comparison uses all Idle directions, not only one hair width.
head_poses = [('idle',i) for i in range(4)] + [('punch_1',i) for i in range(6)] + [('kick_1',i) for i in range(6)] + [('crouch_punch',i) for i in range(6)]
heads = Image.new('RGB', (520*4,260*6), '#30343c')
draw = ImageDraw.Draw(heads)
for i, (clip, frame) in enumerate(head_poses):
    sprite = Image.open(CAPTURE / 'player_03_seiya' / f'{clip}_right_{frame:03}.png').convert('RGBA')
    # Constant 2x analytical enlargement, including the neck and upper body.
    crop = sprite.crop((230,205 if clip != 'crouch_punch' else 265,410,335 if clip != 'crouch_punch' else 395)).resize((360,260),Image.Resampling.NEAREST)
    x,y = (i%4)*520,(i//4)*260
    heads.paste(crop,(x,y),crop)
    draw.text((x+365,y+10),f'{clip}/{frame}',fill='white')
heads.save(OUT / 'pose_aware_heads.png')

hashes = []
for source in sorted({r['source'] for r in inventory}):
    relative = 'godot/' + source.removeprefix('res://')
    current = (ROOT / relative).read_bytes()
    baseline = subprocess.check_output(['git','show','HEAD:'+relative],cwd=ROOT)
    assert current == baseline, f'Official source bitmap changed: {source}'
    hashes.append(dict(source=source,sha256=hashlib.sha256(current).hexdigest(),official_source_unchanged=True))
(OUT / 'source_bitmap_hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
print(f'SEIYA_RENDER_EVIDENCE motions={len(rows)} frames={len(inventory)} original_atlases={len(hashes)}')
