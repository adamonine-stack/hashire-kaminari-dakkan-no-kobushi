# Crusher held pose and down/recovery review

Branch codex/stage1-gou-seiya-20261007; start HEAD 21e38124c42dce8fc70e13e70edbdff1e5211d47.

Replaced only directional_throw_held, one looping frame at 8fps, via last supplemental atlas. Combat timing/hold offsets/damage/physics unchanged. Old resources preserved. Built-in imagegen used official standing and old held sprite: exact character proportions/material, standing calibration and tense planted held stance with fists near chest, unchanged clothes and detailed rugged face, no background/effects. Selected source is art_sources/crusher_victim_held_v7/key_poses.png, gray review saved. Uniform scale228/763=0.2988204456, nearest sampling, original RGBA, no independent limb/body resizing, fixed400x280 cells and baseline260.

Verification: Seiya/Gou full real-physics throws both failures=[] (32 combined cases); focused native held test both facings failures=[] confirms new atlas during actual throw hold and single damage/release unlock. Native three-pose standing/held review passed runtime fixed-scale and new atlas assertions; actual Battle held screenshot inspected. Smartphone hardware/public Web/manual play not tested. Editor safe-save and headless ObjectDB exit leak warnings remain.

Also rendered original normal knockdown(3) and stand_up(4) beside idle, eight actual frames with fixed runtime scale. No scaling change was found in this sample; visual body/face/material continuity still needs work, especially prone face and soft rounded muscle highlights. Normal down and recovery were audited, not replaced. This is not a full-motion visual certification.

Added: selected source/gray/same-scale/native/held/down-recovery reviews, packer, atlas PNG/TRES/manifest, held native/focused live tests, normal down/recovery review test, report. Changed: enemy_01_standard.tres supplemental atlas append only. Unrelated dirty files/import metadata excluded. No publication; remaining normal-down/recovery art and Gou/Seiya dedicated motions.
