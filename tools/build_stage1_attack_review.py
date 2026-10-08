"""Build native attack frame comparisons, preserving all source pixels."""
import json
from pathlib import Path
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / "audit_evidence/stage1_attack_frames"
rows = json.loads((FOLDER / "inventory.json").read_text(encoding="utf-8"))
for actor in ["akky", "crusher", "gou", "seiya"]:
    for facing, side in [(1,"right"),(-1,"left")]:
        selected = [r for r in rows if r["actor"]==actor and r["facing"]==facing]
        clips = list(dict.fromkeys(r["clip"] for r in selected if r["clip"] != "idle"))
        idle = next(r for r in selected if r["clip"] == "idle")
        summary = Image.new("RGB", (1600, ((len(clips)+3)//4)*340), (35,39,44))
        draw = ImageDraw.Draw(summary)
        for index, clip in enumerate(clips):
            frames = [r for r in selected if r["clip"]==clip]
            strip = Image.new("RGB", ((len(frames)+1)*400,340), (35,39,44))
            strip_draw = ImageDraw.Draw(strip)
            for x, row in enumerate([idle]+frames):
                img = Image.open(FOLDER / row["file"]).convert("RGBA")
                strip.paste(img, (x*400,0), img)
                label = "standing" if x==0 else "%s frame %d%s"%(clip,row["frame"]," CONTACT" if row["frame"]==row["contact_frame"] else "")
                strip_draw.text((x*400+8,320),label,fill="white")
            strip.save(FOLDER / (actor+"_"+side+"_"+clip+"_strip.png"))
            contact = frames[0]["contact_frame"]
            row = next((r for r in frames if r["frame"]==contact), frames[len(frames)//2])
            img = Image.open(FOLDER / row["file"]).convert("RGBA")
            x,y=index%4*400,index//4*340
            summary.paste(img,(x,y),img)
            draw.text((x+8,y+320),clip+" / "+("contact" if contact>=0 else "representative"),fill="white")
        summary.save(FOLDER / (actor+"_"+side+"_summary.png"))
print("ATTACK_REVIEW four actors both facings all frames no resizing")
