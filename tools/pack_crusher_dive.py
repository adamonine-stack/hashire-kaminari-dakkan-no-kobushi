from pathlib import Path
from PIL import Image
import json
from pack_crusher_air_attack import isolate
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'art_sources/crusher_dive_v15'
DEST=ROOT/'godot/assets/characters/enemy01/animations/unified_dive_v15'
def main():
 poses=isolate(ART/'key_poses.png',3)
 scale=228/poses[0].height
 ref=Image.open(ROOT/'art_sources/crusher_throw_design_v2/formal_standing.png').convert('RGBA')
 old=Image.open(ROOT/'godot/assets/characters/enemy01/animations/unified_air_attack_v11/motion_atlas.png')
 cells=[]
 for i,p in enumerate(poses):
  p=p.resize((round(p.width*scale),round(p.height*scale)),Image.Resampling.NEAREST)
  y=32 if i==1 else 260-p.height
  assert p.width<396 and y>=2 and y+p.height<278,(i,p.size,y)
  c=Image.new('RGBA',(400,280));c.alpha_composite(p,((400-p.width)//2,y));cells.append(c)
 atlas=Image.new('RGBA',(1600,280))
 packed=[cells[0],old.crop((400,280,800,560)),cells[1],cells[2]]
 for i,c in enumerate(packed):atlas.alpha_composite(c,(i*400,0))
 review=Image.new('RGBA',(2000,280),(48,52,60,255));review.alpha_composite(ref,(0,0));review.alpha_composite(atlas,(400,0));review.save(ART/'same_scale_review.png')
 DEST.mkdir(parents=True,exist_ok=True);atlas.save(DEST/'motion_atlas.png')
 clips={'crusher_dive_kick':{'frames':[1,2,1],'fps':10.0,'loop':False},'crusher_dive_land':{'frames':[3,0],'fps':8.0,'loop':False}}
 s='[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n[ext_resource type="Texture2D" path="res://assets/characters/enemy01/animations/unified_dive_v15/motion_atlas.png" id="2"]\n[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i(400,280)\ncolumns = 4\nclips = '+json.dumps(clips)+'\n'
 (DEST/'motion_atlas.tres').write_text(s,encoding='utf8')
 (DEST/'packing_manifest.json').write_text(json.dumps({'source_scale':scale,'reference_height':228,'ground_baseline':260,'air_top':32,'startup_source':'unified_air_attack_v11 cell5'},indent=2))
 print('CRUSHER_DIVE_PACK_OK',scale)
if __name__=='__main__':main()
