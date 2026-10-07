"""Pack authored poses with one standing-calibrated uniform scale; no anatomy edits."""
from pathlib import Path
from PIL import Image
import json
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'art_sources/crusher_throw_design_v2/key_pose_source.png'
REFERENCE=ROOT/'art_sources/crusher_throw_design_v2/formal_standing.png'
DEST=ROOT/'godot/assets/characters/enemy01/animations/unified_throw_v2'
def main():
 src=Image.open(SOURCE).convert('RGBA')
 ref=Image.open(REFERENCE).convert('RGBA')
 opaque=lambda im: im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
 refbox=opaque(ref)
 standing=opaque(src.crop((0,0,512,512)))
 scale=(refbox[3]-refbox[1])/(standing[3]-standing[1])
 atlas=Image.new('RGBA',(1200,560)); records=[]
 for i in range(6):
  cell=src.crop((i%3*512,i//3*512,i%3*512+512,i//3*512+512))
  box=opaque(cell)
  feet=cell.getchannel('A').crop((0,box[3]-18,512,box[3]))
  xs=[x for x in range(512) if any(feet.getpixel((x,y))>=128 for y in range(18))]
  groups=[]
  for x in xs:
   if not groups or x>groups[-1][-1]+1: groups.append([x])
   else: groups[-1].append(x)
  groups=sorted(groups,key=len,reverse=True)[:2]
  anchor=sum((g[0]+g[-1])/2 for g in groups)/len(groups)
  pose=cell.crop(box)
  pose=pose.resize((round(pose.width*scale),round(pose.height*scale)),Image.Resampling.NEAREST)
  x=200-round((anchor-box[0])*scale); y=260-pose.height
  assert x>=0 and y>=0 and x+pose.width<=400 and y+pose.height<=280,(i,x,y,pose.size)
  atlas.alpha_composite(pose,(i%3*400+x,i//3*280+y))
  records.append({'index':i,'crop':box,'feet_midpoint':anchor,'scale':scale,'offset':[x,y]})
 DEST.mkdir(parents=True,exist_ok=True)
 atlas.save(DEST/'motion_atlas.png')
 clips={'crusher_throw_start':{'frames':[1,2],'fps':12,'loop':False},'crusher_throw_hold':{'frames':[2],'fps':12,'loop':False},'crusher_throw_down_release':{'frames':[4,5],'fps':10,'loop':False}}
 text='[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n'
 text+='[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n'
 text+='[ext_resource type="Texture2D" path="res://assets/characters/enemy01/animations/unified_throw_v2/motion_atlas.png" id="2"]\n'
 text+='[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i(400,280)\ncolumns = 3\nclips = '+json.dumps(clips)+'\n'
 (DEST/'motion_atlas.tres').write_text(text,encoding='utf-8')
 (DEST/'packing_manifest.json').write_text(json.dumps({'reference':str(REFERENCE.relative_to(ROOT)),'standing_height':refbox[3]-refbox[1],'source':str(SOURCE.relative_to(ROOT)),'scale':scale,'frames':records},indent=2),encoding='utf-8')
 print('CRUSHER_UNIFIED_THROW_PACK_OK',scale)
if __name__=='__main__':main()
