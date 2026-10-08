# Crusher normal down and recovery design pass

Branch codex/stage1-gou-seiya-20261007; start HEAD 5b4b6f6c5f5c590d0c23f9d31c49205993b5c70e.

Scope: normal knockdown(3 playback frames) and stand_up(4). Six generated key poses: standing calibration, stagger, seated fall, side-down, one-knee rise, low guard. The final recovery frame copies the original official standing sprite unchanged. Previous directional throw overrides preserved. Timers, invulnerability, hitboxes, physics, damage and save/input data unchanged.

Built-in imagegen prompt: exact official design/anatomical scale and pixel material; preserve detailed face and compact bent legs in side-down; original clothes and skin, no enlarged girth/shrunken prone pose, transparent without effects. Reference official standing and old native down/recovery comparison. Key source reviewed before technical packing. Reconstructed existing pose count/timing; no additional intermediate frames claimed.

Packing: one scale228/471=0.4840764331, nearest sampling, source RGBA, whole-sprite isolation, fixed400x280 cells and baseline260; no separate limb/head/body resizing. Original standing copied into frame6. Common runtime scale is constant; natural visible height changes with posture. This does not certify anatomical perfection for every frame.

Verification: native eight-pose review checks nonempty frames, fixed scale and correct new atlas. Native real-physics normal down->GET_UP->control passes both facings, asserts new atlas throughout and enabled hurtbox at end; captured all seven playback frames per facing. Actual down and kneeling rise screenshots inspected. This fixture enters normal down directly; it does not assert every attack's damage routing. Crusher throw flow test failures=[]; Stage1 KO/character continuation/game-over regression failures=[]. Editor safe-save permission warning and ObjectDB exit leak warnings remain. No physical smartphone/manual/public Web play; no publication.

Added key source/gray/source/native/down/rise reviews, packer, atlas PNG/TRES/manifest, native review and focused live test, report. Modified enemy_01_standard.tres atlas append only. Unrelated dirty/import files excluded. Remaining Stage1 work: other reaction/attack consistency and Gou/Seiya dedicated motion coverage and final gameplay/release checks.
