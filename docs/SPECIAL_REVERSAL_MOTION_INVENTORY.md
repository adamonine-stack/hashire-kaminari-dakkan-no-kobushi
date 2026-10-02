# 必殺技実装前 Motion 調査（2026-10-02）

既存登録名の一覧。登録名だけでは専用原画や自然な動作の証明にならない。

## player_01_akky

定義: ally_balance.tres
既存Clip: backstep, combo_finisher, cross_react_joint, cross_react_joint_down, cross_react_pull, cross_react_pull_down, cross_react_reap, cross_react_reap_down, cross_react_shoulder, cross_react_shoulder_down, crouch, crouch_guard, crouch_guard_release, crouch_idle, crouch_kick, crouch_kick_sweep, crouch_punch, crouch_release, crouch_sweep_kick, damage, damage_heavy, damage_high, damage_light, damage_low, dash, defeat, down, fall, get_up, getup, guard, guard_hit, guard_release, heavy_attack, idle, idle_prebattle, idle_ready, jump, jump_air, jump_fall, jump_kick, jump_land, jump_punch, jump_punch_down, jump_start, jump_up, kick, kick_1, kick_2, knockback, knockdown, knockdown_high, knockdown_low, ko, land, landing, light_attack, punch, punch_1, punch_2, special, special_01, special_02, special_attack, special_recovery, special_startup, special_thunder_drive, stand_up, throw, thrown, ultimate_attack, ultimate_recovery, ultimate_startup, victory, walk, walk_backward, walk_forward
今回必要: special_startup / 専用special_attack / special_recovery / special_hit / special_knockback / special_knockdown / special_guard。既存名がある場合もフレーム共有・原画・足元を要確認。
方向P/K/Throw・空中P/K・各Damageは既存Clipを実画面照合してから不足を確定する。

## player_02_gou

定義: ally_power.tres
既存Clip: backstep, combo_finisher, cross_react_joint, cross_react_joint_down, cross_react_pull, cross_react_pull_down, cross_react_reap, cross_react_reap_down, cross_react_shoulder, cross_react_shoulder_down, crouch, crouch_guard, crouch_guard_hold, crouch_guard_release, crouch_guard_start, crouch_idle, crouch_kick, crouch_kick_sweep, crouch_punch, crouch_release, crouch_start, crouch_sweep_kick, damage, damage_heavy, damage_high, damage_light, damage_low, dash, defeat, down, fall, get_up, getup, grabbed, guard, guard_hit, guard_hold, guard_release, guard_start, heavy_attack, hit_high, hit_low, idle, idle_prebattle, idle_ready, jump, jump_air, jump_attack, jump_fall, jump_kick, jump_land, jump_punch, jump_punch_down, jump_start, jump_up, kick, kick_1, kick_2, knockback, knockdown, knockdown_high, knockdown_low, ko, land, landing, light_attack, punch, punch_1, punch_2, special, special_attack, special_iron_breaker, special_recovery, special_startup, stand_up, throw, throw_hold, throw_release, throw_start, thrown, victory, walk, walk_backward, walk_forward
今回必要: special_startup / 専用special_attack / special_recovery / special_hit / special_knockback / special_knockdown / special_guard。既存名がある場合もフレーム共有・原画・足元を要確認。
方向P/K/Throw・空中P/K・各Damageは既存Clipを実画面照合してから不足を確定する。

## player_03_seiya

定義: ally_speed.tres
既存Clip: backstep, combo_finisher, cross_react_joint, cross_react_joint_down, cross_react_pull, cross_react_pull_down, cross_react_reap, cross_react_reap_down, cross_react_shoulder, cross_react_shoulder_down, crouch, crouch_guard, crouch_guard_hold, crouch_guard_release, crouch_guard_start, crouch_idle, crouch_kick, crouch_kick_sweep, crouch_punch, crouch_release, crouch_start, crouch_sweep_kick, damage, damage_heavy, damage_high, damage_light, damage_low, dash, defeat, down, fall, get_up, getup, grabbed, guard, guard_hit, guard_hold, guard_release, guard_start, heavy_attack, hit_high, hit_low, idle, idle_prebattle, idle_ready, jump, jump_air, jump_attack, jump_fall, jump_kick, jump_land, jump_punch, jump_punch_down, jump_start, jump_up, kick, kick_1, kick_2, knockback, knockdown, knockdown_high, knockdown_low, ko, land, landing, light_attack, punch, punch_1, punch_2, punch_3, special, special_attack, special_clear_counter, special_recovery, special_startup, stand_up, throw, throw_hold, throw_release, throw_start, thrown, victory, walk, walk_backward, walk_forward
今回必要: special_startup / 専用special_attack / special_recovery / special_hit / special_knockback / special_knockdown / special_guard。既存名がある場合もフレーム共有・原画・足元を要確認。
方向P/K/Throw・空中P/K・各Damageは既存Clipを実画面照合してから不足を確定する。

## enemy_01_crusher

定義: enemy_01_standard.tres
既存Clip: backstep, crouch, crouch_guard, crouch_idle, crouch_kick, crouch_kick_sweep, crouch_punch, damage_heavy, damage_high, damage_light, damage_low, dash, down, fall, getup, grabbed, guard, guard_hit, idle, idle_ready, jump, jump_air, jump_fall, jump_kick, jump_land, jump_punch, jump_punch_down, jump_start, kick, kick_1, kick_2, knockdown, ko, land, punch, punch_1, punch_2, stand_up, throw, throw_hold, throw_release, throw_start, thrown, walk, walk_backward, walk_forward
今回必要: special_startup / 専用special_attack / special_recovery / special_hit / special_knockback / special_knockdown / special_guard。既存名がある場合もフレーム共有・原画・足元を要確認。
方向P/K/Throw・空中P/K・各Damageは既存Clipを実画面照合してから不足を確定する。

## enemy_02_shadow_boxer

定義: enemy_02_speed.tres
既存Clip: backhand, backstep, body_jab, counter_jab, cross_joint_finish, cross_muei, cross_wrist_finish, crouch, crouch_guard, crouch_idle, crouch_kick, crouch_kick_sweep, crouch_punch, damage, damage_heavy, damage_high, damage_light, damage_low, dash, down, fall, feint, getup, grabbed, guard, guard_hit, hook, idle, idle_prebattle, idle_ready, jump, jump_air, jump_fall, jump_kick, jump_land, jump_punch, jump_punch_down, jump_start, kick, kick_1, kick_2, knockdown, ko, land, punch, punch_1, punch_2, quick_combo, shadow_jab, shadow_step_counter, slide_straight, slip, special, special_01, special_02, stand_up, step_back, step_in, sway, throw, throw_hold, throw_release, throw_start, thrown, uppercut, victory, walk, walk_backward, walk_forward
今回必要: special_startup / 専用special_attack / special_recovery / special_hit / special_knockback / special_knockdown / special_guard。既存名がある場合もフレーム共有・原画・足元を要確認。
方向P/K/Throw・空中P/K・各Damageは既存Clipを実画面照合してから不足を確定する。

## enemy_03_masato_takahashi

定義: enemy_03_guard.tres
既存Clip: backstep, combo_finisher, crouch, crouch_guard, crouch_idle, crouch_kick, crouch_kick_sweep, crouch_punch, damage, damage_heavy, damage_high, damage_light, damage_low, dash, defeat, down, fall, get_up, getup, grab, grabbed, guard, guard_hit, heavy_attack, idle, idle_prebattle, idle_ready, jump, jump_air, jump_fall, jump_kick, jump_land, jump_punch, jump_punch_down, jump_start, kick, kick_1, kick_2, knockback, knockdown, ko, land, landing, light_attack, punch, punch_1, punch_2, special, special_attack, special_recovery, special_startup, stand_up, throw, throw_hold, throw_release, throw_start, thrown, victory, walk, walk_backward, walk_forward
今回必要: special_startup / 専用special_attack / special_recovery / special_hit / special_knockback / special_knockdown / special_guard。既存名がある場合もフレーム共有・原画・足元を要確認。
方向P/K/Throw・空中P/K・各Damageは既存Clipを実画面照合してから不足を確定する。

## enemy_04_rei_kageyama

定義: enemy_04_throw.tres
既存Clip: backstep, combo_finisher, crouch, crouch_guard, crouch_idle, crouch_kick, crouch_kick_sweep, crouch_punch, crouch_sweep_kick, damage, damage_heavy, damage_high, damage_light, damage_low, dash, defeat, down, fall, get_up, getup, grabbed, guard, guard_hit, heavy_attack, idle, idle_prebattle, idle_ready, jump, jump_air, jump_fall, jump_kick, jump_land, jump_punch, jump_punch_down, jump_start, jump_up, kick, kick_1, kick_2, knockback, knockdown, ko, land, landing, light_attack, punch, punch_1, punch_2, rei_dragon_uppercut, special, special_attack, special_recovery, special_startup, stand_up, throw, throw_hold, throw_release, throw_start, thrown, walk, walk_backward, walk_forward
今回必要: special_startup / 専用special_attack / special_recovery / special_hit / special_knockback / special_knockdown / special_guard。既存名がある場合もフレーム共有・原画・足元を要確認。
方向P/K/Throw・空中P/K・各Damageは既存Clipを実画面照合してから不足を確定する。

## enemy_05_cross_murasame

定義: enemy_05_power.tres
既存Clip: backstep, chop, combo_finisher, cross_ankle, cross_ankle_hold, cross_ankle_release, cross_ankle_start, cross_armbar, cross_armbar_hold, cross_armbar_release, cross_armbar_start, cross_choke, cross_choke_hold, cross_choke_release, cross_choke_start, cross_chop, cross_harai, cross_harai_hold, cross_harai_release, cross_harai_start, cross_joint_finish, cross_knee, cross_muei, cross_osoto, cross_osoto_hold, cross_osoto_release, cross_osoto_start, cross_rotate, cross_rotate_hold, cross_rotate_release, cross_rotate_start, cross_seoi, cross_seoi_hold, cross_seoi_release, cross_seoi_start, cross_side_pin, cross_side_pin_hold, cross_side_pin_release, cross_side_pin_start, cross_sode, cross_sode_hold, cross_sode_release, cross_sode_start, cross_tomoe, cross_tomoe_hold, cross_tomoe_release, cross_tomoe_start, cross_triangle, cross_triangle_hold, cross_triangle_release, cross_triangle_start, cross_uchimata, cross_uchimata_hold, cross_uchimata_release, cross_uchimata_start, cross_wrist_finish, crouch, crouch_guard, crouch_idle, crouch_kick, crouch_kick_sweep, crouch_punch, crouch_sweep_kick, damage, damage_heavy, damage_high, damage_light, damage_low, dash, defeat, down, elbow, fall, get_up, getup, grab, grabbed, guard, guard_hit, heavy_attack, idle, idle_prebattle, idle_ready, jump, jump_air, jump_fall, jump_kick, jump_land, jump_punch, jump_punch_down, jump_start, jump_up, kick, kick_1, kick_2, knee, knockback, knockdown, ko, land, landing, light_attack, punch, punch_1, punch_2, roundhouse, special, special_attack, special_recovery, special_startup, stand_up, straight_punch, throw, throw_hold, throw_release, throw_start, thrown, ukemi, victory, walk, walk_backward, walk_forward
今回必要: special_startup / 専用special_attack / special_recovery / special_hit / special_knockback / special_knockdown / special_guard。既存名がある場合もフレーム共有・原画・足元を要確認。
方向P/K/Throw・空中P/K・各Damageは既存Clipを実画面照合してから不足を確定する。

## enemy_06_rio_flick_garcia

定義: enemy_06_combo.tres
既存Clip: arm_lock, back_jump, backdrop, backstep, brainbuster, clothesline, crouch, crouch_guard, crouch_idle, crouch_kick, crouch_kick_sweep, crouch_punch, damage, damage_heavy, damage_high, damage_light, damage_low, dash, down, dropkick, elbow, fall, flying_tackle, foot_lock, front_choke, front_jump, getup, grab, grabbed, grapple, ground_grapple, guard, guard_hit, high_kick, idle, idle_prebattle, idle_ready, jump, jump_air, jump_fall, jump_kick, jump_land, jump_punch, jump_punch_down, jump_start, kick, kick_1, kick_2, knockdown, ko, land, low_kick, neck_throw, pin, punch, punch_1, punch_2, rolling_knee, shoulder_tackle, special, special_01, special_02, spinning_back_toss, stand_up, submission, suplex, tackle, throw, throw_hold, throw_release, throw_start, thrown, victory, walk, walk_backward, walk_forward
今回必要: special_startup / 専用special_attack / special_recovery / special_hit / special_knockback / special_knockdown / special_guard。既存名がある場合もフレーム共有・原画・足元を要確認。
方向P/K/Throw・空中P/K・各Damageは既存Clipを実画面照合してから不足を確定する。

## enemy_07_teki_fighter

定義: enemy_07_tricky.tres
既存Clip: backstep, combo_finisher, crouch, crouch_guard, crouch_idle, crouch_kick, crouch_kick_sweep, crouch_punch, crouch_sweep_kick, damage, damage_heavy, damage_high, damage_light, damage_low, dash, defeat, down, fall, get_up, getup, grab, grabbed, guard, guard_hit, heavy_attack, idle, idle_prebattle, idle_ready, jump, jump_air, jump_fall, jump_kick, jump_land, jump_punch, jump_punch_down, jump_start, jump_up, kick, kick_1, kick_2, knockback, knockdown, ko, land, landing, light_attack, punch, punch_1, punch_2, special, special_attack, special_recovery, special_startup, stand_up, teki_deadly_hand, teki_face_grab_hold, teki_face_grab_release, teki_face_grab_start, teki_headlock_hold, teki_headlock_release, teki_headlock_start, teki_low_grab_hold, teki_low_grab_release, teki_low_grab_start, throw, throw_hold, throw_release, throw_start, thrown, victory, walk, walk_backward, walk_forward
今回必要: special_startup / 専用special_attack / special_recovery / special_hit / special_knockback / special_knockdown / special_guard。既存名がある場合もフレーム共有・原画・足元を要確認。
方向P/K/Throw・空中P/K・各Damageは既存Clipを実画面照合してから不足を確定する。

## enemy_08_leon_crow

定義: enemy_08_boss.tres
既存Clip: backstep, combo_finisher, crouch, crouch_guard, crouch_idle, crouch_kick, crouch_kick_sweep, crouch_punch, damage, damage_heavy, damage_high, damage_light, damage_low, dash, defeat, down, fall, get_up, getup, grab, grabbed, guard, guard_hit, heavy_attack, idle, idle_prebattle, idle_ready, jump, jump_air, jump_fall, jump_kick, jump_land, jump_punch, jump_punch_down, jump_start, kick, kick_1, kick_2, knockback, knockdown, ko, land, landing, light_attack, punch, punch_1, punch_2, special, special_attack, special_recovery, special_startup, stand_up, throw, throw_hold, throw_release, throw_start, thrown, victory, walk, walk_backward, walk_forward
今回必要: special_startup / 専用special_attack / special_recovery / special_hit / special_knockback / special_knockdown / special_guard。既存名がある場合もフレーム共有・原画・足元を要確認。
方向P/K/Throw・空中P/K・各Damageは既存Clipを実画面照合してから不足を確定する。

## enemy_09_seiya

定義: enemy_09_seiya.tres
既存Clip: aura_charge, aura_charge_max, aura_contact, aura_recovery, aura_slam, backstep, combo_finisher, cross_react_joint, cross_react_joint_down, cross_react_pull, cross_react_pull_down, cross_react_reap, cross_react_reap_down, cross_react_shoulder, cross_react_shoulder_down, crouch, crouch_guard, crouch_guard_hold, crouch_guard_release, crouch_guard_start, crouch_idle, crouch_kick, crouch_kick_sweep, crouch_punch, crouch_release, crouch_start, crouch_sweep_kick, damage, damage_heavy, damage_high, damage_light, damage_low, dash, defeat, down, fall, get_up, getup, grabbed, guard, guard_hit, guard_hold, guard_release, guard_start, heavy_attack, hit_high, hit_low, idle, idle_prebattle, idle_ready, jump, jump_air, jump_attack, jump_fall, jump_kick, jump_land, jump_punch, jump_punch_down, jump_start, jump_up, kick, kick_1, kick_2, knockback, knockdown, knockdown_high, knockdown_low, ko, land, landing, light_attack, punch, punch_1, punch_2, punch_3, special, special_attack, special_clear_counter, special_recovery, special_startup, stand_up, throw, throw_hold, throw_release, throw_start, thrown, victory, walk, walk_backward, walk_forward
今回必要: special_startup / 専用special_attack / special_recovery / special_hit / special_knockback / special_knockdown / special_guard。既存名がある場合もフレーム共有・原画・足元を要確認。
方向P/K/Throw・空中P/K・各Damageは既存Clipを実画面照合してから不足を確定する。


## 必須項目別の登録候補照合

Clip名の候補照合のみ。方向技に固有名がある場合は追加調査が必要。候補ありは原画や動作の完成を意味しない。↓Air Kにはjump_punch_downを流用できないため専用jump_kick_downを要確認。

### player_01_akky  | 必須Motion | Clip候補 | 登録候補 | |---|---|---|
| P | punch | あり・専用性未確認 |
| →P | punch_forward | 未登録・固有名要調査 |
| ←P | punch_backward | 未登録・固有名要調査 |
| ↓P | crouch_punch | あり・専用性未確認 |
| K | kick | あり・専用性未確認 |
| →K | kick_forward | 未登録・固有名要調査 |
| ←K | kick_backward | 未登録・固有名要調査 |
| ↓K | crouch_kick | あり・専用性未確認 |
| Air P | jump_punch | あり・専用性未確認 |
| Air K | jump_kick | あり・専用性未確認 |
| ↓Air K | jump_kick_down | 未登録・固有名要調査 |
| Throw | throw | あり・専用性未確認 |
| →Throw | throw_front | 未登録・固有名要調査 |
| ↓Throw | throw_down | 未登録・固有名要調査 |
| ←Throw | throw_back | 未登録・固有名要調査 |
| Special Startup | special_startup | あり・専用性未確認 |
| Special Attack | special_attack | あり・専用性未確認 |
| Special Finish | special_recovery | あり・専用性未確認 |
| Light Hit | damage_light | あり・専用性未確認 |
| Heavy Hit | damage_heavy | あり・専用性未確認 |
| High Hit | damage_high | あり・専用性未確認 |
| Low Hit | damage_low | あり・専用性未確認 |
| Launch Hit | launch_hit | 未登録・固有名要調査 |
| Air Hit | air_hit | 未登録・固有名要調査 |
| Knockback | knockback | あり・専用性未確認 |
| Ground Bounce | ground_bounce | 未登録・固有名要調査 |
| Knockdown | knockdown | あり・専用性未確認 |
| Throw Front Damage | throw_front_damage | 未登録・固有名要調査 |
| Throw Down Damage | throw_down_damage | 未登録・固有名要調査 |
| Throw Back Damage | throw_back_damage | 未登録・固有名要調査 |
| Special Hit | special_hit | 未登録・固有名要調査 |
| Special Knockback | special_knockback | 未登録・固有名要調査 |
| Special Knockdown | special_knockdown | 未登録・固有名要調査 |
| Special Guard | special_guard | 未登録・固有名要調査 |

### player_02_gou  | 必須Motion | Clip候補 | 登録候補 | |---|---|---|
| P | punch | あり・専用性未確認 |
| →P | punch_forward | 未登録・固有名要調査 |
| ←P | punch_backward | 未登録・固有名要調査 |
| ↓P | crouch_punch | あり・専用性未確認 |
| K | kick | あり・専用性未確認 |
| →K | kick_forward | 未登録・固有名要調査 |
| ←K | kick_backward | 未登録・固有名要調査 |
| ↓K | crouch_kick | あり・専用性未確認 |
| Air P | jump_punch | あり・専用性未確認 |
| Air K | jump_kick | あり・専用性未確認 |
| ↓Air K | jump_kick_down | 未登録・固有名要調査 |
| Throw | throw | あり・専用性未確認 |
| →Throw | throw_front | 未登録・固有名要調査 |
| ↓Throw | throw_down | 未登録・固有名要調査 |
| ←Throw | throw_back | 未登録・固有名要調査 |
| Special Startup | special_startup | あり・専用性未確認 |
| Special Attack | special_attack | あり・専用性未確認 |
| Special Finish | special_recovery | あり・専用性未確認 |
| Light Hit | damage_light | あり・専用性未確認 |
| Heavy Hit | damage_heavy | あり・専用性未確認 |
| High Hit | damage_high | あり・専用性未確認 |
| Low Hit | damage_low | あり・専用性未確認 |
| Launch Hit | launch_hit | 未登録・固有名要調査 |
| Air Hit | air_hit | 未登録・固有名要調査 |
| Knockback | knockback | あり・専用性未確認 |
| Ground Bounce | ground_bounce | 未登録・固有名要調査 |
| Knockdown | knockdown | あり・専用性未確認 |
| Throw Front Damage | throw_front_damage | 未登録・固有名要調査 |
| Throw Down Damage | throw_down_damage | 未登録・固有名要調査 |
| Throw Back Damage | throw_back_damage | 未登録・固有名要調査 |
| Special Hit | special_hit | 未登録・固有名要調査 |
| Special Knockback | special_knockback | 未登録・固有名要調査 |
| Special Knockdown | special_knockdown | 未登録・固有名要調査 |
| Special Guard | special_guard | 未登録・固有名要調査 |

### player_03_seiya  | 必須Motion | Clip候補 | 登録候補 | |---|---|---|
| P | punch | あり・専用性未確認 |
| →P | punch_forward | 未登録・固有名要調査 |
| ←P | punch_backward | 未登録・固有名要調査 |
| ↓P | crouch_punch | あり・専用性未確認 |
| K | kick | あり・専用性未確認 |
| →K | kick_forward | 未登録・固有名要調査 |
| ←K | kick_backward | 未登録・固有名要調査 |
| ↓K | crouch_kick | あり・専用性未確認 |
| Air P | jump_punch | あり・専用性未確認 |
| Air K | jump_kick | あり・専用性未確認 |
| ↓Air K | jump_kick_down | 未登録・固有名要調査 |
| Throw | throw | あり・専用性未確認 |
| →Throw | throw_front | 未登録・固有名要調査 |
| ↓Throw | throw_down | 未登録・固有名要調査 |
| ←Throw | throw_back | 未登録・固有名要調査 |
| Special Startup | special_startup | あり・専用性未確認 |
| Special Attack | special_attack | あり・専用性未確認 |
| Special Finish | special_recovery | あり・専用性未確認 |
| Light Hit | damage_light | あり・専用性未確認 |
| Heavy Hit | damage_heavy | あり・専用性未確認 |
| High Hit | damage_high | あり・専用性未確認 |
| Low Hit | damage_low | あり・専用性未確認 |
| Launch Hit | launch_hit | 未登録・固有名要調査 |
| Air Hit | air_hit | 未登録・固有名要調査 |
| Knockback | knockback | あり・専用性未確認 |
| Ground Bounce | ground_bounce | 未登録・固有名要調査 |
| Knockdown | knockdown | あり・専用性未確認 |
| Throw Front Damage | throw_front_damage | 未登録・固有名要調査 |
| Throw Down Damage | throw_down_damage | 未登録・固有名要調査 |
| Throw Back Damage | throw_back_damage | 未登録・固有名要調査 |
| Special Hit | special_hit | 未登録・固有名要調査 |
| Special Knockback | special_knockback | 未登録・固有名要調査 |
| Special Knockdown | special_knockdown | 未登録・固有名要調査 |
| Special Guard | special_guard | 未登録・固有名要調査 |

### enemy_01_crusher  | 必須Motion | Clip候補 | 登録候補 | |---|---|---|
| P | punch | あり・専用性未確認 |
| →P | punch_forward | 未登録・固有名要調査 |
| ←P | punch_backward | 未登録・固有名要調査 |
| ↓P | crouch_punch | あり・専用性未確認 |
| K | kick | あり・専用性未確認 |
| →K | kick_forward | 未登録・固有名要調査 |
| ←K | kick_backward | 未登録・固有名要調査 |
| ↓K | crouch_kick | あり・専用性未確認 |
| Air P | jump_punch | あり・専用性未確認 |
| Air K | jump_kick | あり・専用性未確認 |
| ↓Air K | jump_kick_down | 未登録・固有名要調査 |
| Throw | throw | あり・専用性未確認 |
| →Throw | throw_front | 未登録・固有名要調査 |
| ↓Throw | throw_down | 未登録・固有名要調査 |
| ←Throw | throw_back | 未登録・固有名要調査 |
| Special Startup | special_startup | 未登録・固有名要調査 |
| Special Attack | special_attack | 未登録・固有名要調査 |
| Special Finish | special_recovery | 未登録・固有名要調査 |
| Light Hit | damage_light | あり・専用性未確認 |
| Heavy Hit | damage_heavy | あり・専用性未確認 |
| High Hit | damage_high | あり・専用性未確認 |
| Low Hit | damage_low | あり・専用性未確認 |
| Launch Hit | launch_hit | 未登録・固有名要調査 |
| Air Hit | air_hit | 未登録・固有名要調査 |
| Knockback | knockback | 未登録・固有名要調査 |
| Ground Bounce | ground_bounce | 未登録・固有名要調査 |
| Knockdown | knockdown | あり・専用性未確認 |
| Throw Front Damage | throw_front_damage | 未登録・固有名要調査 |
| Throw Down Damage | throw_down_damage | 未登録・固有名要調査 |
| Throw Back Damage | throw_back_damage | 未登録・固有名要調査 |
| Special Hit | special_hit | 未登録・固有名要調査 |
| Special Knockback | special_knockback | 未登録・固有名要調査 |
| Special Knockdown | special_knockdown | 未登録・固有名要調査 |
| Special Guard | special_guard | 未登録・固有名要調査 |

### enemy_02_shadow_boxer  | 必須Motion | Clip候補 | 登録候補 | |---|---|---|
| P | punch | あり・専用性未確認 |
| →P | punch_forward | 未登録・固有名要調査 |
| ←P | punch_backward | 未登録・固有名要調査 |
| ↓P | crouch_punch | あり・専用性未確認 |
| K | kick | あり・専用性未確認 |
| →K | kick_forward | 未登録・固有名要調査 |
| ←K | kick_backward | 未登録・固有名要調査 |
| ↓K | crouch_kick | あり・専用性未確認 |
| Air P | jump_punch | あり・専用性未確認 |
| Air K | jump_kick | あり・専用性未確認 |
| ↓Air K | jump_kick_down | 未登録・固有名要調査 |
| Throw | throw | あり・専用性未確認 |
| →Throw | throw_front | 未登録・固有名要調査 |
| ↓Throw | throw_down | 未登録・固有名要調査 |
| ←Throw | throw_back | 未登録・固有名要調査 |
| Special Startup | special_startup | 未登録・固有名要調査 |
| Special Attack | special_attack | 未登録・固有名要調査 |
| Special Finish | special_recovery | 未登録・固有名要調査 |
| Light Hit | damage_light | あり・専用性未確認 |
| Heavy Hit | damage_heavy | あり・専用性未確認 |
| High Hit | damage_high | あり・専用性未確認 |
| Low Hit | damage_low | あり・専用性未確認 |
| Launch Hit | launch_hit | 未登録・固有名要調査 |
| Air Hit | air_hit | 未登録・固有名要調査 |
| Knockback | knockback | 未登録・固有名要調査 |
| Ground Bounce | ground_bounce | 未登録・固有名要調査 |
| Knockdown | knockdown | あり・専用性未確認 |
| Throw Front Damage | throw_front_damage | 未登録・固有名要調査 |
| Throw Down Damage | throw_down_damage | 未登録・固有名要調査 |
| Throw Back Damage | throw_back_damage | 未登録・固有名要調査 |
| Special Hit | special_hit | 未登録・固有名要調査 |
| Special Knockback | special_knockback | 未登録・固有名要調査 |
| Special Knockdown | special_knockdown | 未登録・固有名要調査 |
| Special Guard | special_guard | 未登録・固有名要調査 |

### enemy_03_masato_takahashi  | 必須Motion | Clip候補 | 登録候補 | |---|---|---|
| P | punch | あり・専用性未確認 |
| →P | punch_forward | 未登録・固有名要調査 |
| ←P | punch_backward | 未登録・固有名要調査 |
| ↓P | crouch_punch | あり・専用性未確認 |
| K | kick | あり・専用性未確認 |
| →K | kick_forward | 未登録・固有名要調査 |
| ←K | kick_backward | 未登録・固有名要調査 |
| ↓K | crouch_kick | あり・専用性未確認 |
| Air P | jump_punch | あり・専用性未確認 |
| Air K | jump_kick | あり・専用性未確認 |
| ↓Air K | jump_kick_down | 未登録・固有名要調査 |
| Throw | throw | あり・専用性未確認 |
| →Throw | throw_front | 未登録・固有名要調査 |
| ↓Throw | throw_down | 未登録・固有名要調査 |
| ←Throw | throw_back | 未登録・固有名要調査 |
| Special Startup | special_startup | あり・専用性未確認 |
| Special Attack | special_attack | あり・専用性未確認 |
| Special Finish | special_recovery | あり・専用性未確認 |
| Light Hit | damage_light | あり・専用性未確認 |
| Heavy Hit | damage_heavy | あり・専用性未確認 |
| High Hit | damage_high | あり・専用性未確認 |
| Low Hit | damage_low | あり・専用性未確認 |
| Launch Hit | launch_hit | 未登録・固有名要調査 |
| Air Hit | air_hit | 未登録・固有名要調査 |
| Knockback | knockback | あり・専用性未確認 |
| Ground Bounce | ground_bounce | 未登録・固有名要調査 |
| Knockdown | knockdown | あり・専用性未確認 |
| Throw Front Damage | throw_front_damage | 未登録・固有名要調査 |
| Throw Down Damage | throw_down_damage | 未登録・固有名要調査 |
| Throw Back Damage | throw_back_damage | 未登録・固有名要調査 |
| Special Hit | special_hit | 未登録・固有名要調査 |
| Special Knockback | special_knockback | 未登録・固有名要調査 |
| Special Knockdown | special_knockdown | 未登録・固有名要調査 |
| Special Guard | special_guard | 未登録・固有名要調査 |

### enemy_04_rei_kageyama  | 必須Motion | Clip候補 | 登録候補 | |---|---|---|
| P | punch | あり・専用性未確認 |
| →P | punch_forward | 未登録・固有名要調査 |
| ←P | punch_backward | 未登録・固有名要調査 |
| ↓P | crouch_punch | あり・専用性未確認 |
| K | kick | あり・専用性未確認 |
| →K | kick_forward | 未登録・固有名要調査 |
| ←K | kick_backward | 未登録・固有名要調査 |
| ↓K | crouch_kick | あり・専用性未確認 |
| Air P | jump_punch | あり・専用性未確認 |
| Air K | jump_kick | あり・専用性未確認 |
| ↓Air K | jump_kick_down | 未登録・固有名要調査 |
| Throw | throw | あり・専用性未確認 |
| →Throw | throw_front | 未登録・固有名要調査 |
| ↓Throw | throw_down | 未登録・固有名要調査 |
| ←Throw | throw_back | 未登録・固有名要調査 |
| Special Startup | special_startup | あり・専用性未確認 |
| Special Attack | special_attack | あり・専用性未確認 |
| Special Finish | special_recovery | あり・専用性未確認 |
| Light Hit | damage_light | あり・専用性未確認 |
| Heavy Hit | damage_heavy | あり・専用性未確認 |
| High Hit | damage_high | あり・専用性未確認 |
| Low Hit | damage_low | あり・専用性未確認 |
| Launch Hit | launch_hit | 未登録・固有名要調査 |
| Air Hit | air_hit | 未登録・固有名要調査 |
| Knockback | knockback | あり・専用性未確認 |
| Ground Bounce | ground_bounce | 未登録・固有名要調査 |
| Knockdown | knockdown | あり・専用性未確認 |
| Throw Front Damage | throw_front_damage | 未登録・固有名要調査 |
| Throw Down Damage | throw_down_damage | 未登録・固有名要調査 |
| Throw Back Damage | throw_back_damage | 未登録・固有名要調査 |
| Special Hit | special_hit | 未登録・固有名要調査 |
| Special Knockback | special_knockback | 未登録・固有名要調査 |
| Special Knockdown | special_knockdown | 未登録・固有名要調査 |
| Special Guard | special_guard | 未登録・固有名要調査 |

### enemy_05_cross_murasame  | 必須Motion | Clip候補 | 登録候補 | |---|---|---|
| P | punch | あり・専用性未確認 |
| →P | punch_forward | 未登録・固有名要調査 |
| ←P | punch_backward | 未登録・固有名要調査 |
| ↓P | crouch_punch | あり・専用性未確認 |
| K | kick | あり・専用性未確認 |
| →K | kick_forward | 未登録・固有名要調査 |
| ←K | kick_backward | 未登録・固有名要調査 |
| ↓K | crouch_kick | あり・専用性未確認 |
| Air P | jump_punch | あり・専用性未確認 |
| Air K | jump_kick | あり・専用性未確認 |
| ↓Air K | jump_kick_down | 未登録・固有名要調査 |
| Throw | throw | あり・専用性未確認 |
| →Throw | throw_front | 未登録・固有名要調査 |
| ↓Throw | throw_down | 未登録・固有名要調査 |
| ←Throw | throw_back | 未登録・固有名要調査 |
| Special Startup | special_startup | あり・専用性未確認 |
| Special Attack | special_attack | あり・専用性未確認 |
| Special Finish | special_recovery | あり・専用性未確認 |
| Light Hit | damage_light | あり・専用性未確認 |
| Heavy Hit | damage_heavy | あり・専用性未確認 |
| High Hit | damage_high | あり・専用性未確認 |
| Low Hit | damage_low | あり・専用性未確認 |
| Launch Hit | launch_hit | 未登録・固有名要調査 |
| Air Hit | air_hit | 未登録・固有名要調査 |
| Knockback | knockback | あり・専用性未確認 |
| Ground Bounce | ground_bounce | 未登録・固有名要調査 |
| Knockdown | knockdown | あり・専用性未確認 |
| Throw Front Damage | throw_front_damage | 未登録・固有名要調査 |
| Throw Down Damage | throw_down_damage | 未登録・固有名要調査 |
| Throw Back Damage | throw_back_damage | 未登録・固有名要調査 |
| Special Hit | special_hit | 未登録・固有名要調査 |
| Special Knockback | special_knockback | 未登録・固有名要調査 |
| Special Knockdown | special_knockdown | 未登録・固有名要調査 |
| Special Guard | special_guard | 未登録・固有名要調査 |

### enemy_06_rio_flick_garcia  | 必須Motion | Clip候補 | 登録候補 | |---|---|---|
| P | punch | あり・専用性未確認 |
| →P | punch_forward | 未登録・固有名要調査 |
| ←P | punch_backward | 未登録・固有名要調査 |
| ↓P | crouch_punch | あり・専用性未確認 |
| K | kick | あり・専用性未確認 |
| →K | kick_forward | 未登録・固有名要調査 |
| ←K | kick_backward | 未登録・固有名要調査 |
| ↓K | crouch_kick | あり・専用性未確認 |
| Air P | jump_punch | あり・専用性未確認 |
| Air K | jump_kick | あり・専用性未確認 |
| ↓Air K | jump_kick_down | 未登録・固有名要調査 |
| Throw | throw | あり・専用性未確認 |
| →Throw | throw_front | 未登録・固有名要調査 |
| ↓Throw | throw_down | 未登録・固有名要調査 |
| ←Throw | throw_back | 未登録・固有名要調査 |
| Special Startup | special_startup | 未登録・固有名要調査 |
| Special Attack | special_attack | 未登録・固有名要調査 |
| Special Finish | special_recovery | 未登録・固有名要調査 |
| Light Hit | damage_light | あり・専用性未確認 |
| Heavy Hit | damage_heavy | あり・専用性未確認 |
| High Hit | damage_high | あり・専用性未確認 |
| Low Hit | damage_low | あり・専用性未確認 |
| Launch Hit | launch_hit | 未登録・固有名要調査 |
| Air Hit | air_hit | 未登録・固有名要調査 |
| Knockback | knockback | 未登録・固有名要調査 |
| Ground Bounce | ground_bounce | 未登録・固有名要調査 |
| Knockdown | knockdown | あり・専用性未確認 |
| Throw Front Damage | throw_front_damage | 未登録・固有名要調査 |
| Throw Down Damage | throw_down_damage | 未登録・固有名要調査 |
| Throw Back Damage | throw_back_damage | 未登録・固有名要調査 |
| Special Hit | special_hit | 未登録・固有名要調査 |
| Special Knockback | special_knockback | 未登録・固有名要調査 |
| Special Knockdown | special_knockdown | 未登録・固有名要調査 |
| Special Guard | special_guard | 未登録・固有名要調査 |

### enemy_07_teki_fighter  | 必須Motion | Clip候補 | 登録候補 | |---|---|---|
| P | punch | あり・専用性未確認 |
| →P | punch_forward | 未登録・固有名要調査 |
| ←P | punch_backward | 未登録・固有名要調査 |
| ↓P | crouch_punch | あり・専用性未確認 |
| K | kick | あり・専用性未確認 |
| →K | kick_forward | 未登録・固有名要調査 |
| ←K | kick_backward | 未登録・固有名要調査 |
| ↓K | crouch_kick | あり・専用性未確認 |
| Air P | jump_punch | あり・専用性未確認 |
| Air K | jump_kick | あり・専用性未確認 |
| ↓Air K | jump_kick_down | 未登録・固有名要調査 |
| Throw | throw | あり・専用性未確認 |
| →Throw | throw_front | 未登録・固有名要調査 |
| ↓Throw | throw_down | 未登録・固有名要調査 |
| ←Throw | throw_back | 未登録・固有名要調査 |
| Special Startup | special_startup | あり・専用性未確認 |
| Special Attack | special_attack | あり・専用性未確認 |
| Special Finish | special_recovery | あり・専用性未確認 |
| Light Hit | damage_light | あり・専用性未確認 |
| Heavy Hit | damage_heavy | あり・専用性未確認 |
| High Hit | damage_high | あり・専用性未確認 |
| Low Hit | damage_low | あり・専用性未確認 |
| Launch Hit | launch_hit | 未登録・固有名要調査 |
| Air Hit | air_hit | 未登録・固有名要調査 |
| Knockback | knockback | あり・専用性未確認 |
| Ground Bounce | ground_bounce | 未登録・固有名要調査 |
| Knockdown | knockdown | あり・専用性未確認 |
| Throw Front Damage | throw_front_damage | 未登録・固有名要調査 |
| Throw Down Damage | throw_down_damage | 未登録・固有名要調査 |
| Throw Back Damage | throw_back_damage | 未登録・固有名要調査 |
| Special Hit | special_hit | 未登録・固有名要調査 |
| Special Knockback | special_knockback | 未登録・固有名要調査 |
| Special Knockdown | special_knockdown | 未登録・固有名要調査 |
| Special Guard | special_guard | 未登録・固有名要調査 |

### enemy_08_leon_crow  | 必須Motion | Clip候補 | 登録候補 | |---|---|---|
| P | punch | あり・専用性未確認 |
| →P | punch_forward | 未登録・固有名要調査 |
| ←P | punch_backward | 未登録・固有名要調査 |
| ↓P | crouch_punch | あり・専用性未確認 |
| K | kick | あり・専用性未確認 |
| →K | kick_forward | 未登録・固有名要調査 |
| ←K | kick_backward | 未登録・固有名要調査 |
| ↓K | crouch_kick | あり・専用性未確認 |
| Air P | jump_punch | あり・専用性未確認 |
| Air K | jump_kick | あり・専用性未確認 |
| ↓Air K | jump_kick_down | 未登録・固有名要調査 |
| Throw | throw | あり・専用性未確認 |
| →Throw | throw_front | 未登録・固有名要調査 |
| ↓Throw | throw_down | 未登録・固有名要調査 |
| ←Throw | throw_back | 未登録・固有名要調査 |
| Special Startup | special_startup | あり・専用性未確認 |
| Special Attack | special_attack | あり・専用性未確認 |
| Special Finish | special_recovery | あり・専用性未確認 |
| Light Hit | damage_light | あり・専用性未確認 |
| Heavy Hit | damage_heavy | あり・専用性未確認 |
| High Hit | damage_high | あり・専用性未確認 |
| Low Hit | damage_low | あり・専用性未確認 |
| Launch Hit | launch_hit | 未登録・固有名要調査 |
| Air Hit | air_hit | 未登録・固有名要調査 |
| Knockback | knockback | あり・専用性未確認 |
| Ground Bounce | ground_bounce | 未登録・固有名要調査 |
| Knockdown | knockdown | あり・専用性未確認 |
| Throw Front Damage | throw_front_damage | 未登録・固有名要調査 |
| Throw Down Damage | throw_down_damage | 未登録・固有名要調査 |
| Throw Back Damage | throw_back_damage | 未登録・固有名要調査 |
| Special Hit | special_hit | 未登録・固有名要調査 |
| Special Knockback | special_knockback | 未登録・固有名要調査 |
| Special Knockdown | special_knockdown | 未登録・固有名要調査 |
| Special Guard | special_guard | 未登録・固有名要調査 |

### enemy_09_seiya  | 必須Motion | Clip候補 | 登録候補 | |---|---|---|
| P | punch | あり・専用性未確認 |
| →P | punch_forward | 未登録・固有名要調査 |
| ←P | punch_backward | 未登録・固有名要調査 |
| ↓P | crouch_punch | あり・専用性未確認 |
| K | kick | あり・専用性未確認 |
| →K | kick_forward | 未登録・固有名要調査 |
| ←K | kick_backward | 未登録・固有名要調査 |
| ↓K | crouch_kick | あり・専用性未確認 |
| Air P | jump_punch | あり・専用性未確認 |
| Air K | jump_kick | あり・専用性未確認 |
| ↓Air K | jump_kick_down | 未登録・固有名要調査 |
| Throw | throw | あり・専用性未確認 |
| →Throw | throw_front | 未登録・固有名要調査 |
| ↓Throw | throw_down | 未登録・固有名要調査 |
| ←Throw | throw_back | 未登録・固有名要調査 |
| Special Startup | special_startup | あり・専用性未確認 |
| Special Attack | special_attack | あり・専用性未確認 |
| Special Finish | special_recovery | あり・専用性未確認 |
| Light Hit | damage_light | あり・専用性未確認 |
| Heavy Hit | damage_heavy | あり・専用性未確認 |
| High Hit | damage_high | あり・専用性未確認 |
| Low Hit | damage_low | あり・専用性未確認 |
| Launch Hit | launch_hit | 未登録・固有名要調査 |
| Air Hit | air_hit | 未登録・固有名要調査 |
| Knockback | knockback | あり・専用性未確認 |
| Ground Bounce | ground_bounce | 未登録・固有名要調査 |
| Knockdown | knockdown | あり・専用性未確認 |
| Throw Front Damage | throw_front_damage | 未登録・固有名要調査 |
| Throw Down Damage | throw_down_damage | 未登録・固有名要調査 |
| Throw Back Damage | throw_back_damage | 未登録・固有名要調査 |
| Special Hit | special_hit | 未登録・固有名要調査 |
| Special Knockback | special_knockback | 未登録・固有名要調査 |
| Special Knockdown | special_knockdown | 未登録・固有名要調査 |
| Special Guard | special_guard | 未登録・固有名要調査 |
