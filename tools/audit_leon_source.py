from pathlib import Path
from PIL import Image
import numpy as np, json
from collections import deque
ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/'evidence/leon_source'
folder.mkdir(parents=True,exist_ok=True)
p=ROOT/'godot/assets/characters/enemy08/animations/leon_v1/sources/generated_atlas.png'
a=np.array(Image.open(p).convert('RGBA'))
body=(a[:,:,3]>=100)&~((a[:,:,2].astype(float)>a[:,:,0]*1.2)&(a[:,:,2].astype(float)>a[:,:,1]*1.2)&(a[:,:,2]>55))
labels=np.zeros(body.shape,dtype=np.int32);items=[];n=0
h,w=body.shape
for sy,sx in zip(*np.where(body)):
 if labels[sy,sx]:continue
 n+=1;labels[sy,sx]=n;todo=deque([(int(sx),int(sy))]);pixels=0
 x0=x1=int(sx);y0=y1=int(sy)
 while todo:
  x,y=todo.popleft();pixels+=1
  x0=min(x0,x);x1=max(x1,x);y0=min(y0,y);y1=max(y1,y)
  for dy in [-1,0,1]:
   for dx in [-1,0,1]:
    xx,yy=x+dx,y+dy
    if 0<=xx<w and 0<=yy<h and body[yy,xx] and labels[yy,xx]==0:
     labels[yy,xx]=n;todo.append((xx,yy))
 if pixels>=700:items.append(dict(label=n,box=[x0,y0,x1+1,y1+1],area=pixels))
items.sort(key=lambda v:((v['box'][1]+v['box'][3])/2))
rows=[[] for _ in range(7)]
for v in items:
 cy=(v['box'][1]+v['box'][3])/2
 row=min(6,int(cy//185))
 rows[row].append(v)
ordered=[]
for row in rows:
 row.sort(key=lambda v:(v['box'][0]+v['box'][2])/2)
 ordered.extend(row)
for i,v in enumerate(ordered):
 v['index']=i
 print(i,v['box'],v['area'])
 mask=labels==v['label']; ys,xs=np.where(mask)
 im=Image.fromarray(a.copy()); alpha=np.where(mask,a[:,:,3],0).astype(np.uint8)
 im.putalpha(Image.fromarray(alpha));im=im.crop(v['box'])
 im.save(folder/f'pose_{i:02d}.png')
(folder/'components.json').write_text(json.dumps(ordered,indent=2))
old=Image.open(ROOT/'godot/assets/characters/enemy08/animations/leon_v1/motion_atlas.png').convert('RGBA')
old.crop((0,0,320,320)).save(folder/'old_idle.png')
print('SOURCE_SIZE',a.shape,'POSES',len(ordered))
