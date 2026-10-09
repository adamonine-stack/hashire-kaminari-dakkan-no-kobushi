"""Copy a small reviewable subset; keep full frame captures in local audit_evidence."""
from pathlib import Path
import json, shutil
root=Path(__file__).resolve().parents[1]
audit=root/'audit_evidence/body_dimensions'
dest=root/'docs/stage1_body_evidence_20261010'
dest.mkdir(exist_ok=True)
copies={
 'hit_before_after.png':'akky_hit_before_after.png',
 'idle_akky.png':'wall_all_headless/player_01_akky/idle_right_000_source.png',
 'idle_crusher.png':'wall_all_headless/enemy_01_crusher/idle_right_000_source.png',
 'guard_left_gui.jpg':'landmark_review/guard_left_gui.jpg',
 'wall_fall_right_gui.jpg':'landmark_review/wall_fall_right_gui.jpg',
 'normal_input_jump_gui.jpg':'continuous_gameplay/gui/live_b.jpg',
 'akky_motion_status.csv':'landmark_review/current_sheets/motion_status.csv',
 'visible_landmark_measurements.csv':'landmark_review/visible_landmark_measurements.csv',
 'visible_landmarks.json':'landmark_review/visible_landmarks.json',
 'continuous_gameplay_fixed_camera.json':'continuous_gameplay/capture_fixed_camera/summary.json',
 'continuous_gameplay_realtime.json':'continuous_gameplay/realtime/summary.json',
 'annotated_visible_landmarks.png':'landmark_review/annotated_visible_landmarks.png',
}
for folder in ['upper_lower_review','air_punch_review','back_throw_review','special_guard_review','ground_bounce_review','wall_review']:
    copies[folder+'_comparison.png']=folder+'/comparison.png'
    copies[folder+'_prompts.md']=folder+'/IMAGE_PROMPTS.md'
for name,path in copies.items(): shutil.copyfile(audit/path,dest/name)
inventory=json.loads((audit/'stage1_release_gate/inventory.json').read_text(encoding='utf-8'))
summary={'baseline':inventory['baseline'],'directional_frame_references':len(inventory['frames']),
 'changed_akky_frames':inventory['changed_akky_frames'],'failures':inventory['failures'],'anatomy_status':'unverified','actors':{}}
for row in inventory['frames']:
    actor=summary['actors'].setdefault(row['actor'],{'motions':{},'directional_frame_references':0})
    actor['directional_frame_references']+=1
    actor['motions'][row['clip']]={'fps':row['fps'],'loop':row['loop'],'frames':max(actor['motions'].get(row['clip'],{}).get('frames',0),row['frame']+1),'scale_flip':'pass','anatomy_status':'unverified','all_frames_gui':'unverified'}
(dest/'stage1_contract_summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for path in [root/'.github/workflows/deploy-godot-web.yml',*dest.glob('*.md')]:
    path.write_bytes(path.read_bytes().replace(b'\r\n',b'\n'))
print(f'Packaged {len(copies)+1} files, {sum(p.stat().st_size for p in dest.iterdir())} bytes.')
