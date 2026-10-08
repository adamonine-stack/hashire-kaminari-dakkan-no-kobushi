"""Technical RGBA isolation and uniform atlas packing; no anatomy edits."""
from pathlib import Path
from PIL import Image
import json
from pack_crusher_air_attack import isolate
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'art_sources/crusher_launcher_v14'
DEST=ROOT/'godot/assets/characters/enemy01/animations/unified_launcher_v14'
def place(pose,scale,reference_height):
    image=pose.resize((round(pose.width*scale),round(pose.height*scale)),Image.Resampling.NEAREST)
    assert image.width<396 and image.height<258,image.size
    cell=Image.new('RGBA',(400,280))
    offset=((400-image.width)//2,260-image.height)
    cell.alpha_composite(image,offset)
    return cell,{'scale':scale,'size':list(image.size),'offset':list(offset)}
def main(art=None,dest=None,move_id="crusher_down_punch"):
    ART=art or ROOT/"art_sources/crusher_launcher_v14"
    DEST=dest or ROOT/"godot/assets/characters/enemy01/animations/unified_launcher_v14"
    reference=Image.open(ROOT/'art_sources/crusher_throw_design_v2/formal_standing.png').convert('RGBA')
    bounds=reference.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
    height=bounds[3]-bounds[1]
    keys=isolate(ART/'key_poses.png',2)
    key_scale=height/keys[0].height
    review=Image.new('RGBA',(1200,280),(48,52,60,255))
    review.alpha_composite(reference,(0,0))
    for i,pose in enumerate(keys): review.alpha_composite(place(pose,key_scale,height)[0],((i+1)*400,0))
    review.save(ART/'key_pose_review.png')
    if not (ART/'intermediates.png').exists():
        print('CRUSHER_LAUNCHER_KEY_REVIEW',height,key_scale)
        return
    intermediate=isolate(ART/'intermediates.png',4)
    inter_scale=height/intermediate[0].height
    poses=[(intermediate[0],inter_scale,'calibration'),(intermediate[1],inter_scale,'load'),(intermediate[2],inter_scale,'chamber'),(keys[1],key_scale,'contact'),(intermediate[3],inter_scale,'retract')]
    atlas=Image.new('RGBA',(1600,560));records=[]
    full=Image.new('RGBA',(2400,280),(48,52,60,255));full.alpha_composite(reference,(0,0))
    for i,(pose,scale,role) in enumerate(poses):
        cell,record=place(pose,scale,height)
        atlas.alpha_composite(cell,(i%4*400,i//4*280))
        full.alpha_composite(cell,((i+1)*400,0))
        records.append({'index':i,'role':role,**record})
    DEST.mkdir(parents=True,exist_ok=True)
    atlas.save(DEST/'motion_atlas.png');full.save(ART/'same_scale_review.png')
    clips={move_id:{'frames':[1,2,3,4,0],'fps':12.0,'loop':False}}
    text='[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n[ext_resource type="Texture2D" path="res://assets/characters/enemy01/animations/unified_launcher_v14/motion_atlas.png" id="2"]\n[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i(400,280)\ncolumns = 4\nclips = '+json.dumps(clips)+'\n'
    texture_path='res://'+DEST.relative_to(ROOT/'godot').as_posix()+'/motion_atlas.png'
    text=text.replace('res://assets/characters/enemy01/animations/unified_launcher_v14/motion_atlas.png',texture_path)
    (DEST/'motion_atlas.tres').write_text(text,encoding='utf-8')
    (DEST/'packing_manifest.json').write_text(json.dumps({'reference_height':height,'key_scale':key_scale,'intermediate_scale':inter_scale,'frames':records},indent=2),encoding='utf-8')
    print('CRUSHER_LAUNCHER_PACK_OK',height,key_scale,inter_scale)
if __name__=='__main__':main()
