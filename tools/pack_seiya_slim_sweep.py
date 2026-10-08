"""Technical atlas packing: six authored cells, ONE standing-derived scale."""
from pathlib import Path
from PIL import Image
import json
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'art_sources/seiya_slim_v3/sweep_sequence_source.png'
DEST=ROOT/'godot/assets/characters/player03/animations/slim_sweep_v3'
# Filled from the inspected source; supporting foot, not bounding-box center.
CUTS=[(0,0,512,570),(512,0,1024,570),(1024,0,1536,570),
      (0,570,570,1000),(570,570,1050,1000),(1050,570,1536,1000)]
ROOTS=[(295,548),(726,540),(1132,540),(188,969),(742,969),(1239,969)]
STANDING_HEIGHT=501
# Approved idle_prebattle standing occupies 195px; combat idle is only 190px.
# Calibrate the entire authored sequence to the approved standing, not combat idle.
TARGET_STANDING_HEIGHT=195
SCALE=TARGET_STANDING_HEIGHT/STANDING_HEIGHT
CLIPS={
 "crouch_kick":{"frames":[1,2,3,4,5,1],"fps":10,"loop":False},
 "crouch_kick_sweep":{"frames":[1,2,3,4,5,1],"fps":10,"loop":False},
 "crouch_sweep_kick":{"frames":[1,2,3,4,5,1],"fps":10,"loop":False}
}
def main():
 source=Image.open(SOURCE).convert('RGBA')
 assert source.size==(1536,1024),source.size
 atlas=Image.new('RGBA',(384*3,288*2))
 records=[]
 for i,(rect,root) in enumerate(zip(CUTS,ROOTS)):
  cell=source.crop(rect)
  # Measure opaque character pixels to omit empty gutters/background noise.
  # Only crop; preserve source colors/alpha, never reshape anatomy.
  box=cell.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
  assert box is not None,i
  measured=(rect[0]+box[0],rect[1]+box[1],rect[0]+box[2],rect[1]+box[3])
  pose=source.crop(measured)
  pose=pose.resize((round(pose.width*SCALE),round(pose.height*SCALE)),Image.Resampling.LANCZOS)
  x=160-round((root[0]-measured[0])*SCALE)
  y=270-pose.height
  assert x>=0 and y>=0 and x+pose.width<=384 and y+pose.height<=288,(i,x,y,pose.size)
  atlas.alpha_composite(pose,(i%3*384+x,i//3*288+y))
  records.append({'index':i,'crop':measured,'support_foot':root,'scale':SCALE,'offset':[x,y]})
 DEST.mkdir(parents=True,exist_ok=True)
 atlas.save(DEST/'motion_atlas.png')
 text='[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n'
 text+='[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n'
 text+='[ext_resource type="Texture2D" path="res://assets/characters/player03/animations/slim_sweep_v3/motion_atlas.png" id="2"]\n'
 text+='[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i(384,288)\ncolumns = 3\nhead_scale_override = 1.0\n'
 text+='clips = '+json.dumps(CLIPS)+'\n'
 (DEST/'motion_atlas.tres').write_text(text,encoding='utf-8')
 (DEST/'packing_manifest.json').write_text(json.dumps({'formal_reference':'art_sources/seiya_slim_v3/formal_standing.png','body_balance_reference':'art_sources/seiya_slim_v3/akky_balance_reference.png','source':str(SOURCE.relative_to(ROOT)),'standing_source_height':STANDING_HEIGHT,'target_source_height':TARGET_STANDING_HEIGHT,'frames':records},indent=2),encoding='utf-8')
 print('SEIYA_SLIM_SWEEP_PACK_OK frames=6 one_scale=',SCALE)
if __name__=='__main__':main()
