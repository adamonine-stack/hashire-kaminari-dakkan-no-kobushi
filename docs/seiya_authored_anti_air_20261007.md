# Seiya dedicated anti-air motion

Branch codex/stage1-gou-seiya-20261007, start HEAD73082f2bad891c8204ccf4c8f9ca33642a0d0447.

Inspection found Gou/Seiya back punch still routed to generic punch_2. This phase changes only Seiya back punch animation to seiya_back_punch, with dedicated anticipation/contact/finish/recovery source poses. Gou and other directional moves remain pending. Attack timing/damage/hitbox/cancel/launch rules unchanged.

Built-in imagegen used art_sources/seiya_slim_v3/formal_standing.png as strict official slim design. Prompt: calibration standing plus anti-air anticipation, upward contact, finish and recovery, same head/torso/limbs, slim shoulders, long sleeves never rolled and belly covered, unchanged clothes, no effects, transparent. Key source reviewed and then packed. Four unique action poses mapped to five playback frames [1,1,2,3,4], contact frame2 preserved; first pose held across two frames. No extra intermediate artwork claimed.

Uniform195/468=0.4166667 source scale follows approved slim_sweep195px calibration. Formal reference PNG is a rendered reference, not a raw source-height calibration. No separate body/limb resizing; fixed384x288 cells, baseline270 and origin160. head_scale_override=1 avoids applying legacy0.9 head correction a second time. Actor width correction remains existing. Native comparison is authoritative for size assessment.

Tests: seven native reference/action frames, fixed runtime scale and correct source checks; both-facing anti-air hit and retreat/whiff cancel regression failures=[]; native authored attack test failures=[] with correct clip and head override, actual contact screenshots inspected. Seiya complete atlas contract119clips336frames failures=[] after adding exact new source expectation. Initial review fixture array-index error fixed; initial atlas test lacked new source registration, fixed without removing checks. Editor safe-save and headless ObjectDB exit warnings remain.

No manual physical smartphone/public Web gameplay or publication. Unrelated dirty files preserved. New: source and source/native comparisons, packer, atlas PNG/TRES/manifest, visual and authored anti-air tests, report. Changed: ally_speed supplemental path; seiya_back_punch animation name only; seiya_motion_atlas source expectation. Remaining: Gou dedicated anti-air, both heroes' other directional/throw/receiver consistency, then final Stage1 gameplay and publication.
