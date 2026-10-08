"""Technical sprite isolation/atlas packing. Preserve RGBA and anatomy; use ONE scale."""
from pathlib import Path
from PIL import Image,ImageFilter
import json,sys
HERO=sys.argv[1]
assert HERO in ["gou","seiya"]
VERSION="guard_v10" if HERO=="gou" else "slim_guard_v12"
REFERENCE="gou_anti_air_v2" if HERO=="gou" else "seiya_slim_v3"
HEIGHT=203 if HERO=="gou" else 195
PLAYER="player02" if HERO=="gou" else "player03"
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/f'art_sources/{HERO}_{VERSION}/key_poses.png'
DEST=ROOT/f'godot/assets/characters/{PLAYER}/animations/{VERSION}'
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
 assert len(figures)==8,len(figures)
 # Layout has unequal row heights; rectangular crops would mix adjacent figure pixels.
 figures.sort(key=lambda f: (0 if f[0][1]<h/2 else 1,f[0][0]))
 ref=Image.open(ROOT/f'art_sources/{REFERENCE}/formal_standing.png')
 rb=ref.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
 scale=HEIGHT/(figures[0][0][3]-figures[0][0][1])
 atlas=Image.new('RGBA',(1536,576));records=[]
 for i,(box,pixels) in enumerate(figures):
  # Isolate the supplied figure, retaining its original RGBA including the soft outer edge.
  mask=Image.new('L',(w,h));raw=bytearray(w*h)
  for p in pixels:raw[p]=255
  mask.frombytes(bytes(raw));mask=mask.filter(ImageFilter.MaxFilter(5))
  pose=Image.new('RGBA',src.size);pose.paste(src,(0,0),mask)
  crop=pose.getchannel('A').getbbox();pose=pose.crop(crop)
  anchor=pose.width/2
  pose=pose.resize((round(pose.width*scale),round(pose.height*scale)),Image.Resampling.NEAREST)
  x=160-round(anchor*scale);y=270-HEIGHT if i in [3,5] else 270-pose.height
  assert x>=0 and y>=0 and x+pose.width<=384 and y+pose.height<=288,(i,x,y,pose.size)
  atlas.alpha_composite(pose,(i%4*384+x,i//4*288+y))
  records.append({'index':i,'source_bbox':box,'crop':crop,'scale':scale,'offset':[x,y]})
 DEST.mkdir(parents=True,exist_ok=True);atlas.save(DEST/'motion_atlas.png')
 clips={'guard':{'frames':[1,1],'fps':6,'loop':True},'crouch_guard':{'frames':[2,2],'fps':6,'loop':True},'air_guard':{'frames':[3,3],'fps':6,'loop':True},'guard_hit':{'frames':[4,1],'fps':12,'loop':False},'air_guard_hit':{'frames':[5,3],'fps':12,'loop':False},'damage_light':{'frames':[6,6,0],'fps':14,'loop':False},'damage_heavy':{'frames':[7,6,0],'fps':12,'loop':False}}
 text='[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n[ext_resource type="Texture2D" path="res://assets/characters/{PLAYER}/animations/{VERSION}/motion_atlas.png" id="2"]\n[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i(384,288)\ncolumns = 4\nhead_scale_override = 1.0\nclips = '+json.dumps(clips)+'\n'
 text=text.replace('{PLAYER}',PLAYER).replace('{VERSION}',VERSION)
 (DEST/'motion_atlas.tres').write_text(text,encoding='utf-8');(DEST/'packing_manifest.json').write_text(json.dumps({'source':str(SOURCE.relative_to(ROOT)),'reference_height':HEIGHT,'formal_reference_opaque_height':rb[3]-rb[1],'scale':scale,'resampling':'nearest','frames':records},indent=2),encoding='utf-8')
 review=Image.new('RGBA',(1936,576),(48,52,60,255));review.alpha_composite(ref,(0,0));review.alpha_composite(atlas,(400,0));review.save(ROOT/f'art_sources/{HERO}_{VERSION}/same_scale_review.png')
 print('HERO_GUARD_PACK_OK',HERO,scale)
if __name__=='__main__':main()
