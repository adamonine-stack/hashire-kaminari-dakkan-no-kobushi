# 真エンディング

専用チェックアウト `.true_ending_20261003`、ブランチ `feat/true-ending-20261003`。基点は最新の裏セイヤ2段攻撃修復を含む `738b919`。既存チェックアウトの作業は変更していない。

## 接続と演出

`TrueBattle` の実KO結果から、攻撃判定・AI・入力・HUD・戦闘BGMを停止。撃破後の間と暗転を挟み `TrueEnding.tscn` に移行する。第一エンディングの台本・分岐・表示は変更しない。

全編自動進行。決定・移動・攻撃・ポーズ・タップで進行を操作しない。台詞は指示書の7つだけを原文のまま表示する。

既存のゲーム内SpriteとHit/Walkでセイヤ敗北・退場を描く。4人はアッキー、ゴウ、ミオ、レン。闇オーラは既存素材を減衰させる。セイヤが消えた後の装置では顔・身体・説明文字を表示せず、レバー操作、クリック音、赤ランプ、警報、低音で基地終焉を示唆する。セイヤの死亡描写はない。

脱出CG→波止場CG→海上CGで進行。海上ではBGMを止め、波とエンジンだけで7秒の間を設ける。大爆発CGに白フラッシュ、揺れ、揺らぐ炎、柔らかい煙、GPU火の粉、複数爆発音と減衰を重ねる。揺れは既存設定のNORMAL/LIGHT/OFFに従う。

夜明けCGは緩やかにズームアウトし、専用の穏やかな音楽へ移行。BLACK SPARROW→TRUE ENDING→スタッフロール→タイトル。既存スタッフロール実装がないため `data/story/credits.txt` を追加。個人名は推測せずプロジェクト名と利用エンジン・フォント・CG生成を記載した。

## 素材

正式素材とStage5波止場を参照し、built-in image_genで4枚＋夜明け1枚を制作。`godot/assets/endings/true/{escape,pier,boat,explosion,dawn}.png`。海上CGは船首・航跡・視線を修正し、島から離れながら4人が島を振り返る。制作プロンプトは `art_sources/true_ending/prompt_manifest.json`。

音声は `tools/build_true_ending_audio.py` で再生成できるオリジナル合成音。click/alarm/rumble/waves/engine/explosion/ending_music。環境音と音楽は `.import` でループ指定。既存Music/SFXバスと音量設定を使用。

## セーブ

`user://story_progress.cfg` の既存項目をロードして保持し、TRUE ENDING表示後に `story.true_ending_unlocked=true` を追加。`true_boss_defeated` は撃破時に記録。既存のプレイ中セーブ形式は変更しない。タイトルの既存英語ラベルに `TRUE ENDING CLEAR` を反映。読み込めない既存ファイルは上書きしない。

## 検証

テスト用APPDATAをこのチェックアウトの `qa_userdata` に分離。実ユーザーのセーブを使用しない。

- `true_seiya_combat_check.gd`: 実HitBox攻撃による裏セイヤKOからTrueEndingへの接続、戦闘停止、途中セーブ・CONTINUE。
- `stage8_ending_check.gd`: 既存7ルート、第一エンディング、BAD END、救出Sprite、TRUE戦への進行と敗北。
- `true_ending_check.gd`: 全場面順序、原文7台詞、通常操作とポーズ停止、CG存在、セイヤ退場、スタッフロール完走、フラグ保存、既存独自セーブ項目保持、タイトル反映。
- 実レンダラー: `--rendering-method gl_compatibility --script res://tests/true_ending_check.gd -- --render-ending`。`--real-time` は通常速度完走、`--mobile` は844×390描画。

画面証拠は `evidence/true_ending*`。自動テスト・Godot描画検証であり、手操作による全8ステージ攻略・実スマートフォン・公開Web検証ではない。今回の変更はローカル実装で、公開は行っていない。

最終結果: `TRUE_ENDING_CHECK failures=[]`、`TRUE_SEIYA_COMBAT_CHECK failures=[]`、`STAGE8_ENDING_CHECK failures=[]`。通常速度の実描画完走と844×390の実ウィンドウ描画も成功。最終ログではGodotエラー・警告なし。既存 `.import` の自動更新は一括復元を行わず、新規CG・音声の `.import` だけをコミット対象にした。
