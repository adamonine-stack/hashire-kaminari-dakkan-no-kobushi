"""Technical sprite isolation/atlas packing. Preserve RGBA and anatomy; use ONE scale."""
from pathlib import Path
from PIL import Image,ImageFilter
import json
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'art_sources/crusher_throw_design_v2/remaining_release_candidate.png'
DEST=ROOT/'godot/assets/characters/enemy01/animations/unified_throw_release_v2'
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
 assert len(figures)==7,len(figures)
 # Layout has unequal row heights; rectangular crops would mix adjacent bandana/boot pixels.
 figures.sort(key=lambda f: (0 if f[0][1]<380 else 1 if f[0][1]<700 else 2,f[0][0]))
 ref=Image.open(ROOT/'art_sources/crusher_throw_design_v2/formal_standing.png')
 rb=ref.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
 scale=(rb[3]-rb[1])/(figures[0][0][3]-figures[0][0][1])
 atlas=Image.new('RGBA',(1200,840));records=[]
 for i,(box,pixels) in enumerate(figures):
  # Isolate the supplied figure, retaining its original RGBA including the soft outer edge.
  mask=Image.new('L',(w,h));raw=bytearray(w*h)
  for p in pixels:raw[p]=255
  mask.frombytes(bytes(raw));mask=mask.filter(ImageFilter.MaxFilter(5))
  pose=Image.new('RGBA',src.size);pose.paste(src,(0,0),mask)
  crop=pose.getchannel('A').getbbox();pose=pose.crop(crop)
  feet=pose.getchannel('A').crop((0,pose.height-18,pose.width,pose.height))
  xs=[x for x in range(pose.width) if any(feet.getpixel((x,y))>=128 for y in range(18))];groups=[]
  for x in xs:
   if not groups or x>groups[-1][-1]+1:groups.append([x])
   else:groups[-1].append(x)
  groups=sorted(groups,key=len,reverse=True)[:2];anchor=sum((g[0]+g[-1])/2 for g in groups)/len(groups)
  pose=pose.resize((round(pose.width*scale),round(pose.height*scale)),Image.Resampling.NEAREST)
  x=200-round(anchor*scale);y=260-pose.height
  assert x>=0 and y>=0 and x+pose.width<=400 and y+pose.height<=280,(i,x,y,pose.size)
  atlas.alpha_composite(pose,(i%3*400+x,i//3*280+y))
  records.append({'index':i,'source_bbox':box,'crop':crop,'scale':scale,'offset':[x,y]})
 DEST.mkdir(parents=True,exist_ok=True);atlas.save(DEST/'motion_atlas.png')
 clips={f'crusher_throw_{d}_release':{'frames':frames,'fps':10,'loop':False} for d,frames in [('neutral',[1,2]),('forward',[3,4]),('back',[5,6])]}
 text='[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n[ext_resource type="Texture2D" path="res://assets/characters/enemy01/animations/unified_throw_release_v2/motion_atlas.png" id="2"]\n[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i(400,280)\ncolumns = 3\nclips = '+json.dumps(clips)+'\n'
 (DEST/'motion_atlas.tres').write_text(text,encoding='utf-8');(DEST/'packing_manifest.json').write_text(json.dumps({'source':str(SOURCE.relative_to(ROOT)),'reference_height':rb[3]-rb[1],'scale':scale,'resampling':'nearest','frames':records},indent=2),encoding='utf-8')
 review=Image.new('RGBA',(1600,840),(48,52,60,255));review.alpha_composite(ref,(0,0));review.alpha_composite(atlas,(400,0));review.save(ROOT/'art_sources/crusher_throw_design_v2/remaining_same_scale_review.png')
 print('CRUSHER_REMAINING_THROW_PACK_OK',scale)
if __name__=='__main__':main()
