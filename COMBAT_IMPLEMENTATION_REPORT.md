# ST_action 戦闘拡張：調査・入力基盤の実装記録

本依頼全体は未完了。新しい技を本編へ追加した、全キャラクターへ展開した、またはスマホ実機で確認したという報告ではない。

## Git と作業場所

- 指定フォルダー直下は `.git` ディレクトリがあるが `git rev-parse HEAD` / branch / status は `fatal: not a git repository`。直下の古いGodotコードは変更していない。
- 調査元：`.st_action_theme_20261003`、branch `agent/st-action-theme-20261003`。
- 開始HEAD：`53325f87df4168383331d712ff875ac3950e367c`。
- 専用作業先：`.directional_combat_20261003`、branch `codex/directional-combat-20261003`。開始時は同じHEADの新規worktree。
- 調査元の未Commit変更（import設定・QA成果物等）は引き継いでいない。既存のユーザー変更は削除・Reset・Commitしていない。
- 最終HEAD・Commit Hash・statusは隣接する `combat_git_result.txt` / `combat_git_status.txt` に記録。

## 既存構造の調査

本編Player/Enemyは共通の `Player.tscn` と次の継承列を使う。

`player_fighter_definition_movement.gd → player_knockdown_movement.gd → player_combo_movement.gd → player_movement.gd`

- InputMap：move_left / move_right / jump / crouch / down / attack / kick / guard / throw_attack / special / special_attack / pause。
- スマホ：`mobile_controls.gd` は左9方向のボタン、右P/K/Throw/SpecialとGuardを持つ。上方向はJumpをtapとして入力する。入力保持は参照カウント管理。別の `battle_ui_input.gd` も存在する。
- 攻撃：`PlayerAttackData` Resourceと `FighterDefinition.attack_sequence`。attack_id、startup/active/recovery秒数、HitBox矩形とoffset、移動距離、Damage倍率、HitStun、HitStop、Guard属性、next_attack_ids等を既に持つ。
- State：通常攻撃はNONE/STARTUP/ACTIVE/RECOVERY。投げ・Down/WakeUp・AI・キャラSpecial・Boss攻撃は別状態管理。今回全面置換していない。
- Hit：PunchHitBox/KickHitBox/SpecialHitBoxとHurtBoxのArea2D。矩形の左右offsetはfacing_directionで反転する。body collisionはlayer=2/mask=1。既存のPose別HurtBox更新もある。
- Damage：HitBox接触からResourceをDictionary化し、Combo補正後に共通receive_attackへ。Guard判定、HitStop、HitStun、Knockback、Damage、KOを実施する。通常GuardはDamageゼロ。Specialは設定されたGuard倍率に従う。
- 空中：CharacterBody2Dのis_on_floorと重力で判断。空中攻撃は1滞空1回が既存仕様。既存Air Pは下向きPunch、Air KはJump Kick。新しい速いAir Pや急降下Kとは区別が必要。
- Animation：AnimatedSprite2DとCharacterVisualController/FighterMotionAtlasを使用。Atlasの固定セル／足元基準を維持する。旧AnimationPlayer経路も残る。通常攻撃のphaseはタイマーで進み、表示frameをphaseへ同期する。
- 投げ：startup→hold→release→recovery/whiff。双方の拘束、逃げ、再投げ防止0.9秒がある。air、Hit/GuardHit、無敵等はcan_be_thrownで制限される。キャラ固有grapple処理もあるため、共通方向投げ追加時に保護が必要。
- Combo：既存0.18秒の攻撃buffer、next_attack_ids、Hit確認cancel、最大Hit数、キャラタイプ別Damage/Knockback補正。地上cancel制限がある。
- Special：専用ボタン、ゲージ、Cooldown、短いstartup無敵、被HitStun中発動、Guard、Hit時Interrupt、固有Reversalと受けモーションが既に存在する。今回これらを新規制作したとは数えない。
- AI：profile別Reaction Time、距離管理、Guard/後退/Jump/Combo/Special判断を持つ。通常P/Kの最後の選択はweightによるRandomであり、要求された方向技Situation選択はまだ追加していない。
- Camera/Result/Stage/Save：既存の構造を維持し、今回編集していない。非編集は回帰確認済みという意味ではない。

## 今回追加した基盤

- `CombatCommandBuffer`：150ms（exportで100～180ms）、履歴保持600ms。simulation timestamp、方向、入力時Facing、Press/Releaseを保存。held操作を連打へ変換しない。
- 離した方向も150ms以内のActionへ適用する。左右同時保持はneutral、Downは優先。入力した時点の論理方向をCommandに保存する。
- Special > Throw > P/Kの競合を単一dispatcherで処理。上位の入力が未実行の場合は期限内だけ保持する。同じsampleの下位入力は上位入力成功時に消費する。
- Resourceへcommand_direction / command_priority / ground_only / airborne_only / cancel_start / cancel_end / cancel_targetsを追加。既存Resourceは空のcommand_directionにより従来ルートを維持する。
- データで登録された方向技の選択、Startup、HitBox、Animation、地上／空中状態、指定時間のHit確認cancelを共通の攻撃処理へ接続。
- 対応方向技が登録されているが実行不能な場合、通常P/Kへ誤って置き換えない。通常攻撃の旧combo検索でも方向専用Resourceを誤選択しない。
- 実際の新技Resourceは本編へ未登録。統合テスト内のtest_back_punchは入力とcancelの検証用であり、完成した対空技ではない。

## モーション制作前の一覧

`combat_motion_inventory.md` にAKKY・Gou・Seiya・Crusher・Shadow Boxer・Masato・Rei・Cross・Rio・Teki・Leon・Enemy Seiyaの12定義を掲載。既存Atlas、追加Atlas、Animation定義を読み取り、攻撃側18種・受け側17種に対応するclipを列挙した。

clip名があるものは「流用候補・画面確認待ち」、無いものは「ポーズ検討／制作必要」。同じclipが存在するだけでは適切なモーションとは判断しない。「修正で対応可能」と「正式Designから新規制作が必要」の最終分類は画像比較後に行う。新Spriteは制作していない。

## 自動検証

Godot 4.7 stable。ログ書込み先をworktree内APPDATAへ変更。初回のデフォルトuser://ではログ書込みエラーとエンジンクラッシュが発生し、書込み先変更後に実行できた。初回export_enumに空の選択肢を使ったParse Errorを修正した。

| 検証 | 結果 |
|---|---|
| combat_command_buffer_check.gd | failures=[]：左右反転、0/100/149ms遅延、151ms期限切れ、保持、解放、競合優先、対向入力、履歴期限 |
| combat_command_integration_check.gd | failures=[]：本編AKKY、方向技優先、Startup非Hit、指定cancel時間、Hit確認、Whiff禁止、HitStun、無効化時clear |
| stage1_regression.gd | failures=[]：既存Stage1テストの範囲。全79項目の代替ではない |
| special_reversal_check.gd | failures=[]：既存Special回帰。新規Specialの完成確認ではない |
| combat_motion_inventory.gd | 12キャラクターのResource一覧を出力 |

Windowsのroot certificate store読み出しエラーはログに残る。ネットワークを使わない戦闘テストは成功した。統合テストの初回終了時ObjectDB警告はSceneを解放してからquitするよう修正し、最終ログでは出ていない。

## 依頼の39報告項目に対応する現在の状況

1–5. Gitは上記とGit結果ファイル参照。
6. 変更File：player_attack_data.gd、player_combo_movement.gd。
7. 新規File：combat_command_buffer.gd、combat_command_buffer_check.gd、combat_command_integration_check.gd、combat_motion_inventory.gd、モーション一覧、本報告。engine生成uid/QAログはGit status参照。
8. 既存Battle調査は上記。
9. 新InputMapボタンなし。既存ボタンを共通dispatcherへ接続。
10. Input Bufferは上記。
11–15. 新Punch/Kick/Air/Throw/Comboの本編追加は未実施。
16. 新Resourceの秒単位cancel windowと許可target、Hit/Whiff条件の接続を追加。既存Comboは維持。
17–21. 新Special、キャラ固有Special、Damage約1.5倍への調整、新ComboBreak/Guard変更は未実施。既存実装を調査・回帰検証した。
22–26. 新Attack/Damage/ThrowVictim/SpecialHit MotionおよびEffectは未制作。
27. 本編HitBox/HurtBox形状は未変更。Resource指定経路を再利用。
28–29. Enemy AI変更／キャラ別新技差は未実施。
30. 戦闘シーン内のheadless統合確認と既存回帰のみ。人が実画面を操作した確認はない。
31. Smartphone入力は論理入力遅延の自動テストまで。実タッチ・スマホ画面は未確認。
32. 入力方向と方向技選択の左右反転は自動確認。全技Animation/Effect/Throwの両向き確認は未実施。
33–34. 新Wall/Enemy Collision Throw、Multiple Enemyは未実装・未検証。
35. Stage1と既存Special回帰は成功。他Stage、Continue、Retry、Pause、Result等の全回帰は未実施。
36–37. 発見・修正：空enum Parse Error、userログ書込み失敗、テスト終了時解放、対向方向入力の誤方向、通常Comboによる方向専用Resource誤選択。
38. 未解決：Phase 2以降の本編技・双方のモーション・方向投げ・Launcher/Air Combo・Situation AI・全キャラ展開・実画面／Touch／Performance／全回帰。全体を完成としない。
39. Commit Hashはcombat_git_result.txt参照。

## 後続工程（2026-10-04）
AKKY方向攻撃6技とダウン/復帰Motionの実装・検証・残作業は DIRECTIONAL_PHASE_REPORT.md を参照。全戦闘体系の完成報告ではありません。
