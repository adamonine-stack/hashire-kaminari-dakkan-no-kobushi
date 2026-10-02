from pathlib import Path
import re
ROOT = Path(__file__).resolve().parents[1]
# Horizontal drive, upward launch and power slam retain distinct trajectories.
profiles = {
 'player1_special_thunder_drive': (2200,460), 'player2_special_iron_breaker': (460,400),
 'player3_special_clear_counter': (720,440), 'crusher_fault_break': (820,520),
 'shadow_slip_counter': (700,430), 'masato_palm_reversal': (740,450),
 'rei_dragon_uppercut': (560,700), 'cross_muei': (730,480),
 'rio_cross_counter': (750,450), 'teki_deadly_hand': (680,500),
 'leon_crow_reversal': (840,560), 'seiya_dark_reversal': (780,520),
}
for attack, (x,y) in profiles.items():
    path = ROOT / f'godot/data/attacks/{attack}.tres'
    text = path.read_text(encoding='utf-8')
    text = re.sub(r'^knockback = Vector2\([^\n]+\)',f'knockback = Vector2({x}, -{y})',text,flags=re.M)
    text = re.sub(r'^camera_shake = .+$','camera_shake = 6.0',text,flags=re.M)
    if not re.search(r'^camera_shake =',text,re.M): text += '\ncamera_shake = 6.0\n'
    path.write_text(text,encoding='utf-8')
print('SPECIAL_LAUNCH_PROFILES_OK count=12')
