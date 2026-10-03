# 必殺技引き継ぎ・実参照Motion一覧（2026-10-03）

実Playerシーンへ12定義を読み込み、統合後のSpriteFramesとMoveDataから出力。登録名の有無は機能の有無を断定しない。固有名による方向Attack/Throwは別途接触経路の照合が必要。専用性は原画比較で確定し、同じFrameの共有を新規Motionとして数えない。

## アッキー

技: `player1_special_thunder_drive` / 1接触Damage: 23 / 倍率: 1.50 / Cooldown: 4.20s

| 必殺技Motion | 実Clip | Frame数 | 通常P/K等との共有 |
|---|---|---:|---|
| Special Startup | akky_reversal_startup | 2 | [] |
| Special Attack | akky_reversal_elbow | 1 | [] |
| Special Finish | akky_reversal_finish | 1 | [] |

| 要求Motion | 登録名候補 | 現在の参照 |
|---|---|---|
| P | ["punch_1", "punch"] | punch_1 (4 Frame) |
| →P | ["punch_forward"] | 固有名/入力接続を要調査 |
| ←P | ["punch_backward"] | 固有名/入力接続を要調査 |
| ↓P | ["crouch_punch"] | crouch_punch (4 Frame) |
| K | ["kick_1", "kick"] | kick_1 (6 Frame) |
| →K | ["kick_forward"] | 固有名/入力接続を要調査 |
| ←K | ["kick_backward"] | 固有名/入力接続を要調査 |
| ↓K | ["crouch_kick"] | crouch_kick (4 Frame) |
| Air P | ["jump_punch"] | jump_punch (4 Frame) |
| Air K | ["jump_kick"] | jump_kick (4 Frame) |
| ↓Air K | ["jump_kick_down"] | 固有名/入力接続を要調査 |
| Throw | ["throw_start", "throw"] | throw (4 Frame) |
| →Throw | ["throw_forward"] | 固有名/入力接続を要調査 |
| ↓Throw | ["throw_down"] | 固有名/入力接続を要調査 |
| ←Throw | ["throw_backward"] | 固有名/入力接続を要調査 |
| Light Hit | ["damage_light"] | damage_light (4 Frame) |
| Heavy Hit | ["damage_heavy"] | damage_heavy (4 Frame) |
| High Hit | ["damage_high"] | damage_high (4 Frame) |
| Low Hit | ["damage_low"] | damage_low (4 Frame) |
| Launch Hit | ["launch_hit"] | 固有名/入力接続を要調査 |
| Air Hit | ["air_hit"] | 固有名/入力接続を要調査 |
| Knockback | ["knockback"] | knockback (4 Frame) |
| Ground Bounce | ["ground_bounce"] | 固有名/入力接続を要調査 |
| Knockdown | ["knockdown"] | knockdown (4 Frame) |
| Throw Front Damage | ["throw_front_damage"] | 固有名/入力接続を要調査 |
| Throw Down Damage | ["throw_down_damage"] | 固有名/入力接続を要調査 |
| Throw Back Damage | ["throw_back_damage"] | 固有名/入力接続を要調査 |
| Special Hit | ["special_hit"] | special_hit (2 Frame) |
| Special Knockback | ["special_knockback"] | special_knockback (2 Frame) |
| Special Knockdown | ["special_knockdown"] | special_knockdown (1 Frame) |
| Special Guard | ["special_guard"] | special_guard (2 Frame) |

技別被Damage登録: `{ "shadow_slip_counter": { "hit": "received_shadow_counter_hit", "airborne": "received_shadow_counter_air", "down": "received_shadow_counter_down" }, "crusher_fault_break": { "hit": "received_crusher_hammer_hit", "airborne": "received_crusher_hammer_air", "down": "received_crusher_hammer_down" } }`

## ごう

技: `player2_special_iron_breaker` / 1接触Damage: 38 / 倍率: 1.50 / Cooldown: 5.20s

| 必殺技Motion | 実Clip | Frame数 | 通常P/K等との共有 |
|---|---|---:|---|
| Special Startup | gou_reversal_startup | 2 | [] |
| Special Attack | gou_reversal_breaker | 1 | [] |
| Special Finish | gou_reversal_finish | 1 | [] |

| 要求Motion | 登録名候補 | 現在の参照 |
|---|---|---|
| P | ["punch_1", "punch"] | punch_1 (6 Frame) |
| →P | ["punch_forward"] | 固有名/入力接続を要調査 |
| ←P | ["punch_backward"] | 固有名/入力接続を要調査 |
| ↓P | ["crouch_punch"] | crouch_punch (6 Frame) |
| K | ["kick_1", "kick"] | kick_1 (6 Frame) |
| →K | ["kick_forward"] | 固有名/入力接続を要調査 |
| ←K | ["kick_backward"] | 固有名/入力接続を要調査 |
| ↓K | ["crouch_kick"] | crouch_kick (6 Frame) |
| Air P | ["jump_punch"] | jump_punch (3 Frame) |
| Air K | ["jump_kick"] | jump_kick (3 Frame) |
| ↓Air K | ["jump_kick_down"] | 固有名/入力接続を要調査 |
| Throw | ["throw_start", "throw"] | throw_start (2 Frame) |
| →Throw | ["throw_forward"] | 固有名/入力接続を要調査 |
| ↓Throw | ["throw_down"] | 固有名/入力接続を要調査 |
| ←Throw | ["throw_backward"] | 固有名/入力接続を要調査 |
| Light Hit | ["damage_light"] | damage_light (3 Frame) |
| Heavy Hit | ["damage_heavy"] | damage_heavy (3 Frame) |
| High Hit | ["damage_high"] | damage_high (3 Frame) |
| Low Hit | ["damage_low"] | damage_low (3 Frame) |
| Launch Hit | ["launch_hit"] | 固有名/入力接続を要調査 |
| Air Hit | ["air_hit"] | 固有名/入力接続を要調査 |
| Knockback | ["knockback"] | knockback (3 Frame) |
| Ground Bounce | ["ground_bounce"] | 固有名/入力接続を要調査 |
| Knockdown | ["knockdown"] | knockdown (3 Frame) |
| Throw Front Damage | ["throw_front_damage"] | 固有名/入力接続を要調査 |
| Throw Down Damage | ["throw_down_damage"] | 固有名/入力接続を要調査 |
| Throw Back Damage | ["throw_back_damage"] | 固有名/入力接続を要調査 |
| Special Hit | ["special_hit"] | 固有名/入力接続を要調査 |
| Special Knockback | ["special_knockback"] | 固有名/入力接続を要調査 |
| Special Knockdown | ["special_knockdown"] | 固有名/入力接続を要調査 |
| Special Guard | ["special_guard"] | 固有名/入力接続を要調査 |

技別被Damage登録: `{ "shadow_slip_counter": { "hit": "received_shadow_counter_hit", "airborne": "received_shadow_counter_air", "down": "received_shadow_counter_down" }, "crusher_fault_break": { "hit": "received_crusher_hammer_hit", "airborne": "received_crusher_hammer_air", "down": "received_crusher_hammer_down" } }`

## せいや

技: `player3_special_clear_counter` / 1接触Damage: 13 / 倍率: 1.00 / Cooldown: 3.60s

第9ステージ継承仕様: 各段1倍、両段成功で2倍。初段命中後の確定追撃を保持。

| 必殺技Motion | 実Clip | Frame数 | 通常P/K等との共有 |
|---|---|---:|---|
| Special Startup | seiya_two_start | 1 | [] |
| Special Attack | seiya_two_somersault | 3 | [] |
| Special Finish | seiya_two_finish | 1 | [] |

| 要求Motion | 登録名候補 | 現在の参照 |
|---|---|---|
| P | ["punch_1", "punch"] | punch_1 (6 Frame) |
| →P | ["punch_forward"] | 固有名/入力接続を要調査 |
| ←P | ["punch_backward"] | 固有名/入力接続を要調査 |
| ↓P | ["crouch_punch"] | crouch_punch (6 Frame) |
| K | ["kick_1", "kick"] | kick_1 (6 Frame) |
| →K | ["kick_forward"] | 固有名/入力接続を要調査 |
| ←K | ["kick_backward"] | 固有名/入力接続を要調査 |
| ↓K | ["crouch_kick"] | crouch_kick (6 Frame) |
| Air P | ["jump_punch"] | jump_punch (3 Frame) |
| Air K | ["jump_kick"] | jump_kick (3 Frame) |
| ↓Air K | ["jump_kick_down"] | 固有名/入力接続を要調査 |
| Throw | ["throw_start", "throw"] | throw_start (2 Frame) |
| →Throw | ["throw_forward"] | 固有名/入力接続を要調査 |
| ↓Throw | ["throw_down"] | 固有名/入力接続を要調査 |
| ←Throw | ["throw_backward"] | 固有名/入力接続を要調査 |
| Light Hit | ["damage_light"] | damage_light (3 Frame) |
| Heavy Hit | ["damage_heavy"] | damage_heavy (3 Frame) |
| High Hit | ["damage_high"] | damage_high (3 Frame) |
| Low Hit | ["damage_low"] | damage_low (3 Frame) |
| Launch Hit | ["launch_hit"] | 固有名/入力接続を要調査 |
| Air Hit | ["air_hit"] | 固有名/入力接続を要調査 |
| Knockback | ["knockback"] | knockback (3 Frame) |
| Ground Bounce | ["ground_bounce"] | 固有名/入力接続を要調査 |
| Knockdown | ["knockdown"] | knockdown (3 Frame) |
| Throw Front Damage | ["throw_front_damage"] | 固有名/入力接続を要調査 |
| Throw Down Damage | ["throw_down_damage"] | 固有名/入力接続を要調査 |
| Throw Back Damage | ["throw_back_damage"] | 固有名/入力接続を要調査 |
| Special Hit | ["special_hit"] | 固有名/入力接続を要調査 |
| Special Knockback | ["special_knockback"] | 固有名/入力接続を要調査 |
| Special Knockdown | ["special_knockdown"] | 固有名/入力接続を要調査 |
| Special Guard | ["special_guard"] | 固有名/入力接続を要調査 |

技別被Damage登録: `{ "shadow_slip_counter": { "hit": "received_shadow_counter_hit", "airborne": "received_shadow_counter_air", "down": "received_shadow_counter_down" }, "crusher_fault_break": { "hit": "received_crusher_hammer_hit", "airborne": "received_crusher_hammer_air", "down": "received_crusher_hammer_down" } }`

## クラッシャー

技: `crusher_fault_break` / 1接触Damage: 12 / 倍率: 1.50 / Cooldown: 6.00s

| 必殺技Motion | 実Clip | Frame数 | 通常P/K等との共有 |
|---|---|---:|---|
| Special Startup | crusher_hammer_startup | 2 | [] |
| Special Attack | crusher_hammer_active | 1 | [] |
| Special Finish | crusher_hammer_finish | 1 | [] |

| 要求Motion | 登録名候補 | 現在の参照 |
|---|---|---|
| P | ["punch_1", "punch"] | punch_1 (3 Frame) |
| →P | ["punch_forward"] | 固有名/入力接続を要調査 |
| ←P | ["punch_backward"] | 固有名/入力接続を要調査 |
| ↓P | ["crouch_punch"] | crouch_punch (3 Frame) |
| K | ["kick_1", "kick"] | kick_1 (3 Frame) |
| →K | ["kick_forward"] | 固有名/入力接続を要調査 |
| ←K | ["kick_backward"] | 固有名/入力接続を要調査 |
| ↓K | ["crouch_kick"] | crouch_kick (3 Frame) |
| Air P | ["jump_punch"] | jump_punch (4 Frame) |
| Air K | ["jump_kick"] | jump_kick (4 Frame) |
| ↓Air K | ["jump_kick_down"] | 固有名/入力接続を要調査 |
| Throw | ["throw_start", "throw"] | throw_start (2 Frame) |
| →Throw | ["throw_forward"] | 固有名/入力接続を要調査 |
| ↓Throw | ["throw_down"] | 固有名/入力接続を要調査 |
| ←Throw | ["throw_backward"] | 固有名/入力接続を要調査 |
| Light Hit | ["damage_light"] | damage_light (2 Frame) |
| Heavy Hit | ["damage_heavy"] | damage_heavy (2 Frame) |
| High Hit | ["damage_high"] | damage_high (2 Frame) |
| Low Hit | ["damage_low"] | damage_low (2 Frame) |
| Launch Hit | ["launch_hit"] | 固有名/入力接続を要調査 |
| Air Hit | ["air_hit"] | 固有名/入力接続を要調査 |
| Knockback | ["knockback"] | 固有名/入力接続を要調査 |
| Ground Bounce | ["ground_bounce"] | 固有名/入力接続を要調査 |
| Knockdown | ["knockdown"] | knockdown (3 Frame) |
| Throw Front Damage | ["throw_front_damage"] | 固有名/入力接続を要調査 |
| Throw Down Damage | ["throw_down_damage"] | 固有名/入力接続を要調査 |
| Throw Back Damage | ["throw_back_damage"] | 固有名/入力接続を要調査 |
| Special Hit | ["special_hit"] | 固有名/入力接続を要調査 |
| Special Knockback | ["special_knockback"] | 固有名/入力接続を要調査 |
| Special Knockdown | ["special_knockdown"] | 固有名/入力接続を要調査 |
| Special Guard | ["special_guard"] | 固有名/入力接続を要調査 |

技別被Damage登録: `{ "player2_special_iron_breaker": { "hit": "received_gou_breaker_hit", "airborne": "received_gou_breaker_air", "down": "received_gou_breaker_down" }, "player1_special_thunder_drive": { "hit": "received_akky_elbow_hit", "airborne": "received_akky_elbow_air", "down": "received_akky_elbow_down", "wall": "received_akky_elbow_wall", "fall": "received_akky_elbow_fall" }, "player3_special_clear_counter": { "hit": "received_seiya_two_lift", "airborne": "received_seiya_two_lift", "down": "received_seiya_two_down", "wall": "received_seiya_two_fly", "fall": "received_seiya_two_fly" } }`

## シャドウボクサー

技: `shadow_slip_counter` / 1接触Damage: 11 / 倍率: 1.50 / Cooldown: 6.00s

| 必殺技Motion | 実Clip | Frame数 | 通常P/K等との共有 |
|---|---|---:|---|
| Special Startup | shadow_counter_startup | 1 | [] |
| Special Attack | shadow_counter_active | 1 | ["kick_1"] |
| Special Finish | shadow_counter_finish | 2 | ["kick_1"] |

| 要求Motion | 登録名候補 | 現在の参照 |
|---|---|---|
| P | ["punch_1", "punch"] | punch_1 (3 Frame) |
| →P | ["punch_forward"] | 固有名/入力接続を要調査 |
| ←P | ["punch_backward"] | 固有名/入力接続を要調査 |
| ↓P | ["crouch_punch"] | crouch_punch (4 Frame) |
| K | ["kick_1", "kick"] | kick_1 (3 Frame) |
| →K | ["kick_forward"] | 固有名/入力接続を要調査 |
| ←K | ["kick_backward"] | 固有名/入力接続を要調査 |
| ↓K | ["crouch_kick"] | crouch_kick (3 Frame) |
| Air P | ["jump_punch"] | jump_punch (4 Frame) |
| Air K | ["jump_kick"] | jump_kick (3 Frame) |
| ↓Air K | ["jump_kick_down"] | 固有名/入力接続を要調査 |
| Throw | ["throw_start", "throw"] | throw_start (1 Frame) |
| →Throw | ["throw_forward"] | 固有名/入力接続を要調査 |
| ↓Throw | ["throw_down"] | 固有名/入力接続を要調査 |
| ←Throw | ["throw_backward"] | 固有名/入力接続を要調査 |
| Light Hit | ["damage_light"] | damage_light (3 Frame) |
| Heavy Hit | ["damage_heavy"] | damage_heavy (4 Frame) |
| High Hit | ["damage_high"] | damage_high (4 Frame) |
| Low Hit | ["damage_low"] | damage_low (3 Frame) |
| Launch Hit | ["launch_hit"] | 固有名/入力接続を要調査 |
| Air Hit | ["air_hit"] | 固有名/入力接続を要調査 |
| Knockback | ["knockback"] | 固有名/入力接続を要調査 |
| Ground Bounce | ["ground_bounce"] | 固有名/入力接続を要調査 |
| Knockdown | ["knockdown"] | knockdown (4 Frame) |
| Throw Front Damage | ["throw_front_damage"] | 固有名/入力接続を要調査 |
| Throw Down Damage | ["throw_down_damage"] | 固有名/入力接続を要調査 |
| Throw Back Damage | ["throw_back_damage"] | 固有名/入力接続を要調査 |
| Special Hit | ["special_hit"] | 固有名/入力接続を要調査 |
| Special Knockback | ["special_knockback"] | 固有名/入力接続を要調査 |
| Special Knockdown | ["special_knockdown"] | 固有名/入力接続を要調査 |
| Special Guard | ["special_guard"] | 固有名/入力接続を要調査 |

技別被Damage登録: `{ "player1_special_thunder_drive": { "hit": "received_akky_elbow_hit", "airborne": "received_akky_elbow_air", "down": "received_akky_elbow_down", "wall": "received_akky_elbow_wall", "fall": "received_akky_elbow_fall" }, "player2_special_iron_breaker": { "hit": "received_gou_breaker_hit", "airborne": "received_gou_breaker_air", "down": "received_gou_breaker_down" }, "player3_special_clear_counter": { "hit": "received_seiya_two_lift", "airborne": "received_seiya_two_lift", "down": "received_seiya_two_down", "wall": "received_seiya_two_fly", "fall": "received_seiya_two_fly" } }`

## マサト・タカハシ

技: `masato_palm_reversal` / 1接触Damage: 9 / 倍率: 1.50 / Cooldown: 6.00s

| 必殺技Motion | 実Clip | Frame数 | 通常P/K等との共有 |
|---|---|---:|---|
| Special Startup | special_startup | 1 | [] |
| Special Attack | special_attack | 3 | [] |
| Special Finish | special_recovery | 3 | ["kick_2"] |

| 要求Motion | 登録名候補 | 現在の参照 |
|---|---|---|
| P | ["punch_1", "punch"] | punch_1 (3 Frame) |
| →P | ["punch_forward"] | 固有名/入力接続を要調査 |
| ←P | ["punch_backward"] | 固有名/入力接続を要調査 |
| ↓P | ["crouch_punch"] | crouch_punch (3 Frame) |
| K | ["kick_1", "kick"] | kick_1 (3 Frame) |
| →K | ["kick_forward"] | 固有名/入力接続を要調査 |
| ←K | ["kick_backward"] | 固有名/入力接続を要調査 |
| ↓K | ["crouch_kick"] | crouch_kick (3 Frame) |
| Air P | ["jump_punch"] | jump_punch (3 Frame) |
| Air K | ["jump_kick"] | jump_kick (3 Frame) |
| ↓Air K | ["jump_kick_down"] | 固有名/入力接続を要調査 |
| Throw | ["throw_start", "throw"] | throw_start (1 Frame) |
| →Throw | ["throw_forward"] | 固有名/入力接続を要調査 |
| ↓Throw | ["throw_down"] | 固有名/入力接続を要調査 |
| ←Throw | ["throw_backward"] | 固有名/入力接続を要調査 |
| Light Hit | ["damage_light"] | damage_light (2 Frame) |
| Heavy Hit | ["damage_heavy"] | damage_heavy (2 Frame) |
| High Hit | ["damage_high"] | damage_high (2 Frame) |
| Low Hit | ["damage_low"] | damage_low (2 Frame) |
| Launch Hit | ["launch_hit"] | 固有名/入力接続を要調査 |
| Air Hit | ["air_hit"] | 固有名/入力接続を要調査 |
| Knockback | ["knockback"] | knockback (2 Frame) |
| Ground Bounce | ["ground_bounce"] | 固有名/入力接続を要調査 |
| Knockdown | ["knockdown"] | knockdown (2 Frame) |
| Throw Front Damage | ["throw_front_damage"] | 固有名/入力接続を要調査 |
| Throw Down Damage | ["throw_down_damage"] | 固有名/入力接続を要調査 |
| Throw Back Damage | ["throw_back_damage"] | 固有名/入力接続を要調査 |
| Special Hit | ["special_hit"] | 固有名/入力接続を要調査 |
| Special Knockback | ["special_knockback"] | 固有名/入力接続を要調査 |
| Special Knockdown | ["special_knockdown"] | 固有名/入力接続を要調査 |
| Special Guard | ["special_guard"] | 固有名/入力接続を要調査 |

技別被Damage登録: `{ "player1_special_thunder_drive": { "hit": "received_akky_elbow_hit", "airborne": "received_akky_elbow_air", "down": "received_akky_elbow_down", "wall": "received_akky_elbow_wall", "fall": "received_akky_elbow_fall" }, "player2_special_iron_breaker": { "hit": "received_gou_breaker_hit", "airborne": "received_gou_breaker_air", "down": "received_gou_breaker_down" }, "player3_special_clear_counter": { "hit": "received_seiya_two_lift", "airborne": "received_seiya_two_lift", "down": "received_seiya_two_down", "wall": "received_seiya_two_fly", "fall": "received_seiya_two_fly" } }`

## レイ・カゲヤマ

技: `rei_dragon_uppercut` / 1接触Damage: 14 / 倍率: 1.50 / Cooldown: 4.20s

| 必殺技Motion | 実Clip | Frame数 | 通常P/K等との共有 |
|---|---|---:|---|
| Special Startup | special_startup | 1 | [] |
| Special Attack | rei_dragon_uppercut | 1 | ["punch_2"] |
| Special Finish | special_recovery | 1 | ["punch_2"] |

| 要求Motion | 登録名候補 | 現在の参照 |
|---|---|---|
| P | ["punch_1", "punch"] | punch_1 (3 Frame) |
| →P | ["punch_forward"] | 固有名/入力接続を要調査 |
| ←P | ["punch_backward"] | 固有名/入力接続を要調査 |
| ↓P | ["crouch_punch"] | crouch_punch (3 Frame) |
| K | ["kick_1", "kick"] | kick_1 (3 Frame) |
| →K | ["kick_forward"] | 固有名/入力接続を要調査 |
| ←K | ["kick_backward"] | 固有名/入力接続を要調査 |
| ↓K | ["crouch_kick"] | crouch_kick (3 Frame) |
| Air P | ["jump_punch"] | jump_punch (3 Frame) |
| Air K | ["jump_kick"] | jump_kick (3 Frame) |
| ↓Air K | ["jump_kick_down"] | 固有名/入力接続を要調査 |
| Throw | ["throw_start", "throw"] | throw_start (1 Frame) |
| →Throw | ["throw_forward"] | 固有名/入力接続を要調査 |
| ↓Throw | ["throw_down"] | 固有名/入力接続を要調査 |
| ←Throw | ["throw_backward"] | 固有名/入力接続を要調査 |
| Light Hit | ["damage_light"] | damage_light (2 Frame) |
| Heavy Hit | ["damage_heavy"] | damage_heavy (2 Frame) |
| High Hit | ["damage_high"] | damage_high (2 Frame) |
| Low Hit | ["damage_low"] | damage_low (2 Frame) |
| Launch Hit | ["launch_hit"] | 固有名/入力接続を要調査 |
| Air Hit | ["air_hit"] | 固有名/入力接続を要調査 |
| Knockback | ["knockback"] | knockback (2 Frame) |
| Ground Bounce | ["ground_bounce"] | 固有名/入力接続を要調査 |
| Knockdown | ["knockdown"] | knockdown (3 Frame) |
| Throw Front Damage | ["throw_front_damage"] | 固有名/入力接続を要調査 |
| Throw Down Damage | ["throw_down_damage"] | 固有名/入力接続を要調査 |
| Throw Back Damage | ["throw_back_damage"] | 固有名/入力接続を要調査 |
| Special Hit | ["special_hit"] | 固有名/入力接続を要調査 |
| Special Knockback | ["special_knockback"] | 固有名/入力接続を要調査 |
| Special Knockdown | ["special_knockdown"] | 固有名/入力接続を要調査 |
| Special Guard | ["special_guard"] | 固有名/入力接続を要調査 |

技別被Damage登録: `{ "player1_special_thunder_drive": { "hit": "received_akky_elbow_hit", "airborne": "received_akky_elbow_air", "down": "received_akky_elbow_down", "wall": "received_akky_elbow_wall", "fall": "received_akky_elbow_fall" }, "player2_special_iron_breaker": { "hit": "received_gou_breaker_hit", "airborne": "received_gou_breaker_air", "down": "received_gou_breaker_down" }, "player3_special_clear_counter": { "hit": "received_seiya_two_lift", "airborne": "received_seiya_two_lift", "down": "received_seiya_two_down", "wall": "received_seiya_two_fly", "fall": "received_seiya_two_fly" } }`

## クロス・ムラサメ

技: `cross_muei` / 1接触Damage: 11 / 倍率: 1.50 / Cooldown: 4.20s

| 必殺技Motion | 実Clip | Frame数 | 通常P/K等との共有 |
|---|---|---:|---|
| Special Startup | special_startup | 2 | [] |
| Special Attack | cross_muei | 1 | [] |
| Special Finish | special_recovery | 2 | ["kick_1"] |

| 要求Motion | 登録名候補 | 現在の参照 |
|---|---|---|
| P | ["punch_1", "punch"] | punch_1 (3 Frame) |
| →P | ["punch_forward"] | 固有名/入力接続を要調査 |
| ←P | ["punch_backward"] | 固有名/入力接続を要調査 |
| ↓P | ["crouch_punch"] | crouch_punch (3 Frame) |
| K | ["kick_1", "kick"] | kick_1 (3 Frame) |
| →K | ["kick_forward"] | 固有名/入力接続を要調査 |
| ←K | ["kick_backward"] | 固有名/入力接続を要調査 |
| ↓K | ["crouch_kick"] | crouch_kick (3 Frame) |
| Air P | ["jump_punch"] | jump_punch (3 Frame) |
| Air K | ["jump_kick"] | jump_kick (3 Frame) |
| ↓Air K | ["jump_kick_down"] | 固有名/入力接続を要調査 |
| Throw | ["throw_start", "throw"] | throw_start (1 Frame) |
| →Throw | ["throw_forward"] | 固有名/入力接続を要調査 |
| ↓Throw | ["throw_down"] | 固有名/入力接続を要調査 |
| ←Throw | ["throw_backward"] | 固有名/入力接続を要調査 |
| Light Hit | ["damage_light"] | damage_light (2 Frame) |
| Heavy Hit | ["damage_heavy"] | damage_heavy (2 Frame) |
| High Hit | ["damage_high"] | damage_high (2 Frame) |
| Low Hit | ["damage_low"] | damage_low (2 Frame) |
| Launch Hit | ["launch_hit"] | 固有名/入力接続を要調査 |
| Air Hit | ["air_hit"] | 固有名/入力接続を要調査 |
| Knockback | ["knockback"] | knockback (2 Frame) |
| Ground Bounce | ["ground_bounce"] | 固有名/入力接続を要調査 |
| Knockdown | ["knockdown"] | knockdown (3 Frame) |
| Throw Front Damage | ["throw_front_damage"] | 固有名/入力接続を要調査 |
| Throw Down Damage | ["throw_down_damage"] | 固有名/入力接続を要調査 |
| Throw Back Damage | ["throw_back_damage"] | 固有名/入力接続を要調査 |
| Special Hit | ["special_hit"] | 固有名/入力接続を要調査 |
| Special Knockback | ["special_knockback"] | 固有名/入力接続を要調査 |
| Special Knockdown | ["special_knockdown"] | 固有名/入力接続を要調査 |
| Special Guard | ["special_guard"] | 固有名/入力接続を要調査 |

技別被Damage登録: `{ "player1_special_thunder_drive": { "hit": "received_akky_elbow_hit", "airborne": "received_akky_elbow_air", "down": "received_akky_elbow_down", "wall": "received_akky_elbow_wall", "fall": "received_akky_elbow_fall" }, "player2_special_iron_breaker": { "hit": "received_gou_breaker_hit", "airborne": "received_gou_breaker_air", "down": "received_gou_breaker_down" }, "player3_special_clear_counter": { "hit": "received_seiya_two_lift", "airborne": "received_seiya_two_lift", "down": "received_seiya_two_down", "wall": "received_seiya_two_fly", "fall": "received_seiya_two_fly" } }`

## リオ・“フリック”・ガルシア

技: `rio_cross_counter` / 1接触Damage: 12 / 倍率: 1.50 / Cooldown: 6.00s

| 必殺技Motion | 実Clip | Frame数 | 通常P/K等との共有 |
|---|---|---:|---|
| Special Startup | special_startup | 1 | ["punch_1"] |
| Special Attack | special_attack | 3 | ["punch_1", "jump_punch"] |
| Special Finish | special_recovery | 2 | ["punch_1"] |

| 要求Motion | 登録名候補 | 現在の参照 |
|---|---|---|
| P | ["punch_1", "punch"] | punch_1 (3 Frame) |
| →P | ["punch_forward"] | 固有名/入力接続を要調査 |
| ←P | ["punch_backward"] | 固有名/入力接続を要調査 |
| ↓P | ["crouch_punch"] | crouch_punch (3 Frame) |
| K | ["kick_1", "kick"] | kick_1 (3 Frame) |
| →K | ["kick_forward"] | 固有名/入力接続を要調査 |
| ←K | ["kick_backward"] | 固有名/入力接続を要調査 |
| ↓K | ["crouch_kick"] | crouch_kick (3 Frame) |
| Air P | ["jump_punch"] | jump_punch (3 Frame) |
| Air K | ["jump_kick"] | jump_kick (3 Frame) |
| ↓Air K | ["jump_kick_down"] | 固有名/入力接続を要調査 |
| Throw | ["throw_start", "throw"] | throw_start (1 Frame) |
| →Throw | ["throw_forward"] | 固有名/入力接続を要調査 |
| ↓Throw | ["throw_down"] | 固有名/入力接続を要調査 |
| ←Throw | ["throw_backward"] | 固有名/入力接続を要調査 |
| Light Hit | ["damage_light"] | damage_light (1 Frame) |
| Heavy Hit | ["damage_heavy"] | damage_heavy (2 Frame) |
| High Hit | ["damage_high"] | damage_high (1 Frame) |
| Low Hit | ["damage_low"] | damage_low (1 Frame) |
| Launch Hit | ["launch_hit"] | 固有名/入力接続を要調査 |
| Air Hit | ["air_hit"] | 固有名/入力接続を要調査 |
| Knockback | ["knockback"] | knockback (2 Frame) |
| Ground Bounce | ["ground_bounce"] | 固有名/入力接続を要調査 |
| Knockdown | ["knockdown"] | knockdown (2 Frame) |
| Throw Front Damage | ["throw_front_damage"] | 固有名/入力接続を要調査 |
| Throw Down Damage | ["throw_down_damage"] | 固有名/入力接続を要調査 |
| Throw Back Damage | ["throw_back_damage"] | 固有名/入力接続を要調査 |
| Special Hit | ["special_hit"] | 固有名/入力接続を要調査 |
| Special Knockback | ["special_knockback"] | 固有名/入力接続を要調査 |
| Special Knockdown | ["special_knockdown"] | 固有名/入力接続を要調査 |
| Special Guard | ["special_guard"] | 固有名/入力接続を要調査 |

技別被Damage登録: `{ "player1_special_thunder_drive": { "hit": "received_akky_elbow_hit", "airborne": "received_akky_elbow_air", "down": "received_akky_elbow_down", "wall": "received_akky_elbow_wall", "fall": "received_akky_elbow_fall" }, "player2_special_iron_breaker": { "hit": "received_gou_breaker_hit", "airborne": "received_gou_breaker_air", "down": "received_gou_breaker_down" }, "player3_special_clear_counter": { "hit": "received_seiya_two_lift", "airborne": "received_seiya_two_lift", "down": "received_seiya_two_down", "wall": "received_seiya_two_fly", "fall": "received_seiya_two_fly" } }`

## テキ・ファイター

技: `teki_deadly_hand` / 1接触Damage: 11 / 倍率: 1.50 / Cooldown: 4.20s

| 必殺技Motion | 実Clip | Frame数 | 通常P/K等との共有 |
|---|---|---:|---|
| Special Startup | special_startup | 3 | [] |
| Special Attack | teki_deadly_hand | 2 | [] |
| Special Finish | special_recovery | 3 | [] |

| 要求Motion | 登録名候補 | 現在の参照 |
|---|---|---|
| P | ["punch_1", "punch"] | punch_1 (3 Frame) |
| →P | ["punch_forward"] | 固有名/入力接続を要調査 |
| ←P | ["punch_backward"] | 固有名/入力接続を要調査 |
| ↓P | ["crouch_punch"] | crouch_punch (3 Frame) |
| K | ["kick_1", "kick"] | kick_1 (3 Frame) |
| →K | ["kick_forward"] | 固有名/入力接続を要調査 |
| ←K | ["kick_backward"] | 固有名/入力接続を要調査 |
| ↓K | ["crouch_kick"] | crouch_kick (3 Frame) |
| Air P | ["jump_punch"] | jump_punch (3 Frame) |
| Air K | ["jump_kick"] | jump_kick (3 Frame) |
| ↓Air K | ["jump_kick_down"] | 固有名/入力接続を要調査 |
| Throw | ["throw_start", "throw"] | throw_start (1 Frame) |
| →Throw | ["throw_forward"] | 固有名/入力接続を要調査 |
| ↓Throw | ["throw_down"] | 固有名/入力接続を要調査 |
| ←Throw | ["throw_backward"] | 固有名/入力接続を要調査 |
| Light Hit | ["damage_light"] | damage_light (2 Frame) |
| Heavy Hit | ["damage_heavy"] | damage_heavy (2 Frame) |
| High Hit | ["damage_high"] | damage_high (2 Frame) |
| Low Hit | ["damage_low"] | damage_low (2 Frame) |
| Launch Hit | ["launch_hit"] | 固有名/入力接続を要調査 |
| Air Hit | ["air_hit"] | 固有名/入力接続を要調査 |
| Knockback | ["knockback"] | knockback (2 Frame) |
| Ground Bounce | ["ground_bounce"] | 固有名/入力接続を要調査 |
| Knockdown | ["knockdown"] | knockdown (3 Frame) |
| Throw Front Damage | ["throw_front_damage"] | 固有名/入力接続を要調査 |
| Throw Down Damage | ["throw_down_damage"] | 固有名/入力接続を要調査 |
| Throw Back Damage | ["throw_back_damage"] | 固有名/入力接続を要調査 |
| Special Hit | ["special_hit"] | 固有名/入力接続を要調査 |
| Special Knockback | ["special_knockback"] | 固有名/入力接続を要調査 |
| Special Knockdown | ["special_knockdown"] | 固有名/入力接続を要調査 |
| Special Guard | ["special_guard"] | 固有名/入力接続を要調査 |

技別被Damage登録: `{ "player1_special_thunder_drive": { "hit": "received_akky_elbow_hit", "airborne": "received_akky_elbow_air", "down": "received_akky_elbow_down", "wall": "received_akky_elbow_wall", "fall": "received_akky_elbow_fall" }, "player2_special_iron_breaker": { "hit": "received_gou_breaker_hit", "airborne": "received_gou_breaker_air", "down": "received_gou_breaker_down" }, "player3_special_clear_counter": { "hit": "received_seiya_two_lift", "airborne": "received_seiya_two_lift", "down": "received_seiya_two_down", "wall": "received_seiya_two_fly", "fall": "received_seiya_two_fly" } }`

## レオン・クロウ

技: `leon_crow_reversal` / 1接触Damage: 15 / 倍率: 1.50 / Cooldown: 6.00s

| 必殺技Motion | 実Clip | Frame数 | 通常P/K等との共有 |
|---|---|---:|---|
| Special Startup | special_startup | 2 | ["kick_2"] |
| Special Attack | special_attack | 4 | ["kick_2", "punch_2"] |
| Special Finish | special_recovery | 3 | ["kick_2"] |

| 要求Motion | 登録名候補 | 現在の参照 |
|---|---|---|
| P | ["punch_1", "punch"] | punch_1 (3 Frame) |
| →P | ["punch_forward"] | 固有名/入力接続を要調査 |
| ←P | ["punch_backward"] | 固有名/入力接続を要調査 |
| ↓P | ["crouch_punch"] | crouch_punch (3 Frame) |
| K | ["kick_1", "kick"] | kick_1 (3 Frame) |
| →K | ["kick_forward"] | 固有名/入力接続を要調査 |
| ←K | ["kick_backward"] | 固有名/入力接続を要調査 |
| ↓K | ["crouch_kick"] | crouch_kick (3 Frame) |
| Air P | ["jump_punch"] | jump_punch (3 Frame) |
| Air K | ["jump_kick"] | jump_kick (3 Frame) |
| ↓Air K | ["jump_kick_down"] | 固有名/入力接続を要調査 |
| Throw | ["throw_start", "throw"] | throw_start (1 Frame) |
| →Throw | ["throw_forward"] | 固有名/入力接続を要調査 |
| ↓Throw | ["throw_down"] | 固有名/入力接続を要調査 |
| ←Throw | ["throw_backward"] | 固有名/入力接続を要調査 |
| Light Hit | ["damage_light"] | damage_light (2 Frame) |
| Heavy Hit | ["damage_heavy"] | damage_heavy (1 Frame) |
| High Hit | ["damage_high"] | damage_high (2 Frame) |
| Low Hit | ["damage_low"] | damage_low (2 Frame) |
| Launch Hit | ["launch_hit"] | 固有名/入力接続を要調査 |
| Air Hit | ["air_hit"] | 固有名/入力接続を要調査 |
| Knockback | ["knockback"] | knockback (1 Frame) |
| Ground Bounce | ["ground_bounce"] | 固有名/入力接続を要調査 |
| Knockdown | ["knockdown"] | knockdown (2 Frame) |
| Throw Front Damage | ["throw_front_damage"] | 固有名/入力接続を要調査 |
| Throw Down Damage | ["throw_down_damage"] | 固有名/入力接続を要調査 |
| Throw Back Damage | ["throw_back_damage"] | 固有名/入力接続を要調査 |
| Special Hit | ["special_hit"] | 固有名/入力接続を要調査 |
| Special Knockback | ["special_knockback"] | 固有名/入力接続を要調査 |
| Special Knockdown | ["special_knockdown"] | 固有名/入力接続を要調査 |
| Special Guard | ["special_guard"] | 固有名/入力接続を要調査 |

技別被Damage登録: `{ "player1_special_thunder_drive": { "hit": "received_akky_elbow_hit", "airborne": "received_akky_elbow_air", "down": "received_akky_elbow_down", "wall": "received_akky_elbow_wall", "fall": "received_akky_elbow_fall" }, "player2_special_iron_breaker": { "hit": "received_gou_breaker_hit", "airborne": "received_gou_breaker_air", "down": "received_gou_breaker_down" }, "player3_special_clear_counter": { "hit": "received_seiya_two_lift", "airborne": "received_seiya_two_lift", "down": "received_seiya_two_down", "wall": "received_seiya_two_fly", "fall": "received_seiya_two_fly" } }`

## セイヤ

技: `seiya_dark_reversal` / 1接触Damage: 24 / 倍率: 1.00 / Cooldown: 6.00s

第9ステージ継承仕様: 各段1倍、両段成功で2倍。初段命中後の確定追撃を保持。

| 必殺技Motion | 実Clip | Frame数 | 通常P/K等との共有 |
|---|---|---:|---|
| Special Startup | seiya_two_start | 1 | [] |
| Special Attack | seiya_two_somersault | 3 | [] |
| Special Finish | seiya_two_finish | 1 | [] |

| 要求Motion | 登録名候補 | 現在の参照 |
|---|---|---|
| P | ["punch_1", "punch"] | punch_1 (6 Frame) |
| →P | ["punch_forward"] | 固有名/入力接続を要調査 |
| ←P | ["punch_backward"] | 固有名/入力接続を要調査 |
| ↓P | ["crouch_punch"] | crouch_punch (6 Frame) |
| K | ["kick_1", "kick"] | kick_1 (6 Frame) |
| →K | ["kick_forward"] | 固有名/入力接続を要調査 |
| ←K | ["kick_backward"] | 固有名/入力接続を要調査 |
| ↓K | ["crouch_kick"] | crouch_kick (6 Frame) |
| Air P | ["jump_punch"] | jump_punch (3 Frame) |
| Air K | ["jump_kick"] | jump_kick (3 Frame) |
| ↓Air K | ["jump_kick_down"] | 固有名/入力接続を要調査 |
| Throw | ["throw_start", "throw"] | throw_start (2 Frame) |
| →Throw | ["throw_forward"] | 固有名/入力接続を要調査 |
| ↓Throw | ["throw_down"] | 固有名/入力接続を要調査 |
| ←Throw | ["throw_backward"] | 固有名/入力接続を要調査 |
| Light Hit | ["damage_light"] | damage_light (3 Frame) |
| Heavy Hit | ["damage_heavy"] | damage_heavy (3 Frame) |
| High Hit | ["damage_high"] | damage_high (3 Frame) |
| Low Hit | ["damage_low"] | damage_low (3 Frame) |
| Launch Hit | ["launch_hit"] | 固有名/入力接続を要調査 |
| Air Hit | ["air_hit"] | 固有名/入力接続を要調査 |
| Knockback | ["knockback"] | knockback (3 Frame) |
| Ground Bounce | ["ground_bounce"] | 固有名/入力接続を要調査 |
| Knockdown | ["knockdown"] | knockdown (3 Frame) |
| Throw Front Damage | ["throw_front_damage"] | 固有名/入力接続を要調査 |
| Throw Down Damage | ["throw_down_damage"] | 固有名/入力接続を要調査 |
| Throw Back Damage | ["throw_back_damage"] | 固有名/入力接続を要調査 |
| Special Hit | ["special_hit"] | 固有名/入力接続を要調査 |
| Special Knockback | ["special_knockback"] | 固有名/入力接続を要調査 |
| Special Knockdown | ["special_knockdown"] | 固有名/入力接続を要調査 |
| Special Guard | ["special_guard"] | 固有名/入力接続を要調査 |

技別被Damage登録: `{ "player1_special_thunder_drive": { "hit": "received_akky_elbow_hit", "airborne": "received_akky_elbow_air", "down": "received_akky_elbow_down", "wall": "received_akky_elbow_wall", "fall": "received_akky_elbow_fall" }, "player2_special_iron_breaker": { "hit": "received_gou_breaker_hit", "airborne": "received_gou_breaker_air", "down": "received_gou_breaker_down" }, "player3_special_clear_counter": { "hit": "received_seiya_somersault_hit", "airborne": "received_seiya_somersault_air", "fall": "received_seiya_somersault_fall", "down": "received_seiya_somersault_down" } }`
