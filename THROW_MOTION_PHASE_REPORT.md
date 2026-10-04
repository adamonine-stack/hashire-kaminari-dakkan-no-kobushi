# 方向投げモーション工程

開始/終了branch: codex/directional-combat-20261003。開始HEAD: ba37db8ba7027f7b98c7ad6efb64d201ccd0ccb0。終了HEADと全git statusは工程Commit後のthrow_motion_git_result.txtを参照。既存の未Commit変更は保持し、今回のファイルだけをCommitする。

## 今回の範囲

前工程の方向投げ基盤を維持し、AKKYの通常・前方・下・後方投げに専用Startup/Releaseを接続。Crusherに対応する投げられ側4種と下/後方投げの着地姿勢を追加した。攻撃側8clip/12セル、被投げ側5clip/12セル。掴み中は前工程で確認したcontact姿勢を維持する。

通常投げは短い押し崩し、前方投げは前方への払い出し、下投げは屈んで叩きつけ、後方投げは胴体を後ろへ向けた位置交換として表現。下投げのみ最後の80msに物理座標を最大32px持ち上げ、既存の落下/着地処理へ接続する。Spriteのサイズ/位置は変えない。後方投げの位置交換、壁際のclamp、カウンター受付、投げ耐性、投げ抜けと再掴み制限は既存ルールを維持する。

PlayerAttackDataに開始/準備/解放/被投げ/着地clip名と準備時間・解放offsetを追加。既定値は空/0。Resourceに指定があり、そのキャラクターにAnimationが存在するときだけ専用clipを使用する。他キャラクターは従来のAnimationへfallbackする。被投げ側と攻撃側はReleaseイベントで同時にframe 0から開始、10fps。着地は物理判定で切り替える。

## 維持した入力・数値

新しいInputMapやスマホボタンは追加していない。前工程の単独T＋論理方向、150ms command buffer、600ms方向履歴を維持。P/K/Air/Special/AI選択は今回変更していない。

| 投げ | Startup | Hold | Recovery | Whiff | Damage | 解放速度 |
| --- | --- | --- | --- | --- | --- | --- |
| 通常 | .12s | .20s | .30s | .50s | 15 | (120,-120) |
| 前方 | .17s | .20s | .38s | .60s | 14 | (480,-180) |
| 下 | .20s | .20s | .42s | .65s | 20 | (0,80) |
| 後方 | .10s | .20s | .38s | .60s | 14 | (-70,-100)、位置交換 |

Damageは耐性適用前。下投げのDownは最低1.1s。今回HitBox/HurtBox形状、Guard/Special、Damage補正、KO/Save/Cameraを変更していない。新Effectも追加していない。

## 素材比較

公式参照に対して長袖・腹部・顔・頭身・足の長さを確認し、前方投げの伸びすぎた後脚と後方投げの大きすぎた頭を生成工程で修正した。しゃがみや横倒しを高さに合わせて縮める処理は追加していない。素材履歴と採用判断はgodot/assets/characters/directional_throw_v2/ART_PRODUCTION.md、座標はpacking.jsonに記録。追加Atlas/Sourceはそのフォルダに格納。

## 検証と修正

- directional_throws_check: failures=[]。左右4種、壁際位置交換、counter条件、投げ不可状態、Guard崩し、耐性、MobileControls経由の12ケース。
- throw_motion_sync_check: 最終fixtureでfailures=[]。専用clip、両者frame 0の同期、一回のDamage、全frameの固定Scale/Anchor、切れ/空白frame、Downへの接続、左右反転、実物理のRelease->Down->GetUp->操作復帰とHurtBox復帰を検証。
- directional_throw_visual_review: THROW_MOTION_VISUAL_EXPORT_OK。Godot実描画を固定frameで書き出し、通常/前/下/後の両向きと着地を比較した。投げ保持の手/胸の位置は前工程のcontactを使用。
- テストfixtureのcurrent_scene未設定、投げ抜け確率、誤ったhurtbox変数参照を修正。検証で既存投げ抜けを不具合と誤認しないよう、同期テストはescape確率0に固定した。
- Atlas抽出で透明余白までセルに収めようとする問題を修正。可視範囲＋antialias余白を切り出し、overflow時は生成を失敗させる。
- 方向攻撃、Special Reversal、AKKY Down、Stage 1: failures=[]。AKKY Atlas: 116clip/338frame、failures=0。
- 同期テスト再実行時に従来AIの確率投げが割り込むケースを検出。通常AIとは別のai_throw_probabilityとGuardもテスト内で無効化し、被投げだけを検証するfixtureへ修正した。ゲーム側AIの変更ではない。

root certificate store読込エラーはこのGodot実行環境に残る。Script失敗と区別して記録する。

## 未確認・次工程

スマホ実機・手動連続プレイは未確認。MobileControls自動呼出しは実機操作確認とは扱わない。画像書き出しの軌道配置は見た目の比較用で、物理の成立は別の同期テストで確認した。

壁/敵衝突の追加Damage、Ground/Wall Bounce、新Air Combo、Crusher自身の方向技/投げAIと専用攻撃素材、他キャラクターへの展開、多数敵での実プレイ、全Stage/Result/Continue/Retry/Web公開と性能計測は未完了。戦闘拡張全体の完成報告ではない。次はAir/Launcher/Cancelの接続、続いてCrusher側レパートリーとAI検証へ進む。

変更対象は4スクリプト、4Throw Resource、AKKY/Crusher定義、描画レビューtest、工程メモ。新規はAtlas/Source/Resource/制作記録、packer、同期test、本報告。正確な変更/新規一覧はCommitとthrow_motion_git_result.txtで確認できる。
