# Crusher方向技・Situation AI工程

開始/終了branch: codex/directional-combat-20261003。開始HEAD: b4f6085fe97fe0a37904c6d4f9e0b5772a427001。終了HEAD、git status --short、変更/新規一覧はcrusher_situation_git_result.txtに工程Commit後保存する。既存未Commit変更は保持し、今回のResource/Script/Test/報告だけをCommitする。

## 実装範囲

Crusherの既存PlayerFighterDefinitionMovement / PlayerComboMovementに6技のResourceを接続。プレイヤーの方向技と同じStartup->Active->Recovery、HitBox、Damage/Guard/Knockdown処理で動作する。通常P/K、前進P/K、後退K、足払い。専用の新Sprite制作ではない。InputMap、スマホUI、AKKYの画像・戦闘定義は変更していない。

技を実装したという表現と、専用モーション制作完了を区別する。今回の素材は公式Crusherの既存crusher_v1から流用し、Sprite Scale/Offsetや体格を変更していない。

| 技ID suffix | Startup/Active/Recovery | Damage係数 | HitBoxサイズ/中心 | 移動 | 元Motion | 制作状態 |
| --- | --- | --- | --- | --- | --- | --- |
| neutral_punch | .10/.09/.22s | P×1.0 | (50,42)/(45,-112) | 0 | punch_1 | 既存流用 |
| neutral_kick | .18/.10/.30s | K×1.0 | (68,44)/(84,-82) | 0 | kick_1 | 既存流用 |
| forward_punch | .18/.10/.32s | P×1.0 | (60,46)/(64,-106) | +34px/.20s | punch_2 | 既存流用＋物理踏み込み |
| forward_kick | .28/.12/.44s | K×1.10 | (70,48)/(90,-82) | +66px/.27s | kick_1 | 既存流用＋物理前進 |
| back_kick | .17/.10/.32s | K×.90 | (70,42)/(86,-82) | -30px/.14s | kick_1 | 既存流用＋物理後退 |
| down_kick | .22/.10/.36s | K×1.0 | (100,30)/(65,-25) | 0 | crouch_kick_sweep | 既存流用、Knockdown |

時間はResourceの基準値。既存Character速度/威力倍率を共通処理で適用する。足払いはHitBoxを足元に、HurtBox高さをActive付近のみ60%に設定し、Spriteを縮小しない。前進KはKnockback(300,-90)、足払い(80,-70)、その他(120,-40)。すべてGuard可能、Whiff Cancel不可。新しい無敵・Armor・必殺技・Effectは追加していない。

## Motion棚卸し

今回のP/K素材は上表の4種。既存idle/walk/dash/backstep、jump_start/air/fall/land、air attack、guard/crouch_guard、damage_high/light/heavy/low、knockdown/down/getup、throw_start/hold/release/grabbed/thrown、専用Special/被Special素材は保持する。

Back P対空アッパー、Down P Launcher、Crusher自身の方向投げ3派生・そのAKKY被投げ姿勢は専用制作が必要。今回の6技に含めていない。空中技と通常Throw/Specialは既存処理を維持する。AKKY用throw contact/release artをCrusher攻撃側へ流用していない。

crusher_situation_visual_reviewは6技×左右の接触frameをGodotで書き出す。crusher_situation_evidenceに保存し、前進パンチ/足払いなどを比較した。新画像・Atlas・Texture/Particle/Effect Nodeは追加していない。既存素材を移動/当たり判定の違う技へ接続した段階であり、6種類の新規専用Motionが完成したという意味ではない。

## Situation AI

EnemyAIProfileのuse_situation_movesは既定false、Crusherのみtrue。MoveDataにai_tagsと使用距離の上下限を追加。その他敵は既存AIへfallbackする。

- 至近距離(<65px): P、中距離(～130px): K、遠め(～205px): 前進K。
- GroundのAttack Recoveryを0.24s観測: 前進P候補、Attackを0.24s観測: 後退K候補。しゃがんだ待機相手(>90px): 足払い候補。
- 使用距離範囲の外や未観測段階では選ばない。Startup/Active/Recovery、Air/Ground、距離・しゃがみという戦闘状態を観測し、相手Inputイベントを読まない。
- 既存のReaction Timer、Attack Cooldown、AI locked state、Guard/Backstep判断を尊重。Approach中も射程に入ったら技を候補にする。
- 空中相手への新Anti-Air候補は出さず、既存AIへ戻す。存在しないアッパー姿勢を通常パンチの技IDで強制勝利させることはしない。
- AI_SELECTED_MOVEと観測状態/時間を既存Development Debug情報に追加。Round/Character Resetで消去する。

距離閾値と使用範囲は初期値。Normal EnemyのCrusherを最終Balanceへ調整したという主張ではない。難易度別Parameterの新規展開、方向投げによる壁脱出・Anti-Air・長いCombo選択は残作業。

## 検証

- crusher_situation_check初回: failures=[]。距離選択、反応Timer、Recovery移行直後の差し込み拒否、0.24s観測後のPunish/Evade、未対応Anti-Airの拒否、6技×両向きの実HitBox接触とRecovery終了を確認。
- 同Testの最終版: failures=[]。攻撃開始時Scale維持と、自律AIの6秒間の技選択も確認。前進K/通常Kを計5回選び、実際に攻撃・命中・Recoveryを進行した。長時間対戦や全技の自律選択率確認ではない。
- CRUSHER_SITUATION_VISUAL_EXPORT_OK。Godot接触姿勢の描画比較。手動実プレイとは区別する。
- air_combo_check、directional_throws_check、special_reversal_check、stage1_regression: failures=[]。AKKY側の入力/Combo/Throw、Crusherの既存Special、KO/交代/GameOver等の回帰を確認。
- special_ai_situation_checkはこの作業ツリーに存在せず実行できなかった。別作業ツリーの9Character Test記録を今回の確認済みに流用しない。

Godot環境のroot certificate store読込エラーは残る。スマホ実機・手動連続対戦、多数敵/全Stage/Result/Continue/Retry/Public Web、GPU性能は未確認。

## ファイルと残作業

変更: PlayerAttackData、EnemyAIProfile、PlayerFighterDefinitionMovement、PlayerMovement、Crusher定義、Crusher AI Profile、工程メモ。新規: Crusher攻撃Resource6本、Situation Test、描画Review Test、本報告。既存画像は変更しない。

戦闘拡張全体は未完成。次はCrusherのBack P/Down Pと方向投げを、正式DesignのKey Pose比較から制作して追加する。その後Air P/急降下モーション、Landing Recovery、壁/敵衝突追加反応、双方の対空・位置・距離・Timingの実戦調整、他キャラクターへの展開が必要。
