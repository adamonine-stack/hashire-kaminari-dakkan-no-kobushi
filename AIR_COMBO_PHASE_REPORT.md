# AKKY Launcher / Air Combo接続工程

開始/終了branch: codex/directional-combat-20261003。開始HEAD: 2e6e6bda397c0632089b4bba90903ec69f857405。終了HEAD・変更/新規一覧・git status --shortはCommit後のair_combo_git_result.txtに保存する。既存の未Commit変更を保持し、今回所有するファイルだけをCommitする。

## 実装

AKKYの↓P命中 -> Jump -> Air P命中 -> Air Kの3Hitルートを接続した。既存PlayerComboMovementとPlayerAttackDataを拡張し、既存の地上/投げ/Special/Down/KOを置換していない。

- Jumpも既存CombatCommandBufferへ記録。入力優先度は従来定義の20、buffer150ms、方向履歴600ms。通常Jump処理は維持し、攻撃中のJumpは指定されたHit Confirm区間のみ受け付ける。
- ↓Pのcancel_targetsにjumpを追加。Jump許可区間は0.28～0.41s。命中、can_cancel_on_hit、地上、残りCombo回数を満たす場合のみ。Whiff/早すぎる入力、Hit/GuardHit/Throw/Special中の不正移行は拒否する。通常攻撃から無条件Jump Cancelにはならない。
- Jump Cancelは旧HitBox・攻撃移動を解除し、Combo対象/Countを維持して既存Jump速度で上昇する。空中最初の技をComboとして開始する。着地または被Damage中断で派生状態を解除する。共有APIにAI request引数も用意したが、敵の新しい選択判断は今回追加していない。
- 空中専用のakky_air_punch / akky_air_kickをAKKY定義へ追加。論理方向anyで、左右方向を保持しながらでもAir技を選択する。airborne_onlyで地上の方向技とは競合しない。従来の他Character空中技は変更しない。
- Air PからAir KへのCancelは0.12～0.27s、命中時のみ。Air Kから戻るTargetはない。1ジャンプ1Attack制限は最初の技に維持し、明示された命中Cancelだけ例外とする。最大3Hitと既存Combo Damage補正を使う。

| 技 | Startup | Active | Recovery | Damage係数 | HitStun | HitBoxサイズ/中心 |
| --- | --- | --- | --- | --- | --- | --- |
| Air P | .07s | .10s | .20s | Punch×.8 | .32s | (52,48)/(46,-60) |
| Air K | .12s | .14s | .26s | Kick×1.0 | .30s | (68,40)/(100,-82) |

双方Guard可能、Whiff Cancel不可、HitStop .04s。Air Pは軽い再浮かし(35,-180)、Air Kは既存Knockback(200,-90)。無条件追尾や技IDの強制勝敗は追加していない。基準距離62pxでCrusher HP125->94の3Hitを左右両方で実測した。距離・高さ・入力Timingがずれる場合まで保証するものではない。

## モーションと描画

新Sprite/Atlasや体格変更は行っていない。AKKY既存akky_v3のjump_punch_downとjump_kickを使用。拳/足先をPNG抽出で比較し、Air Pの接触frame1、Air Kの接触frame2に同期。HitBoxをその拳/足先へ合わせた。ジャンプの物理座標とSpriteのScale/Offsetを混同しない。

Air Pは現時点では既存の下向きパンチ姿勢の流用。完全な新規水平Air-to-Airモーション制作ではない。新しいLaunch Hit/Victim素材も今回制作していない。既存Launcherのlaunch_hit/knockback fallbackを維持する。下段Air K（急降下）と専用Landing Recoveryは未実装。

air_combo_visual_reviewでGodot描画を左右両方書き出した（air_combo_evidence）。Actorが被投げ側に隠れて比較できない初回配置を、間隔220pxの素材比較配置へ修正。描画比較の配置は実戦Comboの距離/物理成立証拠とは別。物理は専用自動Testで確認した。新Effect、Camera、Texture/Particle/Node追加なし。

## 検証

- air_combo_check: 手動Phase条件でWhiff/早期Cancel拒否、Jump Buffer、命中Cancel、Air K->Pループ拒否、LandingのHitBox解除を確認。
- 同Testの実物理パートはconnectedを直接セットしない。MobileControlsのCrouch/P/Up/P/Kハンドラーを呼び、方向->Attack約120ms遅延と両向きの3Hit/着地復帰を確認した。Inputは各ケース終了時に解放する。
- 最終Hit直後に既存Combo終了処理がconnectedをクリアするため、Testの確認をattack_hitイベント記録へ変更。実際に発生した最終Hitを、後続Frameの状態だけで見落とさないよう修正した。
- AIR_COMBO_VISUAL_EXPORT_OK。拳・蹴りの接触frameの左右描画を確認した。
- 初回回帰: CombatCommandBuffer、方向攻撃、方向投げ、Special Reversal、AKKY Down、Stage 1はfailures=[]。最後の着地解除/API修正後もAir Combo、方向攻撃、Throw Motion Sync、Stage 1を再実行し、すべてfailures=[]。

root certificate store読込エラーは実行環境に残る。スマホ実機/手動連続プレイ、一般距離全域の対空勝率、多数敵、全Stage/Continue/Retry/Web公開とGPU性能計測は未確認。自動MobileControls検証を実機確認として扱わない。

## 変更ファイル・残作業

変更: player_combo_movement.gd、akky_down_punch.tres、ally_balance.tres、DIRECTIONAL_PHASE_WIP.md。新規: akky_air_punch.tres、akky_air_kick.tres、air_combo_check.gd、air_combo_visual_review.gd、本報告。正確な一覧はCommit参照。

今工程ではLauncher/Air Cancelを接続。戦闘拡張全体は未完成。次工程はCrusher側の方向技レパートリーとSituation AIを、既存の専用素材と整合させて展開する。その後、専用Air P/急降下素材、Landing Recovery、対空/位置/距離の実戦調整、壁/敵衝突追加反応、他Character展開が必要。
