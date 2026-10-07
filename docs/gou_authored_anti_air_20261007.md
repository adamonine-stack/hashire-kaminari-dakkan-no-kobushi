# Gou dedicated anti-air motion

Branch codex/stage1-gou-seiya-20261007; start HEAD af6b446bd0e4cf0c196c62d3316e9167968634f3.

Changed only Gou back-punch animation from generic punch_2 to gou_back_punch. Existing attack timings/damage/hitbox/launch/cancel rules unchanged. Official Gou idle frame0 extracted from gou_v1 384x288 cell as design reference. Source retains white tank top, black pants, original sandals and powerful proportions.

Built-in imagegen prompt: exact official identity/material/body/head/limb proportions, calibration standing plus anticipation/upward-contact/finish/recovery, no enlarged muscles, no belly exposure, original sandals not shoes, transparent without effects. Key poses reviewed before technical packing. Four unique action poses mapped to five playback frames[1,1,2,3,4], first pose held twice and contact2 preserved. No added intermediate artwork claimed.

Uniform203/435=0.4666667 source scale, original RGBA, nearest sampling, no individual limb/body resizing. Fixed384x288 cells, baseline270 and horizontal origin160. Head override1 with existing actor setup. Native seven-pose comparison checks fixed runtime scale and correct new source. Initial review sources/calibration preserved in art_sources/gou_anti_air_v2.

Checks: Gou complete atlas114clips314frames failures=[] after exact new source expectation registration; native authored anti-air test both facings failures=[], correct source during attack and airborne hit, retreat/whiff cancel regression retained; native contact/reference images inspected. Editor safe-save warning remains. No manual smartphone/public Web play or publication. Seiya anti-air already integrated; remaining directional attack/throw/receiver consistency and final Stage1 play/release checks remain.

Added source/reference/gray/same-scale/native images, packer, atlasPNG/TRES/manifest, native review/authored test and report. Modified ally_power supplemental path, gou_back_punch animation name only, gou_motion_atlas source expectation. Unrelated dirty files/import metadata excluded.
