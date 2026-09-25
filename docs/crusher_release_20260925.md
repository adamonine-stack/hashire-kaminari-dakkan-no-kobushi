# Crusher authored motion release — 2026-09-25

Integrates the received 25-pose Crusher atlas into Enemy01 on main 084c83a.
The handoff recorded source HEAD e161dd3 and branch agent/crusher-motion-20260925;
that private source commit was not available remotely. Its five tracked-file
changes applied cleanly to current main; shared visual/data code matched main.
Original handoff and other working copies remain untouched.

## Changes

- Fixed 400x280 cells, 42 animation names, 25 unique source poses.
- Measured 228px Idle body; runtime height about 249px versus Akky 220px.
- Enemy fallback punch/kick startup, contact and recovery follow combat phases.
- Broader Crusher hurt region follows the measured body width.
- Corrected crouch_guard to hold its crouched pose instead of alternating with
  the standing guard pose.
- Source PNGs are reproducible inputs; sources/.gdignore excludes them from the
  game resource import/export. Rebuild/check tools require Node.js and sharp.

## Verification

Windows Godot 4.7, Intel Vulkan renderer:
- 25-cell alpha bounds/baseline check: passed, bottom 259–260px.
- Crusher resource: 42 clips; AKKY: 68 clips / 247 references, failures=0.
- DEV052_OK, DEV053_STAGE1_OK.
- Normal-speed Stage1 regression: failures=[] (collision, clear, restart,
  three-player defeat and game-over path).
- Rendered automated playthrough: cleared=true, enemy_attacks=3,
  player_was_hit=true, final clear image inspected.
- All atlas clips rendered into screenshots; unique pose sequences inspected.
- Real punch/kick Area2D outlines inspected over both facing directions.
- Windows UI: title, team selection, Stage1 entry and live enemy combat observed.
- Web release export: passed.

The accelerated regression run is not acceptance evidence: changing time scale
invalidated fixed-physics-frame timing assertions. The normal-speed rerun passed.
The visual review script reported two ObjectDB instances at exit; the rendered
playthrough cleaned up without that warning.

Browser operation verification was interrupted by the Computer Use URL policy
check. Manual victory and public-browser gameplay are not claimed. Rendered
automated victory is separate evidence. Headbutt, elbow, ground slam and special
moves are not independent gameplay attacks in this release; existing aliases
continue using the shared poses.
