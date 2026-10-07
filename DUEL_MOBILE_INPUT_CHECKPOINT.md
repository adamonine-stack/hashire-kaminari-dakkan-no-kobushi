# One-on-one mobile input checkpoint — 2026-10-04

Branch: codex/directional-combat-20261003 (unchanged).
Starting HEAD: 6360a53ad44e851d488e70d872b438f39a475b3e.

## Scope and changes

The user confirmed one-on-one gameplay. Removed test-owned extra opponents from combat_flow_check.gd. Campaign progression remains unchanged. No crowd combat or multiple-enemy AI is introduced.

Fixed mobile_controls.release_all_touch_inputs: pending tap actions (P/K/Throw/Special/Pause and jump) now release immediately as well as held directions/guard. Previously taps waited for deferred release and could survive a cleanup/reset between physics and render frames. The rendered input test exposed an old P interfering with a subsequent jump. Input timing, moves, character art and proportions are unchanged.

## Verification

New duel_mobile_input_check.gd emits existing mobile Button signals through real callbacks, Input actions and normal fighter physics sampling. It does not inject history, manually dispatch commands or substitute move data.

Both facings: forward/back/down × P/K × held/released direction = 24 cases. Direction precedes action by 8 physics ticks (about 133ms at 60Hz); released-direction cases leave 6 ticks (about 100ms) between release and action. Two expired-direction cases require neutral P; two jump→Air K cases use UI buttons. A pending P is explicitly pressed then cleared immediately to verify cleanup without waiting for deferred release. Current buffer remains 150ms/history 600ms.

Passed markers:
- duel_mobile_input_final.log: DUEL_MOBILE_INPUT_CHECK failures=[] (headless).
- duel_mobile_input_rendered_final.log: DUEL_MOBILE_INPUT_CHECK failures=[] (rendered execution).
- duel_combat_flow_check.log: COMBAT_FLOW_CHECK failures=[] (16 one-on-one actual-contact cases).
- duel_stage1_regression.log: STAGE1_REGRESSION failures=[] (including KO/progression).

This verifies callback/Input/physics integration, not OS touch-event delivery, real thumb ergonomics or smartphone hardware. Rendered execution is not hands-on gameplay. No public deployment performed. The Windows root-certificate error remains environmental. Inherited imports, UIDs and uncommitted files are excluded from the commit.
