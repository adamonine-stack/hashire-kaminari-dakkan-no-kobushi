"""Pack individually reviewed Cross damage originals; preserve formal size/floor."""
from pathlib import Path
import json,re
import build_teki_reversal as m
ROOT=m.ROOT; m.ART=ROOT/'art_sources/cross_stage4_v3'; A=ROOT/'evidence/cross_stage4_audit'
def build():
 files=[]; clips={}; ratios={"cross_down.png":0.90}
 def add(src,name):
  dest='cross_'+name+'.png';(m.ART/'frames'/dest).write_bytes((A/src).read_bytes()); files.append(dest);return len(files)-1
 hit=add('damage_00.png','hit');air=add('damage_heavy_01.png','air');files.append('cross_down.png');down=2
 rise=add('stand_up_01.png','rise');crouch=add('stand_up_02.png','crouch');idle=add('idle_00.png','idle');guard=add('guard_00.png','guard');files.append('cross_low_hit.png')
 for key in ['damage','damage_high','damage_light','grabbed']:clips[key]=([hit],10)
 clips['damage_low']=([7],10)
 for key in ['damage_heavy','knockback','air_hit','launch_hit']:clips[key]=([hit,air],10)
 clips['knockdown']=([hit,air,down],9);clips['down']=([down],5)
 for key in ['ko','defeat','thrown']:clips[key]=([air,down],8)
 for key in ['stand_up','getup','get_up']:clips[key]=([down,rise,crouch,idle],8)
 clips['guard_hit']=([guard],10)
 records=json.loads((A/'frames.json').read_text())
 for key in sorted({row['clip'] for row in records if row['clip'].startswith('received_')}):
  indices=[]
  for row in [v for v in records if v['clip']==key]:
   if key.endswith('_down') and key != 'received_akky_elbow_down':
    indices.append(down)
   else:
    indices.append(add(row['file'],row['file'][:-4]))
    if key.endswith('_down'):ratios[files[-1]]=0.85
  clips[key]=(indices,5 if key.endswith('_down') else 12)
 dest=m.pack('cross',files,clips,'assets/characters/enemy05/animations/cross_damage_v3',ratios)
 manifest=ROOT/'godot/assets/characters/enemy05/animations/cross_damage_v3/packing_manifest.json'
 data=json.loads(manifest.read_text(encoding='utf-8'));data['reference']='art_sources/cross_stage4_v3/references/cross.png';data['method']='Reviewed individual anatomy; bent-knee prone width <=1.30x idle height; fixed runtime scale and floor; prone overlap mass 0.90 (Akky supine 0.85).';manifest.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
 m.attach(ROOT/'godot/data/enemies/enemy_05_power.tres',dest,'cross_damage_v3')
 for name,fighter in [('akky','ally_balance'),('gou','ally_power'),('seiya','ally_speed')]:
  dest=m.pack(name,[f'{name}_guard_{n}.png' for n in range(2)],{'received_cross_muei_guard':([0,1],2/.28)},f'assets/characters/cross_special_guard_v1/{fighter}')
  m.attach(ROOT/f'godot/data/fighters/{fighter}.tres',dest,'cross_special_guard')
 print('CROSS_STAGE4_V3_PACK_OK')
if __name__=='__main__':build()
