"""Pack complete single-actor originals; preserve one anatomical scale and floor."""
from pathlib import Path
from PIL import Image, ImageChops
from collections import deque
import json, math, re, hashlib
ROOT=Path(__file__).resolve().parents[1];G=ROOT/'godot'
CELL=(512,448);BASELINE=404;COLS=6

def area(im):return sum(a>=128 for a in im.getchannel('A').get_flattened_data())

def components(im,minimum=1000,alpha_threshold=100):
 w,h=im.size;mask=bytearray(a>=alpha_threshold for a in im.getchannel('A').get_flattened_data());result=[]
 for seed in range(len(mask)):
  if not mask[seed]:continue
  mask[seed]=0;q=deque([seed]);pixels=[]
  while q:
   p=q.popleft();pixels.append(p);x,y=p%w,p//w
   for dy in [-1,0,1]:
    for dx in [-1,0,1]:
     xx,yy=x+dx,y+dy
     if 0<=xx<w and 0<=yy<h and mask[yy*w+xx]:mask[yy*w+xx]=0;q.append(yy*w+xx)
  if len(pixels)<minimum:continue
  coverage=bytearray(w*h)
  for p in pixels:coverage[p]=255
  selection=Image.frombytes('L',im.size,bytes(coverage));pose=im.copy()
  pose.putalpha(ImageChops.multiply(im.getchannel('A'),selection));box=selection.getbbox()
  result.append((box,pose.crop(box)))
 return sorted(result,key=lambda v:(int(((v[0][1]+v[0][3])/2)//430), (v[0][0]+v[0][2])/2))

def restore_original(i,records,source):
 r=records[i];box=r['box'];region=source.crop(box)
 mask=Image.open(ROOT/f'evidence/masato_source/pose_{i:02d}.png').getchannel('A')
 # Retain original colors inside the measured character contour, including the
 # purple jacket emblem. Purple effects outside the contour are separate VFX.
 w,h=mask.size;solid=bytearray(a>=100 for a in mask.get_flattened_data());outside=bytearray(w*h);q=deque()
 for x in range(w):q.extend([x,(h-1)*w+x])
 for y in range(h):q.extend([y*w,y*w+w-1])
 while q:
  p=q.popleft()
  if outside[p] or solid[p]:continue
  outside[p]=1;x,y=p%w,p//w
  for n in [p-1 if x else -1,p+1 if x<w-1 else -1,p-w if y else -1,p+w if y<h-1 else -1]:
   if n>=0 and not outside[n] and not solid[n]:q.append(n)
 contour=Image.frombytes('L',(w,h),bytes(255 if not v else 0 for v in outside))
 region.putalpha(ImageChops.multiply(region.getchannel('A'),contour))
 return region

def pack(poses,clips,folder,names,scales):
 folder.mkdir(parents=True,exist_ok=True)
 image=Image.new('RGBA',(CELL[0]*COLS,CELL[1]*math.ceil(len(poses)/COLS)));records=[]
 for i,(pose,name,factor) in enumerate(zip(poses,names,scales)):
  pose=pose.resize((round(pose.width*factor),round(pose.height*factor)),Image.Resampling.NEAREST)
  x=(CELL[0]-pose.width)//2;y=BASELINE-pose.height
  assert x>=2 and y>=2 and x+pose.width<=CELL[0]-2 and y+pose.height<=CELL[1],(name,pose.size)
  image.alpha_composite(pose,(i%COLS*CELL[0]+x,i//COLS*CELL[1]+y))
  records.append(dict(index=i,name=name,scale=factor,offset=[x,y],size=list(pose.size),opaque_area=area(pose),relative_area=area(pose)/REFERENCE_AREA))
 image.save(folder/'motion_atlas.png')
 path=(folder/'motion_atlas.png').relative_to(G).as_posix()
 (folder/'motion_atlas.tres').write_text('[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n'+f'[ext_resource type="Texture2D" path="res://{path}" id="2"]\n[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i({CELL[0]}, {CELL[1]})\ncolumns = {COLS}\nclips = '+json.dumps(clips)+'\n',encoding='utf-8')
 (folder/'packing_manifest.json').write_text(json.dumps(dict(cell=CELL,baseline=BASELINE,reference_area=REFERENCE_AREA,reference_height=REFERENCE_HEIGHT,frames=records),indent=2)+'\n',encoding='utf-8')
