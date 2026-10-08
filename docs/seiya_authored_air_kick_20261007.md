# Seiya dedicated airborne kick

Branch codex/stage1-gou-seiya-20261007; start HEAD3eeb1d647d14d3c7e82dcf572c497205aea0c727.

Changed seiya_air_kick animation jump_kick to dedicated seiya_air_kick only. Damage/startup/active/recovery/hitbox/knockback/guard/cancel rules preserved. Imagegen reference seiya_slim_v3/formal_standing.png, slim body/head/limbs/face/blond hair, long white sleeves covering belly, beige trousers/belt/white sneakers. Four unique airborne action key poses plus neutral calibration, playback [1,1,2,3,4]12fps contact2; no additional intermediate art claimed. Front-down kick via hip/knee angle, no separate limb resize.

One195/495=0.3939393939 scale all source poses. Fixed384x288 origin160, air top75 keeps folded feet separate from baseline270; physics supplies jump elevation. head_scale_override1 prevents duplicate reduction. Source gray/same-scale and native comparison inspected against original standing.

Both-facing native Intel Iris Xe and headless authored tests failures=[]: real collision/physics launcher->Jump->AirP->AirK three hits, correct dedicated air K source/head parameter, buffered jump/whiff restrictions and landing restores control. Mobile handlers invoked programmatically; not human touch/device test. Native seven-pose fixed-scale/source review passes; contact inspected. Complete Seiya atlas125clips366frames failures=[]. Crusher old air receiver reaction remains separate pending visual work. Existing editor safe-save error persists, no warning-free claim. No physical smartphone/manual/public Web verification or publication.

Added source/gray/same-scale/native evidence, packer, atlasPNG/TRES/manifest, native review/combat tests/report. Changed fighter supplemental source, attack animation only and atlas exact source test. Existing unrelated dirty/import files preserved/excluded. Other air/throw/receiver dedicated art and final Stage1 play/release unfinished.
