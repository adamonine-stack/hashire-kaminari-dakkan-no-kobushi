# Stage1 剛・聖夜 通常被弾モーション統一

## Gitと範囲
開始／終了branch: `codex/stage1-gou-seiya-20261007`。
開始HEAD: `9b57077d4a7bfcd9515629950bd55722968361a4`。
本工程Commit名: `Unify Gou and Seiya normal received motions`。終了HashはGit履歴と作業報告。
開始status: phase_heroes_reactions_start_status.txt。終了status: phase_heroes_reactions_end_status.txt。既存import差分、seiya_head.gdshader、fighter_definition.gd、過去QAログ等は保持・Commit除外。
1対1のStage1を対象に、剛・聖夜のHigh/Low/Air/Launch/Knockback/Bounce/Wallを正式デザインへ統一。全体の実装・公開完了ではなく、通常受け工程の保存。

## 調査と実装
既存PlayerAttackData/Area2D → receive_attack → HitStop/HitStun/Knockdown State → VisualController/AnimatedSprite2D/SpriteFrames/AtlasTextureを継続。
前工程のLight/Heavy/Guard及びSpecial受けは専用画像へ接続済み。通常High/Low/Launch/Wall等は旧atlasが残っていたため、追加atlasを最後へ登録した。

| 分類 | runtime clip | 今回の画像 |
|---|---|---|
| 頭部受け | damage_high | 顔と顎が反る、手を顔へ寄せる |
| 下段受け | damage_low | 膝が崩れ、胴を前へ曲げる |
| 打ち上げ | launch_hit | 上体が反り、膝を曲げる |
| 空中受け | air_hit | 腹を守り、両膝を引く |
| 吹き飛び | knockback | 後方へ傾く全身姿勢 |
| 地面衝突／反発 | ground_impact / ground_bounce | 背中の接地、反発後の空中姿勢 |
| 壁衝突／落下 | wall_hit / wall_fall | 肩を反らす衝突、落下姿勢 |
| 着地後Down | knockdown_high / knockdown_low | 前工程の正式なthrow victim Downへalias |

各Heroは8原画（立ち校正1＋動的Key Pose7）。両Hero計14動的原画。9clipにはhold反復／既存姿勢の接続を含む。別clip名ごとに全て独立した原画を制作したとは扱わない。
既存の正式Down/WakeUp/KOへ接続。通常DownのHigh/Low名が旧素材を選ばないよう、throw_v11_victim／slim_throw_v13_victimにaliasを追加し、そのpackerも更新した。

## 修正した接続不具合
1. launch_velocityがあると明示hit_reactionをlaunch_hitへ上書きしていた。既存画像が存在する明示指定を優先し、指定がない場合だけ従来fallback。Air Pのair_hitとLauncherのlaunch_hitを区別。物理速度、Damage、HitStunは変更なし。
2. KNOCKBACK中、着地後last_knockdown_animationが通常飛行姿勢より先に選ばれていた。専用Special／Throw受けとLow HitStopの優先を維持した上で、通常の飛行中はknockback、着地後はDownとする。
大規模State置換、Input/Buffer/Move性能/ComboCancel/AI/Save変更なし。Specialの既存割込み・Gauge・Cooldown・Guard処理を継続。

## 正式デザイン・atlas
Gou参照: art_sources/gou_anti_air_v2/formal_standing.png。Seiya参照: art_sources/seiya_slim_v3/formal_standing.png。
剛の顔・肌・白tank・黒pants・和サンダル、聖夜の細い胴・肩・四肢・小さめ成人頭部・手首までの白袖・覆われた腹・beige pants・white sneakersを比較。
Pose設計→Key Pose生成→正式立ち姿と同一倍率比較→atlas→Godot全frame描画→実Physics確認。PythonはRGBA抽出、全姿勢共通の等比倍率、atlas配置、比較のみ。人体の伸縮や修正には使わない。
校正高は既存工程どおりGou203／Seiya195px。Seiya元参照画像212pxとの違いは以前からの校正であり今回変更していない。frameごとのbbox fitなし。head_scale_override=1。空中の絵offsetと物理位置を分離。各新atlas1536×576で追加Particle／常駐Nodeなし。

## 検証
- Native Intel Iris Xe Forward Mobile: 両Heroの新clip＋立ち比較、左右両向き80pose。非空、指定source atlas、固定sprite scale、failures=[]。audit_evidence/stage1_heroes_received_reviewに4panelとinventory。
- Fullatlas: Gou150clips401frames／Seiya155clips419frames、元texture／cell／足元／非空／固定倍率、failures=[]。
- stage1_hero_received_live_check: 両Hero各7種×左右=14、計28実Physics case。High/Lowはattack_heightから自動選択、Launchはfallback、Airは明示hit_reaction＋launch_velocityから選択。Damage1回、HitStun終了、HurtBox/操作復帰を確認。Knockback→Down→WakeUp、Ground Impact→Bounce→Down→WakeUp、Wall Hit→Wall Fall→Down→WakeUpを確認。
- Bounce入力4回でも実際は1回、制限を確認。Wall caseは既存wall_slam Special共通処理を通す。通常攻撃全てに壁反応を付与したという意味ではない。
- 同28caseはheadless及びnative双方failures=[]。Nativeは各Hero30枚、計60枚の反応／着地／WakeUp画像。撮影時だけ対象Actorのphysicsとspriteを停止し、次frameを描画後に復帰。連続状態遷移は実Physicsだが、スマホ手操作／通常速度での無停止撮影とは区別。
- 実Launcher→Jump→Air P→Air Kの既存3Hit route、Gou/Seiyaともfailures=[]。Crusherがlaunch_hit/air_hitを実際に選び、Gouのfinisher knockbackも確認。
- Gou/Seiya通常Guard・空中Guard／投げの攻撃側と受け側／4方向Whiff、failures=[]。アッキーdirectional_throws_checkもfailures=[]。
- Special Reversal（HitStun解除、短い無敵、Whiff/Cooldown/拘束/KO制限、同step Special Trade、AI観測遅延）、両Hero Special Hit/Guard、既存聖夜2段Special18cases、failures=[]。
- Stage開始→Crusher KO→Stage1 Clear、dev053_stage1_smoke合格。Stage1 KO/GameOver/Retry等regression、failures=[]。
- 試験fixtureの誤ったknockdown fieldをcauses_knockdownへ修正。Wall fixtureには実Special packetと同じ飛行clipとkeep_special_flight_in_viewを指定し、失敗caseを再検証。これらfixtureの失敗を製品の成功とは扱っていない。

スマホ実機手操作、公開Web、定量FPS、全Stage手動playは未確認。importはexit0だが既存Safe-save permissions error。一部headless終了時ObjectDB leak warningあり。警告なしとは扱わない。

## ファイル一覧
変更: ally_power.tres／ally_speed.tres、player_movement.gd／player_knockdown_movement.gd、gou_motion_atlas.gd／seiya_motion_atlas.gd、両throw victim motion_atlas.tres、pack_stage1_hero_throw.py。
新規: art_sources/gou_received_v13及びseiya_slim_received_v15のkey_poses.png／same_scale_review.png、両対応atlasのmotion_atlas.png／motion_atlas.tres／packing_manifest.json、pack_stage1_hero_received.py、stage1_hero_received_live_check.gd、stage1_heroes_received_review.gd、本報告。
Native証拠、status、log、生成import/uidはworkspaceに残し、過去User変更へ混ぜない。

## 残り・次工程
新技は前工程のP/K/Air/Throw/Combo/Specialを継続。本工程の追加Inputや新Comboはない。Character固有Special Damageは前報告どおり、聖夜2段総量26と約1.5倍目安との差の最終balanceは継続対象。
Stage1全体の距離・Timing・対空・回避・壁際位置交換を通した総合確認、スマホ操作相当の確認、旧通常攻撃／移動等を含む最終デザイン棚卸しと公開判定へ進む。今回未公開。
