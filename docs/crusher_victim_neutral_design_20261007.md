# Crusher normal throw victim design pass

Branch: codex/stage1-gou-seiya-20261007; start HEAD fc641f01a4ae6433af8da00949d20fbd6cc4191f.

Scope: only throw_victim_neutral_air, three existing playback frames at 10 fps. Supplemental atlas overrides this clip; official standing and earlier slam receiver overrides remain intact. Forward/back receiver and ordinary down are not changed. Physics, damage, timing, hold position, hitboxes and saves are unchanged.

Built-in imagegen used official standing as strict design/material reference and old neutral receiver sequence for pose intent. Prompt: standing calibration plus backward release, tilted recoil, tucked airborne knees; identical anatomical scale and compact limbs, detailed rugged face, reference pixel material and skin color, same clothes, transparent and no effects. Source and opaque-gray review saved alongside same-scale comparison. Existing three-frame sequence retained; no additional intermediate frames claimed.

One uniform scale: 228/522 = 0.4367816092, nearest sampling, original RGBA. Complete sprite isolation and fixed 400x280 cells with baseline260, no independent head/body/limb scaling. Native renderer review checks original standing and all three flight frames, fixed runtime scale, correct new atlas source. Comparison shows pose-dependent visible heights rather than normalizing each airborne pose to standing height.

Verification: Seiya and Gou full real-physics throw checks both failures=[] (32 combined cases); focused neutral flight real-physics and native-rendered check failures=[] for both facings, confirms new atlas in live receiver flow, single damage and release unlock; native five-pose review passed. Flight screenshot inspected in Battle. Headless exit ObjectDB leak warnings and editor safe-save warning remain. No hands-on smartphone or public Web test; no publication or full Stage1 completion claim.

New files: source, gray/source/native comparisons, before screenshot, live flight screenshot; packer; atlas PNG/TRES/manifest; focused live and native review scripts; this report. Modified: enemy_01_standard.tres atlas append only. Unrelated dirty files preserved and excluded from commit.

Next: forward/back receiver artwork, ordinary down/recovery continuity, then remaining Gou/Seiya dedicated motion consistency.
