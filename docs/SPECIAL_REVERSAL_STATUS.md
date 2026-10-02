# ST_action 必殺技追加 作業報告 2026-10-02

**未完成。共通戦闘処理の第一段階を実装した状態。全キャラクター専用原画・方向Attack/Throw/Combo統合・12戦闘ケースの完成条件は満たしていない。公開変更は行っていない。**

作業ツリー: `.special_reversal_20261002`。ブランチ: `feat/special-reversal-20261002`。基点: `4636dbc6a03395a3bcda66340fb7e08aea204270`。親フォルダーの空の`.git`ではGitが動作しないため、公開作業に使用された`.st_action_publish_20261002`から独立したworktreeを作成した。既存の制作物を上書きしていない。

## 1. 調査した既存Battle System

Player.tscnの継承はplayer_movement → player_combo_movement → player_knockdown_movement → player_fighter_definition_movement。Battle.tscnはStage1BattleManager、TrueBattle.tscnには既存セイヤの独立したオーラ攻撃がある。通常技にはStartup/Active/Recovery・HitBox/HurtBox・入力バッファ・Combo・Guard・Knockdownがある。プレイヤー3人とRei/Cross/Tekiにはcharacter special、Leonには別のBoss specialが存在。Crusher/Shadow/Masato/Rioには専用切り返しResourceがなく、敵セイヤにもcharacter specialは未接続だった。

既存のcharacter specialはHitStun中に発動不可、AIもHitStunで停止、Damage倍率2.4等、Guard削り最低20%の強制処理、同時接触の処理順依存があった。

## 2. 変更したFile

- godot/scripts/data/player_attack_data.gd
- godot/scripts/data/fighter_definition.gd
- godot/scripts/player/player_fighter_definition_movement.gd
- godot/scripts/player/player_movement.gd
- godot/scripts/player/player_combo_movement.gd
- godot/data/attacks/player1_special_thunder_drive.tres
- godot/data/attacks/player2_special_iron_breaker.tres
- godot/data/attacks/player3_special_clear_counter.tres
- godot/data/attacks/rei_dragon_uppercut.tres
- godot/data/attacks/cross_muei.tres
- godot/data/attacks/teki_deadly_hand.tres
- godot/data/enemies/enemy_01_standard.tres
- godot/data/enemies/enemy_02_speed.tres
- godot/data/enemies/enemy_03_guard.tres
- godot/data/enemies/enemy_06_combo.tres
- godot/data/enemies/enemy_08_boss.tres
- godot/data/enemies/enemy_09_seiya.tres

## 3. 新規File

- godot/scripts/combat/special_contact_resolver.gd
- godot/scripts/combat/reversal_effect.gd
- godot/data/attacks/crusher_fault_break.tres
- godot/data/attacks/shadow_slip_counter.tres
- godot/data/attacks/masato_palm_reversal.tres
- godot/data/attacks/rio_cross_counter.tres
- godot/data/attacks/leon_crow_reversal.tres
- godot/data/attacks/seiya_dark_reversal.tres
- godot/tests/special_reversal_check.gd
- godot/tests/special_reversal_visual_review.gd
- docs/SPECIAL_REVERSAL_MOTION_INVENTORY.md
- docs/SPECIAL_REVERSAL_STATUS.md
- 検証ログ・48描画画像・比較シート・アッキーKey Pose候補はevidence配下および作業ツリー直下へ保存。

## 4. Input

新しいボタンは追加していない。既存special_attack / specialを使用。HitStop中の入力を既存dev026_combo_input_buffer_time（0.18秒）に保存し、HitStop終了後に条件が成立すれば発動する。通常P/K/ThrowのHitStun禁止は維持。

## 5–7. Attack / Throw / Combo

新規切り返しAttack Resourceは6件。通常方向Attack、方向Throw、派生Comboの新規技はこの段階では追加していない。既存Combo状態は必殺技が実際にHitした際の既存interrupt_combo / action cancel経路で終了する。方向技全体の実装完了とは報告しない。

## 8–9. Character必殺技とDamage

実Battleに読み込んだ各定義のmax(punch_damage,kick_damage)×1.5をGodotのroundで整数化した値。キャンペーン難易度の追加補正前。

| Character | Move ID | Damage |
|---|---|---:|
| アッキー | player1_special_thunder_drive | 23 |
| ゴウ | player2_special_iron_breaker | 38 |
| セイヤ | player3_special_clear_counter | 20 |
| Crusher | crusher_fault_break | 12 |
| Shadow Boxer | shadow_slip_counter | 11 |
| Masato | masato_palm_reversal | 9 |
| Rei | rei_dragon_uppercut | 14 |
| Cross | cross_muei | 11 |
| Rio | rio_cross_counter | 12 |
| Teki | teki_deadly_hand | 11 |
| Leon | leon_crow_reversal | 15 |
| 敵セイヤ | seiya_dark_reversal | 36 |

Leonの既存Boss攻撃と敵セイヤの柱/オーラ攻撃は別技として保持。既存Boss special/ultimateの全技を新ルールへ統一する作業は残る。新規6技の表示名は仮のMove ID。

## 10. Combo Break

HitStun中の必殺技受付をデータで許可。開始0.10秒だけ接触を拒否し、通常被弾後の0.30秒無敵を持ち越さない。Startupは0.14秒。通常Attack中は受付不可。KO/Knockback/Knockdown/GetUp/Throw/Guard recoil/空中/既存オーラ演出中は受付不可。GaugeとCooldownを確認する。

必殺技同士の接触は同じphysics stepで発生した有効接触を保存して遅延解決する。発動・位置・無敵条件で接触できた両者は相打ちできる。プレイヤー固定優先を追加しない。相打ちはArea2Dコールバックで検証した。

## 11. Guard

既存Guard処理を使用する。Hit時の強制中断経路をGuard成功時には呼ばない。最低20%削りの強制を撤廃し、既存6技の設定済み15%削り、新規6技は0削り。既存Guard Reaction/後退/Guard HitStopを使用。特別なGuard Clip選択を追加したが専用原画は未制作。Guard接触には通常Recovery、完全な空振りにはRecovery×1.25。Gaugeは戻さない。

## 12–13. Attack Motion / Damage Motion

専用Startup/Attack/FinishおよびSpecial Hit/GuardのClip指定構造を追加。既存Clipがない場合の表示は従来反応に戻る。**新規専用Sprite/Atlas Motionの制作は未完了。** 特に通常Poseを共有したSpecial、Special Hit/Knockback/Knockdown/Guardの専用原画が不足している。

実装前に12定義の既存Clip一覧をSPECIAL_REVERSAL_MOTION_INVENTORY.mdへ保存。アッキーのStartup Key Poseを1枚だけimagegenで生成しevidence/keypose_candidatesへ保存した。正式素材への採用・中間Frame制作・Atlas化は行っていない。

## 14. Effect

開始/Active/Hit/Finishの呼び出しポイントを追加。アッキーの稲妻線、ゴウの地面リング、セイヤの速度線、Crusherの地面亀裂、Shadowの残像円弧、Masatoの掌打線、Reiの上昇円弧、Crossの交差線、Rioの連続軌跡、Tekiの爪線、Leonの大型Aura、敵セイヤの紫円弧を描画する。Hit時はPower/Speed/Boss/その他で形状を変える。HitStop中はEffectの時間も停止する。カスタムeffect_scene/hit_effect_sceneへ拡張可能。音声は既存special_start/special_attack、Hitは既存special音声経路へ接続。Camera Shake/HitStopもMoveDataから取得する。

## 15. Enemy AI

入力イベントを読まない。画面上の攻撃状態を0.12秒以上観察してCounter候補とする。HitStunも0.12秒以上観察してから一度だけReversal候補を判定。Enemy Order 1–3/4–7/8以上で使用率係数0.30/0.65/1.0を設定済みspecial_ai_use_chanceへ乗算する。Gauge/Cooldown/距離/Stateを満たした場合のみ候補とし、Special中は通常AIを止める。最終使用率の手動Play Test調整は未実施。

## 16. HitBox / HurtBox

既存SpecialHitBoxを使用し、MoveDataの各専用size/offset、移動距離、既存combat_geometry_scaleを適用する。正式HurtBoxのサイズは変更しない。新規6技は専用寸法と移動量を持つ。全左右反転/Wall/空中接触についての実ゲーム検証は残る。

## 17. 実Game確認

新規special_reversal_checkは実Battle.tscnをロードし、12定義のDamage/Resource、HitStun中P/K/Throw禁止・Special受付、短時間保護と終了、空振り硬直、Cooldown、Knockdown/KO/Throw禁止、攻撃中EnemyへのHit中断、Guard、Area2D同時Special相打ち、敵の観察待ち時間とHitStun切り返しを検証した。最後の実行はexit 0、failures=[]、AudioStreamの終了警告なし。

既存run_fix_regressions.ps1の25テストは全件成功。その後の入力/AI変更についてspecial_reversal_check、dev066、dev061、dev063を再実行して成功。専用Motion指定/HitStop設定の最後の変更後はspecial_reversal_checkを再実行して成功。

Godot非headlessのBattle描画で12定義×開始/Active/Hit/Finishを48枚保存。これは制御されたPose/接触経路の検証であり、手動Play Testや全Animation Frameの検証ではない。全キャラクターがそれぞれSpecialを受ける映像の検証も未完了。

## 18. 発見・修正

HitStun発動禁止、AI被弾中の候補停止、過大倍率、最低20%Guard削り、無敵中でもSpecialを先に中断する順序、同フレームSpecial処理順依存、空振り硬直不足を修正。既存被弾無敵の持ち越しとSpecial中AI競合を修正。検証で使用した誤ったDOWN状態名を既存KNOCKDOWNへ修正。AudioStream終了前のテスト終了で出たObjectDB警告は、再現ログで音声終了待ちの問題と確認し、新規テストの終了待ちを修正した。

## 19. 未解決

- 全12キャラクターの専用Attack/Start/Finish/被Damage/Guard原画、中間Frame、Atlas制作と正式デザイン比較。
- 方向P/K/Throw、派生Comboの既存実装を全キャラクターで詳細照合し、不足を制作・統合する作業。
- Boss既存special/ultimateと新切り返しの全ルール統合。
- ユーザー指定12戦闘ケースの実進行、全フレーム、HitBox/HurtBox/Effect同期、左右反転、足位置、Wall、複数Enemy、Airborne/Knockdown/Bossの検証。
- 手動Play TestによるAI/Frame Advantage/Recovery/Resource調整。
- 新しい表示名の確定、新規Key Poseの採用判定。

**コードと一部検証が追加された段階であり、ユーザー指定の完成条件に到達していない。**

## 20–21. Git

変更は未完成の基盤実装としてコミットする。実際のcommit hashとgit status --shortは、コミット後生成するevidence/git_completion.txtへ保存する。生成UID・実行ログ・描画画像等の未追跡ファイルを保持。公開/Push/PRは行っていない。
