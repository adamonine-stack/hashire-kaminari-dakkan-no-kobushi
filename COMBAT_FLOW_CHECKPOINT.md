# Combat flow checkpoint — 2026-10-04

Branch: `codex/directional-combat-20261003`
Starting HEAD: `3639d5faf66e805f6182acab9608c657e19af6ad`

## Changes

- Ordinary sweep contact retains the dedicated low-hit receiver pose during existing hitstop, then follows existing knockback/down/wake-up. Special and wall reaction priorities remain intact.
- Ordinary KO disables the HurtBox after resetting knockdown state, including actors outside the campaign enemy-manager slot.
- Disabled AI now also disables legacy guard and throw fallbacks. Active profile AI remains unchanged.
- Added `godot/tests/combat_flow_check.gd`: starts actual moves and waits for Area2D collision callbacks instead of injecting damage. Both AKKY and Crusher use P/forward P/K/down K in both directions (16 cases), with reaction selection, fixed Sprite transform, recovery and hitbox cleanup assertions. Two receiving Crusher actors verify independent contacts/recovery in both directions; an extra actor verifies KO exclusion.

## Evidence

Headless combat flow: `combat_flow_final.log`, `COMBAT_FLOW_CHECK failures=[]`.
Rendered combat flow: `combat_flow_rendered_final.log`; screenshots in `combat_flow_evidence/`. During screenshots actor physics is temporarily paused and the visual state refreshed before frame_post_draw; this is scripted rendering, not hands-on gameplay.

Regression markers passed: STAGE1_REGRESSION, WALL_BOUNCE_CHECK, SPECIAL_REVERSAL_CHECK, AIR_COMBO_CHECK, CRUSHER_SITUATION_CHECK, CRUSHER_THROW_AI_CHECK (`failures=[]`). Incorrect historical test filenames were corrected; failed script-load attempts are not verification evidence.

## Boundaries

Campaign enemy progression is unchanged and remains sequential. The additional test-owned enemy verifies multi-target damage/recovery/KO, not simultaneous multiple-enemy AI. No smartphone hardware, touch input or public deployment was verified in this checkpoint. Character source art, proportions and scale were not changed. Windows root-certificate environment warnings remain unrelated to these combat checks. Inherited imports, generated UIDs and previous uncommitted work are excluded from the commit.
