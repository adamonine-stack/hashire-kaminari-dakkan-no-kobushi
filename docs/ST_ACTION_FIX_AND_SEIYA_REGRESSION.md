# ST_action表示修正とセイヤ回帰確認（2026-10-02）

基点は最終ボス版セイヤ公開済みmain `7687bfc1f599285ce86ff1320a71bfd122532832`。新しいworktree `.st_action_publish_20261002` / `fix/st-action-publish-20261002` に既存の未公開修正を差分で統合した。以前の作業フォルダーと未コミット素材は維持している。

## 公開中の不具合と原因

公開ページは `game-7687bfc1f599` を配信しており、以前のST_action修正はmainに入っていなかった。セイヤの公開は成功していたが、第5・6の旧背景・旧Atlas定義はそのまま配信されていた。

第5のShadow Boxer画像は1230×1278、第6のRio Garciaは1261×1247。高さの異なる7段の絵を旧定義が153×159 / 157×155の均等な8段として分割し、前の段の靴を頭上に拾い、現在の段の足を切っていた。存在しない8段目のKO参照、横幅の広いRioのタックル段も原因だった。画像の描き直しや足を隠す処理で回避していない。

第7・8は1920×1920 / 320×320 / 6列の正しい定義を参照する。最新mainの公開Webと統合後Webの双方で起動・歩行・ジャンプ・攻撃・必殺を比較し、第5・6と同じAtlas混入は再現していない。全登録RegionをGodot描画でも再確認した。詳細な発生モーション、参照経路、数値は[キャラクター崩れ詳細](ST_ACTION_CHARACTER_FAILURE_DETAILS.md)。

## 修正

- 第5・6: 各56個のSource Regionを実測。完全な全身を透明な320×256セルへ配置してSpriteFramesを個別生成する。Rioの7姿勢の段は最終姿勢を論理8コマ目にも割り当てる。KO/Down/GetUp、着地、投げられ、しゃがみ参照を修正。Shadowの元絵で大きい反応段だけ一律0.832402を適用し、通常段と同じ頭身へ合わせる。毎ポーズの引き伸ばしはしない。
- 必殺ゲージ: 通常シアン `#26CEEF`、暗い青の背景、高さ14px。MAX到達時に白金色の約0.38秒フラッシュと外周発光、その後金色・弱い発光・0.8Hzのパルス・`SPECIAL MAX`。状態更新でNode/Tweenを生成しない。消費時に通常表示へ戻す。
- 第5背景: 到着船の一部、離島の海と島影、波と照明反射、基地へ続く灯り、係船設備、濡れた床で手前・中景・遠景を構成。
- 第6背景: 敵アジトの閉じた大型鋼鉄ゲート、門柱、監視カメラ、警告灯、防護柵、警備小屋、岩山と植物、港につながる海景を構成。
- 背景は1280×720の既存Viewportと `Rect2(-112,-63,1504,846)` に合わせる。カメラ、床Collision、人物本体の立ち位置、既存背景Node構成を維持。旧SVGも保持。
- 第1～8の開始文から総数を削除し `STAGE 番号 タイトル` とする。TRUE最終戦は既存の `TRUE FINAL BATTLE` を維持。内部の総数管理・セーブ・選択・クリア判定は維持。
- 既存icon.pngの壊れた圧縮データは既存icon.svg内の同一画像から復旧。オープニング最終キーで画面切替後のViewportへアクセスする既存エラーは、入力処理済み通知を画面切替前に行うことで解消。原文26行は変更しない。

## セイヤ保持

セイヤ関連32ファイルを基点と照合し、ソース・素材の一致を確認（改行形式のみ正規化）。`extra_motion_atlases` の地面パンチ追加経路、頭部分shader、別レイヤーのオーラ、TRUE最終戦への登録・生存者分岐を保持する。

主人公版とボス版のSprite scaleはともに `(1.019240,1.107869)`、position `(0,-139.5915)`、HurtBox `(77.61295,185.2357)`。基準1.03・身体幅0.92・頭0.90、床の接点、Collision、影は維持。HP180・移動280・初段16/26ダメージ・リーチ約171/224px、柱26ダメージ/84×96/単発/7秒を回帰テストで確認した。

## 実描画と進行

Godot 4.7 / OpenGL Compatibilityの非headlessで実際のBattle.tscnを描画し、Viewport画像を保存して照合した。素材プレビューやheadlessだけの確認ではない。自動入力による歩行・ジャンプ・攻撃と、既存receive_attackを使った被弾・KO、実際の遷移で第1→8クリアまで確認した。AIや位置を検証用に制御しており、人間が通常難易度で手動クリアした証拠ではない。

| Stage | 登録Clip | 重複を除いた描画Frame |
|---|---:|---:|
| 1 | 46 | 33 |
| 2 | 62 | 35 |
| 3 | 73 | 48 |
| 4 | 122 | 51 |
| 5 | 69 | 48 |
| 6 | 76 | 56 |
| 7 | 61 | 33 |
| 8 | 61 | 34 |

計570Clip / 338Frame。Idle、Walk、Dash、Jump開始・空中・落下・着地、Punch、Kick、Special、Guard、Crouch、Hit、Down、GetUp、KO、投げ関連、Victoryなど全登録モーションを対象とした。第5～8はIdle/Walk/Jump/Attack/Hit/KOの実状態遷移も確認。Spriteのoffset、centered、position、scale、Z、個別Resource、全Region範囲を回帰確認した。

TRUE第9戦もGodotでIdle/Walk/Dash/Jump/Punch/Kick/Guard/Hit/KOと柱攻撃全段階を描画し、左右移動・ジャンプ回避、狙い固定、単発ヒット、終了後の判定解除、クールダウンを確認。Web版でも実AIの柱攻撃と通常戦闘を確認した。

ゲージは0/35/75%、MAX到達・維持、MAX更新40回、実際の必殺使用直後・active・終了を保存した。第1～8の開始演出、TRUE最終戦の見出しに総ステージ数はない。

## テスト

`tools/run_fix_regressions.ps1` の25件すべて成功。第1～4回帰、5/6/7/8 Atlas、Shadow、主人公3名のAtlas、Stage1戦闘、ジャンプ攻撃、敵圧力、ガード、ゲージ・キャラバランス、ダッシュ・後退、UI/日本語フォント、Opening、Stage8全7ルート、TRUE Seiya、dark Seiyaを含む。オープニング最終キーによる実シーン切替も追加テストし成功。

最終Import、GDScript、Scene、Missing Resource、Invalid Atlas Region、SpriteFramesのエラーなし。Webは未変更のPCK/JS/WASMを新しい検証用ブラウザーcontextで読み込み、検証用checkpointだけを入れて実ゲームを操作する。第5～8を1280×720と844×390で確認し、実行時エラー・404なし。既存のソフトウェアWebGL buffer警告は検証用環境で残る。実機スマートフォンと人間によるネイティブ手動操作はこの記録に含めない。

## 修正ファイル

- `godot/scripts/data/fighter_motion_atlas.gd`
- `godot/scripts/characters/character_visual_controller.gd`
- `godot/assets/characters/enemy05/animations/shadow_boxer_v1/motion_atlas.tres`
- `godot/assets/characters/enemy06/animations/rio_garcia_v1/motion_atlas.tres`
- `godot/data/enemies/enemy_02_speed.tres`, `enemy_06_combo.tres`
- `godot/ui/battle/battle_hud.gd`
- `godot/scripts/battle/battle_manager.gd`, `stage1_backdrop.gd`
- `godot/assets/backgrounds/stage_05_island_pier_v2.png`, `stage_06_secret_base_gate_v2.png`
- `godot/icon.png`, `godot/scripts/ui/opening.gd`
- Atlas/Opening回帰テスト、実描画・実進行チェック、Webチェック、比較資料作成ツール、CI追加チェック

## 比較資料

- [異常パーツの修正前後](../evidence/contact/sprite_failures_before_after.png)
- [公開中の旧背景と統合版の比較](../evidence/contact/web_backgrounds_before_after.jpg)
- [ゲージ各状態](../evidence/contact/gauge_states.jpg)
- [第5～8の実状態遷移](../evidence/contact/stage5_8_live.jpg)
- [第1～8開始演出](../evidence/contact/stage_intros.jpg)
- [第5全身描画1](../evidence/contact/stage05_page01.jpg) / [2](../evidence/contact/stage05_page02.jpg)
- [第6全身描画1](../evidence/contact/stage06_page01.jpg) / [2](../evidence/contact/stage06_page02.jpg) / [3](../evidence/contact/stage06_page03.jpg)
- [セイヤの同一サイズ](../evidence/seiya/size_comparison.png)

公開作業ではCI成功後にmainへマージし、配信HTMLのコミット付きruntime名と実際の公開Web画面を再照合する。公開結果は作業完了時のリリース報告へ記録する。
