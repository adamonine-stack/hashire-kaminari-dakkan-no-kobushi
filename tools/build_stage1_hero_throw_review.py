"""Build native review panels by cropping rendered cells; never alter sprite anatomy."""
from pathlib import Path
from PIL import Image
import json
ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/'audit_evidence/stage1_heroes_throw_review'
data=json.loads((folder/'inventory.json').read_text(encoding='utf-8'))
for hero in ['gou','seiya']:
 sheet=Image.open(folder/f'{hero}_right.png');rows=[r for r in data if r['hero']==hero and r['facing']==1]
 for kind,clips in [('contact',['idle' if hero=='gou' else 'idle_prebattle','throw_hold',hero+'_throw_forward_release','directional_throw_held','throw_victim_forward_air','throw_victim_back_air']),('down',['idle' if hero=='gou' else 'idle_prebattle','down','stand_up','stand_up','stand_up','ko'])]:
  result=Image.new('RGBA',(1200,640));seen={}
  for j,clip in enumerate(clips):
   matches=[i for i,r in enumerate(rows) if r['clip']==clip];frame=seen.get(clip,0);seen[clip]=frame+1;i=matches[min(frame,len(matches)-1)]
   result.paste(sheet.crop((i%5*400,i//5*320,i%5*400+400,i//5*320+320)),(j%3*400,j//3*320))
  result.save(folder/f'{hero}_{kind}_review.png')
