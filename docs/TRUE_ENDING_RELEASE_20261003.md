# 真エンディング公開確認（2026-10-03）

- 実装PR: https://github.com/adamonine-stack/hashire-kaminari-dakkan-no-kobushi/pull/164
- 公開コミット: `6058f8e43d91be50fa4a93897f53cbb6c232134b`
- Pages成功: https://github.com/adamonine-stack/hashire-kaminari-dakkan-no-kobushi/actions/runs/37093618321
- 公開URL: https://adamonine-stack.github.io/hashire-kaminari-dakkan-no-kobushi/?v=6058f8e43d91
- 配信ランタイム: `game-6058f8e43d91`。JS/WASM/PCKとaudio worklet 2ファイルはすべてHTTP 200。

公開版を専用セーブで起動し、実際の攻撃で裏セイヤを倒した後、敗北会話、退場、スイッチ、島の脱出、波止場、海上、爆発、夜明け、BLACK SPARROW、TRUE ENDING、スタッフロール、タイトル帰還を確認した。PC画面と844×390のタッチ対応横画面で成功。途中のEscapeやタップで通常操作・中断に戻らず、IndexedDBに `true_boss_defeated=true` と `true_ending_unlocked=true` が保存され、タイトルに `TRUE ENDING CLEAR` が表示された。ページ・ランタイム・HTTPエラーはなかった。

通常エンディングAとBAD END Cも公開版の横画面で成功。CIでは既存7ルート、真セイヤ戦、真エンディングと他の回帰チェックが成功した。

初回公開読み込みが固定14秒待機を超えたため、検証スクリプトを実際の起動完了待ちに修正して再実行した。検証時の注入はHTML起動設定と専用セーブのみで、公開JS/WASM/PCKは変更していない。

証跡は `evidence/web/true_ending_public_desktop/`、`evidence/web/true_ending_public_mobile/`、`evidence/stage8/public_A_mobile_*`、`evidence/stage8/public_C_mobile_*`、`evidence/release/` に保存した。これは専用セーブによるブラウザー自動検証であり、全ステージ通しの手動プレイや実機スマートフォン検証ではない。
