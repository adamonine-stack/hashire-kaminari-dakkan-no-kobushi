# クラッシャー空中受けデザイン統一（2026-10-07）

開始/終了branch: codex/stage1-gou-seiya-20261007
開始HEAD: 8bd11b410d8a0239a888540680649154bf9c7ffb

## 実装
正式な立ち姿 art_sources/crusher_throw_design_v2/formal_standing.png を参照し、肌の陰影・顔・赤いバンダナ・黒いタンクトップ・カーゴパンツ・ブーツを揃えた空中受け4ポーズを作成。launch_hit、air_hit、knockbackに各2フレームで接続した。4ポーズは共有接続を含み、6枚の独立新規画像ではない。
骨格の部分伸縮をせず、基準立ち姿からの一律倍率0.4461839530332681で配置。空中姿勢のセル位置は基準身長から設定し、物理ジャンプ/吹き飛ばしと分離する。体格は立ち姿・実描画比較で目視確認。
攻撃の威力・HitBox・HurtBox・発生・連携条件・敵AIには変更なし。画像参照の追加だけで既存の技別Special/Throw反応とDown/Wakeupを保持する。

## 制作
画像生成スキルのbuilt-in imagegenを使用。透明背景で、正式立ち姿を第1参照として、打ち上げ、空中被弾、後傾吹き飛ばし、下降受けを作成するプロンプトを使用。共通条件は同じ顔/肌のピクセル陰影/衣装/骨格長、脚を長くしない、身体を太くしない、ラベルやEffectなし。Pythonは連結成分の分離・同率縮小・Atlas配置に限定。
保存先: art_sources/crusher_air_received_v9 と godot/assets/characters/enemy01/animations/unified_air_received_v9。

## 検証
- CRUSHER_AIR_RECEIVED_REVIEW poses=7：Intel Iris Xeで正式立ち姿＋全6クリップフレームを描画、空画像なし、共通Sprite倍率、専用Atlas参照を確認。
- CRUSHER_AIR_RECEIVED_CHECK gou failures=[]：headless・実描画双方、左右とも実衝突3Hitと着地復帰、launch_hit/knockback新規参照を確認。
- 同seiya failures=[]：headless・実描画双方、左右3Hitと着地復帰、launch_hit新規参照を確認。聖夜のこの3Hitは剛と異なり最終Down条件にならない既存仕様を維持。air_hitは比較シーンで参照/描画確認、実コンボ中の選択確認は未実施。
- CRUSHER_DOWN_RECOVERY_LIVE_CHECK failures=[]：左右Down/Wakeup後の操作復帰と既存Atlasを確認。
- 聖夜テストの初回失敗は剛専用Atlas名/最終Down期待をコピーした確認コードによるもの。キャラ別の既存条件に修正して再実行済み。

## 未完了
モバイル入力は既存ハンドラーのプログラム駆動であり、手動Touch/実機確認は未実施。全Stage回帰・全モーションデザイン統一・公開は未完了。聖夜空中キック接触画像では既存地上Heavy Hitが表示される瞬間もあり、その画像は今回の空中受け変更対象ではない。
インポートのSafe save権限エラーとheadless終了時ObjectDBリーク警告（15/25件、Down検査2件）は残存し、隠していない。実描画検査は終了コード0。
開始/終了statusは phase_crusher_air_received_start_status.txt / phase_crusher_air_received_end_status.txt。既存dirty/import生成物は保持し、本フェーズのファイルのみコミット。
