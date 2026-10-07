# クラッシャー地上被弾統一（2026-10-07）

branch（開始/終了）: codex/stage1-gou-seiya-20261007
開始HEAD: 8b5396d9e0bfbfd5de2e2c090f8974bc4ac3acd4

## 制作・接続
画像生成スキル/built-in imagegenを使用し、正式立ち姿を基準にLight/Heavy/High/Lowの4被弾姿勢を作成した。プロンプトは同じ顔、赤いバンダナ、筋肉量、粗い肌のピクセル陰影、黒タンクトップ、カーゴパンツ、ブーツ、同じ骨格長、足接地、透明背景を指定。軽い肩の反動、体幹の後傾、顎の上反り、脚を畳んだ低い受けに区別した。
保存先: art_sources/crusher_ground_received_v10、godot/assets/characters/enemy01/animations/unified_ground_received_v10。
共通倍率0.47010309278350515（正式立ち姿の身長から算出）、足元260px。低い姿勢を独立に拡大/縮小しない。Pythonは透明画の連結成分分離と一律倍率Atlas配置のみ使用。
各クリップは3フレーム。Lightは接触姿勢を2フレーム保持、他は接触→軽い反動→正式立ち姿の共通復帰。12枚の独立新規絵ではない。復帰フレームには正式立ち姿の元画像をコピーした。既存fpsを維持。追加Atlasを末尾に登録し、4つの既存アニメーション名を上書きする。戦闘ロジック、Damage量、発生、判定、AI、Saveには変更なし。

## 検証
CRUSHER_GROUND_RECEIVED_REVIEW poses=13（Intel Iris Xe実描画）: 正式立ち姿＋全12フレーム、同一Sprite倍率、新規Atlas参照、空画像なしを確認し比較画像を目視確認。
CRUSHER_GROUND_RECEIVED_CHECK failures=[]（headless/実描画）: 左右4種のreceive_attack経路で1Damageを一度だけ適用、反応の選択/画像参照/倍率、HitStun終了と操作状態復帰を確認。これは明示的hit_reactionを含むテスト用ダメージパケットによる受け処理検査で、全4種の自然なHitBox衝突を再現した検査ではない。
CRUSHER_AIR_RECEIVED_CHECK gou/seiya failures=[]: 既存の実衝突Launcher→Jump→AirP→AirKが左右3Hit成立、着地復帰、新規空中受けを維持。今回のAtlas追加による回帰なし。

## 発見・修正
Atlas保存後に復帰フレームを貼っていたため、実描画テストで最終フレームが空になる失敗を検出。貼り付け→保存の順に修正し、再インポート後に全12フレームが通過。生成画像の行高さが不均一だったため、キーの行分離境界も適切な位置に修正した。

## 未完了・境界
全モーション統一/全Stage回帰/手動スマホTouch/公開は未完了。インポートの既存Safe save権限エラーと、初回headless受け処理テスト終了時のObjectDB4件リーク警告は残る。実描画の比較/受け処理は終了コード0。Start/End statusはphase_crusher_ground_received_start_status.txt / phase_crusher_ground_received_end_status.txtに保存。既存未コミット変更は保持。
