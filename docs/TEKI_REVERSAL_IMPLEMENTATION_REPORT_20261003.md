# 第3ステージ テキ・ファイター 修正・必殺技実装報告

基準: 公開済みab0264cf1cbc0c2d5145b05708b0312c9a8bbd9a。専用branch `feat/teki-reversal-20261003`。既存作業は別worktreeに保存。

1. **既存Battle Systemの調査**: FighterMotionAtlas合成、CharacterVisualController、HitStun/Knockback/Knockdown/Getup/KO、Throw、Special Contact Resolver、既存Gauge/Cooldown/AIを調査。Stage3のテキはenemy_07_tricky。実際のSpriteFrames全185Frameを抽出し原画と描画を比較した。今回の合成後は190Frameを左右とも検査。
2. **変更File**: attacks/teki_deadly_hand、enemies/enemy_07_tricky、fighters/ally_balance・ally_power・ally_speed、player_fighter_definition_movement、reversal_effect、既存6テスト（3人Atlas・Special Reversal・Grapple Guard・Stage3）、回帰Runner、Pages Workflow。正確な一覧は本報告と同梱の`teki-changed-files.txt`。
3. **新規File**: Teki damage_v2 / reversal_v1および主人公3人received_teki Atlas、10個別新規原画と既存原画、references/packing/prompt manifests、Teki専用5検証・2抽出script、build/audit/review tools、Motion Plan、本報告と検証資料。詳細はFile一覧。
4. **追加Input**: なし。既存Special入力・GaugeがMAXの受付を使用。
5. **追加Attack**: 新規IDはなし。既存デッドリーハンドの掴み演出流用を廃止し、専用のGuard可能な掌打Reversalへ改修。通常P/K/方向Attack/Air/Dashを維持。
6. **追加Throw**: なし。通常Throw・方向Throw・4種のテキ掴みは維持しStage3回帰で検査。Special接触だけ掴みPipelineから分離した。
7. **追加Combo**: なし。既存Comboを維持し、Special Hitで進行Attack/ComboをInterruptする共通経路を使用。
8. **Characterごとの必殺技**: テキの「デッドリーハンド」。低い構え→掌を引く→踏み込み→掌打→指を開くImpact→手を引く→Recovery→構え。主人公3人が受ける専用Reaction mappingも追加。他のCharacter技は変更対象外。
9. **Damage値**: テキ主力max(P5,K7)×1.5をroundし11。固定DamageをActor側へ埋め込まず共通算出を使用。Guard Chipは既存15%に従い2。
10. **Combo Break方式**: 既存HitStun Special Cancel + Startup無敵0.10s。Startup0.18s/Active0.20s/Recovery0.55s。倒れ/KO/掴み/強制演出での禁止は共通受付を維持。GaugeMAXを消費、Cooldown4.2s。同時接触は双方を先にSnapshotするresolverで相打ちを許可しPlayer固定優先はない。
11. **Guard時**: Dedicated Guard Reaction0.28s、小さな後退、Chip2、Launch/Attack Interruptなし。攻撃側Recovery0.55sによりGuard側が先に動ける。Whiffは0.6875s、Damageなし。
12. **Attack Motion**: 専用8原画/3Clip(teki_deadly_startup・teki_deadly_hand・teki_deadly_finish)。一括Sprite Sheet生成は行わず1Frameずつ制作・比較後にAtlas化。512×448Cell、固定scale/pivot、floor baseline固定。不要なface_grab_hold流用をSpecialから削除。
13. **Damage Motion**: 新規DownとLow Hit原画。通常High/Light/Heavy/Air/Launch/Knockback/Knockdown/KO/Thrown/Getupを体格補正。Akky壁反応、Gou回転着地、Seiya旧/2段Hit反応も補正。主人公3人は掌打の横方向被弾に適する既存Shadow Counter原画を安全共有し、専用Clip名/mappingで接続。Guardは既存Rei専用反応を使用、Gouのサングラス画像は使用していない。
14. **Effect**: 手元の短いCharge Arc、掌打の水平Trail、5本の短いFinger Impact Trail、Finishの小さいGround Ring。Startup/Active/Hit/Finish同期。既存Sound callback/HitStop0.13/Camera Shake6を使用、長い演出停止なし。
15. **Enemy AI**: 既存observed hitstun/counter判断を使用、0.12s観察後にReversal候補。使用chance0.4を維持、Cooldown/Gauge制限あり、入力ボタンを読まない。テストは乱数を制御して受付境界0.11/0.13sを検証。
16. **HitBox/HurtBox**: Special HitBoxを84×96、offset(70,-116)へ調整。元70×66/(84,-142)ではGou/Seiyaへ自然接触しない問題があった。専用原画の掌と胸の接触を自然Area overlapで左右検証。HurtBoxは既存契約を維持。移動24/0.20s、受け手のflight cap420/280・gravity1000とkeep-in-viewで壁付近の見切れを防ぐ。
17. **実Gameで確認**: Native Godot Battle.tscnのStage3で通常被弾High/Low、空中吹き飛び、倒れ、Getup全4Frame、KO、左右反転、主人公3人への自然Special接触・通常Attack中断・Guard・Whiff・壁・受け手KO、観察AI、Special同士のresolver相打ち、Airborne Hit・Down拒否を確認。Special111枚、Damage129枚、Akky→Teki14枚、Gou→Teki24枚、Seiya→Teki10枚（TrueBattle内の2段Hit専用QA、Stage3背景ではない）を描画し比較。SeiyaQAの追加通常柱1枚は本改修の確認対象に含めない。独立Key Poseの16枚は初期Battle背景、自然接触以降はStage3背景。Screenshot比較資料はevidence/teki_audit/*page*.jpg。
18. **発見・修正した問題**: 元Down体格面積0.632、通常Hit0.832、Gou/Seiya受けHit0.780で縮小。新Down/Lowとoffline面積補正で統一（姿勢重なりのあるGou/Seiya proneは0.85を意図して維持）。Specialが通常掴みへ移行し相打ちresolverを迂回→共通Special経路へ修正。新自然接触テストで8件miss→HitBox修正後成功。旧Stage3テストが旧掴みを要求→新掌打仕様に更新し成功。停止fixtureのStartup無敵残留→resetし、KO原画確認の既存点滅をfixtureで解除。Knockdown high/low aliasを不用意に追加せず、空中と着地のClip選択を維持。
19. **未解決/未実施**: 40回帰テストすべて機能成功、35件warningなし。既存5テスト(dev053/dev056/dev064/dev065/Stage2)には終了時ObjectDB警告が残る。新しいTeki専用5テストとNative描画にはERROR/WARNINGなし。手操作による長時間Balance試遊、スマホ実機、Tekiを含む複数Enemy戦・新しいBoss戦での専用描画試遊は未実施。既存Boss/Stage8/9自動回帰成功をこれらの手動確認と混同しない。AI頻度や0.55sRecoveryの長期Balance調整はプレイフィードバックが必要。
20. **git status --short**: 公開前snapshotを`evidence/teki_audit/git-status-before-commit.txt`へ保存。新checkoutのGodot自動生成Import/UIDを本修正とは別に記録し、必要な新Atlas importだけ採用。他worktreeの既存作業を変更していない。
21. **commit hash / 公開**: 実装1e24ac42afe6f18deb825c43786d1e1e603ec382、検証資料610998ecb7af61fbf7d7ea1fa835006a8e7e3fdb。PR #168をMergeし公開e2fd41a99990036961b1b480d1752d2c09ebad8f、Pages 37112817091はbuild/deployとも成功。公開HTML/Runtime5ファイルの反映と公開PCKのHeadless/Native描画を確認。詳細は[公開検証報告](TEKI_PUBLIC_RELEASE_20261003.md)。ブラウザ接続が利用できず公開Canvas目視は未実施。

回帰結果: `evidence/handoff_checks/test-results.json`、Teki専用5log、Stage3回帰log。Native log: `evidence/teki_audit/{special,damage,incoming-akky,incoming-gou,incoming-seiya}-native.log`。画像元Frame185枚はローカルのevidence/teki_auditに保持し、Gitには再構築に必要な元Frameと比較Sheetを採用。
