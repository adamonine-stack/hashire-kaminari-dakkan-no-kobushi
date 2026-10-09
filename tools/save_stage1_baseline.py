"""Pin the pre-repair fighter definition for animation/combat contract QA."""
from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[1]
folder=root/'godot/tests/fixtures/body_dimensions'
folder.mkdir(parents=True,exist_ok=True)
data=subprocess.check_output(['git','show','7d0c79c:godot/data/fighters/ally_balance.tres'],cwd=root)
(folder/'akky_before.tres').write_bytes(data.replace(b'\r\n',b'\n'))
print('Saved baseline definition from 7d0c79c; source art stays at existing res paths.')
