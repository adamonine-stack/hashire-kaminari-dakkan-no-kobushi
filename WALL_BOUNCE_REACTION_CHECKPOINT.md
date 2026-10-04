# AKKY / Crusher wall and ground-bounce checkpoint

Branch: codex/directional-combat-20261003
Start HEAD: a0eda7ac661dfd8286123fedfdc59040435ece59

Dedicated sources: art/dedicated_pair_v1/sources/wall_hit_key.png, wall_hit_strip.png, ground_bounce_key.png, ground_bounce_strip.png. Key poses were compared before strip production. Four transparent atlases expose wall_hit/wall_fall and ground_impact/ground_bounce for both fighters. Uniform source packing, fixed actor Sprite scale and pivot; no runtime frame scaling. The previously shortened Crusher prone artwork is unchanged.

Both Down Throws now request one ground bounce: 0.07s contact, 0.025s hitstop, velocity (0,-160), approximately 15px rise, then existing long down and wake-up. Data defaults to zero; count is clamped to one and forces bounded. HurtBox/throw eligibility stay disabled through bounce; no extra damage or combo reset. KO and reset cannot retain bounce state.

AKKY Thunder Drive -> Crusher uses dedicated wall impact/fall. AKKY has the same receiver support, tested using a debug wall-enabled packet. Crusher Fault Break keeps its existing non-wall trajectory. Existing special chip damage, move timing and balance are preserved.

Checks passed: wall_bounce_check (both actors and facings, real physics down throws, wall contacts, wake-up, KO, bounded count/force); directional_throws_check; crusher_throw_motion_check; special_reversal_check; special_launch_reaction_check headless across nine enemies; dive_kick_check; dedicated_special_guard_check; crusher_down_correction_check; stage1_regression.

Rendered review: wall_bounce_visual_review produced 12 standing/wall/contact/bounce/down frames across both facings, visually inspected. These are posed runtime review frames, not manual gameplay. Full rendered special-launch test is separately recorded in wall_bounce_rendered_final.log. The first rendered capture attempt missed a short wall phase while awaiting an extra process frame; capture now draws the observed physics phase directly. Windows certificate-store warning remains environmental.

No phone hardware, hands-on touch session, public deployment or performance benchmark was performed in this checkpoint. General high/low/heavy receiver coverage remains work for the following phase. Existing uncommitted imports, UID files, logs and user-data folders are excluded from this commit.

Rendered full-roster result: 137 screenshots; wall/fall assertions passed after synchronous capture. Two Seiya-right velocity assertions still failed in the rendered run; headless full-roster failures=[] and Stage1 failures=[]. This rendered-only Seiya issue is unresolved and is not counted as a passed test. No Seiya combat data or motion was changed.
