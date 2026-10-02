from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'godot/assets/effects/special_v1'
OUT.mkdir(parents=True,exist_ok=True)
for name in ['aura','impact']:
    source=ROOT/'art_sources/special_vfx'/f'{name}.png'
    Image.open(source).convert('RGBA').resize((512,512),Image.Resampling.LANCZOS).save(OUT/f'{name}.png')
print('SPECIAL_VFX_PACK_OK textures=2 size=512')
