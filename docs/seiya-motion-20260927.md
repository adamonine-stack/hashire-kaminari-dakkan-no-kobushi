# Seiya / ally character 3 authored motion

Seiya (`player_03_seiya`, せいや / セイヤ) now uses original sprites faithful to the supplied design: golden blond fringe, slim five-head proportions, white collared long-sleeve shirt, beige chinos, brown belt and white sneakers. The reference sheet was not cropped into animation frames.

## Assets and integration

- `godot/assets/characters/player03/animations/seiya_v1/motion_atlas.png`: 104 generated poses in 384 x 288 cells, 8 columns, 3072 x 3744 transparent atlas.
- `motion_atlas.tres`: 76 named clips / 265 frame references. Includes idle/prebattle, forward/backward walk, dash, jump/landing, crouch/guard, three punches, standing/crouching/air kicks and punches, throw, Clear Counter, hit reactions, KO/get-up and victory.
- Five retained source sheets are excluded from Godot imports by `sources/.gdignore`. Some superseded poses remain in the source/atlas for reproducibility; clip definitions select the reviewed poses.
- `tools/build_seiya_motion_atlas.cjs` packs isolated connected sprites without neighboring-limb contamination. Fixed per-sheet density factors, no per-pose scaling. Common feet baseline 270; walk/victory sheet origins adjusted to match the core art.
- `tools/configure_seiya_motion.cjs` regenerates clips and binds the existing fighter resource.
- Existing ID, selection flow, HP 46, attack timing/damage, combo limits, special gauge and other fighters are preserved. Seiya-only contact phase mapping follows the combat clock; reviewed hitbox offsets follow authored limbs on both facings.

## Verification

- Seiya contract test: 76 clips, 265 frames, no failures; resource bounds, fixed origin/scale, KO hold, real battle selection, HP, both facings, grounded/crouching/air attack phases, Clear Counter startup/contact/recovery.
- Actual graphical Godot Battle renders of all clip frames and both-facing attack hitbox overlays in `audit_evidence/seiya_visual_review/`. These are scripted rendering checks, not manual input.
- Akky, Gou, DEV052 and DEV053 regression checks pass locally. Stage 1 and Stage 2 full scenario tests passed with failures=[]. Stage 2 retains an existing two-object exit leak warning.
- Pages workflow runs the Seiya contract before export.

## Generation prompt set (built-in ImageGen)

Common: original production arcade pixel-art animation, reference only for identity; slim adult 21-year-old blond man, brown eyes, white collared button shirt with chest pocket and long sleeves tucked into beige chinos, dark brown belt with silver buckle, white lace sneakers; five-head proportions; right-facing full body; consistent scale, transparent alpha, no text, grid, shadows, effects or other characters.

1. Locomotion: 6x6 grid. Six idle/breathing, six walk, six dash, jump anticipation/takeoff/rise/apex/descent/landing; shallow/deep/held crouch, guard entry/impact/crouching guard; light/heavy hit/fall/supine KO/kneeling rise/recovery.
2. Attacks: requested 6x6 sequential anticipation/windup/extension/contact/retraction/return rows for lead punch, rear cross, high side kick, crouching punch, low sweep, and air attacks. Output had 30 isolated poses; only the first 24 were selected, with contact order reviewed explicitly.
3. Supplement: exact 6x4 low sweep, three air punch and three air kick phases, six jujutsu throw stages without an opponent, six parry/coil/palm-strike Clear Counter stages. Background removal edit requested; final alpha was measured and packed by connectivity, ignoring RGB in transparent pixels.
4. Victory/prebattle: 4x2 relaxed smile/hands on hips/raised fist/settle and neutral/adjust cuff/raise guard/ready.
5. Corrected walk: six distinct contact/passing/raised-knee poses across both steps with opposing arm swings. Used instead of the initial walk row.

Run packing with Node and `sharp` available via NODE_PATH, then run configuration, Godot import, `res://tests/seiya_motion_atlas.gd` and graphical `res://tests/seiya_visual_review.gd`.
