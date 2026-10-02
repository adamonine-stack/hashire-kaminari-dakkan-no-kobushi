"""Pack individually authored poses at one density; never fit a pose to its box."""
from pathlib import Path
from PIL import Image
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "godot/assets/characters/player01/animations/reversal_v1"
SOURCES = ["startup_key", "transition", "active_key", "finish_key",
           "special_hit", "special_knockback", "special_knockdown",
           "special_guard_impact", "special_guard_hold"]
SCALE = 0.13
CELL = (320, 224)
BASELINE = 208
atlas = Image.new("RGBA", (CELL[0] * 4, CELL[1] * 3))
manifest = []
for index, name in enumerate(SOURCES):
    path = ASSET / "sources" / (name + ".png")
    src = Image.open(path).convert("RGBA")
    # Use solid art to measure the foot anchor; transparent RGB is preserved.
    support = src.getchannel("A").point(lambda alpha: 255 if alpha >= 128 else 0)
    bounds = support.getbbox()
    if bounds is None:
        raise ValueError(f"Empty source: {name}")
    width, height = round(src.width * SCALE), round(src.height * SCALE)
    offset_x = (CELL[0] - width) // 2
    offset_y = BASELINE - round(bounds[3] * SCALE)
    mapped = (offset_x + round(bounds[0] * SCALE), offset_y + round(bounds[1] * SCALE),
              offset_x + round(bounds[2] * SCALE), BASELINE)
    if min(mapped[:2]) < 0 or mapped[2] > CELL[0] or mapped[3] > CELL[1]:
        raise ValueError(f"Character art would be clipped: {name} {mapped}")
    cell = Image.new("RGBA", CELL)
    cell.alpha_composite(src.resize((width, height), Image.Resampling.NEAREST), (offset_x, offset_y))
    cell.save(ASSET / (name + "_cell.png"))
    atlas.alpha_composite(cell, ((index % 4) * CELL[0], (index // 4) * CELL[1]))
    manifest.append({"index": index, "source": name, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                     "source_size": list(src.size), "source_opaque_bounds": list(bounds),
                     "fixed_scale": SCALE, "offset": [offset_x, offset_y], "cell_opaque_bounds": list(mapped)})
atlas.save(ASSET / "motion_atlas.png")
clips = {
    "akky_reversal_startup": ([0, 1], 2 / .14),
    "akky_reversal_elbow": ([2], 1 / .18),
    "akky_reversal_finish": ([3], 1 / .40),
    "special_hit": ([4, 5], 8),
    "special_knockback": ([4, 5], 10),
    "special_knockdown": ([6], 5),
    "special_guard": ([7, 8], 2 / .28),
}
lines = []
for name, (frames, fps) in clips.items():
    lines.append(f'"{name}": {{"frames": {frames}, "fps": {fps:.8f}, "loop": false}}')
(ASSET / "motion_atlas.tres").write_text(
    '[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n'
    '[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n'
    '[ext_resource type="Texture2D" path="res://assets/characters/player01/animations/reversal_v1/motion_atlas.png" id="2"]\n'
    '[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\n'
    'cell_size = Vector2i(320, 224)\ncolumns = 4\nclips = {\n' + ',\n'.join(lines) + '\n}\n',
    encoding="utf-8")
(ASSET / "packing_manifest.json").write_text(json.dumps({"cell": CELL, "scale": SCALE,
    "baseline": BASELINE, "frames": manifest}, indent=2) + "\n", encoding="utf-8")
print(f"AKKY_REVERSAL_PACK_OK poses={len(manifest)} scale={SCALE} baseline={BASELINE}")
