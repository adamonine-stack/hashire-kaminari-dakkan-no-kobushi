# Crusher anti-air design integration

Branch: codex/stage1-gou-seiya-20261007. Start HEAD:dfef494.

Old crusher_upper atlas skin/face density differed from official standing and new launcher. Replaced enemy extra atlas route with unified_anti_air_v16. Reused already reviewed launcher_v14 source cells at unchanged scale: [4,2,3,0], high guard -> rise -> contact -> standing. Ground launcher remains [1,2,3,4,0] with deeper load. Shared natural uppercut contact art, distinct move sequence; no newly drawn sprite or claim of all-unique pose artwork.

Contact runtime frame2, 400x280 cells, ground baseline260, calibration opaque height228. Attack damage/startup/active/recovery, hitbox/hurtbox, launch velocity and AI properties unchanged. One small Resource uses existing texture, no new runtime texture/node/effect overhead.

Headless and native checks: crusher_anti_air_live_check both facings hit/guard/whiff, actual Area2D controlled receiver, fixed scale/origin/contact, recovery and upward reaction passed. crusher_anti_air_pair_check true airborne target physical collision and grounded launcher/landing/control passed both facings. Native source image viewed for right-facing contact; pose source sheets previously reviewed with official standing. Audio Dummy; no audio/device-play claims. Some harness exits retain ObjectDB cleanup warnings.

Full attack frame/headless and Stage1 regression/situation results recorded in phase_anti logs. No public deployment. Unrelated working-tree changes retained.

Next release gate: Stage1 full battle and mobile-equivalent visual/navigation acceptance, followed by Web deployment and deployed verification. Full-frame artistic review across all actors is not automatically proved by fixed-scale tests.
