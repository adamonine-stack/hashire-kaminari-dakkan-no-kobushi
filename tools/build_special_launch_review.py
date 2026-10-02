from pathlib import Path
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'evidence/special_launch'
names=['enemy_01_standard','enemy_02_speed','enemy_03_guard','enemy_04_throw','enemy_05_power','enemy_06_combo','enemy_07_tricky','enemy_08_boss','enemy_09_seiya']
contact=Image.new('RGB',(1200,9*247),(20,20,25))
draw=ImageDraw.Draw(contact)
for row,name in enumerate(names):
    for column,phase in enumerate(['startup','air','down']):
        screenshot=Image.open(OUT/f'{name}_R_{phase}.png').convert('RGB')
        contact.paste(screenshot.resize((400,225)),(column*400,row*247+22))
        draw.text((column*400+6,row*247+5),name+' / '+phase,fill='white')
contact.save(OUT/'contact.jpg',quality=92)
frames=[]
for path in sorted(OUT.glob('preview_*.png')):
    frames.append(Image.open(path).convert('RGB').resize((768,432)))
frames[0].save(OUT/'akky_crusher_preview.gif',save_all=True,append_images=frames[1:],duration=100,loop=0)
print(f'SPECIAL_LAUNCH_REVIEW_OK rows=9 preview_frames={len(frames)}')
