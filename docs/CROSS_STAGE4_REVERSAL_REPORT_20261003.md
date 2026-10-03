# 第4ステージ クロス・ムラサメ 描写修正・無影連投 改修報告

基準 e27db58e1c03589d85788081e58caa998d4003fa。専用worktreeで既存作業を保持。

1. 既存Battle System: FighterMotionAtlas合成、Visual Controllerの高さ連動scale/Frame scale、通常Attack/Combo、HitStun/Knockdown/Getup/KO、6種Throw、Special Gauge/Cooldown/AI、同Frame Contact Resolverを調査。合成後291Frameを左右検査。既存Motion一覧はPlan、frames.json、SPECIAL_HANDOFF_INVENTORY参照。
2. 変更File: Cross AttackData/EnemyData、主人公3人のFighterData、Special Contact Resolver、Player Definition Movement/Throw Recovery、Reversal Effect、既存Cross/主人公Atlas/Guard/Special/Stage4テスト、回帰Runner、Pages workflow。正確な一覧はcross-changed-files.txt。
3. 新規File: Cross Damage v3 Atlas、主人公3人のCross Special Guard Atlas、個別Down/Low Hit原画と参照資料、3検証/抽出Script、2制作/Audit tools、Plan/本報告/比較資料。
4. Input: 新規なし。既存Special入力とGaugeMAXを使用。
5. Attack: 新規IDなし。既存無影連投の地上grip→pivot→releaseを保持し共通Special接触へ統合。通常P/K/方向/Air/Dash維持。
6. Throw: 新規なし。通常6種の投げを維持。Specialの掴み接触はGuard成功時に発生しない。
7. Combo: 新規なし。既存Comboを維持。Special命中で進行Attackを中断。
8. 必殺技: クロスの「無影連投」。専用charge/reach/grip/pivot/release/recover原画を保持。主人公3人の受け側を検証対象とする。
9. Damage: 主力max(P5,K7)×1.5を共通算出でroundし11。Guard Chipは既存15%の2。投げRelease時に一度のみ適用。
10. Combo Break: 既存HitStun Cancel＋Startup無敵0.10s。Startup0.14/Active0.18/Recovery0.55。倒れ/KO/Throw/強制演出時は禁止。Gauge100、Cooldown4.2。相互Special接触は双方のHitとして解決し固定Player優先を設けない。片側地上接触は既存投げ抜け可能な専用回転投げ。
11. Guard: 専用反応0.28s＋軽い後退、Chip2、掴み/強制Interruptなし。攻撃側Recovery0.55でGuard側が先に動ける。Whiff0.6875。投げ抜けされた場合にもSpecial側0.55Recoveryを維持。
12. Attack Motion: 既存クロス専用charge/reach/grip/pivot/release/recoverを保持。通常Punch/Kickの高速再生で代用していない。無影連投中のEffectを手元へ限定。
13. Damage Motion: Down/Low Hitを個別制作。通常High/Light/Heavy/Air/Knockback/Launch/Knockdown/Thrown/KO/Getupを体格・足位置補正。HitStun中にIdleが混ざる接続を修正。Gou/Seiya倒れ姿勢を膝を曲げた専用Downへ接続。Akkyの仰向け姿勢は保持し重なりを考慮した体格補正。主人公3人Guardは承認済みRei Guard原画を安全共有。Gouのサングラス画像不使用。
14. Effect: Startup手元の短いgrip arc、Active交差trail、Finish小さいground ring、既存Hit Effect/Sound callback/HitStop/Camera Shakeを位相同期。Sprite視認性を維持。
15. Enemy AI: 既存距離/HitStun/State観察判断を利用、0.12s観察後の候補判断とchance0.4を維持。入力ボタンを読まない。検査時だけ乱数制御し0.11/0.13s境界を確認。
16. HitBox/HurtBox: Specialを84×96/offset(70,-116)へ修正。旧70×66/(84,-142)のGou/Seiya自然接触missを解消。HurtBox契約保持。空中/相打ち時は既存Special Hit飛行cap420/280、gravity1000、keep-in-viewを利用し不正な掴みを回避。
17. 実Game: Native Godot Stage4 Battleで通常被弾High/Low、空中→倒れ→Getup全4Frame、KO、左右反転を129Screenshotで確認。無影連投/通常6Throws/壁/3人受け/Guard/Whiff/投げ抜け/同時Special/AI/空中/Down拒否と逆方向3人必殺技受けは別の検証Log/比較資料に記録。手動試遊と自動描画を区別。
18. 問題/修正: 元Down面積0.725、Gou/Seiya受けHit0.811/Down0.706、足位置差を補正。制作候補Downは横幅347px/構え高さ213pxに対し長すぎたため不採用。膝を曲げ胴脚比率を修正した個別原画へ交換し268pxへ。Gou/Seiya倒れも327pxから268pxへ、Akky仰向け274px。頭の大きさ/衣装を比較し全proneの横幅<=構え全高1.30倍を新検査。runtime横方向縮小によるごまかしは行っていない。同Frame resolver迂回と通常Throw Recovery短縮を修正。
19. 未解決/未実施: 46自動回帰は全機能成功。既存6検証の終了時ObjectDB警告(dev053/dev056/dev064/dev065/dev066/dark_seiya)を記録。新Cross検証とStage4回帰は警告なし。長時間手操作Balance、スマホ実機、複数Enemy戦の手動描画、公開ブラウザCanvasは未実施。自動Boss/Stage8/9回帰と混同しない。
20. git status --short: evidence/cross_stage4_audit/git-status-before-commit.txtおよび公開報告を参照。Godotが生成した無関係なImport/UIDは採用対象から外す。他worktreeは変更していない。
21. commit/public: 公開完了後のCROSS_STAGE4_PUBLIC_RELEASE_20261003.mdにコードcommit、Merge、Pages、公開Runtime/PCK検証を記録する。

同一pixel倍率の体格比較: evidence/cross_stage4_audit/down_proportions_comparison.png。実画面: evidence/cross_stage4_damage/pose_down_00_R.png。原画一括生成は行わず個別Frameを比較後Atlas化。
