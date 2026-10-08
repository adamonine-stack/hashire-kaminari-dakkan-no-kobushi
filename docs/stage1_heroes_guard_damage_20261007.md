# Stage 1 剛・聖夜 防御／通常被弾の統合工程（2026-10-07）

## 範囲と保全
- 開始／終了branch: codex/stage1-gou-seiya-20261007
- 開始HEAD: 70075ff011b5aa840bc7f14effb7e67fa0729a7f
- 終了HEAD: この文書を含むphase commit（git logで特定可能）。
- 開始statusは phase_heroes_guard_start_status.txt。終了statusは phase_heroes_guard_end_status.txt に保存。既存の大量のimport/uid、fighter_definition.gd、seiya_head.gdshader等はcommitに含めない。
- 1対1、既存戦闘エンジン／入力／ダメージ／投げ／ステージ進行は変更なし。後勝ちextra atlasを2fighter定義へ追加。

## 専用画像と接続
各キャラ7clip、合計14clip: guard / crouch_guard / air_guard / guard_hit / air_guard_hit / damage_light / damage_heavy。
各8source key pose（立ち校正1 + 新規7）。各clip計16frame参照は保持・共有復帰画像を含み、16個の新規中間絵ではない。
立ち／しゃがみ／空中ガードは2参照の保持loop。地上／空中guard impactは専用受け→保持pose。Light/Heavyは受け→復帰pose→立ち。
しゃがみguard impactは既存仕様通りcrouch_guardを維持。専用crouch guard hitやSpecial guardは今回追加していない。

剛: gou_guard_v10、uniform scale 0.47540983606557374、校正height203。
聖夜: seiya_slim_guard_v12、uniform scale 0.42951541850220265、校正height195（既存承認基準）。
セル384x288、atlas1536x576、ground足元270、airは物理座標と絵のoffsetを分離。head_scale_override=1、全frame共通sprite scale。部位の引き伸ばしなし。
正式立ち姿とキーposeを比較後、Godot描画を両向きで比較。剛の体格・肌・白tank・黒trousers・草履、聖夜の細身・頭身・白長袖・beige trousers・白sneakersを確認。
今回kick画像の修正／拡大縮小なし。以前修正した脚長を維持。

## 調査・変更ファイル
既存: CharacterVisualControllerのextra atlas順序とalias、player_movementのguard/state routing、既存air_guard_check、ground_received / throw / air combo regression。
変更: ally_power.tres、ally_speed.tres、gou_motion_atlas.gd、seiya_motion_atlas.gd。
新規: tools/pack_stage1_hero_guard.py、両キャラsource画像・比較画像、player02/guard_v10及びplayer03/slim_guard_v12のmotion_atlas.png/tres/packing_manifest.json、stage1_heroes_guard_review.gd、stage1_hero_guard_check.gd、stage1_hero_ground_received_live_check.gd、この文書。
新Input／Move／Combo／Special／AI／HitBox／HurtBox／バランス数値の変更なし。

## 確認結果
- Native Intel Iris Xe Forward Mobile: 2キャラ×2向き×17pose=68描画。全pose非空、固定scale、指定atlas source一致。右／左の画像を目視比較。
- Fullatlas: Gou124clips354frames / Seiya129clips376frames failures=[]。
- 両キャラguard check headless及びnative: Gで空中guard、通常／Specialのguardable hitを0damageで受ける、空中の垂直速度保持、release、背面／unguardable／throw拒否、Down／KO／throw拘束制限、実重力で着地→standingguard、地上standing/crouch guard、両facing、観測遅延AI airguard。failures=[]。
- 両キャラ通常被弾fixture headless: Light/Heavy×2facing、receive_attack→1damage→専用atlas→90physics ticks→操作／HurtBox復帰、failures=[]。明示的reaction packetを使う検証であり、実HitBox衝突によるLight/Heavy振分け確認とは区別。
- 両キャラ実空中3Hitコンボ（Launcher→AirP→AirK）、方向投げ、急降下Kick Hit/Guard/Whiff・着地硬直、Stage開始→EnemyKO→StageClear regression全てfailures=[]。
- Native通常被弾fixtureの画像確認は下記追記参照。

## 修正・限界・次工程
新テスト初稿の攻撃高さを誤ってmidとしていたため、既存正式値highに修正。またしゃがみguard impactの期待を既存crouch_guardへ修正。ゲームロジック変更なし。
importはexit0だが既存Safe save permissions errorあり。一部headless test終了時ObjectDB leak warningあり。警告ゼロとは報告しない。
実スマホの手操作、公開Web、全Stage manual playは今回未確認・未公開。
投げ攻撃／投げ受け、High/Low/Launch/Down/起き上がり、Special攻撃／受けの全専用art完成とは扱わない。残るモーションも両キャラの関連工程をまとめ、正式design比較を省略せず進める。

Native通常被弾fixture（両キャラ、Light/Heavy×左右）はfailures=[]。戦闘画面のHeavy右／Light左画像を目視確認し、専用絵が選択されることを確認。nativeの描画／自動入力確認でありスマホ実手操作ではない。
