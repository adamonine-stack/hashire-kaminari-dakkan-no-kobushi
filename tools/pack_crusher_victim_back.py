"""Technical sprite isolation/atlas packing. Preserve RGBA and anatomy; use ONE scale."""
from pathlib import Path
from PIL import Image,ImageFilter
import json
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'art_sources/crusher_victim_back_v6/key_poses.png'
DEST=ROOT/'godot/assets/characters/enemy01/animations/unified_victim_back_v6'
def main():
 src=Image.open(SOURCE).convert('RGBA');w,h=src.size
 alpha=bytearray(1 if x>=128 else 0 for x in src.getchannel('A').get_flattened_data())
 figures=[]
 for k in range(len(alpha)):
  if not alpha[k]:continue
  todo=[k];alpha[k]=0;pixels=[];lx=w;ly=h;hx=hy=0
  while todo:
   p=todo.pop();x=p%w;y=p//w;pixels.append(p);lx=min(lx,x);ly=min(ly,y);hx=max(hx,x);hy=max(hy,y)
   for j in [p-1 if x else -1,p+1 if x<w-1 else -1,p-w,p+w]:
    if 0<=j<len(alpha) and alpha[j]:alpha[j]=0;todo.append(j)
  if len(pixels)>10000:figures.append(([lx,ly,hx+1,hy+1],pixels))
 assert len(figures)==4,len(figures)
 # Layout has unequal row heights; rectangular crops would mix adjacent bandana/boot pixels.
 figures.sort(key=lambda f: (0 if f[0][1]<600 else 1,f[0][0]))
 ref=Image.open(ROOT/'art_sources/crusher_throw_design_v2/formal_standing.png')
 rb=ref.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
 scale=(rb[3]-rb[1])/(figures[0][0][3]-figures[0][0][1])
 atlas=Image.new('RGBA',(800,560));records=[]
 for i,(box,pixels) in enumerate(figures):
  # Isolate the supplied figure, retaining its original RGBA including the soft outer edge.
  mask=Image.new('L',(w,h));raw=bytearray(w*h)
  for p in pixels:raw[p]=255
  mask.frombytes(bytes(raw));mask=mask.filter(ImageFilter.MaxFilter(5))
  pose=Image.new('RGBA',src.size);pose.paste(src,(0,0),mask)
  crop=pose.getchannel('A').getbbox();pose=pose.crop(crop)
  anchor=pose.width/2
  pose=pose.resize((round(pose.width*scale),round(pose.height*scale)),Image.Resampling.NEAREST)
  x=200-round(anchor*scale);y=260-pose.height
  assert x>=0 and y>=0 and x+pose.width<=400 and y+pose.height<=280,(i,x,y,pose.size)
  atlas.alpha_composite(pose,(i%2*400+x,i//2*280+y))
  records.append({'index':i,'source_bbox':box,'crop':crop,'scale':scale,'offset':[x,y]})
 DEST.mkdir(parents=True,exist_ok=True);atlas.save(DEST/'motion_atlas.png')
 clips={'throw_victim_back_air':{'frames':[1,2,3],'fps':10,'loop':False}}
 text='[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n[ext_resource type="Texture2D" path="res://assets/characters/enemy01/animations/unified_victim_back_v6/motion_atlas.png" id="2"]\n[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i(400,280)\ncolumns = 2\nclips = '+json.dumps(clips)+'\n'
 (DEST/'motion_atlas.tres').write_text(text,encoding='utf-8');(DEST/'packing_manifest.json').write_text(json.dumps({'source':str(SOURCE.relative_to(ROOT)),'reference_height':rb[3]-rb[1],'scale':scale,'resampling':'nearest','frames':records},indent=2),encoding='utf-8')
 review=Image.new('RGBA',(1200,560),(48,52,60,255));review.alpha_composite(ref,(0,0));review.alpha_composite(atlas,(400,0));review.save(ROOT/'art_sources/crusher_victim_back_v6/same_scale_review.png')
 print('CRUSHER_VICTIM_BACK_PACK_OK',scale)
if __name__=='__main__':main()
