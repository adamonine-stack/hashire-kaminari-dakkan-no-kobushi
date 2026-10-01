# STAGE 8 第一エンディング実装・確認記録

作業ブランチ: `feat/stage8-true-ending-20261001`。基準: `origin/main` の `826851040a53b6d0c67a1832ead391d1a16d2f94`。
既存の `.opening_dialogue_20261001` の未コミット変更・未追跡ファイルには手を加えず、独立した作業ツリーで実装した。

## ストーリーの接続

STAGE 8 の敵撃破後は戦闘・入力・リザルト重複を停止し、2.5秒のクリア表示から収容区画に接続する。生存者のHPと死亡フラグのスナップショットで分岐し、会話途中では再判定しない。
会話は提出台本を `godot/data/story/stage8_dialogue.txt` に格納。要約・説明セリフの追加なし。明示的に指定された重要文は連続した原文を同一ページに表示する。

通常ルート: 再会 → 不在の救出対象を尋ねる → 黒幕の示唆 → 0.8秒暗転 → TO BE CONTINUED…。
TRUE ROUTE: 同じ黒幕の示唆 → 暗転しない3秒の沈黙 → セイヤの笑い → 真相告白 → BGM停止 → 最深部に移動・構え → TRUE FINAL BATTLE → セイヤ戦。
セイヤ単独は「……残ったのは俺だけか……。」「……くくく。」「くはは……。」「あはははははー！」の4セリフと間・暗転だけ。

## キャラクターと背景

ミオ・レンは imagegen による新規の透過PNG。既存2Dの描写に合わせた通常Spriteで、アトラスを置換しない。
ミオ: 茶色の肩までの髪、紫のカーディガン、水色のワンピース。アッキーの恋人。
レン: 茶色の短髪、青いパーカー、白いシャツ、濃紺のパンツ。ゴウの弟。
新規の収容区画背景は開いた牢・暖色の照明・紫色の奥の通路で救出と不穏さを表現する。
主人公は既存Playerシーンと既存の待機画像を使用。全員の足元を同一座標に合わせ、名前札と話者の明るさで誰の発言かを示す。ユイ本人の画像・Spriteは追加しない。
1280×720の会話領域を等比縮小し、スマホ横画面844×390でも文字・キャラクター・次へボタンを領域内に収める。

## 分岐結果

|ルート|生存者|救出・表示|終了|Godot描画確認|
|---|---|---|---|---|
|A|アッキー|ミオ|TO BE CONTINUED…|合格|
|B|ゴウ|レン|TO BE CONTINUED…|合格|
|C|セイヤ|なし|BAD END|合格・4セリフ完全一致|
|D|アッキー・ゴウ|ミオ・レン|TO BE CONTINUED…|合格|
|E|アッキー・セイヤ|ミオ|TO BE CONTINUED…|合格|
|F|ゴウ・セイヤ|レン|TO BE CONTINUED…|合格|
|G|全員|ミオ・レン|告白→TRUE FINAL BATTLE|合格|

全分岐でユイ非表示、死亡主人公の救出対象非表示、会話順序、タイトル復帰、二重クリア防止を確認。
Gは「まだ裏で操っている奴がいるのか……。」直後の暗転なし、告白・TRUE BOSSカード・戦闘開始を確認。
既存セイヤのスプライト・攻撃・被弾・KOモーションを敵用Resourceとして再利用。HP150、既存ボスAI、アッキーとゴウのみ交代可能。
実際の物理移動、双方の攻撃HitBoxによる被弾、攻撃によるKO→勝利、主人公交代、全滅、リトライ、保存→CONTINUEの最終戦再開を確認した。

## 検証の証拠と範囲

`stage8_ending_check.gd`: 実際のBattleシーンでSTAGE 8クリア判定を通し、7種類の生存状態から実際のエンディング・最終戦シーンを描画する自動検証。`STAGE8_ENDING_CHECK failures=[]`。
`true_seiya_combat_check.gd`: 本物の戦闘キャラクター・物理・HitBox・セーブ・タイトル再開を使用。`TRUE_SEIYA_COMBAT_CHECK failures=[]`。
通常のSTAGE 1回帰、STAGE 7・8アトラス、オープニング、和文フォントの検証も合格。既存オープニング検証は終了時のObjectDBリーク警告2件を出すが、今回の新規検証にはランタイムエラー・警告なし。
証拠画像は `evidence/stage8/`。全8ステージを手操作で繰り返し攻略したという意味ではなく、各生存条件を設定して実ゲームシーンを動かした検証である。
スマホは横画面サイズとブラウザーのタッチ対応環境での確認。実物のiOS/Android端末では未確認。

Web書き出し版でも7条件の専用セーブからCONTINUE・既存STAGE 8開始会話・実際の敵への攻撃とKO・救出会話・各終了まで画面操作で確認した。通常5ルートのTO BE CONTINUED、セイヤ単独BAD END、Gの実際のセイヤ戦開始を確認。ミオ・レンの両方が登場するDは844×390のタッチ対応ブラウザーでも確認。`tools/stage8_web_check.cjs` は新規ブラウザーcontext内のセーブだけを用意する検証ツールで、公開PCK・JS・WASMを改変しない。

描画・ブラウザー確認で修正した問題: 待機中の主人公の姿勢、会話ボタンと足元の重なり、セイヤ戦HUDの右端切れとポーズボタンの重なり、最終戦リトライ後の開始条件、最終戦を通常ステージとして開くCONTINUE遷移、敵Sprite再生成時に保存済みHPがシグナルで上書きされる問題。
公開版の確認では、既存のキャッシュ対策によるファイル名更新で音声補助ファイル2種類が更新されず、AudioWorklet/PositionWorkletが404になる問題を発見した。公開ワークフローで補助ファイルも同じコミット付きの名前へ更新し、書き出し検証でも存在を必須にする修正を追加した。

## 追加・変更ファイル

追加: `godot/assets/backgrounds/stage8_detention.png`、`godot/assets/characters/rescued/mio.png`、`ren.png`（各Godot import設定）、`godot/data/story/stage8_dialogue.txt`、`godot/data/enemies/enemy_09_seiya.tres`、`godot/data/stages/stage_09_true_seiya.tres`、`godot/scenes/Stage8Ending.tscn`、`TrueBattle.tscn`、`godot/scripts/ui/stage8_ending.gd`、`godot/scripts/battle/true_battle_manager.gd`、2検証スクリプト（各UID）、本記録と証拠画像。
追加の検証ツール: `tools/stage8_web_check.cjs`。
変更: `godot/scripts/battle/stage1_battle_manager.gd`、`battle_manager.gd`、`godot/scripts/ui/title_screen.gd`、`godot/export_presets.cfg`、`.github/workflows/deploy-godot-web.yml`。
旧セーブのversion・キャラクターID・各HP等は維持。新規sceneキーは最終戦の再開先の区別に使用し、旧セーブは従来のBattleシーンへ進む。

公開URLは既存の https://adamonine-stack.github.io/hashire-kaminari-dakkan-no-kobushi/ を維持。commit・push・デプロイ結果と公開版での検証結果は作業完了報告に記載する。
