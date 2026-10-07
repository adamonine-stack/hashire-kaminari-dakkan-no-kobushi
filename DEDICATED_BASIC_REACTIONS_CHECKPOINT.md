# Dedicated light / high / low receiver checkpoint

Branch at start/end: codex/directional-combat-20261003
Start HEAD: 340420e115b523544b40a744eaf160dcf23043ed

AKKY and Crusher each now have separate three-frame damage_light, damage_high, damage_low source art. Small shoulder flinch, face/chin recoil, and hip/knee buckle distinguish the three reactions. Dedicated damage_heavy from the previous checkpoint remains separate. Existing generic animations elsewhere and other characters are not claimed to be fully authored.

Workflow: each reaction's paired key pose was made and compared to the standing runtime design, then its three-frame sheet produced and visually inspected. Original low sheet had top-Crusher clipping risk and was rejected; corrected low sheet restores complete head and margins. Light preview appeared to contain glow; inspection proved surrounding RGB pixels had alpha0 and no background was rendered. Original reviewed light source retained. Unselected generated variants are not runtime references.

Selected art sources (outside Godot): art/dedicated_pair_v1/sources/{light_hit,high_hit,low_hit}_{key,strip}.png. Six runtime atlas PNG/import/tres groups in godot/assets/characters/dedicated_pair_v1. Each clip: three frames at14fps, non-looping. AKKY atlas960x224 with320x224 cells, Crusher1200x280 with400x280 cells. Packing uses one uniform factor per actor per motion, shared root; no frame-by-frame scale changes or Sprite transform hacks. Alpha-visible bottoms: AKKY207 in all nine frames; Crusher258-259 (one pixel rounding). No cropped anatomy or cell-edge overlap in packed images.

Two fighter definitions append these resources to extra_motion_atlases; shared receiver selection, attack damage/timing/hitboxes/guard/save/stage behavior unchanged this phase. No new effect or particle nodes. PAIR_REACTION_INVENTORY.json refreshed from actual runtime SpriteFrames. receiver_routing_check now requires all light/heavy/high/low clips to contain three frames from the matching actor-specific source, not just an animation name.

Passed headless checks after integration: RECEIVER_ROUTING_CHECK; DEDICATED_SPECIAL_GUARD_CHECK; DIRECTIONAL_ATTACKS_CHECK; AIR_COMBO_CHECK; WALL_BOUNCE_CHECK; STAGE1_REGRESSION, all failures=[]. Rendered RECEIVER_ROUTING_CHECK failures=[] covers seven packet cases per actor/facing, actual receive_attack -> Sprite selection, every clip frame with fixed scale/pivot. Inspected all18 new packed source frames and12 runtime contact screenshots (two actors x three reactions x two facings). Controlled rendered snapshots are distinct from hands-on gameplay. Windows root-certificate warning remains environmental.

No new Input, Combo, Throw, Special, AI, Gauge, Save schema or gameplay balance in this phase. Smartphone hardware/manual touch, deployment, full multi-enemy rendered play and GPU profiling remain unverified. Start/end git status saved in next_hit_start_status.txt / next_hit_end_status.txt; inherited imports, UID files, logs, evidence and user-data excluded from commit.

Remaining work: full AKKY/Crusher motion coverage audit in ordinary play (not just source registration), next-state transitions/KO and multi-enemy render flow, followed by mobile-equivalent input regression and wider character rollout. This checkpoint completes separate basic receiver source art for this pair, not the entire 79-item combat expansion.
