# Seiya dedicated ground launcher

Branch codex/stage1-gou-seiya-20261007; start HEAD bfb92e5612ba262db5bd33517818be37bf8395bc.

Changed only seiya_down_punch animation from crouch_punch to seiya_down_punch. New dedicated low anticipation, diagonal forward-up contact, retract and guard poses. Combat damage/startup/active/recovery/hitbox/launch/cancel behavior unchanged. Gou launcher remains generic and pending.

Built-in imagegen used approved slim standing reference. Prompt: identical slim body/head/limb proportions, crouched grounded launcher striking forward-up at own head height (distinct from overhead anti-air), white long sleeves and covered belly, unchanged clothes/pixel material, transparent with no effects. Selected key source reviewed before packing. Four unique action poses mapped to five playback frames[1,1,2,3,4], contact2 retained; no additional intermediate art claimed.

Uniform195/475=0.4105263158, approved standing calibration as prior slim atlas. Fixed384x288, baseline270, origin160, preserved RGBA/nearest sampling, no individual anatomical resizing. head_scale_override1 avoids duplicate legacy head reduction.

Checks: both-facing native authored launcher test failures=[], correct dedicated clip/head override, ground hit and existing retreat/whiff cancel checks; native seven-pose reference/action review passed fixed-scale/source checks. Real-physics launcher->Jump->AirP->AirK both facings failures=[] in stage1_hero_air_combo_check. Complete Seiya atlas120clips341frames failures=[]. Native contact screenshot inspected (victim overlaps striker, source pose comparison provides unobscured view). Editor safe-save and headless ObjectDB exit warnings remain. No physical smartphone/manual/public Web play or publication.

Added key source/gray/same-scale/native comparisons, packer, atlasPNG/TRES/manifest, native review/authored test, report. Changed ally_speed supplemental path, seiya_down_punch animation name only, seiya_motion_atlas exact new source expectation. Unrelated dirty/import files preserved and excluded. Remaining Gou launcher and other direction/throw/receiver dedicated art, final Stage1 play and release verification.
