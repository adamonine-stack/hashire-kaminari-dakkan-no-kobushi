"""Build contact sheets and a sampled-physics preview from actual game captures."""
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
NAMES=['enemy_01_standard','enemy_02_speed','enemy_03_guard','enemy_04_throw','enemy_05_power',
       'enemy_06_combo','enemy_07_tricky','enemy_08_boss','enemy_09_seiya']
for folder,phases in [('akky_wall_launch_final',['air','wall','fall','down']),
                     ('gou_low_arched_270_final',['impact','air','prone_descent','down'])]:
    out=ROOT/'evidence'/folder
    if not all((out/f"{name}_R_{phase}.png").exists() for name in NAMES for phase in phases): continue
    sheet=Image.new('RGB',(1280,len(NAMES)*202),(25,25,30))
    draw=ImageDraw.Draw(sheet)
    for row,name in enumerate(NAMES):
        for col,phase in enumerate(phases):
            im=Image.open(out/f'{name}_R_{phase}.png').convert('RGB').resize((320,180))
            sheet.paste(im,(col*320,row*202+22))
            draw.text((col*320+5,row*202+5),name+' / '+phase,fill='white')
    sheet.save(out/'contact.jpg',quality=94)
    frames=[Image.open(p).convert('RGB').resize((768,432)) for p in sorted(out.glob('preview_*.png'))]
    # Each capture is four 60Hz physics frames apart; this is a controlled
    # animation review, not a recording of a user's manual play session.
    frames[0].save(out/'preview.gif',save_all=True,append_images=frames[1:],duration=67,loop=0)
    print(f'SPECIAL_REACTION_REVIEW_OK {folder} frames={len(frames)}')
