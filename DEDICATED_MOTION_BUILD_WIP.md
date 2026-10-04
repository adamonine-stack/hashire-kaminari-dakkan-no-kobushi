# AKKY / Crusher専用モーション制作台帳

開始branch codex/directional-combat-20261003、HEAD 97de2c5e3f4b397604cc1876388fcb708e0b7e62。既存未Commit変更を保持する。今回の目標は双方の攻撃・受け専用素材とゲーム接続。登録名だけで完成扱いにしない。

| 対象 | 既存専用素材 | 修正/新規必要 |
| --- | --- | --- |
| AKKY Ground | P、前P、下K | Back P/Down Pは同一列、Forward K/Back Kは同一列なので分離必要 |
| AKKY Air | 既存Jump P/K | 専用Air P、急降下K、着地硬直 |
| AKKY Throw | 4方向Attacker/Crusher Victim | Crusherから受ける4方向Victim |
| AKKY Reactions | 既存Hit/Down/GetUp、Special専用受け | High/Low/Air/Launch/Wall/Bounceの不足を検査し追加 |
| Crusher Ground | 既存P/K/Sweep | Forward P/K、Back P/K、Down P/Kの専用姿勢/連続Frame |
| Crusher Air | 既存Air P/K | 急降下K・着地 |
| Crusher Throw | 既存通常Throw、AKKYからの4Victim | 4方向専用Attacker＋AKKY Victim同期 |
| Crusher Reactions | 既存Hit/Down/GetUp、Special専用受け | High/Low/Air/Launch/Wall/Bounceの不足を検査し追加 |
| 両者Special | 既存専用Startup/Attack/Finishと相互被Special素材 | Guard含め描画と同期を再検査 |

各新規素材は設計->Key Pose->正式Design比較/修正->中間Frame->全Frame比較->Atlas->Godot->描画/Test。全体Scaleで脚やDownサイズを誤魔化さない。足元Anchor固定。Key Poseを一括大量生成して無検証採用しない。

最初の制作: Crusher Back P対空アッパーとAKKY Launch Hit受け。正式Crusherの赤Bandanna/黒Tank/緑Cargo/腕帯/黒Bootsと筋肉量を維持。AKKYのベージュ長袖ジャケット/黒タートルネック/黒パンツ/黒Boots/顔と髪を維持。袖まくり・腹露出禁止。

2026-10-04 checkpoint: new Air P/air-launch reactions, both distinct Down P, Crusher Back P/Forward K/Back K and AKKY Back K connected; see DEDICATED_MOTION_CHECKPOINT.md. Full two-character target remains in progress. Authoring sources moved outside Godot to art/dedicated_pair_v1/sources.

2026-10-04 later checkpoints: Crusher neutral/forward/down/back dedicated attacker + AKKY receiver pairs are now connected; shared grab/hold, individual release/air clips, reviewed down pose, fixed Sprite transforms. AIR_GUARD_IMPLEMENTATION.md adds both dedicated air guard/impact clips. CRUSHER_BACK_THROW_AI_CHECKPOINT.md connects all four Crusher directional throws to situational AI, with wall-position swap/counter checks. Original table above is the starting inventory, not current completion status. Next outstanding art work is dive K/landing and remaining receiver/special guard coverage audit.

2026-10-04 dive checkpoint: AKKY/Crusher dedicated Down+Air K startup/contact/landing now connected; shared 0.32s punishable landing recovery and delayed observed-recovery AI selection. See DIVE_KICK_CHECKPOINT.md for tests and evidence boundaries. Remaining receiver and special-guard motion coverage still pending.

2026-10-04 special guard checkpoint: three dedicated grounded guard phases for both actors, receiver-data mapping and opt-in guard-stun synchronization. Air guard retained. Runtime receiver sources inventoried in PAIR_REACTION_INVENTORY.json; wall/ground-bounce and high/low/heavy hit review remain. See SPECIAL_GUARD_REACTION_CHECKPOINT.md.

2026-10-04 wall/bounce checkpoint: both dedicated wall_hit/wall_fall and ground_impact/ground_bounce atlases connected. Down throws have one bounded bounce before existing down/wake-up. See WALL_BOUNCE_REACTION_CHECKPOINT.md for verification boundaries. High/low/heavy receiver coverage remains pending.

2026-10-04 receiver checkpoint: rendered Seiya launch sampling resolved, middle-hit routing repaired; newly authored three-phase dedicated heavy-hit clips for AKKY/Crusher replace shared frames. High/low/light distinct source authoring remains pending. See RECEIVER_ROUTING_CHECKPOINT.md.

2026-10-04 basic receiver checkpoint: distinct three-phase light/high/low original atlases for AKKY/Crusher now connected, removing remaining shared basic receiver art for this pair. Heavy remains dedicated. See DEDICATED_BASIC_REACTIONS_CHECKPOINT.md for tests and remaining full-play coverage.
