# Stage1 integrated design audit — 2026-10-08

Worktree: `.heroes_stage1_20261007`; branch `codex/stage1-gou-seiya-20261007`.
Start HEAD: `dcc483581f9d96630a061a2dbc2531a366a991df`.
Pre-existing imports, shader/fighter-definition changes and untracked evidence preserved.

## Confirmed findings and fix

- Native Godot rendered inventory: AKKY, Crusher, Gou, Seiya, 540 registered clips. Atlas frame regions checked for all frames; per-clip sprite display scale checked against that actor's standing baseline. No bounds/scale failures. This does NOT establish anatomical or artistic consistency.
- Representative same-display-scale comparison exposed broken Crusher jump punch/kick source art, and old Seiya jump aliases with larger-looking heads. Seiya directional Air P/K already use new dedicated slim atlases; basic jump aliases still require review.
- Crusher `knockdown`/`stand_up` used unified v8 art, while `down`/`ko`/`getup` still used legacy v1 art. Routed those remaining states to v8, sharing the exact prone frame between down and wake-up. Verified mirrored physical recovery, fixed scale/origin, floor anchor, hurtbox restoration. Prone opaque span is 268 pixels, accepted tolerance 265–271; no limb stretching.
- Raw touch test's initial failures were caused by unreleased native finger events in the fixture. Track/release touches before resetting each scenario. No product touch-input change made.

## Verified automated evidence

Passed: raw ScreenTouch direction/action tests for AKKY, Gou, Seiya (both facing directions, held/released direction, delayed action, expired buffer, jump/kick, logical cleanup); Stage1 regression; directional attacks; directional throws; special reversal; throw motion sync; Crusher situation AI and throw AI; air guard; remaining Stage1 heroes; Gou atlas (150 clips/401 frames); Seiya atlas (155 clips/419 frames); updated Crusher down correction and live down recovery.

Headless checks and native offscreen rendering are distinct from hands-on gameplay. No actual smartphone/device run, no complete manual Stage1 clear and no public deployment verification in this phase. Existing ObjectDB cleanup warnings remain.

## Unresolved / next acceptance gates

- Crusher air attack restoration: first key had overlong arm, second shortened it by bending elbow and was rejected by user. Final contact must fully extend the elbow while retaining compact anatomical arm length. Rejected candidates are not connected to the game.
- Intermediate-frame candidate has inappropriate background and cannot be accepted as-is. Review corrected contact before rebuilding frames.
- AKKY legacy atlas test reported obsolete authored texture expectations and did not complete; it is NOT a passing check. Full current-source inventory bounds/scale checks passed separately.
- Visual audit has rendered one representative frame per clip; not all frames have had semantic/artistic manual review. Full-frame head/limb/skin/face comparison remains required before declaring total design consistency.
- Some early audit invocations used nonexistent `*_motion_atlas_check.gd` names. Correct `gou_motion_atlas.gd` and `seiya_motion_atlas.gd` were subsequently run and passed; failed attempts are not counted as results.

## Scope

No new combat input actions, attack statistics, combo/cancel rules, Special damage or save format changes. 1-on-1 combat retained. New tests: generalized mobile raw touch and four-fighter full motion inventory. Runtime change only Crusher down/KO/wakeup art routing. Publication remains pending design fixes and complete gameplay acceptance.
