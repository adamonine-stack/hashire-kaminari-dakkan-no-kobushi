# Crusher directional ground kicks

Start branch: codex/stage1-gou-seiya-20261007
Start HEAD: 88eb1ec4d67939e7a75a752286a933a7593e734f

## Completed
Forward K v12 and Back K v13 now use dedicated five-frame clips with detailed skin, face and outfit matching the official standing reference. Source-sheet calibration uses standing opaque height 228 pixels and ground baseline 260 in 400 x 280 cells. Uniform source-sheet scaling only; no per-frame physique reshaping. Contact stays runtime frame 2. Forward advances, Back retreats and retains the existing reduced hurtbox window.

Hitboxes follow elevated boots: Forward (110,-130), 70 x 48; Back (118,-128), 70 x 42. Damage, startup/active/recovery, movement distance, combo properties and AI tags are preserved. Existing fighter extras route to the new atlases, avoiding duplicate legacy clips. Each texture is 1600 x 560, no extra runtime nodes/effects.

## Evidence
- Key pose and all five packed poses visually compared with formal standing for each move.
- Actual Battle scene attacker physics and Area2D collision: two moves x both facings x hit/guard/whiff = 12 cases, headless and native passed. Target physics frozen as a controlled fixture. Scale, sprite origin, active contact, mirror, damage, guard recoil, recovery and movement direction checked.
- Guard uses existing apply_guard_recoil, which cancels the attack into recoil rather than ordinary AttackPhase.RECOVERY; test explicitly validates this existing behavior.
- Native full four-character attack review: 548 frames, failures=[]. Automated atlas bounds/scale/mirror check, not manual review of every frame.
- Directional attacks, remaining heroes, Stage 1 regression, Crusher air attack checks: failures=[].
- Native images: audit_evidence/crusher_ground_kicks_live. Source/design comparisons: art_sources/crusher_forward_kick_v12 and crusher_back_kick_v13. Built-in imagegen edit mode and prompt specifications recorded in each source folder.

## Boundaries / next work
No actual smartphone-device play or public deployment this phase. Dedicated controlled native rendering is not a full manual combat session. Unrelated pre-existing working-tree changes preserved. Crusher Down P and Dive K skin/design consistency remain for the next bundled pass. Full project completion/publication is not claimed.
