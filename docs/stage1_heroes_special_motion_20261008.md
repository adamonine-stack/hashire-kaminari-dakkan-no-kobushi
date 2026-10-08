# Stage1 剛・聖夜 Special攻撃／受けモーション統一

## 作業範囲とGit
開始・終了branch: `codex/stage1-gou-seiya-20261007`。
開始HEAD: `112f2d1e995e70aad936171c343ce6f971e3711f`。
本工程のCommit: `Unify Gou and Seiya special attack and received motions`（終了Hashは作業報告及びGit履歴）。
開始statusは `phase_heroes_special_start_status.txt`、終了statusは `phase_heroes_special_end_status.txt` に保存。大量の既存import差分、seiya_head.gdshader、fighter_definition.gd、過去QA資料は削除せず、今回Commitへ混ぜない。

1対1のStage1で、両HeroのSpecial攻撃とCrusher／聖夜Specialの受け・専用Guardを同じ正式デザインへ接続する工程。全Stage1完成や公開完了とは扱わない。

## 調査・変更
既存はPlayerAttackData Resource → CharacterSpecialState STARTUP/ACTIVE/RECOVERY → Area2D接触の共通resolver → receive_attack／guard／knockdown。既存Gauge／Cooldown／HitStunからのReversal・Down/KO/Throw拘束制限を継続。全体の置換、AI入力読み、固定技ID優先判定は追加しない。

剛は旧reversal_v1の4姿勢、聖夜は旧two_hit_v1の8姿勢を使用。聖夜は時間に応じて3枚の宙返りと4枚の横蹴りへ切り替え、物理座標とsprite回転／offsetで回転を表現する。既存の2段構成と接触窓は維持した。

追加atlasをextra_motion_atlas_pathsの末尾へ登録し、同じruntime名を上書き。旧素材は保持。特殊受けは旧512×384から共通384×288へ統一し、専用guardの3姿勢は既存sync_special_guard_to_stunで硬直に同期。Crusherの受けguard指定はHero側Dataでspecial_guardへ対応。

| Hero | 攻撃専用clip | Special受けclip |
|---|---|---|
| 剛 | gou_reversal_startup / breaker / finish | received_crusher_hammer_hit/air/down/guard、received_seiya_two_lift/fall/fly/down、special_guard |
| 聖夜 | seiya_two_start / somersault / sidekick / finish | 同上 |

受けのlift/fall/fly/downは既存名へ接続したaliasを含む。32生成姿勢中、4枚は立ち姿校正、28枚が動的Key Pose。全clip／aliasごとに別原画を制作したという意味ではない。剛のGuard候補（攻撃sheet末尾）は今回runtimeでは未使用。

## デザイン・制作
正式参照はgou_anti_air_v2/formal_standing.png及びseiya_slim_v3/formal_standing.png。最初の攻撃sheetは頭／肩が大きく、そのまま採用せず修正。姿勢設計→Key Pose→正式参照比較→修正→atlas化→Godot接続→native全frame比較。
剛は白tank、黒pants、黒belt、黄土色の和サンダルと露出した足指を維持。聖夜は細い肩・胴・脚、白い袖を手首まで、腹を覆うshirt、beige pants、white sneakersを維持。横蹴りの脚は通常体格の長さで描く。
各source sheet全姿勢に同一倍率。校正高は剛203／聖夜195px（前工程と同値、正式聖夜参照の元画像212pxを今回変えない）。姿勢ごとのbody伸縮なし。全clip head_scale_override=1。空中は絵の上端配置と物理offsetを分離。Downは横向き全身の長さと顔の詳細を比較。
PythonはRGBA figure抽出、単一倍率、atlas packing、比較panel制作のみ。四肢や顔の加工には使用していない。4atlasはいずれも1536×576。追加Particle／常駐Nodeなし。

## 性能・Guard・Effect
| Hero | Startup | Active | Recovery | Damage | Guard | Gauge/Cooldown |
|---|---:|---:|---:|---:|---|---|
| 剛 | .14 | .20 | .58 | 38（主力25×1.5を丸め） | 0 damage / 小押し戻し | 既存Gauge / 5.20秒 |
| 聖夜 | .14 | 1.00 | .24 | 各段13、両段合計26 | 両段0 damage | 既存Gauge / 3.60秒 |
DamageはCampaign補正後の実packet値。聖夜は既存承認の2段技を維持したため、総量は主力13の2倍であり当初目安1.5倍との差が残る。総Damageの最終balanceは未決定。
剛のguard_damage_multiplier=.15を0へ修正。聖夜2段技のpacketが通常guard_hitを強制していた箇所をDataのspecial_guard_reactionへ変更。通常技のGuardや他Character固有Guard指定は維持。
Special Hitは既存攻撃をInterrupt、Guardはlaunch/downさせずRecoveryを残す。Startup保護 .10秒、HitStun CancelとGauge/Cooldownを使ったCombo Break方式は変更なし。
剛の体を覆うtexture Auraを拳と足元の短いarc／衝撃表現へ変更。聖夜は既存の回転Trail、Crusherは既存のPower Effect。色違いだけの新共通effectを追加していない。
新規Input／Buffer／Punch／Kick／Air／Throw／Combo／Cancel／AI／HitBox/HurtBox／Save変更なし。前工程の方向履歴と単独Specialボタンを継続。Wall／Enemy Collision及びMultiple Enemyは本工程の確認対象外。

## 検証と証拠の範囲
- 全atlasテスト: Gou144clips395frames、Seiya149clips413frames、failures=[]。全frameの元texture、cell、非空、anchor、固定scaleを確認。
- Native Intel Iris Xe Forward Mobile: 両HeroのSpecial攻撃／受け／Guard92poseを左右両向き描画、failures=[]。audit_evidence/stage1_heroes_special_reviewにpanelとinventory。
- stage1_heroes_special_guard_check: 各Special段×左右のHit／Guard、実receive_attackによるInterrupt、HP減少／0chip、Recovery。両HeroがCrusherを受ける左右両向きHit／Guard、3frame Guardと硬直同期。headless及びnative failures=[]。Native20pair画像。
- Pair画像は制御した状態・時間でpacketを適用し、spriteを停止して取得する固定snapshot。自然な連続PhysicsやHitBox勝敗Timingの証拠ではない。試験途中に前case Effect残留、sidekick timer未設定を修正して最終再撮影。HUDは初期選択Gouのままのfixtureであり、Hero切替UIの確認画像ではない。
- special_reversal_check: HitStun切り返し、短時間保護／失効、Whiff Recovery、Cooldown、Down/KO/Throw禁止、Interrupt、Guard、同step双方Special trade、観測遅延AI、failures=[]。
- seiya_somersault_check: 既存実Physics2段pipelineの18cases、guard／whiff／KO等、failures=[]。画像監査は別native検査。
- dev053_stage1_smoke: Stage開始→Crusher KO→Stage1 Clear、合格。
- stage1_regression: KO／GameOver／Retryなど既存回帰、failures=[]。
- Test接続失敗（Array[String]の閉じ括弧）、旧guard/fall atlas参照、Gou liftのsoft edge位置を修正し、失敗した検査を再実行した。

スマホ実機手操作、公開Web、定量FPS、全Stage manual playは未確認。既存import Safe-save permissions error、headless終了時一部ObjectDB leak warningが残る。警告なしとは報告しない。新機能によるSave互換変更はない。

## ファイル・次工程
変更: ally_power/ally_speed、player2_special_iron_breaker.tres、player_fighter_definition_movement.gd、reversal_effect.gd、gou/seiya_motion_atlas.gd、special_reversal_check.gd。
新規: 4source folder（key_poses/same_scale_review）、4atlas folder（png/tres/packing_manifest）、pack_stage1_hero_special.py／received.py、stage1_heroes_special_guard_check.gd／review.gd、この報告。
Native証拠／status／実行logはworkspaceに保持し、generated .import/.uidや過去User変更はCommitへ入れない。
残りの通常High/Low/Launch/Wall等旧受け素材の統一、実戦での距離・Timing・操作確認、Stage1全体の公開判定を継続する。まだ未公開。
