"""Review annotations only: never rewrites production sprites.

Coordinates are manually read visible surface proxies, not skeletal landmarks.
Each endpoint has a conservative two source-pixel radial uncertainty.
"""
from pathlib import Path
import csv, json, math
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'audit_evidence/body_dimensions/landmark_review'
SRC = OUT.parent / 'wall_all_headless/player_01_akky'
# crown, visible chin, shirt collar center, belt center; pose comparability
DATA = [
 ('idle_right_000_source.png', [(163,36),(166,69),(162,71),(160,113)], 'master'),
 ('damage_light_right_001_source.png', [(153,40),(153,73),(152,76),(154,112)], 'head_down'),
 ('damage_heavy_right_001_source.png', [(142,39),(141,69),(144,73),(164,110)], 'lean_rotation'),
 ('damage_high_right_000_source.png', [(143,38),(151,66),(150,70),(165,110)], 'head_up'),
 ('damage_low_right_001_source.png', [(172,75),(174,107),(162,109),(155,128)], 'forward_fold_occlusion'),
 ('akky_throw_back_start_right_000_source.png', [(163,49),(164,78),(158,80),(160,121)], 'guard_pose'),
 ('special_guard_right_002_source.png', [(162,66),(168,91),(158,94),(162,128)], 'crouch_head_down'),
 ('wall_hit_right_000_source.png', [(125,56),(133,85),(134,87),(148,119)], 'lean_rotation'),
 ('idle_right_001_source.png', [(163,35),(166,68),(163,70),(158,113)], 'idle_reference_variation'),
 ('idle_right_002_source.png', [(163,37),(166,70),(162,71),(159,114)], 'idle_reference_variation'),
 ('idle_right_003_source.png', [(163,36),(166,69),(163,71),(158,114)], 'idle_reference_variation'),
 ('special_guard_right_000_source.png', [(161,66),(164,92),(155,94),(158,126)], 'chin_partly_occluded'),
 ('special_guard_right_001_source.png', [(162,66),(165,92),(157,94),(161,127)], 'chin_partly_occluded'),
 ('wall_fall_right_000_source.png', [(162,67),(164,95),(155,97),(148,133)], 'head_down_forward_lean'),
]

def distance(a,b): return math.dist(a,b)
base_head = distance(*DATA[0][1][:2])
base_torso = distance(*DATA[0][1][2:])
rows = []
sheet = Image.new('RGB', (1280, math.ceil(len(DATA)/2)*480), '#303b45')
for i,(name,points,pose) in enumerate(DATA):
    im = Image.open(SRC/name).convert('RGBA')
    panel = Image.new('RGB',(640,480),'#303b45')
    panel.paste(im.resize((640,448),Image.Resampling.NEAREST),(0,0),im.resize((640,448),Image.Resampling.NEAREST))
    d = ImageDraw.Draw(panel)
    for label,p in zip(['C','H','N','B'],points):
        x,y = p[0]*2,p[1]*2
        d.ellipse((x-4,y-4,x+4,y+4),outline='#ffdf00',width=1)
        d.line((x-6,y,x+6,y),fill='#ffdf00')
        d.line((x,y-6,x,y+6),fill='#ffdf00')
        d.text((x+7,y-5),label,fill='white')
    for a,b in [(points[0],points[1]),(points[2],points[3])]:
        d.line((a[0]*2,a[1]*2,b[0]*2,b[1]*2),fill='#ffdf00',width=1)
    d.text((8,450),name,fill='white')
    d.text((8,465),'Visible proxies; endpoint uncertainty +/-2px; anatomy UNVERIFIED',fill='white')
    sheet.paste(panel,((i%2)*640,(i//2)*480))
    head,torso = distance(*points[:2]),distance(*points[2:])
    rows.append(dict(frame=name,pose=pose,crown=points[0],chin=points[1],collar=points[2],belt=points[3],
      head_surface_distance=round(head,3),collar_belt_distance=round(torso,3),
      head_proxy_delta_percent=round((head/base_head-1)*100,2),
      torso_proxy_delta_percent=round((torso/base_torso-1)*100,2),
      endpoint_uncertainty_pixels=2,distance_uncertainty_pixels=4,
      anatomy_status='未確認',target_2percent_status='未確認',
      chin_visibility='partly_occluded' if 'special_guard' in name else 'visible_surface',
      reason='Surface proxies, rotation and occlusion do not establish bone dimensions.'))
sheet.save(OUT/'annotated_visible_landmarks.png')
(OUT/'visible_landmarks.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
with (OUT/'visible_landmark_measurements.csv').open('w',encoding='utf-8-sig',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=rows[0].keys());writer.writeheader();writer.writerows(rows)
print(json.dumps(rows,ensure_ascii=False,indent=2))
