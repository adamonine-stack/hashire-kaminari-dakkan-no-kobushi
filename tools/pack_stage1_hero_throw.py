"""Pack reviewed throw key poses; one scale per sheet, no anatomical edits."""
from pathlib import Path
from PIL import Image,ImageFilter
import json,sys
HERO,MODE=sys.argv[1:3]
assert HERO in ['gou','seiya'] and MODE in ['attack','victim']
VERSION=('throw_v11' if HERO=='gou' else 'slim_throw_v13')+('_victim' if MODE=='victim' else '')
REFERENCE='gou_anti_air_v2' if HERO=='gou' else 'seiya_slim_v3'
HEIGHT=203 if HERO=='gou' else 195
PLAYER='player02' if HERO=='gou' else 'player03'
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/f'art_sources/{HERO}_{VERSION}/key_poses.png'
DEST=ROOT/f'godot/assets/characters/{PLAYER}/animations/{VERSION}'
def main():
 src=Image.open(SOURCE).convert('RGBA');w,h=src.size
 alpha=bytearray(1 if v>=128 else 0 for v in src.getchannel('A').get_flattened_data());figures=[]
 for k in range(len(alpha)):
  if not alpha[k]:continue
  todo=[k];alpha[k]=0;pixels=[];lx=w;ly=h;hx=hy=0
  while todo:
   p=todo.pop();x=p%w;y=p//w;pixels.append(p);lx=min(lx,x);ly=min(ly,y);hx=max(hx,x);hy=max(hy,y)
   for j in [p-1 if x else -1,p+1 if x<w-1 else -1,p-w,p+w]:
    if 0<=j<len(alpha) and alpha[j]:alpha[j]=0;todo.append(j)
  if len(pixels)>10000:figures.append(([lx,ly,hx+1,hy+1],pixels))
 assert len(figures)==8,[(b,len(p)) for b,p in figures]
 figures.sort(key=lambda f:(0 if f[0][1]<h/2 else 1,f[0][0]))
 scale=HEIGHT/(figures[0][0][3]-figures[0][0][1])
 atlas=Image.new('RGBA',(1536,576));records=[]
 for i,(box,pixels) in enumerate(figures):
  mask=Image.new('L',(w,h));raw=bytearray(w*h)
  for p in pixels:raw[p]=255
  mask.frombytes(bytes(raw));mask=mask.filter(ImageFilter.MaxFilter(5))
  pose=Image.new('RGBA',src.size);pose.paste(src,(0,0),mask)
  crop=pose.getchannel('A').getbbox();pose=pose.crop(crop)
  anchor=pose.width/2
  if MODE=='attack' or i in [0,1,7]:
   a=pose.getchannel('A');bottom=pose.height;xs=[x for x in range(pose.width) if any(a.getpixel((x,y))>=128 for y in range(max(0,bottom-12),bottom))];groups=[]
   for x in xs:
    if not groups or x>groups[-1][-1]+1:groups.append([x])
    else:groups[-1].append(x)
   groups=sorted(groups,key=len,reverse=True)[:2]
   if groups:anchor=sum((g[0]+g[-1])/2 for g in groups)/len(groups)
  pose=pose.resize((round(pose.width*scale),round(pose.height*scale)),Image.Resampling.NEAREST)
  x=160-round(anchor*scale);y=270-pose.height
  assert x>=0 and y>=0 and x+pose.width<=384 and y+pose.height<=288,(i,x,y,pose.size)
  atlas.alpha_composite(pose,(i%4*384+x,i//4*288+y));records.append({'index':i,'crop':crop,'scale':scale,'anchor_x':anchor,'offset':[x,y]})
 def clip(frames,fps=10,loop=False):return {'frames':frames,'fps':fps,'loop':loop}
 if MODE=='attack':
  clips={'throw_start':clip([1,2],14),'throw_hold':clip([2],10,True),'directional_throw_hold':clip([2],10,True),'throw_release':clip([3,1,0]),f'{HERO}_throw_neutral_release':clip([3,1,0]),f'{HERO}_throw_forward_release':clip([4,1,0]),f'{HERO}_throw_down_release':clip([5,1,0]),f'{HERO}_throw_back_release':clip([6,1,0]),f'{HERO}_throw_whiff':clip([7,1,0],8)}
 else:
  clips={'directional_throw_held':clip([1],10,True),'grabbed':clip([1],10,True),'throw_victim_neutral_air':clip([2,2]),'throw_victim_forward_air':clip([3,3]),'throw_victim_down_air':clip([4,4]),'throw_victim_back_air':clip([5,5]),'throw_victim_slam_down':clip([6],8,True),'down':clip([6],8,True),'knockdown':clip([6],8,True),'knockdown_high':clip([6],8,True),'knockdown_low':clip([6],8,True),'standup':clip([6,7,0],8),'getup':clip([6,7,0],8),'stand_up':clip([6,7,0],8),'get_up':clip([6,7,0],8),'ko':clip([4,6,6],10),'defeat':clip([4,6,6],10)}
  for name,index in [('held',1),('neutral_air',2),('forward_air',3),('down_air',4),('back_air',5),('slam_down',6)]:clips['crusher_throw_'+name]=clip([index],10,name in ['held','slam_down'])
 DEST.mkdir(parents=True,exist_ok=True);atlas.save(DEST/'motion_atlas.png')
 text='[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n'+f'[ext_resource type="Texture2D" path="res://assets/characters/{PLAYER}/animations/{VERSION}/motion_atlas.png" id="2"]\n[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i(384,288)\ncolumns = 4\nhead_scale_override = 1.0\nclips = '+json.dumps(clips)+'\n'
 (DEST/'motion_atlas.tres').write_text(text,encoding='utf-8');(DEST/'packing_manifest.json').write_text(json.dumps({'source':str(SOURCE.relative_to(ROOT)),'reference_height':HEIGHT,'scale':scale,'resampling':'nearest','frames':records},indent=2),encoding='utf-8')
 review=Image.new('RGBA',(1936,576),(48,52,60,255));review.alpha_composite(Image.open(ROOT/f'art_sources/{REFERENCE}/formal_standing.png'),(0,0));review.alpha_composite(atlas,(400,0));review.save(SOURCE.parent/'same_scale_review.png')
 print('HERO_THROW_PACK_OK',HERO,MODE,scale)
if __name__=='__main__':main()
