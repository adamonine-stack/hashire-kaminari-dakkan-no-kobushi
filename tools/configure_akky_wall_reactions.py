"""Reuse each victim's authored recoil/air poses for wall contact and gravity fall."""
from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]
for folder in (ROOT/'godot/assets/characters/special_received_v1').iterdir():
    atlas=folder/'motion_atlas.tres'
    text=atlas.read_text(encoding='utf-8')
    if 'received_akky_elbow_wall' not in text:
        text=text.rstrip().removesuffix('}')+',\n"received_akky_elbow_wall": {"frames": [1], "fps": 8.0, "loop": false},\n"received_akky_elbow_fall": {"frames": [0], "fps": 10.0, "loop": false}\n}\n'
    text=re.sub(r'("received_akky_elbow_wall": \{"frames": )\[\d+\]',r'\g<1>[1]',text)
    text=re.sub(r'("received_akky_elbow_fall": \{"frames": )\[\d+\]',r'\g<1>[0]',text)
    atlas.write_text(text,encoding='utf-8')
    fighter=ROOT/'godot/data/enemies'/(folder.name+'.tres')
    text=fighter.read_text(encoding='utf-8')
    match=re.search(r'^special_damage_reactions = (.+)$',text,re.M)
    reactions=json.loads(match[1])
    reactions['player1_special_thunder_drive'].update(wall='received_akky_elbow_wall',fall='received_akky_elbow_fall')
    fighter.write_text(text[:match.start(1)]+json.dumps(reactions)+text[match.end(1):],encoding='utf-8')
print('AKKY_WALL_CLIPS_OK enemies=9')
