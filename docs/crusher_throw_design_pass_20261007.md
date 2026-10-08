# Crusher remaining throw design pass — 2026-10-07

- Branch: `codex/stage1-gou-seiya-20261007`; starting HEAD: `ea33963`.
- Scope: normal, forward and back throw release art only. Earlier start/hold/down overrides remain in place. Combat damage, timing, position exchange and hold offset are unchanged.
- Reused the saved reference-generated candidate rather than generating another sheet. Calibrated every frame with one uniform scale (228 / 363), nearest-neighbor resampling, 400×280 cells and planted-foot baseline 260. No independent limb/body resizing or color edits.
- Adjacent source figures had overlapping bounding rectangles. Connected-component masks isolate each complete sprite while retaining original RGBA/soft edges; this avoids mixing a neighboring bandana or boot into the atlas.
- Added a supplemental atlas last in Crusher's existing atlas list, overriding only `crusher_throw_neutral_release`, `crusher_throw_forward_release`, `crusher_throw_back_release`. Existing source resources are preserved.
- Native renderer comparison: official standing and both frames of each release, eight poses total. Assertions check constant runtime sprite scale and selection of the new atlas. Intel Iris Xe / Forward Mobile rendered successfully. The pose changes alter visible height naturally; frames are not enlarged to fill a fixed height.

## Verification

- `crusher_throw_motion_check`: failures=[]; four throws, both facings, release/down/wake-up and single damage.
- `stage1_hero_throw_live_check`: Gou and Seiya each failures=[]; 32 combined real-physics cases, both attacker roles, both facings, four throw directions. Hero touch-handler direction precedes action by approximately 116 ms.
- Native Seiya/Crusher live test: failures=[]; inspected the three new release screens and captured hold/release in both facings.
- `stage1_regression`: failures=[] (KO, character continuation, game-over/retry flow).
- No physical smartphone or public browser gameplay test in this phase. Native scripted gameplay is not manual play.
- Editor import returned success but reported the existing safe-save permission warning; headless hero tests reported ObjectDB exit leaks. These are unresolved warnings, not clean-run claims.

## Remaining work

Other Crusher victim/air/reaction clips and Gou/Seiya dedicated motions still require design consistency work. This phase improves the throw attacker's material and proportion continuity; it does not certify every motion or complete Stage 1. No publication occurred. Existing unrelated dirty files were preserved and excluded from the phase commit.

## Files

New: packer, selected source sheet, source/native review images, supplemental atlas PNG/TRES/manifest, native review test, this report.
Changed: Crusher enemy definition and source review status. Generated import metadata and QA logs are excluded.
