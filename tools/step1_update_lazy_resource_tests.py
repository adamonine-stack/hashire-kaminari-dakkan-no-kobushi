from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
tests = root / "godot" / "tests"
changed = []

replacements = {
    ".STAGE_DEFINITIONS.size()": ".STAGE_DEFINITION_PATHS.size()",
    ".ENEMY_DEFINITIONS.size()": ".ENEMY_MANIFESTS.size()",
}

for path in tests.rglob("*.gd"):
    text = path.read_text(encoding="utf-8")
    updated = text
    for old, new in replacements.items():
        updated = updated.replace(old, new)
    updated = re.sub(
        r"([A-Za-z_][A-Za-z0-9_]*)\.STAGE_DEFINITIONS\[(\d+)\]",
        r"\1._stage_definition_for_enemy_index(\2)",
        updated,
    )
    if updated != text:
        path.write_text(updated, encoding="utf-8")
        changed.append(str(path.relative_to(root)))

unsupported = []
for path in tests.rglob("*.gd"):
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if "STAGE_DEFINITIONS" in line or "ENEMY_DEFINITIONS" in line:
            unsupported.append(f"{path.relative_to(root)}:{line_no}:{line.strip()}")

print("changed:", changed)
if unsupported:
    print("unsupported legacy references:")
    print("\n".join(unsupported))
    raise SystemExit(1)
