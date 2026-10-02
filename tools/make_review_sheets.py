from pathlib import Path
from PIL import Image, ImageDraw

base = Path(__file__).resolve().parents[1] / 'evidence'
source = base / 'final'
out = base / 'contact'
out.mkdir(exist_ok=True)
for stage in range(1,9):
    files = sorted(p for p in source.glob(f'stage{stage:02d}_*.png') if 'intro' not in p.name)
    for page in range((len(files)+24)//25):
        sheet = Image.new('RGB',(1200,1050),(25,29,35))
        draw = ImageDraw.Draw(sheet)
        for i,p in enumerate(files[page*25:page*25+25]):
            im = Image.open(p).convert('RGB').crop((590,140,1080,560))
            im.thumbnail((240,180))
            x,y = i%5*240,i//5*210
            sheet.paste(im,(x,y+25))
            draw.text((x+3,y+5),p.stem,(255,255,255))
        sheet.save(out/f'stage{stage:02d}_page{page+1:02d}.jpg')
files=sorted(source.glob('gauge*.png'))
sheet=Image.new('RGB',(640,len(files)*130),(25,29,35))
draw=ImageDraw.Draw(sheet)
for i,p in enumerate(files):
    sheet.paste(Image.open(p).convert('RGB').crop((0,95,640,200)),(0,i*130+25))
    draw.text((5,i*130+5),p.stem,(255,255,255))
sheet.save(out/'gauge_states.jpg')
sheet=Image.new('RGB',(1920,820),(25,29,35))
draw=ImageDraw.Draw(sheet)
for row,stage in enumerate(range(5,9)):
    for col,motion in enumerate(['idle','walk','jump','attack','hit','ko']):
        p=base/'live'/f'stage{stage:02d}_{motion}.png'
        im=Image.open(p).convert('RGB').resize((320,180))
        sheet.paste(im,(col*320,row*205+25))
        draw.text((col*320+5,row*205+5),p.stem,(255,255,255))
sheet.save(out/'stage5_8_live.jpg')
sheet=Image.new('RGB',(1280,800),(25,29,35))
draw=ImageDraw.Draw(sheet)
for i in range(8):
    p=source/f'stage{i+1:02d}_intro.png'
    im=Image.open(p).convert('RGB').crop((0,500,1280,700)).resize((640,100))
    x,y=i%2*640,i//2*200
    sheet.paste(im,(x,y+25))
    draw.text((x+5,y+5),p.stem,(255,255,255))
sheet.save(out/'stage_intros.jpg')
