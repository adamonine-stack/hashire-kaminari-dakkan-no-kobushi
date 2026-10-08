# 剛の急降下キック（2026-10-07）

開始/終了branch: codex/stage1-gou-seiya-20261007
開始HEAD: 5cdf53229490b7a297067f2169f86875383d5df5

## 追加技
↓＋空中K、gou_dive_kick。Direction Priority120（通常AirK20より優先）、既存150ms履歴。地上不可。Startup .18 / Active .16 / Recovery .36秒（実時間は既存キャラ倍率等を反映）。通常KのDamage倍率.9（現Campaign18）。HitBox48×46、Offset42/-24、Knockback130/-40、HitStun.24、HitStop.045、Guard可/Overhead、下降520・前進70、着地硬直.36秒、キャンセルなし、無敵/Armorなし。
既存の共通急降下/着地処理を使用し共有コードは変更しない。既存の他攻撃/移動/特殊技の値は維持。

## 制作・体格
正式立ち姿を参照し、画像生成スキルbuilt-in imagegenで校正立ち姿＋準備/下降/着地/復帰4キーを作成。白タンクトップで腹部を覆う、坊主頭の成人顔、黒ズボン、黄土色の草履と黒い鼻緒・足指、同じ筋肉量/頭サイズ/四肢の骨格長、透明背景、という条件を指定。
初稿の蹴り脚が長く見えたため不採用。再編集で蹴り脚の腰から草履までを25%短くすることを目標に膝/足首を近づけた（25%は指示値で実測保証ではない）。全身の縮小で解決しない。初稿はkey_poses_before_leg_revision.pngとして保持し、ゲームは修正版だけを使用。
全キーは203px校正の一律倍率0.39264990328820115、空中上端67px、地上足元270px。Sprite倍率は固定。Pythonは連結成分の分離/一律縮小/Atlas配置だけで、身体の部分加工はしない。
攻撃3フレーム（接触保持）と着地3フレーム。4つのキーを構成し、独立6枚の新規中間絵ではない。保存先art_sources/gou_dive_kick_v9、godot/assets/characters/player02/animations/dive_kick_v9。

## 検査
GOU_DIVE_KICK_CHECK failures=[]（headless / Intel Iris Xe実描画）：左右のHit/Guard/Whiff、命中18DamageとGuard0、地上拒否、降下とFacing反転、Landing時攻撃/HitBox解除、着地中P/K/Throw/Guard/Special/移動/Jump禁止、HurtBox有効、硬直終了後復帰を確認。
攻撃が先に終了しても着地硬直を保持、テスト用被弾パケットで着地硬直が中断されることを確認。120ms遅延・方向Release後のDownK優先、MobileUIハンドラーで方向7tick保持→Kを左右確認。実スマホ手動Touchではない。
GOU_MOTION_ATLAS_OK clips=122 frames=350 failures=[]（専用参照/固定倍率）。GOU_DIVE_KICK_REVIEW poses=7（正式idleと全フレーム実描画を目視比較）。
CRUSHER_AIR_RECEIVED_CHECK gou failures=[]：左右の従来Launcher→Jump→AirP→AirK実衝突3Hit/着地の回帰。
DEV053_STAGE1_OK enemy=enemy_01_crusher round_time=99：既存アッキーでステージ開始・HUD・Damage・敵KO・Stage Clearの自動検査。全手動プレイを意味しない。

## 未完了
残るGuard/Throw/被弾等のモーション統一、全Stage回帰、手動スマホ、公開は未完了。インポートの既存Safe save権限エラー、headless終了時ObjectDB警告23件（Stage1smoke4件）は未解決。実描画検査は終了コード0。
Start/End status: phase_gou_dive_start_status.txt / phase_gou_dive_end_status.txt。既存dirtyを保持し対象ファイルだけコミット。
