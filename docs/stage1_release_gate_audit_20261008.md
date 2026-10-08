# 第1ステージ公開前の総合確認

開始branch: codex/stage1-gou-seiya-20261007
開始HEAD: c48b22ddb72f040426c82cd06fed631386161566

## 今回確認したこと
4人の攻撃Contact比較画像を再構築し、AKKY・Crusher・Gou・Seiyaの右向き代表Contactを目視比較した。全フレームの目視完了とは扱わない。Crusher Back Pの旧素材には、正式立ち姿および新Launcherに比べ滑らかな肌と顔の描画密度差が残る。公開前の修正対象。

- ネイティブ全登録モーション検査:541 clips、failures=[]。全atlas領域を検査、各clipの代表poseを描画し固定scaleを確認。解剖学的デザイン一致の自動証明ではない。
- AKKY/Gou/Seiyaの生ScreenTouch入力:raw_touch=true、各failures=[]。左右、方向保持・離した履歴、遅延action、失効buffer、Jump/Kick等の既存ケース。実機スマートフォンではない。
- Gou/Seiyaの投げ・受けlive physics:双方failures=[]。Crusherとの双方向投げ、左右、復帰、scale/origin確認。
- Special reversal、Special situation AI(9characters)、Air Guard、Stage1 regression:failures=[]。
- Crusher situation:前進Kickを至近距離90pxで当てる旧fixtureが失敗。設定ai_distance_min/max=115/205に対して175pxへ修正すると、左右とも自然なArea2D衝突に成功。AI距離選択の近距離P/中距離K/遠距離Forward Kも通過。攻撃の判定や威力は今回変更していない。
- Crusher situationネイティブもpass。導入演出のawait待ちを除きintro完了をfixtureで明示し、音声Dummy使用。

## 今回修正したファイル
godot/tests/crusher_situation_check.gd:前進Kickの適正距離fixtureとnative intro待ち。製品の技性能、デザイン、Save、1対1ルール変更なし。既存の別作業の変更を保持。

## 検証上の問題
全motion描画テストをheadlessで実行した初回はviewport imageがnullとなり停止した。ネイティブで再実行し541clips成功。モバイルtestの初回引数--raw-touchは未対応でraw_touch=falseだったため、正式な--touchで3人を再実行した結果のみ生Touch確認とする。複数のテスト終了時にObjectDB cleanup警告が残り、警告なしとは報告しない。

## 公開までの残り工程見込み
大きく3〜4工程。各工程を1技ごとの細かいチャットに分割せず、関連確認をまとめる。
1. Crusher Back Pの正式デザイン適合と、攻撃・受け・投げ・Down/KO/Guardの最終デザイン差確認。追加の差が出れば同工程で修正。
2. 3主人公での第1ステージ通し戦闘、KO/Continue/Retry/Result/Pause、スマホ相当レイアウトと入力、実画面確認。自動・native・手動相当証拠を区別。
3. Webビルド、公開用の変更範囲確認、commit/push/PR/merge、GitHub Pages deployment完了待ち。既存deploy-godot-web.ymlのmain公開経路を使用。
4. 公開先の起動、キャラ選択、第1ステージ戦闘・クリア、cache-safe更新確認。3と4を同じ公開工程にまとめられれば計3工程。

追加不具合がない場合の見込みであり、日時保証や全デザイン承認ではない。現時点は未公開。公開フローはworkflowファイル確認のみで、ネットワーク上の最新deployment状態は本工程で確認していない。
