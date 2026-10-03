# レイ影山・竜巻昇龍拳 実装報告（2026-10-03）

対象は第2ステージのレイ影山。受け手の新規制作・検証は指示どおりアッキー／ゴウ／せいやの3人。第1・第9ステージと既存の未commit作業を保持した。

1. **既存Battle System**
   PlayerAttackData、FighterDefinition、追加MotionAtlas、player_fighter_definition_movement、player_knockdown_movement、Battle.tscn、Stage2の敵定義・HUD・AIを調査。既存のGauge、Cooldown、HitStun Special受付、開始保護、同Frame接触キュー、Guard処理、Sound呼び出しを利用。制作前一覧は [既存Motion調査](SPECIAL_HANDOFF_INVENTORY_20261003.md) と [制作計画](REI_REVERSAL_MOTION_PLAN.md)。

2. **変更File**
   godot/data/attacks/rei_dragon_uppercut.tres
   godot/data/enemies/enemy_04_throw.tres
   godot/data/fighters/ally_balance.tres / ally_power.tres / ally_speed.tres
   godot/scripts/combat/reversal_effect.gd
   godot/scripts/player/player_movement.gd / player_fighter_definition_movement.gd
   godot/tests/akky_motion_atlas.gd / gou_motion_atlas.gd / seiya_motion_atlas.gd / special_reversal_check.gd / stage2_regression.gd
   tools/run_special_handoff_checks.ps1
   .github/workflows/deploy-godot-web.yml
   回帰ログとtest-results.json。正式な変更・新規Fileの全一覧は [commit対象一覧](../evidence/rei_reversal/changed-files.txt)。

3. **新規File**
   tools/build_rei_reversal.py、tools/review_rei_screenshots.py、tools/review_rei_all_frames.py。
   godot/tests/rei_reversal_presentation_check.gd / combat_pose_flow_check.gd / rei_reference_export.gd。
   art_sources/rei_reversal_v1: 23個別制作原画、既存紹介Poseとidleの2コピー、実Sprite参照5枚、prompt_manifest.json。
   godot/assets/characters/enemy04/animations/rei_reversal_v1: Atlas PNG/TRES・packing_manifest.json。
   godot/assets/characters/special_received_rei_v1/{ally_balance,ally_power,ally_speed}: 各Atlas PNG/TRES・packing_manifest.json。
   制作計画、本報告、検証ログ、画面確認画像。

4. **追加Input**
   新規追加なし。既存Special入力とEnemyの状況判断から発動。プレイヤー側の既存U/L／Joypad button 3設定を変更していない。

5. **追加Attack**
   既存rei_dragon_uppercutを専用MotionとReactionへ更新。通常Attackは変更していない。

6. **追加Throw**
   なし。既存Throwを維持。

7. **追加Combo**
   なし。既存Comboを維持。必殺技Hitは既存のinterrupt_comboと行動Cancelへ接続。

8. **Character固有Special**
   レイの竜巻昇龍拳。低いAnticipation→腰で巻き込む拳→上方へ伸ばすアッパー→拳を戻すRecovery→専用Finish。通常Punch/Kickの高速再生や同Frame流用をやめた。

9. **Damage / Timing / Resource**

   |項目|値|
   |---|---|
   |Damage|14 = round(max(Punch, Kick) × 1.5)|
   |Startup|0.18秒|
   |開始保護|0.10秒|
   |Active|0.20秒|
   |Hit／Guard後Recovery|0.55秒|
   |Whiff Recovery|0.6875秒（×1.25）|
   |Cooldown|4.2秒|
   |Gauge|既存MAX消費|
   |HitStop|0.13秒|
   |Camera Shake|既存6.0|
   |移動|42px / 0.20秒|
   |Launch上限|横420px/s、上560px/s|
   |Launch重力|1200px/s²、画面内保持|

   固定14の加算ではなく、各キャラの主力Damageから算出する共通経路を保持。

10. **Combo Break**
    観察したHitStunからSpecial候補を受け付け、開始直後だけ保護する。Hit時に相手の攻撃・Comboを中断し、専用Hit→Launch→Downへ移行。KnockDown／KO／Throw／強制演出などの既存禁止条件は維持。特定プレイヤー優先順位を追加していない。同Frame相打ちは既存キューを利用し、special_reversal_checkで確認。

11. **Guard**
    Guard可能。Hitと区別し、Launch／攻撃中断を適用しない。既存15%Chipは主人公3人で2Damage。Guard Reaction 0.28秒より攻撃側Recovery 0.55秒を長くした。自然なArea接触でもGuardとRecoveryを検証。

12. **Attack Motion**
    rei_uppercut_startup: 原画0/1/2。
    rei_dragon_uppercut: 原画3/4。
    rei_uppercut_finish: 原画5/6/7。
    Key Poseを個別に比較後、中間Frameも1枚ずつ制作。自然な物理進行で各clipの最終Frameへ到達する検証を追加。

13. **Damage Motion**
    3人それぞれにreceived_rei_uppercut_hit、_air、_down、_guard。5個別原画／人（Hit、Air、Down、Guard Impact、Guard Hold）。Air clipはHit原画から浮き上がり原画へ接続。体格・足基準は各人の実idleに合わせ、RuntimeのFrame別拡縮を使用しない。**ゴウのGuard 2原画はユーザー指定によりサングラスなし。サングラス入りGuard画像は採用していない。**

14. **Effect / Sound**
    Startupの細い足元螺旋と側面の上昇線、Activeの実HitBox位置から伸びるアッパー弧、Hitの小さな上向きSpark、短いFinish余韻。大きい身体を覆うAuraをレイでは使わない。既存special_start、special_attack、Hit Sound呼び出しを維持。

15. **Enemy AI**
    既存reversal/counterタグを利用し、画面上のHitStun／Attack Stateを観察して発動する。入力ボタン読み取りは追加していない。0.11秒の未観察状態では発動せず、0.13秒の観察後に専用Startupへ入ることを検証。頻度の基礎設定は維持。

16. **HitBox / HurtBox**
    レイ専用HitBoxは既存86×130、offset(65,-145)を保持。Effect位置をこの実HitBoxと左右反転へ接続。HurtBoxサイズは変更なし。描画の体格補正で当たり判定を変えない。

17. **実Game検証とEvidence**
    Godot 4.7、実Battle.tscn、第2ステージの背景・HUD、主人公3人、左右両方向。描画ありの107枚とPose Flowの2枚を取得。全画像はローカルevidence/rei_reversal_final、一覧比較はqa_page_01〜09.jpg。
    通常攻撃中への自然なSpecial Area接触・攻撃中断・14Damage・被弾／上昇／着地・Guard 2Damage・Whiffの追加Recovery・全8Frameの自然再生・AI Reversal・両壁付近のSprite全体保持・KO Launch／着地・固定Scale／Pivot・Atlas範囲・Camera Zoom維持を確認。
    [描画検証ログ](../evidence/rei_reversal/native.log)、[Pose Flow描画ログ](../evidence/rei_reversal/pose_flow_native.log)、[全回帰結果](../evidence/rei_reversal/test-results.json)。
    34/34は機能成功、27/34は警告なし。既存7テスト（dev053、dev056、dev064、dev065、dev066、stage1、stage2）には終了時ObjectDB警告が残る。新しいRei検証とPose Flowは警告なし。Headless成功と描画あり検証を分けて扱う。手動Play／スマートフォン／公開Webの確認とは報告しない。

18. **発見・修正した問題**
    - 旧Specialが通常punch_2と同Frameだったため、専用8原画へ変更。
    - Enemyのinput_enabled=falseを戦闘前と誤判定し、手を広げる紹介Poseが戦闘中にも出ていた。is_round_activeで通常構えを選ぶよう変更。主人公3人＋敵9人で検証。
    - レイの紹介Pose原画がidleの約77%の身体面積だった。Atlas制作時に通常体格へ補正し、足位置を維持。紹介中だけ短く残す。戦闘中の待機・Special前後では使用しない。
    - Special表示が毎Frameに待機Animationを挟んで先頭Frameへ戻っていた。基底表示更新の前に正しいSpecial clipを選び、8Frameを自然に進行させる。
    - 画面外へ大きく飛ぶLaunchを速度上限・重力・画面内保持で調整。
    - ゴウのサングラス入りGuard原画を不採用にし、目の見えるGuard 2原画へ差し替え。
    - 旧レイのStartup名／無制限Launchを前提にするテスト契約を、今回の実仕様を検証する形へ更新。

19. **未実施／未解決**
    受け手は指定3人のみ。他のEnemyへ新しいRei被弾原画は制作していない。今回のRei専用追加テストでは複数Enemy、既に空中／KnockDownの相手、Bossを受け手にする組合せ、長時間の手動Balance試験は未実施。既存回帰のBoss戦は成功しているが、この組合せの確認とは区別する。終了時ObjectDB警告7件は残る。公開版への反映・公開後確認は未実施。

20. **git status --short**
    [作業終了時の出力](../evidence/rei_reversal/git-status-short.txt)。先行作業のimport／UID／未追跡Evidenceを維持しており、checkout全体をcleanとは報告しない。今回の変更だけを明示的にstageしてcommitする。

21. **commit**
    本報告・実装・原画・検証を含むcommit hashは最終回答に記載。ローカルのfeat/rei-reversal-20261003でgit log -1 --format=%Hから確認できる。公開／pushを実施したとは報告しない。
