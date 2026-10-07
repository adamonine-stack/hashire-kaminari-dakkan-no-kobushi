# Dedicated motion production checkpoint 2026-10-04

Start/current branch: codex/directional-combat-20261003. Phase baseline HEAD: 97de2c5e3f4b397604cc1876388fcb708e0b7e62.
This is an intermediate checkpoint. AKKY/Crusher full attack+receiver motion scope remains in progress; not a completion report.

## Connected new art

|Actor|Clip|Source key / selected strip generated exec ID|Technical pack scale|
|--|--|--|--|
|Crusher|Back P anti-air|6f09ba62-3275-4adc-bc9e-f6779ea9c984 / 296803b7-3819-4892-807c-0337491c5670|0.66|
|AKKY|Launch/air receiver|same upper sheet bottom row|0.46|
|AKKY|Air P horizontal jab|user_preferred_air.jpg / f6ab9977-7f33-404d-a87e-c1b7939c037d|0.44|
|Crusher|Air/launch receiver|same Air sheet bottom row|0.52|
|Crusher|Down P body launcher|183a9bc5-9f86-4dde-8c4b-c6f814b279f5 / 68822dbe-1c56-4856-8e2d-5d575a548999|0.36|
|AKKY|Down P body launcher|b032f1c2-4fa0-40e0-bb8c-c5e4d4ef927c / 3aabb918-41af-4045-bbb2-78fd4e0442b5|0.28|
|Crusher|Forward K push kick|f5cb5679-f3e6-4a82-9992-3fac7c0cebad / 50aaaeb3-b7cc-4460-831f-6fdd3370b9a7|0.36|
|Crusher|Back K evasive kick|6acbf94b-3c6a-4bc6-ac2b-88a4d7781b4e / 0140466e-be27-4e17-a2dc-54e45d1c7555|0.36|
|AKKY|Back K evasive kick|49903cff-7323-4bb4-807a-166cd43e45c1 / 87b2c8fd-221f-4f74-a2da-f25be417a158|0.28|

Built-in imagegen used. Source/key images live outside Godot under art/dedicated_pair_v1/sources to avoid exporting/importing authoring textures. Runtime PNGs and .tres are under godot/assets/characters/dedicated_pair_v1. Pack scripts use Godot Image cropping, uniform per-character resizing and canonical-facing mirroring only. No anatomical editing through scripts; no per-frame fit/scale. Cell/root remain AKKY320x224/(160,208), Crusher400x280/(200,260). Source keys may include rejected background glow; only clean selected strips supply runtime atlases.

## Prompt set and revision decisions

- All prompts lock official identity, head/body and limb proportions, detailed face/hair, costume and clean alpha. AKKY beige FULL long sleeves to closed cuffs, black high neck covering abdomen, slim torso; Crusher red bandanna, black sleeveless tank/wristbands, olive cargo/boots and official muscular build.
- Upper: upward anti-air bent-elbow fist, four anticipation/startup/contact/recovery poses plus paired AKKY launch reaction. Contact arm was corrected20percent shorter after key review.
- Air: user's supplied sheet is preferred proportion baseline. Targeted extended punching-arm correction; over-shortened output e2ece2b3 rejected in favor of intermediate arm length f6ab9977. Head retained at user-reference size, not the earlier small-head/slim-body trials.
- Launcher: low grounded rising body blow below own head, distinct from overhead anti-air. Key then four2x2 frames: load fist at belt -> ribs -> chest-high bent-elbow contact -> guard. Crop-boundary contaminated Crusher4x1 output was replaced with2x2 layout.
- Forward K: advancing front push kick, knee chamber -> bent-knee contact -> chamber recovery; range comes from movement, not extending legs.
- Back K: head/torso withdraw, planted rear leg, compact front counter kick -> chamber. Crusher upperbody/head size revised after runtime comparison. AKKY shortening trial c963280b was rejected because it over-shortened the limb; selected87b2c8fd remains.

## Code/data and verified evidence

Directional custom animations now remain selected by command_direction rather than requiring ai_tags. Existing KO/down/hit/special precedence remains. New Crusher Back P selected only after observed airborne state has accumulated reaction observation time. Down P data added; no automatic launcher AI route claimed yet.

Actual collision: DEDICATED_PAIR_CHECK failures=[] covers Crusher Back P vs airborne AKKY and Crusher Down P vs grounded AKKY in both facings, launch/scale/landing recovery.
AIR_COMBO_CHECK failures=[] after horizontal Air P HitBox(70,-112), middle height, air_hit and updated Down P HitBox(60,-105): mobile-handler-driven direction->action delay, launcher->jump->Air P->Air K actual3hit contacts in both facings. Not physical touch-device verification.
DIRECTIONAL_ATTACKS_CHECK, THROW_MOTION_SYNC_CHECK, SPECIAL_REVERSAL_CHECK, CRUSHER_SITUATION_CHECK and STAGE1_REGRESSION all failures=[] during this checkpoint. Crusher situation test now covers observed anti-air, not input reads.
DEDICATED_PAIR_VISUAL_EXPORT_OK: scripted1280x720 game-screen render, both facings, contact poses and paired launch/air reactions. GL compatibility used for stable screenshot capture; not manual play or Intel Iris/mobile performance certification. The Windows root-certificate-store engine error remains and is separate from script correctness.

## Remaining target scope

Crusher4direction attacker throws and AKKY4victim throws are being authored, not connected yet. Grip key/strip are pending authoring material, not runtime motion.
Both dive kicks/landing, remaining high/low/wall/bounce reactions and special/throw full synchronization still require audit/production/validation. Existing neutralP/K, AKKYForwardP/K/DownK, CrusherForwardP/DownK and existing dedicated specials are reused where appropriate and are not counted as newly authored. No all-character rollout or completion claim.
