# Crusher forward throw receiver design pass

Branch codex/stage1-gou-seiya-20261007, start HEAD bdd52e7a257e599f0660001a006f3189a6fe4d93.

Scope: only throw_victim_forward_air, existing 3 frames at 10 fps. Supplemental atlas appended last; previous normal/slam receiver and attacker corrections preserved. No damage, timing, trajectory, throw positions, hitbox, save or input changes. Back throw receiver and ordinary down remain pending.

Built-in imagegen used official standing and old forward-flight pose intentions. Prompt: four separate poses (standing calibration, release recoil, fast tilted flight, near-horizontal follow-through); exact original character proportions/head/limbs/boots, granular pixel skin texture, rugged detailed face and unchanged clothes, transparent without glow/effects. No extra intermediate frames are claimed. Source saved in art_sources/crusher_victim_forward_v5/key_poses.png and reviewed before technical atlas integration.

Packing uses original RGBA sprite isolation and uniform scale 228/547=0.4168190128, nearest sampling, fixed 400x280 cells and baseline260. No separate anatomical stretching. Original resources remain available.

Checks: full Seiya/Gou real-physics throw suites failures=[] (32 combined cases); native standing plus three receiver frame review passed fixed runtime scale and new atlas source assertions. Focused native forward throw validates correct receiver atlas in live physics, both facings, single damage and throw release unlock. See native screenshots for visual evidence. No physical smartphone/manual/public Web test or publication. Editor safe-save and headless ObjectDB exit warnings persist and were not hidden.

Changed: enemy_01_standard.tres atlas path append only. Added: selected source and before/source/native comparisons, packer, atlas PNG/TRES/manifest, native review and focused live test, this report. Existing unrelated changes/import metadata excluded from phase commit. Remaining: back receiver, ordinary down/recovery continuity and Gou/Seiya dedicated motions.
