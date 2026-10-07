# 第1ステージ 剛・聖夜の専用投げ／受け／ダウン工程（2026-10-08）

## 保存状態
開始／終了branch: `codex/stage1-gou-seiya-20261007`。
開始HEAD: `7e38534d7738fc987a749251382644ad4a5ddb91`。
終了HEADはこの文書を含む `Complete Gou and Seiya directional throw motions` phase commit。
開始／終了の全 `git status --short` は `phase_heroes_throw_start_status.txt` / `phase_heroes_throw_end_status.txt` に保存。大量の既存import/uid、既存fighter_definition.gd・seiya_head.gdshader等は保全し今回のcommitに含めない。公開／push／mergeは未実施。

## 調査と既存構造
共通PlayerAttackDataの投げパラメータ、player_combo_movementの方向投げ、player_knockdown_movementの受け→飛行→Down→GET_UP、CharacterVisualControllerのextra atlas重ね順とaliasesを確認。
両主人公の4投げとCounter／位置交換／投げ制限／150ms入力履歴は既存実装済み。剛・聖夜の方向別releaseが共通画像で、クラッシャーから受ける際はgrabbed/thrown fallbackを使用していた。
基本操作は既存十字キー＋T。InputMap／新Action／入力優先度／Buffer仕様は今回変更なし。スマホUI handlerで方向保持→release→約120ms→Tを既存テストにて検証。

## 追加・修正
両キャラの専用Throw: anticipation、hold、Neutral/Forward/Down/Back release、whiff。
専用Victim: grabbed/held、Neutral/Forward/Down/Back flight、ground down、half kneeling wakeup、KO終端。
1キャラにつきattack sheet8pose＋victim sheet8pose（各sheetの1poseは立ち校正）。2キャラ計32source poseのうち28が動作pose。hold／復帰／aliasは共有参照を含む。clip名は各30（attack9＋victim21）、aliasを含むため30個の独立した技／独立描画モーションではない。多数の滑らかな中間絵を追加したとは扱わない。
Attack atlas: `player02/throw_v11` / `player03/slim_throw_v13`。
Victim atlas: `player02/throw_v11_victim` / `player03/slim_throw_v13_victim`。
4atlas共に1536×576、cell384×288、foot baseline270、head_scale_override=1。

| Sheet | 校正高さ | 全pose共通倍率 |
|---|---:|---:|
| Gou Attack | 203 | .4821852731591449 |
| Gou Victim | 203 | .47877358490566035 |
| Seiya Attack | 195（既存承認基準） | .45348837209302323 |
| Seiya Victim | 195（既存承認基準） | .4588235294117647 |

各sheetの立ちから1倍率を算出し全poseに適用。frameごとのbboxフィット／人体部位の画像引き伸ばしなし。地上は足元基準、寝姿は地面の接触基準。足を自然に折り畳み、下段／飛行で長く伸びる脚を避けた。剛の肌・筋肉・tank・草履、聖夜の細身・頭身・長袖・服・白靴を正式立ち姿と比較。聖夜の初稿で掴み時に前腕が露出していたため、画像生成で全袖を手首まで修正してから接続。

## 共通処理への最小拡張
`throw_whiff_animation` default空文字: opt-inで専用空振り、未設定characterは既存動作。
`throw_hold_offsets_by_fighter` default空Dictionary: 相手の正式体格／絵に合わせて保持位置をData指定。値がVector2のみ採用、未登録対象は既存throw_hold_offset。
剛／聖夜の保持距離は125→75。クラッシャーの保持は剛・聖夜に限り75、アッキー等は従来125を維持。実画面で生じた手と胸の空間を調整。腕そのものの長さは変更なし。
Damage／startup／recovery／Counter受付140ms／throw Range／位置交換／耐性／Down／Bounce条件は変更なし。保持距離の変更は解放位置に影響するが、軌道速度・初期成立範囲は維持しwall/counter/実物理を再検証。
4投げのrelease animationを方向別に指定し、全過程でattackerとvictimが同じ投げDataを参照。ダウン後のKOが旧画像に戻る接続を検出してKO／stand_up／get_up aliasesを新素材へ統一。特殊技固有のDownまで全統一したという意味ではない。

## 初期値（変更なし）
| Throw | Startup秒 | Recovery秒 | Damage倍率 | 特性 |
|---|---:|---:|---:|---|
| Neutral | .12 | .30 | 1.0 | 至近距離Down |
| Forward | .17 | .38 | .9 | x480 / y-180の飛行 |
| Down | .20 | .42 | 1.3 | その場、Down1.1秒、Bounce最大1 |
| Back | .10 | .38 | .9 | 位置交換、短い接近Counter |
Whiff .60秒（Down .65秒）。既存Campaignのthrow damage＋各fighter倍率／受け耐性を使用。新Punch/Kick/Air/Combo/Special／Effect／HitBox/HurtBox／AI変更なし。

## 検証
- Native Intel Iris Xe Forward Mobileで全172frame、左右両向き: 非空、指定source atlas、sprite倍率一定。formal立ち／contact／Down／WakeUp／KOの比較panelと代表両向きpairを目視。
- Fullatlas: Gou143clips382frames / Seiya148clips403frames、failures=[]。旧KOと新Downが一致しない失敗を修正し再実行合格。
- `stage1_hero_throw_live_check`: 各heroでAttacker/Victim双方×4方向×左右=16、両hero計32実Physicsケース。掴み・release・Damage一重適用・Down・GET_UP・HurtBox/制御復帰。各hero4方向×左右=8whiffケースも専用pose、再投げ不能、硬直解除。headlessとnative共にfailures=[]（最終保持位置75で再検証）。
- `stage1_heroes_throw_pair_review`: 32case×hold/release=64枚。共通処理のタイマーを指定値へ進めた固定snapshotであり自然連続playの証拠と区別。両Actorを同時更新しframe固定、保持距離75、failures=[]。
- Native live snapshotはActorの物理とsprite playbackを一時停止して取得後に再開。PNG保存待ちでimpact frameが次のframeへ進む撮影上の問題を修正。固定snapshotと実Physics検証の役割は区別する。
- `stage1_hero_throws_check`両hero: 120ms履歴、スマホUI handler、wall際Back入替、接近Counter／後退／遅延失敗、Guard崩し、投げ再受付、耐性、Air/HitStun/無敵/Down/KO制限、failures=[]。
- アッキー既存 `directional_throws_check` failures=[]。
- 両hero Launcher→AirP→AirKの実3Hit route、両heroガード／空中ガード、Special Reversal、Stage開始→敵KO→StageClear、Stage1既存KO/GameOver/Retry回帰はfailures=[]。
- 通常被弾全種／Special固有受け／WallHit／全Stage manual play／スマホ実機手操作／公開Webは今回未確認。1対1のためMultiple Enemyを完成条件には含めない。
- 全新textureは2048未満、追加effect/node生成なし。Iris Xeでnative描画可能。定量FPS／スマホ端末性能計測は未実施。

## ファイル
変更: PlayerAttackData、player_combo_movement、Gou/Seiya/Crusher各4throw.tres、ally_power/ally_speed、両motion_atlasテスト、stage1_hero_throw_live_check。
新規: 4source folder（key_poses/same_scale/native比較）、4atlas folder（png/tres/packing_manifest）、pack_stage1_hero_throw.py、build_stage1_hero_throw_review.py、stage1_heroes_throw_review.gd、stage1_heroes_throw_pair_review.gd、この報告。

## 未解決・次工程
importはexit0だが既存Safe-save permissions errorあり。一部headless終了時ObjectDB leak warningあり。警告なしとは扱わない。
剛・聖夜のSpecial攻撃／Special被弾／Special Guard及びHigh/Low/Launch等旧素材の正式デザイン統一は継続対象。既存Special挙動は回帰確認のみで今回専用絵の完成は報告しない。GouのSpecial Dataにはguard_damage_multiplier=.15、Seiyaは専用2段実行があるため、次工程で実packetのGuard chipと総Damageを仕様と照合する。今回勝手に必殺技の主要挙動は変更していない。
公開はデザイン統一・残るSpecial接続・実戦確認がそろってから。現在ローカルphase保存まで。
