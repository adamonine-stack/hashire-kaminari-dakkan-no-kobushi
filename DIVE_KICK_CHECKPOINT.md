# AKKY / Crusher dedicated dive-kick checkpoint

## Scope
Branch codex/directional-combat-20261003; starting HEAD 96bdab8b2341979350a24f7f1a6cdfe29e6eb193. Existing command buffer, MoveData, shared player/enemy physics, attack collision, defense, and atlas routing extended. No input-map/UI changes. Other characters retain default zero dive/landing recovery. Prior uncommitted imports and user work excluded from commit.

## Moves and motion
Both fighters: airborne Down + K, priority120 over generic Air K; standing Down K unchanged. Startup0.16s/active0.16s/recovery0.32s, guardable overhead, no cancel targets. Dedicated tuck and descending-contact poses plus grounded landing pose, with contact pose synchronized to attack phase. Damage uses each fighter existing kick power (current Stage1 AKKY15 / Crusher8, subject to normal scaling). Knockback(130,-40), hitstun0.24s, hitstop0.045s, hitbox48x46 at(42,-24) before existing battle scale.

After startup, local forward85/down520 velocity; movement and height determine collisions. Land recovery0.32s blocks movement, jump, P/K, guard, throw and special; hurtbox stays vulnerable. Pending landing data survives natural aerial move end or attacker guard recoil. Incoming hit/down/KO cancels pending recovery through existing cancellation path. Fixed Sprite scale and origin; no per-frame fitting. Sources outside Godot export; atlas AKKY960x224 / Crusher1200x280, no added particles or recurring instance allocations.

Fixed old landing cleanup condition: evaluating an airborne predicate after move_and_slide had excluded newly grounded actors. Snapshot pre-move airborne attack, then clean up hitbox on landing. Normal air attacks keep zero extra recovery. Development debug label adds landing seconds only when debug display enabled.

## AI
Crusher chooses dive from data when airborne against a grounded unguarded opponent whose recovery has been observed for the profile reaction interval (0.22s default), within90px and late ascent/descent. Otherwise ordinary jump kick remains available. No player input events inspected.

## Validation
DIVE_KICK_CHECK failures=[]: both actors/facings, collision-based hit/guard/whiff, mirrored dive, grounded rejection, landing locks and live movement/jump/guard lock, real punishment, high-altitude move end preserving recovery, cleanup on damage; released direction with120ms history, actual mobile Down button then K after7physics ticks, AI early/late observed recovery selection.

DIVE_KICK_VISUAL_EXPORT_OK: actual Battle scene rendered startup/contact/landing/standing in both facings; fixed scale/anchor and body/clothing/head proportions inspected. Rendered evidence in dive_kick_evidence. Air combo, air guard, directional throws, special reversal and Crusher situational AI regression all failures=[]. Stage1 clear/gameover regression passed during prior down correction with the same dive core; not re-run solely for debug text. Root certificate-store warning persists in local Godot, unrelated to scripts.

These are scripted live physics/rendering/mobile UI handler checks. Manual phone touch play, subjective balance testing, public web release and full all-character rollout remain unconfirmed. The two-character full motion/reaction inventory still has remaining receiver/special-guard coverage to audit.
