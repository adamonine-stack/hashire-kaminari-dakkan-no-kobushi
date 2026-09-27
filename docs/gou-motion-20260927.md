# Gou / protagonist 2 motion release

Gou (`player_02_gou`) now uses original animation art based on the supplied design: muscular five-head proportions, brown buzz cut, white tank top, loose black trousers, belt and wooden geta. The design sheet itself is not used as animation cells.

## Assets

- `godot/assets/characters/player02/animations/gou_v1/motion_atlas.png`: 88 authored poses, 384 x 288 cells, 8 columns (3072 x 3168, below 4096 on both axes), transparent PNG.
- `motion_atlas.tres`: 75 explicit clip names, including aliases, using 253 frame references.
- `sources/`: three original generated sheets; excluded from Godot imports with `.gdignore`.
- `packing_manifest.json`: original bounding rectangles, per-sheet scale and fixed feet baseline (270).
- `tools/build_gou_motion_atlas.cjs`: connected-component packing prevents neighboring extended limbs from leaking into a frame. No pose-by-pose resizing. Supplementary sheet uses one uniform 0.66 density conversion.
- `tools/configure_gou_motion.cjs`: reproducible clip definitions and fighter binding.

Idle, forward/backward walk, dash, jump phases, crouch, standing/crouching guard, straight punch, uppercut, front kick, crouching punch/sweep, air punch/kick, hit reactions, knockdown, get-up, KO, throw, Iron Breaker and victory are covered. Walk and dash each have six distinct drawings. KO finishes on the prone frame without looping.

The existing fighter ID, selection path, campaign HP (65), base stats, damage, attack timing and combo limits are preserved. Gou's hitbox offsets now follow the authored limbs. Contact frames use the existing combat clock, including hitstop; the change is scoped to Gou. Existing Akky/Crusher/Rei mappings remain intact.

## Verification

- `gou_motion_atlas.gd`: all clips, cells, origin/scale, KO, real fighter selection, campaign HP, both facings, normal/crouching/air contact frames and Iron Breaker phases.
- `akky_motion_atlas.gd`, `dev052_visual_check.gd`, `dev053_stage1_smoke.gd`, `stage1_regression.gd`, `stage2_regression.gd` pass locally.
- `gou_visual_review.gd`: actual graphical Godot Battle rendering of every clip frame, plus normal attack hitbox overlays on both facings. These are scripted rendering checks, not manual gameplay.
- The Pages workflow also runs the Gou test before export.

## Generation

Built-in ImageGen was used with the supplied image as an identity/design reference, transparent output requested. Three prompts share these requirements: original full-body right-facing arcade pixel art; stocky very muscular adult Japanese man; brown buzzcut, fierce eyebrows, tan skin, white tank top, black loose trousers gathered at ankles, black belt/silver buckle, wooden geta/black straps/bare toes; faithful five-head proportions; consistent body scale; transparent background; no labels, grid lines, shadows, effects or other characters.

Prompt set:

1. **Locomotion**: request a 6 x 6 atlas, nominal 1536 square, 256-square cells, 190px standing body and y232 feet. Rows: six idle breathing poses; six alternating-leg walk poses; six forward-leaning dash poses; jump anticipation/takeoff/rise/apex/descent/landing; shallow/deep/held crouch and standing/impact/crouching guard; light/heavy hit, falling, supine KO, kneeling rise, recovered stance.
2. **Attacks**: request the same 6 x 6 layout. Six sequential anticipation/windup/extension/contact/retract/return drawings per row for straight punch, uppercut, front kick, crouching punch and low sweep. Last row: three air punch phases and three air kick phases. Distinct contact silhouettes; geta retained throughout.
3. **Extras**: request 4 x 4, nominal 1024 square, same cell/body/baseline dimensions. Rows: reach/clinch/pivot/throw release; Iron Breaker stance/coil/full right punch/recover; arms-folded pride/head raise/raised fist/shout and settle; falling/supine/push to knee/stand. No opponent is drawn into the throw frames.

ImageGen returned 1254-square images. Packing uses measured sprites instead of assuming the requested grid dimensions. Original outputs are retained for reproducibility.
