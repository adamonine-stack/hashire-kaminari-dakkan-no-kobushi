"""Create review evidence and check Seiya sources against the release baseline."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
git = ["git", "-c", f"safe.directory={root.as_posix()}", "-C", str(root)]
baseline = "7687bfc1f599285ce86ff1320a71bfd122532832"
tracked = subprocess.check_output(git + ["ls-tree", "-r", "--name-only", baseline]).decode().splitlines()
protected = [p for p in tracked if p.startswith("godot/") and (
    "seiya" in p.lower() or p in (
        "godot/data/fighters/ally_speed.tres", "godot/scripts/battle/true_battle_manager.gd",
        "godot/scenes/TrueBattle.tscn", "godot/scripts/ui/stage8_ending.gd"))
    and not p.endswith((".import", ".uid"))]
results = []
for name in protected:
    expected = subprocess.check_output(git + ["show", f"{baseline}:{name}"])
    actual = (root / name).read_bytes()
    if Path(name).suffix in (".gd", ".tres", ".tscn", ".gdshader", ".json") or Path(name).name == ".gdignore":
        expected = expected.replace(b"\r\n", b"\n")
        actual = actual.replace(b"\r\n", b"\n")
    match = expected == actual
    results.append({"file": name, "unchanged": match, "sha256": hashlib.sha256(actual).hexdigest()})
assert all(r["unchanged"] for r in results), [r["file"] for r in results if not r["unchanged"]]
(root / "evidence/seiya-preservation.json").write_text(json.dumps(results, indent=2), encoding="utf-8")

old = root.parent / ".st_action_fix_20261001"
for name in ("sprite_failures_before_after.png",):
    shutil.copy2(old / "evidence/contact" / name, root / "evidence/contact" / name)
for name in ("stage05_damage_00.png", "stage05_ko_00.png", "stage05_getup_00.png", "stage06_idle_00.png", "stage06_walk_00.png", "stage06_ko_00.png"):
    (root / "evidence/before").mkdir(exist_ok=True)
    shutil.copy2(old / "evidence/before" / name, root / "evidence/before" / name)
sheet = Image.new("RGB", (1280, 820), (20, 24, 32))
draw = ImageDraw.Draw(sheet)
for row, stage in enumerate((5, 6)):
    for column, tag in enumerate(("baseline", "local")):
        photo = Image.open(root / f"evidence/web/{tag}_desktop/stage{stage}_idle.png").convert("RGB")
        photo.thumbnail((640, 360))
        sheet.paste(photo, (column*640, row*410+30))
        draw.text((column*640+10, row*410+8), f"STAGE {stage} {tag}", fill="white")
sheet.save(root / "evidence/contact/web_backgrounds_before_after.jpg", quality=92)

report = root / "docs/ST_ACTION_CHARACTER_FAILURE_DETAILS.md"
text = report.read_text(encoding="utf-8-sig")
text = text.replace("](evidence/", "](../evidence/")
text = text.replace("第9は未実装・ユーザー指示による対象外です。", "この記録の基点では第9は未実装でした。2026-10-02の統合版では最新mainのTRUE最終ボス版セイヤも描画・戦闘・サイズの回帰確認対象に含めています。")
text = text.replace("# キャラクター表示崩れの詳細レポート", "# キャラクター表示崩れの詳細レポート\n\n2026-10-02追記: 最新main `7687bfc1` に以下の修正を統合しました。第7・8は統合版Webでも起動・移動・ジャンプ・攻撃・必殺技を確認し、今回の第5・6のAtlas混入とは別に照合しています。")
report.write_text(text, encoding="utf-8", newline="\n")
print(f"SEIYA_PRESERVATION_OK files={len(results)} baseline={baseline}")
