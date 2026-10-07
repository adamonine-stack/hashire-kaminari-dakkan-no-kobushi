# Seiya dedicated evasive kick

Branch codex/stage1-gou-seiya-20261007; start HEAD a571bda23459ad09526498ccf0e1576afcba8e8f.

Changed seiya_back_kick animation from kick_2 to dedicated seiya_back_kick only. Existing startup0.15/active0.09/recovery0.30, damage0.85, retreat35 and hitbox76x38 at82,-105, hurtbox and cancel targets retained. Dedicated knee chamber/backward lean, horizontal counter kick, knee retract and guard recovery.

Imagegen used official art_sources/seiya_slim_v3/formal_standing.png. Slim shoulders/torso/limbs, unchanged blond hair/head, white long sleeves/covered belly, beige pants and white sneakers. Source key poses reviewed before atlas connection; no individual leg or body resizing. Source calibration487px, one195/487=0.4004106776 scale for all poses, cell384x288, baseline270, origin160, head_scale_override1 prevents duplicate head shrink. Four unique action key poses mapped [1,1,2,3,4] at12fps, contact2. No additional intermediate art claimed.

Native Intel Iris Xe Forward Mobile seven-pose comparison inspected with original standing, fixed scale and correct source assertions. Both-facing native authored combat check failures=[]: new source/head correction, actual retreat and damage, whiff prevents forward-punch cancel. Headless same test passes; complete Seiya atlas121clips346frames failures=[]. Combat screenshot inspected. No player manual touch, physical phone or deployed Web verification. Editor safe-save error and headless ObjectDB exit warning persist; no claim of warning-free run. Existing unrelated dirty files preserved and excluded.

Added source, gray/same-scale/native comparisons, packer, PNG/TRES/manifest, native review/combat test/report. Changed fighter supplemental source, move animation and exact atlas test expectation. Other pending dedicated directional/throw/victim art and Stage1 release remain unfinished.
