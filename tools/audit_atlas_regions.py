"""Audit existing pixels and write explicit frame rectangles; never edit artwork."""
from pathlib import Path
from collections import deque
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'godot'
CASES = {
 'enemy05/animations/shadow_boxer_v1': [0, 163, 326, 487, 648, 818, 981, 1217],
 'enemy06/animations/rio_garcia_v1': [0, 184, 346, 541, 728, 917, 1055, 1247],
}

def components(mask):
    seen = np.zeros(mask.shape, dtype=bool)
    results = []
    h, w = mask.shape
    for y, x in zip(*np.where(mask)):
        if seen[y,x]: continue
        todo = deque([(int(x),int(y))]); seen[y,x] = True
        x0=x1=int(x); y0=y1=int(y); count=0
        while todo:
            px,py = todo.popleft(); count += 1
            x0=min(x0,px); x1=max(x1,px); y0=min(y0,py); y1=max(y1,py)
            for nx,ny in ((px-1,py),(px+1,py),(px,py-1),(px,py+1)):
                if 0<=nx<w and 0<=ny<h and mask[ny,nx] and not seen[ny,nx]:
                    seen[ny,nx]=True; todo.append((nx,ny))
        if count>300: results.append((x0,y0,x1+1,y1+1,count))
    return results

if __name__ == '__main__':
    import json
    result = {}
    for folder, rows in CASES.items():
        a=np.array(Image.open(ROOT/'assets/characters'/folder/'motion_atlas.png').convert('RGBA'))
        frames=[]
        for row,(top,bottom) in enumerate(zip(rows,rows[1:])):
            comps=sorted(components(a[top:bottom,:,3]>100), key=lambda c:c[4],reverse=True)[:8]
            comps.sort(key=lambda c:c[0])
            print(folder,row,len(comps),comps)
            assert len(comps)==8 or ('rio_garcia' in folder and row==5 and len(comps)==7)
            for x0,y0,x1,y1,count in comps:
                # Include antialiasing around the same complete body, while keeping
                # transparent gaps to adjacent poses and row separators.
                frames.append([x0,top+max(0,y0-1),x1-x0,min(bottom-top,y1+1)-max(0,y0-1)])
            if len(comps)==7: frames.append(frames[-1].copy())
        result[folder]=frames
    out=ROOT.parent/'evidence/atlas_regions.json'
    out.parent.mkdir(exist_ok=True,parents=True)
    out.write_text(json.dumps(result,indent=2))
    if '--write' in __import__('sys').argv:
        import re
        for folder, frames in result.items():
            path=ROOT/'assets/characters'/folder/'motion_atlas.tres'
            text=path.read_text(encoding='utf-8')
            text=re.sub(r'^frame_(?:regions|offsets|source_scales) = .*\n?', '', text, flags=re.MULTILINE).rstrip()+'\n'
            text=re.sub(r'cell_size = Vector2i\(\d+, \d+\)', 'cell_size = Vector2i(320, 256)',text)
            # The final physical row contains hit, fall, floor, recovery, victory.
            remap={56:51,57:52,58:52,59:52,60:53,61:54,62:0,63:55}
            text=re.sub(r'"frames": \[([^]]+)\]',lambda m:'"frames": ['+', '.join(str(remap.get(int(n.strip()),int(n.strip()))) for n in m[1].split(','))+']',text)
            text=re.sub(r'"victory": \{[^}]+\}', '"victory": {"frames": [55], "fps": 6.0, "loop": false}',text)
            for clip, indices in {'fall':[50,51,52], 'land':[40,0], 'thrown':[49,50,51,52], 'knockdown':[49,50,51,52], 'down':[51,52], 'ko':[51,52], 'getup':[52,53,54,0], 'stand_up':[52,53,54,0]}.items():
                text=re.sub(r'"'+clip+r'": \{[^}]+\}', '"'+clip+'": {"frames": ['+', '.join(map(str,indices))+'], "fps": 8.0, "loop": false}',text)
            # Keep crouches on actual crouching poses, not running poses.
            crouch=[40,45] if 'rio_garcia' in folder else [40]
            for clip in ['crouch','crouch_idle','crouch_guard']:
                text=re.sub(r'"'+clip+r'": \{[^}]+\}', '"'+clip+'": {"frames": ['+', '.join(map(str,crouch))+'], "fps": 6.0, "loop": true}',text)
            text += '\nframe_regions = Array[Rect2i](['+', '.join('Rect2i(%d, %d, %d, %d)'%tuple(r) for r in frames)+'])\n'
            text += 'frame_offsets = Array[Vector2i](['+', '.join('Vector2i(%d, %d)'%((320-r[2])//2,240-r[3]) for r in frames)+'])\n'
            scales=[1.0]*48+([0.832402]*8 if 'shadow_boxer' in folder else [1.0]*8)
            text += 'frame_source_scales = PackedFloat32Array('+', '.join(map(str,scales))+')\n'
            path.write_text(text,encoding='utf-8',newline='\n')
