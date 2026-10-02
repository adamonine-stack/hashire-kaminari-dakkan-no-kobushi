"""Stage the reviewed ST_action change only; retain all generated QA files."""
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
git = ["git", "-c", f"safe.directory={root.as_posix()}", "-C", str(root)]
names = subprocess.check_output(git + ["diff", "--name-only"]).decode().splitlines()
for name in names:
    if name.endswith(".import") or name.startswith("evidence/seiya/"):
        current = root / name
        # These files were clean in this fresh integration worktree. Keep the
        # new test screenshots separately and retain baseline evidence in Git.
        if name.startswith("evidence/seiya/"):
            saved = root / "evidence/st_action_seiya" / current.name
            saved.parent.mkdir(exist_ok=True)
            saved.write_bytes(current.read_bytes())
        original = subprocess.check_output(git + ["show", f"HEAD:{name}"])
        if name.endswith(".import"):
            original = original.replace(b"\r\n", b"\n").replace(b"\n", b"\r\n")
        current.write_bytes(original)

paths = [
    ".github/workflows/deploy-godot-web.yml",
    "godot/scripts/data/fighter_motion_atlas.gd",
    "godot/scripts/characters/character_visual_controller.gd",
    "godot/assets/characters/enemy05/animations/shadow_boxer_v1/motion_atlas.tres",
    "godot/assets/characters/enemy06/animations/rio_garcia_v1/motion_atlas.tres",
    "godot/data/enemies/enemy_02_speed.tres", "godot/data/enemies/enemy_06_combo.tres",
    "godot/ui/battle/battle_hud.gd", "godot/scripts/battle/battle_manager.gd",
    "godot/scripts/battle/stage1_backdrop.gd", "godot/scripts/ui/opening.gd", "godot/icon.png",
    "godot/tests/stage5_6_motion_atlas.gd", "godot/tests/stage5_shadow_boxer_regression.gd",
    "godot/tests/opening_flow_smoke.gd",
    "docs/ST_ACTION_CHARACTER_FAILURE_DETAILS.md", "docs/ST_ACTION_FIX_AND_SEIYA_REGRESSION.md",
    "tools/audit_atlas_regions.py", "tools/make_review_sheets.py", "tools/run_fix_regressions.ps1",
    "tools/st_action_web_check.cjs", "tools/prepare_st_action_review.py",
    "tools/stage_st_action_release.py", "evidence/seiya-preservation.json",
]
for asset in ("stage_05_island_pier_v2.png", "stage_06_secret_base_gate_v2.png"):
    paths += [f"godot/assets/backgrounds/{asset}", f"godot/assets/backgrounds/{asset}.import"]
for test in ("st_action_fix_regression", "st_action_screen_review", "st_action_live_flow_review"):
    paths += [f"godot/tests/{test}.gd", f"godot/tests/{test}.gd.uid"]
paths += [p.relative_to(root).as_posix() for p in (root / "evidence/before").glob("*.png")]
paths += [f"evidence/contact/{name}" for name in (
    "sprite_failures_before_after.png", "web_backgrounds_before_after.jpg", "gauge_states.jpg",
    "stage5_8_live.jpg", "stage_intros.jpg", "stage05_page01.jpg", "stage05_page02.jpg",
    "stage06_page01.jpg", "stage06_page02.jpg", "stage06_page03.jpg")]
subprocess.run(git + ["add", "--"] + paths, check=True)
subprocess.run(git + ["diff", "--cached", "--check"], check=True)
subprocess.run(git + ["diff", "--cached", "--stat"], check=True)
