# Crusher back throw receiver design pass

Branch codex/stage1-gou-seiya-20261007; start HEAD a9ded0cb0a6c8f594cf1dcbcb5206e0ede9be4d9.

Scope: throw_victim_back_air only, 3 existing playback frames at 10fps. Added supplemental atlas last in existing list; previous attacker/neutral/forward/slam corrections preserved. No combat timing, damage, position-swap, physics, input, hitbox or save changes.

Built-in imagegen prompt: strict official standing identity/material, calibration standing plus three forward-falling back-throw receiver poses; compact original proportions, unchanged head/limb/boot size, bent elbows/knees, rugged detailed face, granular pixel skin, unchanged clothes, transparent without effects. Key source and gray review saved. Existing three-frame pose sequence reconstructed, no added intermediate frames claimed.

Packing: common scale 228/495=0.4606060606, nearest sampling, retained RGBA, complete-sprite isolation, 400x280 cells and baseline260. No separate limb/body scaling. Reviewed beside official standing before integration. Original resources retained.

Verification: Seiya/Gou full real-physics throw suites failures=[] (32 combined cases); native five-pose review verifies fixed runtime sprite scale and new atlas selection. Focused native back-throw test covers both facings, new receiver atlas in real physics, single damage and throw release unlock. These are automated/native renderer checks, not manual smartphone or public Web play. Editor safe-save and headless ObjectDB exit warnings remain. No publication.

Added source/before/gray/same-scale/native comparisons, packer, atlas PNG/TRES/manifest, native review/focused live scripts and this report. Modified enemy_01_standard.tres only to append atlas path. Unrelated dirty files and generated imports excluded.

Remaining: ordinary knockdown/recovery and held/preparation receivers still need design continuity review; Gou/Seiya dedicated motion work remains. Directional flight clips now each have a reviewed override, but this does not certify all character frames or finish Stage1.
