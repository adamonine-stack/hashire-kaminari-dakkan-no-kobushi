# AKKY 方向攻撃・ダウン復帰工程（2026-10-04）

作業先: `.directional_combat_20261003`。branch: `codex/directional-combat-20261003`。
開始HEAD: `200f47ee95b985456c783cc42976694695093f9e`。
元の作業先 `.st_action_theme_20261003` とユーザーの未コミット変更は変更していない。

今回の工程はAKKYの地上方向攻撃とダウン・起き上がり画像の接続。戦闘拡張全体の完了ではない。

## 追加した戦闘処理

既存のPlayerAttackData / 共通Player継承 / HitBox・HurtBox・Damageを拡張した。
方向はキャラクターの向き基準。既存の150ms Input Buffer / 600ms履歴を使い、方向を離して120ms後にP/Kを押す経路も検証した。InputMapや右親指の2ボタン同時押しは追加していない。

| 技 | Startup / Active / Recovery (秒) | 基本Damage | 判定サイズ・Offset | 移動・役割 |
|---|---|---:|---|---|
| P | .08 / .08 / .16 | 11 | 54x32 / (62,-140) | 近距離、最速 |
| P2 | .09 / .08 / .18 | 12 | 58x34 / (64,-140) | 既存連続技 |
| K | .16 / .10 / .28 | 18 | 86x38 / (64,-90) | Pより長い |
| Forward P | .12 / .08 / .24 | 12 | 60x34 / (68,-137) | 前進38 |
| Back P | .08 / .10 / .28 | 10 | 42x76 / (29,-166) | 高い判定、短時間の上体回避、軽い打ち上げ |
| Down P | .20 / .09 / .34 | 11 | 50x64 / (36,-130) | Launch (55,-420) |
| Forward K | .25 / .10 / .40 | 17 | 78x38 / (89,-105) | 前進85、Knockback320 |
| Back K | .15 / .09 / .30 | 13 | 76x38 / (82,-105) | 後退35、上体回避、壁で後退距離を失う |
| Down K | .18 / .09 / .32 | 14 | 82x28 / (98,-20) | Low / Knockdown、連続キャンセルなし |

数値は初期値。判定・移動は既存のbattle scale / geometry scaleを掛ける。DamageはCombo補正前。

新技の接触フレームをデータ指定し、Startup/RecoveryではHitBoxを無効化する。HurtBoxのみ短時間変更し、Spriteを潰して回避させない。
新技の前進/後退はCharacterBodyのvelocity経由とし、ステージ境界を尊重する。
カウンターは受け手のStartupを観測してHitStunを加算。固定技IDの勝敗判定はない。既存Crusher Armorを維持する。
Launcherは通常HitStunのまま浮かせ、Down拘束や全身無敵にしない。3Hit制限と既存Combo補正を維持。

Data-driven Cancel: P -> Forward P、Back K -> Forward P、Forward P -> K / Forward K。各Resourceのcancel_start/end/targetsとHit確認を使い、未指定技へのCancelとWhiff Cancelを禁止する。
Down P / Back Pからの追撃は高さ・距離に依存。Jump CancelやLauncher -> Air P -> Air Kの完成は次工程。

## 画像の修正と接続

正式参照: `godot/assets/characters/player01/battle.png` と `portrait.png`。
長袖・袖口、腹部を覆う黒いタートルネック、細身の体格、顔、髪、脚の比率を維持する。

新Attack画像: Straight P、Uppercut、Standing K、Sweepの4Frame素材。通常P/P2/Kも新Atlasへ接続。
新Damage画像: 倒れる3Frame + 修正済みダウンKey Pose、起き上がり4Frame。
`knockdown` / `knockdown_high` / `knockdown_low` / `down` / `ko` / `special_knockdown` / `stand_up` / `get_up` をdown_v2へ接続。
ダウン末尾と起き上がり先頭は同じAtlasセルを参照する。

320x224セル、基準点(160,208)。同じ素材内は固定倍率。しゃがみや横倒しを各フレームの外接矩形へfitしていない。
Proneセルのalpha>=.5境界は195x67。単なるSprite.scale固定を「体格一致」の証拠とせず、正式立ち絵・キーポーズ・実ゲーム描画を比較した。
拒否された太い体格、淡白な顔、長い脚の画像はruntimeへ接続していない。
他キャラ、特殊投げ被害者、キャラ固有Wall/Throw/Special専用反応の全面修正は未実施。

## 検証結果

- `combat_command_buffer_check.gd`: failures=[]（入力基盤工程で実施）
- `combat_command_integration_check.gd`: failures=[]
- `directional_attacks_check.gd`: failures=[]。両向き6技、既存MobileControlsのボタンhandlerで方向保持/離して120ms後のアクション、Contact/Recovery、Launcher/Sweep/Guard/Counter、Cancel制限、実Area2DのForward K Hit、浮いたHurtBoxへのSweep Whiff、壁際Back K。
- Jump KがActiveの場面で通常P Startupは被Hit、適切にActiveになったBack Pは高さと上体HurtBoxによって迎撃。全高さ/距離/Timingで必ず勝つという試験ではない。
- `akky_down_motion_check.gd`: failures=[]。全8別名の新Atlas接続、端の切れ/足元、共通Proneセル、実Down -> WakeUp、両向き倍率/座標、HurtBox復帰。
- `akky_motion_atlas.gd`: 107 clips / 325 frames / failures=0。
- `special_reversal_check.gd`: failures=[]。既存Specialを保護。
- `stage1_regression.gd`: failures=[]。Stage開始/攻撃/Jump/HitStop/Clear/Retry/AIによるKO・交代/GameOver。
- `directional_visual_review.gd`: Intel Iris Xe / OpenGL compatibilityで全新Attackフレームを両向き描画、ダウンと起き上がり全Frame、KOをPNG出力。代表画面とAtlasを目視比較。

Mobile確認は既存UI handler -> InputMap -> Bufferの自動確認と1280x720の描画まで。実機Touch、手動戦闘、Web公開、Iris Xeでの負荷計測は未実施。
Windows root certificate storeのエンジンエラーは環境由来で残る。新テストの終了時AudioStream警告はBGM停止処理を追加して再検証。

## 残作業

方向Throw、位置入れ替え/Counter Throw、Throw Victim同期、Air P/Down Air K、Jump Cancel/Air Combo、Enemy技体系とSituation AI、Crusher全体系、他Character展開、特殊反応のDesign再監査、Multiple Enemy、スマホ実機・全Stage回帰・負荷測定。
既存Specialの新規制作・約1.5倍Damage調整は本工程には含まない。

変更一覧・終了HEAD・コミット・終了git statusは`directional_git_result.txt`参照。
