# AKKY / Crusher special guard and reaction audit

Branch codex/directional-combat-20261003, starting HEAD e9115fd034d7ae22cce45e9837b583860a3bda27. Stage checkpoint, not complete all-character combat rollout.

## Added
Both actors now have dedicated three-pose ground special guard (brace / impact / return). Uniform source packing, AKKY320x224 and Crusher400x280 cells, fixed ground anchors208/260. No runtime per-frame scale changes. Source key pose compared with official art before producing strip; complete frames and normal standing compared in rendered Battle scene. Air special guard retains existing dedicated air_guard_hit. No new effects/nodes/particles; existing guard flash/spark/hitstop/small push used.

Defender special_damage_reactions now supports guard phase, allowing the receiving fighter to select its own pose. Missing map falls back to existing attack-defined reaction. Seiya staged launch handling excluded for guard phase so a block cannot accidentally select a flight pose. End-of-block, ordinary block and action interruption clear special pose. Special guard clip driven by actual guard-stun timer only for opt-in fighters (sync_special_guard_to_stun default false; true for AKKY/Crusher). Existing special damage, chip, cooldown, startup protection and attack/hitbox rules preserved. In this existing game Thunder Drive has authored15% chip while Crusher has0%; this phase does not change that prior balance contract.

## Verified
DEDICATED_SPECIAL_GUARD_CHECK failures=[]: actual Area2D collision -> SpecialContactResolver -> guard, both receivers/both facings; three synchronized frames; fixed scale/origin; small push instead of launch/down; normal block does not inherit special pose; air block chooses air art; guard damage matches existing data; cleanup at block end/interruption.

SPECIAL_GUARD_VISUAL_EXPORT_OK: normal guard /3special phases /air /standing, both facings,12rendered screenshots inspected for both actors. AI/phone hardware manual play not claimed. Air guard, special reversal, dive kick, air combo, Crusher down recovery regressions passed. Root certificate store warning persists in Godot launcher; no script failures in listed checks.

## Current receiver source inventory
This is runtime SpriteFrames routing, not proof that every alias or actual combat route is reviewed. Move-specific special/throw art remains available even where canonical aliases are absent.

| Clip | AKKY source | Crusher source |
| --- | --- | --- |
| damage_light | player01/animations/akky_v3/motion_atlas.png | enemy01/animations/crusher_v1/motion_atlas.png |
| damage_heavy | player01/animations/akky_v3/motion_atlas.png | enemy01/animations/crusher_v1/motion_atlas.png |
| damage_high | player01/animations/akky_v3/motion_atlas.png | enemy01/animations/crusher_v1/motion_atlas.png |
| damage_low | player01/animations/akky_v3/motion_atlas.png | enemy01/animations/crusher_v1/motion_atlas.png |
| air_hit | dedicated_pair_v1/akky_upper.png | dedicated_pair_v1/crusher_air.png |
| launch_hit | dedicated_pair_v1/akky_upper.png | dedicated_pair_v1/crusher_air.png |
| knockback | player01/animations/akky_v3/motion_atlas.png | canonical clip absent; inspect move-specific reaction |
| knockdown | player01/animations/down_v2/motion_atlas.png | enemy01/animations/crusher_v1/motion_atlas.png |
| down | player01/animations/down_v2/motion_atlas.png | enemy01/animations/crusher_v1/motion_atlas.png |
| ground_bounce | canonical clip absent; inspect move-specific reaction | canonical clip absent; inspect move-specific reaction |
| wall_hit | canonical clip absent; inspect move-specific reaction | canonical clip absent; inspect move-specific reaction |
| special_hit | player01/animations/reversal_v1/motion_atlas.png | canonical clip absent; inspect move-specific reaction |
| special_knockback | player01/animations/reversal_v1/motion_atlas.png | canonical clip absent; inspect move-specific reaction |
| special_knockdown | player01/animations/down_v2/motion_atlas.png | canonical clip absent; inspect move-specific reaction |
| special_guard | dedicated_pair_v1/akky_special_guard.png | dedicated_pair_v1/crusher_special_guard.png |

Next art candidates: distinct wall-impact and bounded ground-bounce reaction (currently no canonical clips), followed by high/low/heavy hit routing/pose review. Existing move-specific special wall/down reactions and the shortened Crusher ground-down pose are preserved. No claim that all attack/receiver motions are finished.

Files: new special_guard key/strip and two atlas PNG/TRES/imports, pack/check/render-review scripts, PAIR_REACTION_INVENTORY.json; modified fighter_definition.gd, shared movement/combo movement and AKKY/Crusher definitions. Inherited imports/untracked QA logs/user changes excluded from commit.
