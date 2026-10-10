"""Stage only this task's implementation and compact review evidence."""
from pathlib import Path
import subprocess,json
root=Path(__file__).resolve().parents[1]
paths=['godot/data','godot/assets/characters/basic_moves_v2','docs/HERO_ORIGINAL_MOVES.md']
paths += ['tools/'+p for p in ['pack_basic_move_sources.py','pack_basic_move_supplements.py','configure_basic_moves.py','build_basic_moves_gallery.py','stage_basic_moves_release.py']]
for stem in ['basic_moves_inventory','basic_moves_combat_check','basic_moves_visual_review','hero_original_moves_check']:
    paths += [f'godot/tests/{stem}.gd']
    uid=f'godot/tests/{stem}.gd.uid'
    if (root/uid).exists():paths.append(uid)
paths.append('godot/tests/air_combo_check.gd')
evidence=root/'audit_evidence/basic_moves_20261010'
paths += [str(p.relative_to(root)).replace('\\','/') for p in (evidence/'rendered').glob('*.gif')]
paths += [str(p.relative_to(root)).replace('\\','/') for p in (evidence/'rendered').glob('*contacts.jpg')]
paths += ['audit_evidence/basic_moves_20261010/rendered/'+p for p in ['index.html','manifest.json']]
paths += ['audit_evidence/basic_moves_20261010/combat_results.json','audit_evidence/basic_moves_20261010/inventory/inventory.json']
inventory=json.loads((evidence/'inventory/inventory.json').read_text(encoding='utf-8'))
for actor in inventory:
    for clip in ['punch_1','kick_1','crouch_punch','crouch_kick_sweep','jump_punch','jump_kick']:
        p=evidence/'inventory'/f"{actor['id']}__{clip}.png"
        if p.exists():paths.append(p.relative_to(root).as_posix())
    for slug in ['akky','gou','seiya']:
        if slug not in actor['id'] or 'enemy_' in actor['id']:continue
        for clip in ['forward_punch','back_punch','forward_kick','back_kick','air_punch','air_kick']:
            p=evidence/'inventory'/f"{actor['id']}__{slug}_{clip}.png"
            if p.exists():paths.append(p.relative_to(root).as_posix())
subprocess.run(['git','add','-u','--','godot/scripts'],cwd=root,check=True)
subprocess.run(['git','add','--']+paths,cwd=root,check=True)
subprocess.run(['git','diff','--cached','--check'],cwd=root,check=True)
print('SCOPED_BASIC_MOVES_STAGE_OK paths=',len(paths))
