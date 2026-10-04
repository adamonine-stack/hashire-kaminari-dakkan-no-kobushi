# 走れカミナリ 奪還の拳 — メインテーマ導入記録

対象: `.st_action_theme_20261003/godot/project.godot`

ユーザー指定により、本日更新された `.true_ending_release_20261003` のコミット `0890add` を基に、専用ブランチ `agent/st-action-theme-20261003` に実装。元の作業コピーや直下の古い `godot` へは変更していません。

## 調査結果

- 実行Godot: `4.7.stable.official.5b4e0cb0f`。project.godotも4.7指定。
- 既存Autoload: SettingsManager / AudioManager / GlobalFontManager。AudioManagerを拡張し、新しいMusicManagerは追加していません。
- 従来BGM: AudioManagerが曲IDに応じて生成するWAVループ。TRUEエンディングのみ `res://assets/endings/true/ending_music.wav` を使用。
- 従来プレイヤー: BGM用AudioStreamPlayer 1台、SE用16台。TRUEエンディングには場面内の環境音・SEプレイヤーもあります。今回の対象シーンにAudioStreamPlayer2Dの配置はありません。
- Audio Bus: AudioManagerがMusic / SFXを実行時に存在確認して追加。Masterへ送出する既存構成を再利用。
- タイトル: Title.tscn / title_screen.gd。START→Opening.tscn→Battle.tscn。CONTINUEは保存されたBattleまたはTrueBattleへ直接遷移。
- ステージ・リトライ: BattleManagerが敵とステージを切り替え、fade_bgm()を呼ぶ構成。通常ステージのID・曲は維持。
- STAGE 8ボス: `final_boss`。全員生存ルートGの対峙演出・無音指示も維持。
- TRUE最終ボス: TrueBattle.tscn、`secret_boss`を維持。撃破→TrueEnding.tscn。
- その他のクリア: Stage1BattleManagerの既存クリア演出→Stage8Ending.tscnの7分岐。セーブ・台詞・操作・戦闘契約に変更なし。

## 音源

提供された `1-境界を砕いて.m4a` をFFmpeg 7.1 / libvorbis quality 5で、切断・正規化・速度変更なしに全曲変換しました。元M4Aは添付場所に残しています。

- 使用パス: `res://audio/local_music/st_action_theme.ogg`
- 絶対パス: `C:\Users\takas\Documents\hashire-kaminari-dakkan-no-kobushi\.st_action_theme_20261003\godot\audio\local_music\st_action_theme.ogg`
- 全長: 約214.77秒（3分34.77秒）。OGG容量: 3,906,630 bytes。
- 標準パスにも対応: `res://audio/music/st_action_theme.ogg`。
- MP3 / WAVは同じ場所の `st_action_theme.mp3` / `.wav` に対応。Godotインポート後に利用できます。
- ローカルパスを優先します。Suno URLへ接続する処理はありません。
- 末尾約2.28秒に無音を検出。タイトルは全曲終了後0.75秒待機して先頭から自然に再スタート。曲中のループ点は推測で設定していません。
- 元音源の平均-18.4 dB、ピーク-1.9 dBを変換後音源で確認。初期設定は既存BGM音量0.80・既存ゲイン0.68を維持し、聴感での最終調整は別途可能です。

音源が見つからない場合は一度だけ `ST-Action theme audio file not found` を警告し、タイトル・エンディングで元の曲を使用します。存在しないテーマ音源をpreloadしません。Godotのインポートキャッシュに残る旧音源も、ローカルファイルを外した場合には使用しません。

## 再生と制御

- タイトル表示: 先頭から1.25秒フェードイン。
- START / CONTINUE: 1秒フェードアウト完了後に次シーンへ。通常ステージBGMと重複しません。
- 通常ステージ: 従来のBGM・遷移を維持。
- 最終ボス: 従来の曲を維持。`play_theme()` / `play_theme_from_position(position)` / `fade_to_theme(duration, position)` で将来の同期演出に対応。サビ時刻の決め打ちはありません。
- STAGE 8通常・BADエンディング: テーマ曲を先頭から再生し、終端カードでも継続。タイトルへ戻る操作でフェードアウト。
- 全員生存ルートG: 既存の対峙BGM・無音指示を維持し、TRUE最終ボスへ。
- TRUEクリア: 戦闘BGMを1秒でフェードアウト。既存の映画演出と環境音・海上の無音を維持し、夜明けの既存BGM開始位置からテーマ曲を先頭再生。
- TRUEスタッフロール: 曲の残り時間に合わせて流し、全曲終了後にタイトルへ戻る。既存の自動進行・スキップ不可の演出を維持。
- `play_music()` / `stop_music()` / `fade_in()` / `fade_out()` / `crossfade()` / `pause_music()` / `resume_music()` / `is_music_playing()` / 既存音量設定を提供。
- 曲ID・パス・フェード時間・開始位置・ループはAudioManagerに集約。
- Music用プレイヤーは固定2台（主再生＋明示的crossfade用の予備）。通常操作・テーマ再生では1台だけ再生し、何度play_themeを呼んでも追加生成しません。
- crossfadeはテーマ以外の明示的呼び出しでのみ固定2台をミックス。テーマを含む切り替えは必ず先の曲を消音してから次を再生。
- 新しい切り替え要求・停止は以前のTweenと非同期処理をキャンセル。SEのduckとフェードは別の音量係数にして干渉を防止。

## 変更ファイル

追加指示に対応: 日本語タイトルを「走れカミナリ」、英語表記を「HASHIRE KAMINARI」に統一。ウィンドウ名・HTMLページ名・README・GDD・日本語フォント検査も更新しました。既存セーブの場所は `config/custom_user_dir_name` で従来の `Godot/app_userdata/HashireIkazuchi` に固定し、Linuxは従来の小文字godotフォルダーを維持します。この保存用識別子だけはタイトル変更で移動させません。

スタッフロールは、企画・構成→蒼大→ディレクター→PAPA→音楽ディレクター→蒼大→Suno→クリエイター→chatGPT→codexの順に表示。既存のエンジン・フォント等のクレジットはその後に維持。文字列の増加に合わせてロール終点を計算し、最後の行も画面外まで流れるようにしました。

- `godot/scripts/autoload/audio_manager.gd`: 既存管理機能の拡張。
- `godot/scripts/ui/title_screen.gd`: テーマ開始・START/CONTINUEのフェード待機。
- `godot/scripts/battle/true_battle_manager.gd`: 撃破時のフェードアウト。
- `godot/scripts/ui/stage8_ending.gd`: 通常分岐のテーマ再生・タイトル復帰時のフェード。
- `godot/scripts/ui/true_ending.gd`: 締めのテーマ・全曲対応スタッフロール。
- `godot/.gitignore`: local_musicと標準テーマ音源の除外。
- `godot/tests/theme_music_check.gd`: 新規。切り替え、重複、音源なし、描画付き検証。
- `godot/tests/theme_full_ending_check.gd`: 新規。実時間の全曲終了・タイトル復帰検証。
- `godot/tests/stage8_ending_check.gd`: 音楽フェード待機にテストを対応。
- `godot/tests/true_seiya_combat_check.gd`: CONTINUEの音楽フェード待機に対応。
- `godot/project.godot`: 正式タイトル・説明・保存場所の互換性。
- `godot/data/story/credits.txt`: 正式タイトルと指定スタッフロール。
- `godot/tests/japanese_font_smoke.gd`: 正しいタイトルとスタッフ名の字形確認。
- `README.md` / `docs/GDD/GDD_Ver1.0.md`: 正式タイトルへ統一。
- `docs/index.html` / `godot/docs/index.html`: ページ名を正式タイトルへ統一。
- この導入記録。音源は上記ローカル配置のみ。

## 確認

最終実行の合格結果: `THEME_MUSIC_CHECK missing=false rendered=false failures=[]`、`THEME_MUSIC_CHECK missing=false rendered=true failures=[]`、`THEME_MUSIC_CHECK missing=true rendered=false failures=[]`、`STAGE8_ENDING_CHECK failures=[]`、`TRUE_SEIYA_COMBAT_CHECK failures=[]`、`TRUE_ENDING_CHECK failures=[]`、`OPENING_FLOW_OK pages=26`、`JAPANESE_FONT_OK`。正式タイトル、指定スタッフ順、既存Windows保存先、Stage 1→Stage 2の遷移も検証しています。

全曲の自然終了通知を待ち、終了通知より前にエンディングが完了しないことも実時間テストで合格。`THEME_FULL_ENDING_CHECK elapsed=226.650 failures=[]`。音源自体の長さは214.77秒です。ここでelapsedはQA実行環境での終了通知までの実測時間で、音源の長さとは区別しています。

最終結果は以下のログで確認できます。

- `theme_music_check.log`: タイトル、再生、フェード、START、Stage 1、最終ボス、リトライ、TRUEクリア、エンディング、2周目、位置指定、ポーズ、競合キャンセル、crossfade。
- `theme_render_check.log`: 同じゲーム経路をOpenGL描画付きで確認。`evidence/theme/`にタイトル・Stage 1・TRUEボス・エンディングの実描画画像。
- `theme_missing_check.log`: 音源をプロジェクト外へ一時移動した状態の検証。確認後に音源を復元。
- `theme_stage8_check.log`: STAGE 8の7分岐、TRUEボス、リトライ、クリアの既存回帰。
- `theme_true_combat_check.log`: 物理接触による攻撃・撃破、保存・CONTINUE、TRUEエンディングへの遷移。
- `theme_true_ending_check.log`: 既存台詞、演出順、環境音、海上の無音、セーブ保持。
- `theme_opening.log`: 既存26行のオープニングと本編遷移。
- `theme_audio_smoke.log`: 従来BGMとSEの互換性。既存の短時間SE終了時にはObjectDB警告が残るため、無警告の確認とは区別。
- `theme_full_ending_check.log`: 約214.77秒の全曲終了と自動タイトル復帰を実時間で確認。

これらは専用のQA用APPDATAを使用し、通常のセーブを変更しません。自動テスト・実描画・デスクトップ操作・聴感確認を区別しています。Windowsデスクトップ操作は `GetCursorPos failed: アクセスが拒否されました (0x80070005)` で復旧できず、手動操作と耳での聴感確認は未実施です。サンドボックス実行の一部ログにはWindows証明書ストア読み取りエラーがあり、ゲームのローカル音源再生とは別の環境診断です。

使用した[computer-useスキル](C:/Users/takas/.codex/plugins/cache/openai-bundled/computer-use/26.930.31730/skills/computer-use/SKILL.md)の[復旧規則](C:/Users/takas/.codex/plugins/cache/openai-bundled/computer-use/26.930.31730/docs/guidance.md)は、ウィンドウ再選択後も復旧しない場合に "report the exact error if recovery fails" と指示しています。そのため直接操作を停止し、Godot自身の描画キャプチャとログで検証しました。

## Gitと公開範囲

ユーザーの「公開まで進めてください」に基づき、最新mainのキャラクター修正を保持した `.kaminari_theme_release_20261003/godot/project.godot` へ統合しました。公開版は `res://audio/music/st_action_theme.ogg` を使用します。提供M4Aから全曲をOGG Vorbisへ変換したファイルだけを明示的にGit管理し、Webエクスポートへ含めます。元M4Aと `audio/local_music/` は引き続き公開対象外です。音源の独自の利用許諾条件を判断・変更するものではありません。

CIには公開用音源の存在とtheme_music_checkを追加しました。タイトル・ゲーム開始・ステージ・ボス・エンディング・リトライ・重複防止を既存回帰テストとともに検証し、成功後に既存GitHub Pagesワークフローで公開します。音源欠落時の安全なフォールバックも維持します。

公開用コピーでも標準パスからのテーマ検証、実描画検証、音源を一時的に外した検証がすべて `failures=[]` で合格しました。

公開PR: https://github.com/adamonine-stack/hashire-kaminari-dakkan-no-kobushi/pull/167
公開URL: https://adamonine-stack.github.io/hashire-kaminari-dakkan-no-kobushi/

残る任意調整: 耳での最終音量調整、最終ボスの音楽同期箇所を採用する場合の指定。既存最終ボス専用BGMは保持しています。