# ST_action 必殺技追加 作業報告 2026-10-02

最新追加: ゴウの技を受ける敵9種の専用反応、アッキーの表示画面端への高速壁衝突→落下、反応素材とカメラのサイズ補正、ゴウの短距離着地。詳細はENEMY_REACTIONS_AND_WALL_LAUNCH_UPDATE.md。以下は各工程時点の記録。

**全体は未完成。共通戦闘処理、アッキー専用切り返し、登録12技の豪華Effect/大きな吹き飛び、アッキーの肘打ちを受ける敵9種の専用反応を実装。次工程でゴウの専用攻撃原画4枚と、重打撃を受けるクラッシャーの専用反応3枚も追加。詳細はSPECIAL_PRESENTATION_UPDATE.mdとGOU_REVERSAL_PRESENTATION_UPDATE.md。他10技の専用原画・全受け手反応・方向Attack/Throw/Combo統合・指定12戦闘ケースの完成条件は未達。公開変更なし。**

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

専用Startup/Attack/FinishおよびSpecial Hit/Guard/Knockback/KnockdownのClip指定構造を追加。既存Clipがない場合の表示は従来反応に戻る。実装前の12定義の既存Clip一覧はSPECIAL_REVERSAL_MOTION_INVENTORY.mdに保存。

アッキーは既存battle.pngの黒髪・茶色ジャケット・黒い服とブーツを参照し、1枚ずつ9原画を制作。開始2枚、前進肘打ち1枚、終了1枚、被弾/吹き飛び2枚、地上ダウン1枚、ガード2枚をreversal_v1へ統合。全原画を同一倍率0.13で320×224セル、足基準208へ配置し、原画のSHA-256と配置値をpacking_manifest.jsonに記録。通常のspecial_thunder_driveは互換性のため従来Clipを保持し、今回の技はakky_reversal_elbowを使う。空中はspecial_knockback、着地後はspecial_knockdownへ切り替え、Throw/通常被弾では専用状態をクリアする。被弾と吹き飛びは専用2枚を共有しており、別々の全中間Frame制作まで完了したという意味ではない。残り11定義の制作は未完了。

## 14. Effect

追加依頼に対応し、全12定義の発動/Active/Finishに全身オーラ、足元リング、上昇光を追加。Activeには白い前方軌跡、Hitには白い放射閃光と拡大衝撃波を追加。既存のキャラクター別線演出は保持し、色を青/金/紫/赤へ分けた。Hit持続0.28秒、Finish0.22秒。HitStop中は演出時間も停止する。共通戦闘テスト成功、12定義×4局面の非headless描画48枚を確認。手動実戦確認ではない。

ユーザーの補足により、被弾/ダウン要件は「攻撃した必殺技に対応する、受けた各キャラクターの反応」であると確認。その後アッキー→敵9種について専用原画27枚と技ID×受け手選択を実装。アッキー自身の汎用special_hit/downをこの要件の達成として数えない。他技×受け手の専用素材は未完了。

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

継続作業で、前段階の倍率置換がguard_damage_multiplierにも誤って適用され、既存6技のガード削りが1.5になっていた問題を発見。6技を0.15へ修正し、新規6技の0.0も含めた独立した期待値と、実ガードDamageが通常Hitの半分未満である検証を追加。前段階の報告だけではこの誤設定を検出できていなかった。

継続作業の最終回帰は既存25テスト全件成功。追加のakky_reversal_motion_checkとspecial_reversal_checkも成功。新アトラス追加時に旧akky_motion_atlasが全Clipを旧アトラス参照と仮定して失敗したため、登録済みextra_motion_atlasesのClipを正しい参照先として検証するよう更新した。専用テスト終了時のAudioStream残存警告は、固定FPSが実音声より速く進むため発生し、テスト終了で音声停止とミキサー待機を追加して解消した。

Godot非headlessでアッキー全11表示Frameを左右反転し22枚保存。全FrameでSpriteのScale=(1.280403,1.280403)、Pivot=(0,-122.9187)を検証し、描画画像でも足位置・向き・切れ・ポーズを確認。実receive_attackによる被弾/空中/着地/Guardの遷移も検証。画像はevidence/akky_reversal、連結画像はcontact.jpg。制御された実描画であり、手動Play Testや指定12戦闘ケース完了の証拠ではない。

HitStun発動禁止、AI被弾中の候補停止、過大倍率、最低20%Guard削り、無敵中でもSpecialを先に中断する順序、同フレームSpecial処理順依存、空振り硬直不足を修正。既存被弾無敵の持ち越しとSpecial中AI競合を修正。検証で使用した誤ったDOWN状態名を既存KNOCKDOWNへ修正。AudioStream終了前のテスト終了で出たObjectDB警告は、再現ログで音声終了待ちの問題と確認し、新規テストの終了待ちを修正した。

## 19. 未解決

- 残り11定義の専用Attack/Start/Finish/被Damage/Guard原画、中間Frame、Atlas制作と正式デザイン比較。アッキーも長い実戦中の同期と必要な追加中間Frameを継続確認する。
- 方向P/K/Throw、派生Comboの既存実装を全キャラクターで詳細照合し、不足を制作・統合する作業。
- Boss既存special/ultimateと新切り返しの全ルール統合。
- ユーザー指定12戦闘ケースの実進行、全フレーム、HitBox/HurtBox/Effect同期、左右反転、足位置、Wall、複数Enemy、Airborne/Knockdown/Bossの検証。
- 手動Play TestによるAI/Frame Advantage/Recovery/Resource調整。
- 新しい表示名の確定、新規Key Poseの採用判定。

**コードと一部検証が追加された段階であり、ユーザー指定の完成条件に到達していない。**

## 20–21. Git

変更は未完成の基盤実装としてコミットする。実際のcommit hashとgit status --shortは、コミット後生成するevidence/git_completion.txtへ保存する。生成UID・実行ログ・描画画像等の未追跡ファイルを保持。公開/Push/PRは行っていない。

## 2026-10-02 ゴウ被弾向き・着地の作り直し

全9敵で対面から頭を後ろへ倒して1周し、頭をゴウ側に向けたうつぶせへ変更。開始/着地18原画をv2として制作。詳細はGOU_BACKFLIP_V2.md。飛距離・速度を維持し、実描画167枚と既存25回帰テストを確認。

## 2026-10-02 到達姿勢の角度と自然な中間モーション

対面立位から頭がゴウ側のうつぶせへ到達する動きは後方270度へ修正。膝を引き寄せる中間原画を全9敵へ追加し、反らす/膝引き/開く姿勢と最後の下降を滑らかにつないだ。詳細はGOU_PRONE_270_NATURAL_MOTION.md。

## 2026-10-02 最新指定: 上体反り・低い回転・滑らかな下降

体を丸める中間姿勢を除去。上体反りと軽い膝曲げのまま後方270度へ回り、約25pxの低い浮き上がりから約0.3秒かけて頭がゴウ側のうつぶせへ倒れる。横の距離は約320px。詳細はGOU_LOW_ARCHED_270_FINAL.md。前工程の360度/膝引き/高い弾道は履歴で、最終仕様ではない。
