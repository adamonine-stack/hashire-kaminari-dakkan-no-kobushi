"""Record actual sheet-review coverage, separately from anatomy certification."""
from pathlib import Path
import csv,json
root=Path(__file__).resolve().parents[1]/'audit_evidence/body_dimensions/landmark_review'
rows=json.loads((root/'current_sheets/index.json').read_text(encoding='utf-8'))
focus={'special_guard','wall_hit','wall_fall','air_guard','air_guard_hit'}
results=[]
for row in rows:
    motion=row['files'][0].split('_right_')[0]
    results.append(dict(index=row['index'],sha256=row['sha256'],representative=row['files'][0],
      alias_count=len(row['files']),sheet=f'page_{row["index"]//20:02}.png',
      sheet_review='一覧確認済み',body_dimensions='未確認',anatomy_2percent='未確認',
      follow_up='頭部の回転・遮蔽と寸法差の切り分け' if motion in focus else '身体部位寸法の詳細確認',
      gui='未確認'))
with (root/'current_sheets/screening_results.csv').open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.DictWriter(f,fieldnames=results[0]);w.writeheader();w.writerows(results)
source=list(csv.DictReader((root/'current_frame_results.csv').open(encoding='utf-8-sig')))
motions={}
for row in source: motions.setdefault(row['motion'],[]).append(row)
with (root/'current_sheets/motion_status.csv').open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.writer(f);w.writerow(['character','motion','directional_frame_references','unique_images','scale_flip','sheet_review','body_dimensions','gui_all_frames'])
    for motion,frames in sorted(motions.items()):
        w.writerow(['player_01_akky',motion,len(frames),len({r['sha256'] for r in frames}),'合格','一覧確認済み','未確認','未確認'])
print(f'Recorded {len(results)} unique images and {len(motions)} animation names; no anatomy passes awarded.')
