# Seiya dedicated airborne punch

Branch codex/stage1-gou-seiya-20261007; start HEADafe3360e2447a78bc403ca8379774ffc48f098c8.

Changed seiya_air_punch animation from jump_punch to dedicated seiya_air_punch only. Damage/startup/active/recovery/hitbox/launch/cancel rules preserved. Official seiya_slim_v3/formal_standing.png reference, slim torso/head/limbs, blond hair/face, white long sleeves covering abdomen, beige trousers/belt/white sneakers maintained. Imagegen four unique airborne action key poses plus neutral scale reference, playback [1,1,2,3,4]12fps contact2. No additional intermediate art claimed.

One195/480=0.40625 scale all source poses, no separate anatomy resizing. Cell384x288 origin160. Air pose top75 keeps upper body at standing calibration height rather than pushing folded feet to ground baseline270. Physics provides actual jump elevation, no changed actor scale. head_scale_override1 avoids duplicate reduction.

Native Intel Iris Xe seven-pose comparison inspected against original standing; fixed sprite-scale/source assertions pass. Headless and native authored tests failures=[] both facings: real collision/physics launcher->Jump->AirP->AirK three hits, new dedicated air P source/head parameter, jump buffer/whiff restrictions and landing restores control. Real mobile UI handlers invoked programmatically; not human touch/device test. Native contact screenshot inspected (receiver overlaps punching arm). Complete Seiya atlas124clips361frames failures=[]. Existing editor safe-save error/headless ObjectDB exit warnings persist, not warning-free. No physical phone/manual touch/public Web play or publication.

Added source/gray/same-scale/native evidence, technical packer, atlasPNG/TRES/manifest, native review/authored combat tests/report. Changed fighter supplemental path, air P animation only and atlas exact source expectation. Unrelated dirty/import files preserved/excluded. Other air/throw/receiver dedicated art and final Stage1 play/release unfinished.
