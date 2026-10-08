# Crusher air attack restoration, 2026-10-08

Branch unchanged: `codex/stage1-gou-seiya-20261007`.
Start HEAD: `690f8c1491a284cb252593dde24d1d1753845a58`.

## Delivered

- Replaced damaged embedded legacy air attack artwork with `unified_air_attack_v11` via the existing supplemental atlas slot, avoiding an additional loaded atlas override.
- Air punch contact uses the short anatomical arm with straight elbow key. Anticipation/retraction/recovery keep official head, bandana, muscular body, skin and clothing texture. Air kick retains compact leg proportions. Rejected half-kick source frame is omitted from the runtime atlas; return uses the folded-knee preparation pose.
- Three clip aliases: `jump_punch`, `jump_punch_down`, `jump_kick`, four frames each, 10 FPS, non-looping. Static body anchor remains separate from airborne physics.
- All source figures use a single uniform calibration scale per original sheet, based on its standing figure compared with the official 228-pixel-height reference. No individual limb/body stretching or frame-height normalization.
- Added Crusher-specific Air P/K resources. Preserved legacy startup/active/recovery, damage multipliers (.95 punch, 1.10 kick), knockback, hitstop, hitstun and guard timing. Active frame explicitly 1, so the collision clock holds the contact pose rather than the old frame-2 retraction pose.
- Punch collider 52x42 at (85,-174); kick 70x45 at (90,-95), mirrored and scaled by existing fighter rules. The old downward punch fallback offset (46,+32) did not match the new fist. Shared engine code unchanged.

## Checks

Native Godot: 16 snapshots (2 actions x 2 facing directions x 4 frames), sprite scale/origin stable; actual physics attack -> landing clears air state; correct source atlas; active interval holds contact frame; actual Area2D hits on both sides at the attack height. Optional `--boxes` draws developer-only hitbox overlay. All passed.

Headless: same live test, Crusher situation AI, Stage1 regression, air guard, Crusher down correction passed. Directional attack regression initially exposed an outdated fixture: an enemy 160 pixels above the ground fighter was expected to reach it with an invisible downward hitbox. The revised test uses an 85-pixel jump height to verify ordinary P loses / Back P intercepts; an additional 160-pixel-height case requires the jump kick to miss the ground body. Both actual Area2D cases pass without a move-ID priority override.

Intermediate test attempted a nonexistent debug property, corrected to `AttackPhase.ACTIVE` and rerun. Failed intermediate runs are not reported as passing. Some headless ObjectDB cleanup warnings remain.

## Remaining Stage1 scope

This phase restores Crusher air attacks, not total Stage1 completion. AKKY legacy source-contract test reconciliation and Seiya basic jump alias design review remain. No hands-on smartphone or complete manual stage run performed; no publication in this phase. No new InputMap actions, UI buttons, Special damage/cancel rules or save-format changes. Existing uncommitted imports/shader/fighter-definition changes preserved.

Files: enemy definition; two attack resources; atlas PNG/resource/packing manifest; live test; directional attack regression fixture; technical packer; source key/intermediates/same-scale comparison; this report and native contact evidence.
