# Gou dedicated ground launcher

Branch codex/stage1-gou-seiya-20261007; start HEAD e35c5f6109b8670f901d919f7383831340e66642.

Changed only gou_down_punch animation from crouch_punch to gou_down_punch. Dedicated low anticipation, diagonal forward-up contact, retract and guard poses. Damage/startup/active/recovery/hitbox/launch/cancel behavior unchanged.

Built-in imagegen source follows formal_standing.png from gou_anti_air_v2. Preserve powerful body, head and limbs, white tank top, covered belly, black trousers/belt and ochre Japanese sandals. No effects or background. Four unique action key poses mapped to five playback frames [1,1,2,3,4], contact2 retained; no additional intermediate art claimed. Fixed row ordering before integration.

One scale203/473=0.4291754757 for every source pose. Fixed384x288, baseline270, origin160, preserved RGBA/nearest sampling, no separate anatomical resizing. Source and native rendered comparisons inspected against original idle. Native contact screenshot overlaps receiver, so unobscured pose comparison retained separately.

Checks: native authored launcher both facings failures=[], new atlas source during attack, ground hit, existing retreat and whiff cancel restrictions. Native seven-pose review fixed-scale/source assertions passed on Intel Iris Xe Forward Mobile. Real-physics launcher->Jump->AirP->AirK both facings, three hits failures=[]. Complete Gou atlas115clips319frames failures=[]. Editor safe-save error and headless ObjectDB exit warning remain; not a warning-free run. No physical smartphone/manual/public Web play or publication.

Added source/gray/same-scale/native evidence, technical packer, atlasPNG/TRES/manifest, review/authored tests and report. Changed ally_power supplemental path, gou_down_punch animation only, gou_motion_atlas exact source expectation. Unrelated dirty/import files preserved and excluded. Remaining other directional/throw/receiver dedicated art and final Stage1 play/release verification.
