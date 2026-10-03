# 第3ステージ テキ 公開結果

[公開ゲーム](https://adamonine-stack.github.io/hashire-kaminari-dakkan-no-kobushi/)

- 実装Commit: `1e24ac42afe6f18deb825c43786d1e1e603ec382`
- 全回帰資料Commit: `610998ecb7af61fbf7d7ea1fa835006a8e7e3fdb`
- [PR #168](https://github.com/adamonine-stack/hashire-kaminari-dakkan-no-kobushi/pull/168): Merge済み
- 公開Merge Commit: `e2fd41a99990036961b1b480d1752d2c09ebad8f`
- [Pages run 37112817091](https://github.com/adamonine-stack/hashire-kaminari-dakkan-no-kobushi/actions/runs/37112817091): build / deployともsuccess
- 公開HTMLのRuntime: `game-e2fd41a99990`。JS、WASM、PCK、2個のAudio WorkletすべてHTTP200。PCKサイズ116390924byteはHTML宣言と一致。
- 公開PCK SHA256: `4d53c6789e8eb764ffc510385f4d3f04c96eda7a0b7bd096cac162a8b87560f7`

公開PCKを実際にダウンロードし、Godot4.7で再検証した。Packed project.binaryの存在を確認して公開Resourceを使用。Special Headless: failures=[]。Native gl_compatibility: Special111枚とDamage129枚、Damage全190Frame左右検査、両テストfailures=[]かつERROR/WARNINGなし。画像はpublic-native-review-1/2.jpgとして比較した。Wrapperは保存先のみ変更し検証内容は同じ。

これは公開ゲームデータを使用したNative描画検証であり、ブラウザCanvas内の目視ではない。CUAのbrowser inventoryは空で、Edge/iabともBrowser unavailableとなったため、公開Webの目視・手操作試遊、スマホ実機確認は未実施。HTTP200だけで描画成功と判断していない。

ローカル40件の回帰は機能成功。既存5件の終了時ObjectDB警告、長時間Balance試遊・複数Enemy/Boss専用の手操作検証未実施は実装報告の19項を参照。

公開Mainへ並行して入ったPR #167（正式テーマ曲・スタッフロール）を保持。統合したMainのCIでもTeki/Special/Stage3およびEnding・テーマ曲の検証が成功している。

正確な改修File一覧: evidence/teki_audit/teki-changed-files.txt。公開検証詳細: evidence/teki_public/verification.json、pages-run.json、assets.json、packed-*-*.log。240枚の公開データNative画面と116MBのPCKそのものはローカル保持し、Gitには比較Sheetと検証metadata/logのみ保存。

`git status --short`: evidence/teki_public/git-status-after-public.txtへ保存。追跡済み実装Fileの未Commit変更なし。抽出元全Frame、Native画像、Godotテストuserdata/cache等のローカルQA資料は未追跡で保持している。
