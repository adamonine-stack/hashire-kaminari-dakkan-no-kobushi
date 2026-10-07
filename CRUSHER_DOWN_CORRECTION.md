# Crusher ground-down correction

User clarified the ground-lying pose, not the dive landing pose. Rejected the mistaken dive landing edit and restored the originally selected dive strip.

Main crusher_v1 atlas cell 19 replaced with an authored anatomical correction. Other 27 cells are pixel-identical to HEAD. Opaque lying span now 329px; former span 346px. Cell remains 400x280, baseline 262px, runtime sprite scale and origin unchanged. Upper-body proportions used to calibrate uniform source packing; no per-frame runtime scale correction. Detailed face, red bandana, tank top, cargo trousers retained. Down, knockdown final, KO final and get-up initial all share this cell. Throw slam receiver is a different pose and remains unchanged.

Validation: CRUSHER_DOWN_MOTION_CHECK failures=[]; actual down/wake-up flow in both facings; fixed scale/origin and hurtbox restored. CRUSHER_DOWN_VISUAL_EXPORT_OK; standing/down screenshots in both facings inspected. Stage 1 regression result recorded separately. These are scripted runtime/rendered checks, not manual smartphone play or public release.

Dedicated dive-kick implementation is still uncommitted and under validation; excluded from this correction commit.

User rejected the first subtle correction. Superseded by crusher_down_two_thirds.png: waist-to-boot span targets roughly two-thirds of original; fixed upper-body packing scale retained. Full lying silhouette around 295px instead of original 346px. Stage 1 regression failures=[] before this second art-only correction.
