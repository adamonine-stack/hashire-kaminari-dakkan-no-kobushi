# Crusher slam victim design pass

Branch: codex/stage1-gou-seiya-20261007. Start HEAD: a6f01d3.

Replaced only `throw_victim_down_air` (2 frames) and `throw_victim_slam_down` (1 frame) through a supplemental atlas. Official idle remains authoritative. Other knockdown/victim motions are unchanged and still need review. No combat data, timing, physics, hitbox, damage or save changes.

Built-in imagegen generated four key poses using official standing and the old slam pose sequence as references. Prompt: strict official character identity and pixel material; standing calibration, bent-knee slam crouch, face-down falling brace, compact prone forearm rest; constant anatomical scale, detailed rugged face, no elongated limbs, no glow/background. Source: art_sources/crusher_victim_design_v3/key_poses.png. Key poses were reviewed before technical packing. No additional in-between frames were generated. This replaces an existing two-frame flight and single-frame down clip, rather than claiming a new full animation set.

Uniform scale 228/547 = 0.416819, nearest sampling, preserved source RGBA. Individual anatomy is not rescaled. Fixed 400x280 cells, centered visible sprite and baseline 260. Supplemental source atlas contains an unused standing calibration frame. Existing resources are preserved.

Verification: native six-pose standing/receiver review with constant sprite-scale and correct-atlas assertions; Seiya and Gou real-physics throw suites both failures=[] (32 combined cases); AKKY directional throws failures=[]; native Seiya full throw suite failures=[]; focused native slam test both facings failures=[] with assertions that both new receiver stages are reached. Actual prone in Battle was visually inspected. These are automated/native rendered checks, not hands-on smartphone or public Web play.

Import reports existing safe-save permission warning. Headless throw suites report existing ObjectDB exit leaks. Neither warning was hidden or claimed resolved. No publication. Full Stage 1 design unification and hero dedicated art remain unfinished. Unrelated dirty files/import metadata excluded from this phase commit.

New files: key-pose source and gray review, before/same-scale/native review images; packer; atlas PNG/TRES/manifest; focused physics test; native review test; this report. Changed file: enemy_01_standard.tres atlas-path append only.
