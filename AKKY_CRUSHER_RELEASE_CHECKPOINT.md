# AKKY / Crusher release checkpoint — 2026-10-04

Original branch: codex/directional-combat-20261003; original HEAD 35198386d60b82c8dd1c28f1f07638ac4cbdf5c8.
Release branch: codex/akky-crusher-release-20261004, isolated worktree .pair_release_20261004.
Integrated main: b05bb8c0038fc62685e1a2a30193119234c46157; merge 6a10fda.

## Release scope

One-on-one AKKY versus Crusher: facing-relative ground P/K variants, air P/K/dive, four directional throws and paired victim motions, hit-confirmed cancels/launcher air route, anti-air and evasive attacks, special reversal/interrupt and guard, dedicated air guard and basic/light/heavy/high/low/launch/wall/bounce receiver motion. Existing costume and reviewed proportions preserved. See earlier motion/checkpoint documents for source selection and rejected art. No crowd gameplay is included.

Mobile callback test covers direction→action delays, holding directions, both facings, expiry, jump→air K and pending-tap cleanup. Buffer remains 150ms/history 600ms. Test callback events are not physical phone touch certification.

Latest main's Web save directory, cache-versioned build, local authorized theme audio and iPhone memory improvements preserved. Pair atlas lists are also lazy paths. Fixed the inherited throw override signature to forward optional special damage, retaining Cross's existing grapple.

Added nine pair checks to the existing Pages CI so release builds fail on missing completion markers, script errors or combat failures. Only owned files staged; original uncommitted imports and work remain untouched in the original worktree.

## Verification and remaining phases

Original-worktree headless checks passed: directional attacks/throws, air combo/guard, Crusher throw AI, special guard, receiver routing, wall bounce and opening flow. Merged worktree checks and CI/public evidence are recorded with their actual status, not assumed from this list. Prior scripted render checks cover both facings and dedicated receiver frames; hands-on phone play and long-term balance remain unverified.

Requested sequence: publish AKKY/Crusher first; then configure and publish Gou and Seiya; then proceed to Stage 2. Their existing specials/source art are preserved and must be audited before expansion. Stage 2 and other protagonist work are not included in this first release.
