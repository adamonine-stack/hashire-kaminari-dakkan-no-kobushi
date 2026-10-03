from pathlib import Path
from PIL import Image,ImageDraw
import json, math
root=Path(__file__).resolve().parents[1]
folder=root/'evidence/teki_audit'
records=json.loads((folder/'frames.json').read_text())
def metrics(path):
 im=Image.open(path).convert('RGBA'); mask=im.getchannel('A').point(lambda a:255 if a>=128 else 0)
 box=mask.getbbox(); area=sum(a>=128 for a in im.getchannel('A').get_flattened_data())
 return im,box,area
idle,ib,ia=metrics(folder/'idle_00.png')
for r in records:
 im,b,a=metrics(folder/r['file']);r.update(bounds=b,area_ratio=round(a/ia,3),height_ratio=round((b[3]-b[1])/(ib[3]-ib[1]),3))
(folder/'metrics.json').write_text(json.dumps(records,indent=2))
selected=[r for r in records if r['clip'] in ['idle','damage','damage_high','damage_low','damage_heavy','knockback','knockdown','down','ko','stand_up','grabbed','thrown','received_akky_elbow_hit','received_akky_elbow_air','received_akky_elbow_down','received_gou_breaker_hit','received_gou_breaker_air','received_gou_breaker_down','received_seiya_two_lift','received_seiya_two_fly','received_seiya_two_down','special_startup','teki_deadly_hand','special_recovery']]
for start in range(0,len(selected),16):
 page=Image.new('RGB',(1280,1200),(32,38,45));d=ImageDraw.Draw(page)
 for i,r in enumerate(selected[start:start+16]):
  im,b,a=metrics(folder/r['file']); im.thumbnail((312,244))
  x=i%4*320;y=i//4*300;page.paste(im,(x+(320-im.width)//2,y+25),im)
  d.text((x+4,y+2),r['file'],fill='white');d.text((x+4,y+277),f"body={r['area_ratio']} height={r['height_ratio']}",fill='white')
 page.save(folder/f'audit_page_{start//16+1:02d}.jpg')
print('idle',ib,ia,'selected',len(selected))
for r in selected:print(r['file'],r['bounds'],r['area_ratio'],r['height_ratio'])
