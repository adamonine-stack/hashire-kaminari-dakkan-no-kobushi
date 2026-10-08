# Stage1 Seiya jump / AKKY atlas audit — 2026-10-08

Branch unchanged: `codex/stage1-gou-seiya-20261007`. Start HEAD `5217e0f2ad433792216dd4c0b6cf2a3323016a5e`. Existing shader/fighter-definition/import changes preserved.

## Changes

Seiya's base jump poses still used the old larger-headed artwork despite dedicated directional air attacks already having slim art. New `slim_jump_v16` covers anticipation, ascent, descent, landing, recovery and generic jump aliases. Six source key poses were compared with the approved slim standing reference; the first draft was corrected for head and shoulder proportions before packing. All poses share one uniform scale based on standing calibration to the existing 195px art height; no frame or limb stretching. Head override 1.0; grounded foot baseline 270; airborne body offset separate from physics. Reference comparison is also calibrated to 195px, to avoid falsely comparing differently scaled originals.

Generic `jump_punch`, `jump_punch_down`, `jump_attack`, `jump_kick` aliases now refer to the existing approved slim Air P/K art. No directional attack data/damage/cancel changes.

The runtime selected `jump_start` throughout Seiya's normal flight. New phase clips opt in through `jump_ascent` availability: the takeoff duration is read from SpriteFrames, physics decrements its timer, vertical speed selects descent near the apex, and landing uses the existing landing flow. Other fighters without the opt-in clip retain their existing flow. Jump speed/gravity/air control/collision/attack rules unchanged. New visual timer defaults to zero and resets with mobility/defensive preparation.

AKKY's old atlas test ignored lazy path-based supplemental atlases and assumed one canvas size for almost all clips. It now checks the actual configured merge order, source texture, declared cell dimensions, region bounds, nonblank interior, fixed scale/origin; cached pixel bounds avoid repeated alias image reads. Existing KO hold/loop, landing, eight-frame walk and 105% display-scale assertions retained. No AKKY runtime/art changes.

## Evidence

- AKKY atlas: 142 clips / 376 frames, zero failures.
- Gou atlas: 150 clips / 401 frames, zero failures.
- Seiya atlas: 156 clips / 423 frames, zero failures.
- Native four-fighter inventory: 541 representative clip renders; all frame atlas bounds and per-clip display scales pass. This is not semantic manual approval of every frame.
- Real Seiya physics jump, both facings: start/ascent/fall/land observed, current sources selected, fixed scale/anchor, mirror correct, return grounded. Headless and native pass; eight live phase snapshots inspected.
- Actual raw ScreenTouch tests for all three heroes: direction held/released/delayed action/expired history/jump-kick/cleanup pass both facings. Simulated input is not a physical-phone test.
- Stage1 regression, Crusher Air P/K live collision/landing, directional attacks (ordinary P / anti-air at contact height plus high-jump miss), air guard pass.

Initial phase selection based on `AnimatedSprite2D.is_playing()` skipped takeoff in automated execution; replaced by the animation-derived physics timer and rerun. Failed drafts/checks are not counted as passed. Some existing headless ObjectDB cleanup warnings remain.

## Remaining

No full hands-on Stage1 playthrough or physical-smartphone confirmation, and no publication in this phase. Four-fighter design review still needs gameplay/transition acceptance beyond automatic invariant-scale checks. No new InputMap/UI actions, throw/Special behavior, Special damage, save format or stage progression changes.

Relevant files: Seiya fighter definition, jump atlas PNG/resource/manifest, slim Air P/K alias resources, player visual phase handling, AKKY/Seiya atlas tests, jump live test, technical packer, authored source/comparison, four-fighter inventory and native evidence.
