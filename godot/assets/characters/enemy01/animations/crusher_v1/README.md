# Crusher authored motion atlas

`sources/` contains individually produced, right-facing RGBA poses based on the
formal Crusher design sheet. `tools/build_crusher_motion_atlas.cjs` assembles
25 selected poses into `motion_atlas.png` at a fixed 20% source scale. No pose
is independently fit to a bounding box. Each 400×280 cell shares the same
foot/body baseline at y=260. `packing_manifest.json` records the cells.

`motion_atlas.tres` maps game animation names to those cells. Production
`enemy_01_standard.tres` points to this atlas and retains the old sprite
sheet as an unused legacy asset. Indexes 1–4 form one Walk cycle: near leg
back / passing / near leg front / passing. Indexes 5 and 6 are the strong
punch windup and contact; their visible heights are 221 and 220 pixels.
Rejected source candidates are never packed.

Rebuild with `node tools/build_crusher_motion_atlas.cjs`; validate all cell
boundaries, alpha baselines and gait/punch height continuity with
`node tools/check_crusher_motion_atlas.cjs`. The game currently uses idle,
walk, dash, jump phases, punches, kicks, guard, crouch, damage, knockdown,
recovery, KO and throw. Aliases map further game names to shared poses.
The enemy AI does not request a special move. Headbutt, elbow, body blow,
ground slam and special techniques from the concept sheet are not distinct
gameplay animations in this implementation.

Full visual acceptance requires a Godot rendering display and a Stage 1 play
session. Headless tests exercise the atlas wiring and combat state, but cannot
establish that every transition looks natural in the rendered game.
