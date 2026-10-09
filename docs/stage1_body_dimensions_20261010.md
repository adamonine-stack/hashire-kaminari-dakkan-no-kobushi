# 第一ステージのモーション寸法修正とQA

基準コミット: `7d0c79c`。対象: アッキー、クラッシャー、第一ステージで選択できる剛・聖也の回帰確認。

## 原因と変更

アッキーの一部モーションは、正式Idleと異なる身体比率で描かれた画像を使用していた。ノードのscaleだけを合わせても頭・胴体・袖の差が残る。正式Idleを参照し、軽・重・高・低被弾、空中パンチ、後方投げ、特殊ガード、地面衝突・バウンド、壁被弾・落下の計26枚を修正した。既存素材を保持し、対象12モーションだけを追加アトラスで置換する。

共通320×224キャンバス、足元基準(160,208)を使う。転倒時は身体を縮めず、横向きの描画領域と骨盤の基準を確保する。各元シートに固定のピクセル単位変換を設定し、モーション中・切り替え時のAnimatedSprite2D.scaleを変更しない。共通アトラス処理に表示ピクセル単位の配置、微小アルファの除去、元画像・切出し範囲のメタデータを追加した。いずれも初期値は従来動作を保持する。

HP、攻撃力、移動速度、判定、ノックバック、攻撃データを変更していない。正式Idle画像も変更していない。

## 保存した比較資料

[正式Idle・アッキー](stage1_body_evidence_20261010/idle_akky.png)、[正式Idle・クラッシャー](stage1_body_evidence_20261010/idle_crusher.png)。

修正前後の比較: [高低被弾](stage1_body_evidence_20261010/upper_lower_review_comparison.png)、[空中パンチ](stage1_body_evidence_20261010/air_punch_review_comparison.png)、[後方投げ](stage1_body_evidence_20261010/back_throw_review_comparison.png)、[特殊ガード](stage1_body_evidence_20261010/special_guard_review_comparison.png)、[地面衝突](stage1_body_evidence_20261010/ground_bounce_review_comparison.png)、[壁被弾](stage1_body_evidence_20261010/wall_review_comparison.png)。同じフォルダの `*_prompts.md` に採用画像の編集指示を保存した。全フレームの元画像・GPUキャプチャ・以前の試行は、作業用チェックアウトの `audit_evidence/body_dimensions` に保持している。

## 自動検証

`stage1_body_dimensions_check.gd` は第一ステージ4キャラクターの全2,802方向付きフレーム参照を検査する。全モーションでscale・global_scale・position・offset、左右反転、AtlasTexture領域、可視画素、Idle復帰を確認する。修正前のアッキー定義をテスト用fixtureに固定し、全142モーションの名前・フレーム数・FPS・ループ・フレーム継続時間を比較。対象26画像以外の画素が変化していないことも検査する。頭身の一致をこのテストで証明することはできない。

部位修正ごとの6テスト、後方投げ・地面・壁の実物理テスト、通常InputMap入力の6遷移×左右、既存第一ステージ回帰がローカルで合格した。被弾入力だけは既存receive_attackへ再現用パケットを渡す。全攻撃の手動入力・実機スマートフォン検証ではない。

軽・重被弾の [修正前後](stage1_body_evidence_20261010/hit_before_after.png) も保存した。3主人公の通し戦闘では全員が被弾し、通常AIのクラッシャーを倒して第一ステージをクリアした。最初の聖也用botは他2人と同じ98pxで接近を止めて敗北した。テスト側だけ、短い通常パンチに合わせ接近目標を65pxに変更するとクリアした。攻撃力・HP・判定・敵AIを弱めていない。Akky/Gouの高速headless通し戦闘の終了時にはAudioStreamWAV/PlaybackのObjectDB解放警告が残る。終了コード0と戦闘クリアは確認済みだが、警告なしとは報告しない。

通常入力の記録: [固定カメラ12ケース・212画像](stage1_body_evidence_20261010/continuous_gameplay_fixed_camera.json)、[通常カメラ36ケース・5,220tick](stage1_body_evidence_20261010/continuous_gameplay_realtime.json)。実画面: [ジャンプ中](stage1_body_evidence_20261010/normal_input_jump_gui.jpg)、[左向き特殊ガード](stage1_body_evidence_20261010/guard_left_gui.jpg)、[右向き壁落下](stage1_body_evidence_20261010/wall_fall_right_gui.jpg)。後者2枚は物理停止・ポーズ保持の表示確認であり連続遷移の証明ではない。

CIは既存戦闘・全ステージQAを維持し、この寸法・互換性検査と3主人公の第一ステージ通し戦闘を追加する。ログと全フレーム台帳を `stage1-motion-qa` artifactに保存する。PRではWebビルドまで実行し、Pagesデプロイは行わない。

## 完了判定の制約

アッキー192種類、クラッシャー102種類の現行画像を一覧で目視確認した。モーション名・別名を区別した [4キャラクターの検査台帳](stage1_body_evidence_20261010/stage1_contract_summary.json) と [アッキーの判定表](stage1_body_evidence_20261010/akky_motion_status.csv) を保存した。

[部位計測14枚](stage1_body_evidence_20261010/visible_landmark_measurements.csv) は髪頂点、顎、襟元、ベルトの表面位置。髪・衣服の外形を骨格寸法とみなさない。各点±2px、距離±4pxの読取誤差があり、33pxの頭部に対する±2%は約0.66pxなので、この計測で±2%適合を認証できない。特殊ガードは顎が腕で一部隠れる。肩・腕・脚の隠れた関節、全フレームの身体寸法±2%、全遷移を左右とも直接GUIで連続目視する項目は未確認。

従って、このPRのQA/Webビルド合格を、当初依頼の全寸法・全目視の完成とは扱わない。身体寸法とGUIの未確認を残したまま合格へ書き換えない。
