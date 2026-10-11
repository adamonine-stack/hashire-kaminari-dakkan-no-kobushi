"""Stage only the authored normal-chain changes and compact review evidence."""
from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[1]
paths=['godot/data','godot/assets/characters/overhead_v1']
paths += ['godot/scripts/player/'+n for n in ['player_combo_movement.gd','player_knockdown_movement.gd','player_movement.gd','player_fighter_definition_movement.gd']]
paths += ['godot/tests/basic_moves_combat_check.gd']
for n in ['normal_chains_check','normal_chains_live_check','normal_chains_visual_review','stage1_chain_source_inventory','stages2_5_chain_sources','stages6_9_chain_sources']:
    paths.append('godot/tests/'+n+'.gd')
paths += [p.relative_to(root).as_posix() for p in (root/'tools').glob('*chain*.py')]
paths += ['tools/register_overhead_poses.py','tools/prepare_stage1_chain_references.py','tools/review_stages2_5_render.py','tools/review_stages2_5_sources.py','tools/review_stages6_9_render.py']
for folder in ['normal_chains_20261011','normal_chains_stages2_5','normal_chains_stages6_9']:
    base=root/'audit_evidence'/folder
    paths += [p.relative_to(root).as_posix() for p in base.glob('*.md')]
    paths += [p.relative_to(root).as_posix() for p in base.glob('*.jpg')]
subprocess.run(['git','add','--']+paths,cwd=root,check=True)
subprocess.run(['git','diff','--cached','--check'],cwd=root,check=True)
print('NORMAL_CHAINS_SCOPED_STAGE_OK')
