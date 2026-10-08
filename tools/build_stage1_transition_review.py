"""Arrange native captures without changing character pixels or proportions."""
import json
from pathlib import Path
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / "audit_evidence/stage1_received_transitions"
rows = json.loads((FOLDER / "inventory.json").read_text(encoding="utf-8"))
legacy = json.loads((ROOT / "audit_evidence/stage1_full_motion_inventory/inventory.json").read_text(encoding="utf-8"))
actors = ["akky", "crusher", "gou", "seiya"]
states = ["KNOCKBACK", "KNOCKDOWN", "GET_UP", "RECOVERED"]
for facing, side in [(1, "right"), (-1, "left")]:
    sheet = Image.new("RGB", (2000, 1360), (35, 39, 44))
    draw = ImageDraw.Draw(sheet)
    for y, actor in enumerate(actors):
        idle = next(r for r in legacy if r["actor"] == actor and r["clip"] == "idle")
        standing = Image.open(ROOT / "audit_evidence/stage1_full_motion_inventory" / idle["file"]).convert("RGBA")
        if facing < 0:
            standing = standing.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        sheet.paste(standing, (0, y * 340), standing)
        draw.text((8, y * 340 + 320), actor + " / standing reference", fill="white")
        for x, state in enumerate(states, 1):
            row = next(r for r in rows if r["actor"] == actor and r["facing"] == facing and r["state"] == state)
            cx, cy = row["ground_anchor"]
            frame = Image.open(FOLDER / row["file"]).convert("RGB")
            # Same 400x320 pixels and ground baseline as the standing viewport.
            crop = frame.crop((round(cx)-200, round(cy)-300, round(cx)+200, round(cy)+20))
            sheet.paste(crop, (x * 400, y * 340))
            draw.text((x * 400 + 8, y * 340 + 320), actor + " / " + state + " / " + row["clip"], fill="white")
    sheet.save(FOLDER / ("comparison_" + side + ".png"))
print("TRANSITION_REVIEW rows=4 columns=5 facings=2 no pixel resizing")
