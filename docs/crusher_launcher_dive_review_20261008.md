# Crusher launcher and dive design pass

Branch unchanged: codex/stage1-gou-seiya-20261007. Start HEAD: aff4a5b.

## Completed
- Dedicated launcher v14: five-frame grounded load/rise/contact/retract/guard clip, contact runtime frame 2. Official standing reference opaque height 228, cells 400x280, ground baseline 260. Skin, face, costume and compact limbs compared at same scale. Initial fist exceeded cell bounds; corrected arm pose instead of shrinking fighter.
- Dedicated dive v15: accepted existing air chamber reused without resizing, new downward kick contact and grounded landing. Contact runtime frame 1; authored landing clip added. Key sheet uniformly calibrated to 228 pixels from standing; air top 32 and ground baseline 260.
- Enemy definition replaces old launcher/dive atlas paths. No shared runtime refactor.
- Launcher hitbox changed from (48,-115),50x64 to (54,-170),50x110 to follow rising fist/forearm path. Contact-only high box (54,-205) failed grounded collision and was rejected. Crouched hurtbox ends at .18 seconds before upright contact. Damage/startup/active/recovery/launch velocity/cancel routes preserved.
- Dive boot hitbox offset (65,-55), size48x46; damage, descent velocity, active/recovery and .32-second landing recovery preserved.

## Validation
- Launcher dedicated controlled Battle physics: both facings x hit/guard/whiff, headless and native passed. Frozen receiver fixture; true Area2D damage and upward velocity.
- dedicated_pair_check: real grounded player collision, launch and return/control both facings passed after hitbox correction.
- air_combo_check, directional_attacks_check, stage1_regression: failures=[].
- dive_kick_check headless and adapted crusher_dive_live_check headless/native: both AKKY and Crusher, both facings, hit/guard/whiff, late landing, recovery punish, ground rejection, released direction120ms and mobile UI event path passed. Synthetic touch/UI path, not actual phone.
- Native dive visual export: startup/contact/landing/standing both facings. Static controlled display; actual native physics separately tested above.
- Full four-actor attack frame review headless:552 frames failures=[]. Native final review also passed:552 frames failures=[], recorded in phase_two_moves_frames_native.log. Every frame automated bounds/mirror/scale checks; visual inspection focused on new key/full pose sheets and native launcher/dive contact/landing, not all552 manually.
- Native audio WASAPI device error observed. Another native stall traced to awaited select_player_by_id/intro completion in existing test. New test explicitly completes intro, final native combat checks use Dummy audio; audio playback not verified. Exit ObjectDB cleanup warnings remain in some test harnesses; not suppressed.

## Paths and production
Built-in imagegen edit mode, transparent output. Full prompts: art_sources/crusher_launcher_v14/prompts.md and art_sources/crusher_dive_v15/prompts.md. Source images, same-scale comparisons and packing manifests retained. Runtime assets: godot/assets/characters/enemy01/animations/unified_launcher_v14 and unified_dive_v15. Packing performs alpha isolation and uniform whole-pose scaling only. No per-frame anatomical edits.

Existing unrelated working-tree modifications preserved. No push/public deployment or actual smartphone-device play this phase. Overall project completion is not claimed.
