"""Package Godot-rendered frames for visual review; no art is drawn here."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,html
root=Path(__file__).resolve().parents[1]
folder=root/'audit_evidence/basic_moves_20261010/rendered'
records=json.loads((folder/'manifest.json').read_text(encoding='utf-8'))
font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',18)
names=['アッキー','豪','セイヤ','クラッシャー','シャドウボクサー','高橋雅人','影山レイ','クロス村雨','リオ・ガルシア','テキ','レオン・クロウ','闇セイヤ']
traits=['小さく構えて鋭く踏み込む総合格闘','低い重心と大きな腕振りの剛力','細身の体を伸ばす軽快な速攻','巨体で押し込む重量級の打撃','高いガードから伸びるボクシング','腰を落として崩す柔道家の足技','胸を開いて打ち上げる荒々しい空手','開いた手で間合いを制する打撃','弾むような体重移動の蹴り','長い手足と深い腰構え','しなやかな上体と長く伸びる蹴り','セイヤの身体技を鋭く、闇の演出を維持']
keys=['P','→ P','↓ P','← P','↑ P','K','→ K','↓ K','← K','↑ K']
sections=[]
actors=list(dict.fromkeys(r['actor'] for r in records))
for ai,actor in enumerate(actors):
    group=[r for r in records if r['actor']==actor]
    montage=Image.new('RGB',(1250,480),(18,21,28)); d=ImageDraw.Draw(montage)
    cards=[]
    for ki,r in enumerate(group):
        frames=[Image.open(folder/f).convert('RGB') for f in r['frames']]
        c=r['contact']; n=len(frames)
        durations=[max(20,round(r['startup']*1000/max(c,1))) if f<c else (round(r['active']*1000) if f==c else max(20,round(r['recovery']*1000/max(n-c-1,1)))) for f in range(n)]
        durations[-1]+=450
        gif=actor+'__'+r['key']+'.gif'
        small=[f.resize((300,252)) for f in frames]
        palette=small[0].quantize(colors=256)
        gif_frames=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in small]
        gif_frames[0].save(folder/gif,save_all=True,append_images=gif_frames[1:],duration=durations,loop=0,optimize=True)
        image=frames[c].resize((250,210))
        x=(ki%5)*250; y=(ki//5)*240
        montage.paste(image,(x,y+30));d.text((x+8,y+4),keys[ki]+' '+r['title'],font=font,fill='white')
        cards.append('<article><b>'+html.escape(keys[ki]+' '+r['title'])+'</b><img loading="lazy" src="'+gif+'"><small>発生 '+str(round(r['startup']*1000))+' ms / 硬直 '+str(round(r['recovery']*1000))+' ms</small></article>')
    montage.save(folder/(actor+'__contacts.jpg'))
    sections.append('<section><h2>'+names[ai]+'</h2><p>'+traits[ai]+'</p><div class="grid">'+''.join(cards)+'</div></section>')
(folder/'index.html').write_text('<!doctype html><html lang="ja"><meta charset="utf-8"><title>各キャラクターの基本技モーション</title><style>body{background:#12151c;color:#eee;font:16px sans-serif;margin:24px}section{margin:40px 0}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:12px}article{background:#252b36;padding:10px;border-radius:8px}img{width:100%;display:block}small{color:#bbc6d5}</style><h1>基本技 12キャラクター × 10操作</h1><p>Godot実描画による姿勢・モーション確認用。矢印はキャラクターの向きに対する前後です。ジャンプの移動軌道は別途、実際の物理・当たり判定テストで確認しています。</p>'+''.join(sections),encoding='utf-8')
print('GALLERY_OK',len(records),'clips')
