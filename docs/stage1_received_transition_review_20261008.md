# 第1ステージ 被弾・投げ遷移の実画面確認

開始/終了 branch: codex/stage1-gou-seiya-20261007
開始 HEAD: 02ff3c4954359ee045eab8e21506e7c64708f098

## 発見と修正
通常のダウン攻撃を受けた瞬間、enter_knockback が地上用 last_knockdown_animation を優先していた。通常の毎フレーム選択は knockback を優先するが、ヒットストップ中は毎フレーム更新が止まるため、豪・聖夜は地上で横たわる姿勢が吹き飛び開始時に表示されていた。開始処理も既存の knockback を優先し、専用Special/Throw反応と低段ヒットストップ反応は既存優先順位を保持した。物理、ダメージ、時間、Sprite画像、サイズは変更していない。

## 検証と比較
- 新規 stage1_received_transition_check.gd: 4人×左右両向き8ケース。receive_attack を経由する制御されたDamage fixtureで実physicsの KNOCKBACK→KNOCKDOWN→GET_UP→復帰を検査。ダメージ1回、ヒットストップ開始時の専用knockback、全tickのSprite倍率・基準位置・左右反転、HurtBox/操作復帰を確認。
- 修正後headless/Intel Iris Xeネイティブ描画とも failures=[]、各32姿勢を記録。描画はphysicsを一時停止して保存し再開。実画面テストは固定FPSの自動fixtureで、手操作の試合ではない。
- 豪/聖夜対Crusherの双方が投げる4方向×左右の実physics/ネイティブ確認が failures=[]。豪は修正後にもheadless回帰済み。
- special_reversal_check 修正後 failures=[]。専用Special反応と切り返しを維持。
- 比較画像2枚は立ち姿の400×320px viewportと同じ画素倍率・足元基準で32の実描画を配置。画像の身体・頭・手足を変形していない。被弾開始の赤色は既存Damage Flashであり、素材の肌色変更ではない。
- 立ち姿・倒れた姿勢・起き上がりの代表画像を左右で比較。各キャラクターの衣装・顔・体格の識別と接地を確認した。全Attackの全中間Frameの目視承認を意味しない。

## ファイル
変更: godot/scripts/player/player_knockdown_movement.gd
追加: godot/tests/stage1_received_transition_check.gd、tools/build_stage1_transition_review.py、本報告、audit_evidence/stage1_received_transitions/inventory.json、comparison_right.png、comparison_left.png。
32枚の生キャプチャとテストログは作業フォルダに保存。headless inventoryは別名で保存しnative証拠を上書きしない。

## 残る範囲
全攻撃/必殺技/KOを含む全Frame目視、スマホ実機、手操作の1対1試合、公開Web確認は今回未実施。新規Sprite制作はなし。豪投げテストの既存ObjectDB終了警告2件は残る。既存未Commit変更は保持し、今回のファイルのみCommitする。

修正後 stage1_regression: failures=[]。ステージ進行・敗北遷移の既存回帰を通過。公開は行っていない。
