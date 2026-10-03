# 第4ステージ クロス 公開結果

[公開ゲーム](https://adamonine-stack.github.io/hashire-kaminari-dakkan-no-kobushi/)

- 実装Commit: da184fb79dad5c6a196663e9e057a73656c228d3
- PR #170: https://github.com/adamonine-stack/hashire-kaminari-dakkan-no-kobushi/pull/170 Merge済み
- 公開Merge: 08083b78e7f70e113e92886836e6e6173156be17
- Pages 37125923169: build/deploy success https://github.com/adamonine-stack/hashire-kaminari-dakkan-no-kobushi/actions/runs/37125923169
- Runtime: game-08083b78e7f7、JS/WASM/PCK/Audio Worklet2件すべてHTTP200
- 公開PCK: 117063792byte、HTML宣言と一致、SHA256 fcd0478e55f013edeeb03605ce654ff5790cbbc0a82c7d3779e043e46a2333a1

公開PCKをダウンロードしてGodot4.7で再検証。Native Wrapperはproject.binaryの存在を検査し、公開Resourceを使用した。倒れ/被弾/KO/Getup全291Frame左右検査・129枚描画と、主人公3人への自然必殺技接触/Guard/Whiff/投げ抜け/Recovery/同時Hit/AI/空中/Down禁止50Capture（48個別PNG）成功。基本54ケースと追加ケースは公開PCKのHeadlessでも成功。最終3LogにERROR/WARNINGなし。

倒れ候補347pxは不採用。正式立ち全高213pxに対し、新しい膝を曲げたDownの不透明域268px（描画外縁約269px）、Akky受け仰向け274px。Gou/Seiya受けも同じDownへ接続。runtimeの横scaleを潰さず原画の胴脚比率を修正した。

Native実行でGPU shader cache再利用による起動失敗が1回あり、別APPDATAへ分離して解消。短縮検証Wrapperのcurrent_scene設定漏れも修正し、正式テストと同じScene設定で再実行成功。これら失敗は成功として計上していない。

これは公開データのNative描画検証。CUA browser inventoryは空、iab unavailable。公開ブラウザCanvas目視・手操作、スマホ実機、長時間Balance、複数Enemy戦の手動試遊は未実施。ローカル46回帰は全機能成功、40件警告なし、既存6件の終了時ObjectDB警告は実装報告19を参照。

[21項目の実装報告](CROSS_STAGE4_REVERSAL_REPORT_20261003.md)。変更File一覧: evidence/cross_stage4_audit/cross-changed-files.txt。Native詳細: native-results.json、special/integrity/incoming各比較Sheet。公開詳細: verification.json、pages-run.json、packed-special-headless/packed-special-native/packed-damage-native.log、比較Sheet。大きい公開PCK/全PNG/ユーザーデータはローカル保持し、Gitにはmetadata/log/比較Sheetを採用。

`git status --short`はevidence/cross_stage4_public/git-status-after-public.txtに保存。自動生成Import/UIDを除外し、コードの追跡済み未Commit変更なし。抽出Frame/大量Native PNG/Shader cache等は未追跡QA資料として保持。他worktreeの既存作業は変更していない。
