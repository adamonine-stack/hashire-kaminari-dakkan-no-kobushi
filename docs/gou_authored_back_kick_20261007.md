# Gou dedicated evasive kick

Branch codex/stage1-gou-seiya-20261007; start HEAD5e82b7f432eac0d87a4beb534e615c4dfca33dc7.

Changed gou_back_kick animation from kick_2 to dedicated gou_back_kick only. Existing startup0.19/active0.09/recovery0.30, damage0.85, retreat35, hitbox76x38 at82,-105, hurtbox and cancel targets retained. Dedicated backwards lean/knee chamber, horizontal kick, knee retract and guard recovery.

Imagegen reference art_sources/gou_anti_air_v2/formal_standing.png. Preserve powerful body/head/limb proportions, buzzcut face, white tank top covering abdomen, black trousers/belt and ochre Japanese sandals. Key source comparison inspected before integration. One203/483=0.4202898551 scale for all source poses, no separate anatomy changes. Cell384x288, baseline270, origin160. Four unique action key poses mapped [1,1,2,3,4] at12fps, contact2. No additional intermediate art claimed.

Native Intel Iris Xe Forward Mobile seven-pose review inspected against original standing; fixed sprite scale and dedicated source assertions passed. Both-facing native authored combat check failures=[]: correct dedicated source, actual damage and retreat, whiff denies forward-punch cancel. Headless same test failures=[]. Complete Gou atlas116clips324frames failures=[]. Contact screenshot inspected. Existing editor safe-save error and headless ObjectDB exit warning persist; not a warning-free run. No physical smartphone/manual/deployed Web confirmation or publication.

Added source/gray/same-scale/native evidence, packer, atlasPNG/TRES/manifest, native review/combat tests and report. Changed fighter supplemental path, attack animation only, atlas exact source test. Unrelated dirty/import files preserved and excluded. Other pending directional/throw/victim art and final Stage1 play/release remain incomplete.
