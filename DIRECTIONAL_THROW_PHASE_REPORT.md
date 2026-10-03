# 方向投げ基盤・掴みContact工程（2026-10-04）

本書はPhase 4の中間工程の報告。投げ4種のゲーム処理と掴みContactは実装済みだが、4種の専用Release/Victim Motion・衝突拡張までを完成とはしていない。

## Git

開始/終了branch: `codex/directional-combat-20261003`。
開始HEAD: `9b42db19481c48cfaa654ee8724daa767bcd9ded`。
実Worktree: `.directional_combat_20261003`（親フォルダはGit Repositoryではない）。
終了HEAD・Commit Hash・変更/新規File・git status --shortは `directional_throw_git_result.txt`。
既存の多数のimport差分、UID、QAログ、Save/Cacheはコミット対象外で保存。

## 調査と既存互換

PlayerMovement -> PlayerComboMovement -> PlayerKnockdownMovement -> PlayerFighterDefinitionMovementをPlayer/Enemyが共有。
既存ThrowはStartup -> Hold -> Release -> Recovery。Whiff、双方同時Throw Escape、被投げ側Escape判定、再掴みLockがある。
KO/Down/Airborne/HitStun/Invincible/Throw拘束中の投げ制限を保持。HitStun中は投げ不可とした。
Character固有のCross/Teki/Readable Grappleは既存のRoutingを維持。
全キャラへ一斉に技を追加せず、AKKYでResourceを有効化し、Crusherを相手に共通Receiverを確認した。

## 追加Move（秒、AKKY Throw基礎Damage 15）

|Move|Startup|Hold|Recovery|Whiff|Damage|Velocity|役割|
|---|---:|---:|---:|---:|---:|---|---|
|Neutral Throw|0.12|0.20|0.30|0.50|15|(120,-120)|基本Down|
|Forward Throw|0.17|0.20|0.38|0.60|14|(480,-180)|前方へ距離を作る|
|Down Throw|0.20|0.20|0.42|0.65|20|(0,80)|横移動なし、Down最低1.10秒|
|Back Throw|0.10|0.20|0.38|0.60|14|(-70,-100)|解放時の位置交換|

4技はPlayerAttackData Resource。方向はFacing基準で、Direction/Action競合処理を既存Bufferへ接続。
Buffer 150ms、方向保持と方向を離して120ms後のThrowに対応。InputMap/UIボタンの追加・二Action同時押しなし。
Downはしゃがみ状態から投げへ移行可能。Backstep中に新RoutingからThrow開始する迂回は不可。
Back Throwは掴み成立前の両者位置を保存し、壁範囲内で解放時に交換する。
通常Range外のCounterは140ms以内、相手が80px/s以上で接近中、延長時Range 70px（通常55px）まで。ボタン入力や特定Move IDを読まない。失敗時Whiff Recovery。
通常Range内のBack Throwは基本投げとして成立する。
Directional Throwのみ旧Knockdownの最低水平Forceを外し、ResourceのTrajectoryを使う。
Ground Bounceは未追加。Down Throwは長めDownで制限し、追撃不能/再掴み防止を維持。
FighterDefinitionの `throw_received_damage_scale`（初期1.0、設定範囲0.25〜1.0）でThrow耐性を指定可能。既存AI Throw Escape Probabilityも保持。実Bossの数値調整/投げ回数制限は未実施。

## Motion・Design

正式AKKY `player01/battle.png` とCrusher Portrait/Battleを比較。旧AKKY throw/Crusher thrownの流用だけではHeldが倒れ姿になったため採用を見直した。
imagegen built-inでContact Key -> 分離 -> 上端Margin修正の順に制作。長袖、腹部の黒いインナー、細身、顔、脚比率を確認。
新規Motionは `directional_throw_hold` / `directional_throw_held` 各1Key Pose。現在は静止Contactで同期。手と胸の位置、足元を保持。
Godot Imageで固定Cellへ技術的Packingし、Crusherの原画を標準Facing方向にMirror。SpriteのRuntime Scaleを変更しない。
AKKY 320x224、Crusher 400x280の小Atlas、追加Node/Particleなし。
StartupとRelease/Knockbackは現在の既存Motionを再利用。Directionごとの専用Victim/Releaseの制作は残る。Specialや新Air Motionはこの工程に含めない。

## Test

- `directional_throws_check.gd`: failures=[]。左右4種、Hold/Release/一回だけDamage、Trajectory、位置交換、壁際脱出、Counter成功/退避/時間切れ、Guard崩し、Throw耐性、Down/KO/HitStun/Invincible/Airborne不可、Backstep迂回不可。
- 既存MobileControlsのhandler -> InputMap -> Buffer -> Dispatcherで左右3方向、保持/Releaseから120ms後Throwが通る。実スマホTouchは未確認。
- `directional_throw_visual_review.gd`: Iris Xe/OpenGLで左右4種のStart/Hold/Release計24PNG。両向きのHeld Contactを目視。描画確認と手動戦闘を区別する。
- `directional_attacks_check.gd`: failures=[]（新Contact接続後）。
- `special_reversal_check.gd`: failures=[]（新Contact接続後）。
- `stage1_regression.gd`: failures=[]（新Contact接続後）、Stage開始/攻撃/Jump/HitStop/Clear/Retry/AI KO/交代/GameOver。
- Windows root certificate storeの環境エラーが残る。実戦手動、実機、公開Web、負荷測定、全Stage回帰は未実施。

## 次に必要な工程

4種のRelease/Victim専用Key Poseと中間Frame、両者Frame同期の完成。
Forward ThrowのWall/Enemy Collision、Boss個別Resistance調整、敵側Move repertoire/AI、Air Combo、全キャラ展開。
全79項目の戦闘システム完成は未達。
