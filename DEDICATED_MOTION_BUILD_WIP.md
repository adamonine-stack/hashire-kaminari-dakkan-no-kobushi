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
