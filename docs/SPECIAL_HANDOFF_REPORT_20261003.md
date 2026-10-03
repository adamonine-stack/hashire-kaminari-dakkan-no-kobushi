# ST_action 必殺技引き継ぎ報告 2026-10-03

全体完成ではなく、既存第1・第9ステージを保持した引き継ぎ修正の記録。作業場所は `.cross_motion_20261003/godot/project.godot`、ブランチ `feat/special-handoff-ai-20261003`、基点 `738b919`。親フォルダーの `.git` は空でGit作業ツリーではない。通常実行が起動前に失敗する環境のため、権限切替後の実行で調査・編集・検証を行った。

1. 調査した既存Battle System

   Playerの継承チェーン、共通必殺技の状態・開始保護・ゲージ・接触遅延解決、Guard、Throw、Combo中断、敵AI、Battle/TrueBattle、MoveData、12定義の実SpriteFramesを調査。第1ステージのCrusherには専用攻撃・三人の専用受け手原画がある。第9ステージには確定済みサマーソルト→サイドキックがあり、既存仕様を維持。旧資料の未実装一覧をそのまま現在の状態とは扱わない。

2. 変更したFile

   - `godot/scripts/player/player_fighter_definition_movement.gd`: AIタグ・使用率・一度だけの状況判断、観察リセット、Cross/Teki必殺技のガード受付と必殺ダメージ。
   - `godot/scripts/player/player_movement.gd`: `_connect_throw`へ任意Damage引数。通常投げの既定値を維持。
   - `godot/scripts/combat/reversal_effect.gd`: Cross/Tekiの人物を覆わないEffect、実SpecialHitBoxへのActive軌跡同期。
   - `godot/tests/cross_muei_check.gd`: 通常投げと必殺技の独立したDamage期待値。
   - `godot/tests/muei_web_qa.gd`: 上記からWeb用QAを再生成。
   - `godot/tests/stage9_two_hit_qa.gd`: 終了時の音声停止・接触参照解放。戦闘仕様は保持。
   - `.github/workflows/deploy-godot-web.yml`: 新規2戦闘チェックを登録。

3. 新規File

   - `godot/tests/special_ai_situation_check.gd`
   - `godot/tests/special_grapple_guard_check.gd`
   - `godot/tests/special_handoff_inventory.gd`
   - `tools/run_special_handoff_checks.ps1`
   - `docs/SPECIAL_HANDOFF_INVENTORY_20261003.md` / `.json`
   - 本報告。実行ログと結果JSONは `evidence/handoff_checks`、描画36PNGは `evidence/handoff_grapple_guard`。PNGとローカルRuntimeディレクトリーはローカル証跡として保持する。

4. 追加したInput

   追加なし。既存 `special` / `special_attack` とInput Bufferを維持。AIは相手の入力イベントを読み取らない。

5. 追加したAttack

   新規技Resource追加なし。既存 `cross_muei` / `teki_deadly_hand` の実接触経路を修正。

6. 追加したThrow

   新規通常投げなし。通常投げはGuardを攻略し、従来のThrow Damageを使用する。必殺技の入口だけはGuard可能で、命中後は既存の脱出可能な専用掴み演出へ接続する。

7. 追加したCombo

   新規Comboなし。命中時は既存 `receive_throw` / `interrupt_combo` を通じて攻撃と入力連携を中断する。

8–9. Characterごとの必殺技とDamage

   実定義を読み込んだ値。難易度の追加補正前。通常は `round(max(P,K)×1.5)`。Stage9の承認済み例外は維持する。

   | Character | 技ID | Damage |
   |---|---|---:|
   | アッキー | player1_special_thunder_drive | 23 |
   | ゴウ | player2_special_iron_breaker | 38 |
   | 主人公セイヤ | player3_special_clear_counter | 13+13（各段1倍） |
   | クラッシャー | crusher_fault_break | 12 |
   | シャドウ | shadow_slip_counter | 11 |
   | マサト | masato_palm_reversal | 9 |
   | レイ | rei_dragon_uppercut | 14 |
   | クロス | cross_muei | 11 |
   | リオ | rio_cross_counter | 12 |
   | テキ | teki_deadly_hand | 11 |
   | レオン | leon_crow_reversal | 15 |
   | 第9ステージセイヤ | seiya_dark_reversal | 24+24（各段1倍） |

10. Combo Break方式

    既存のHitStun受付＋開始0.10秒保護、明示的な発動禁止条件を維持。Gauge/Cooldownが必要。AIは0.12秒の観察後、同じ連続した可視攻撃について一度だけ抽選する。被弾中のReversalも一度だけ判断する。相手が変わった場合・攻撃終了・自分の定義変更時は観察をリセットする。

11. Guard時の処理

    Cross/TekiのHurtBox接触で、掴みへ移る前に `_can_guard_attack` を確認。Guard成功は共通必殺技接触Resolver→既存Guard Reaction/後退/HitStopへ進み、Throw Lockは発生しない。設定済み15%Chipだけを許可。Guardは接触として数え、攻撃側は設定されたRecoveryを消化する。完全WhiffのRecovery倍率は従来どおり。通常投げのGuard突破は維持。

12–13. 追加したAttack / Damage Motion

    今回新しいSprite原画・Atlas・Motionを制作したとは報告しない。既存のCross/Teki専用掴み・解放と受け手素材を保持して実接触を修正。現在の実参照一覧は `SPECIAL_HANDOFF_INVENTORY_20261003.md`、具体的なAtlas領域は同名JSON。登録名だけで専用Motion完成とは判定しない。

14. 追加・変更したEffect

    Crossは細い方向線、Tekiは手元の爪軌跡を中心に、人物を覆う大きなAuraを外した。Active中心は実SpecialHitBoxから取得し、左右反転を含む位置一致をテスト。HitStop同期は維持。検証Fixtureの残ったEffectが次のケースへ重なる問題も修正。

15. Enemy AI変更

    `ai_special_tags` のreversal/counterを実際に参照。未指定の旧Resourceは既存用途を維持。Counter/Reversal両経路に敵種別係数0.30/0.65/1.0を適用。可視通常攻撃・必殺技状態を観察し、即時入力読み取りをしない。抽選を同じ脅威中に繰り返して、長い攻撃にほぼ必ず反応する挙動を修正。HPによる新規Frequency/UI追加は行っていない。

16. HitBox / HurtBox変更

    寸法・HurtBox・正式Sprite Scaleは変更なし。Cross/TekiのEffectを実HitBoxへ同期。専用Damageを既存投げ演出へ渡す任意引数を追加。

17. 実Gameで確認した内容

    - `special_ai_situation_check`: 9敵の実Battle Sceneで用途タグ、使用率、観察待ち、一度だけの抽選、入力イベント非参照、状態リセット。失敗0。
    - `special_grapple_guard_check`: Cross/Teki×味方3人×左右12組の実HurtBoxコールバックでGuard、設定Chip、Recovery、攻撃中断、掴み、1.5倍Damage、一度だけの解放Damage、通常投げ互換性、Effect/HitBox位置。失敗0。手動で状態を制御した自動接触検証であり、自然な連続プレイの全フレーム検証ではない。
    - 同チェックを非headless OpenGLのBattle描画で再実行、Guard/held/released計36枚を保存・比較。画像だけでは受け手デザインの全フレーム合格を意味しない。
    - 第9ステージ `stage9_two_hit_qa`: 54戦闘ケース、322Motionフレーム、失敗0。今回この項目はheadless。
    - `cross_muei_check`: 通常投げ・必殺投げ・壁・脱出・KOを含む54ケース、失敗0。
    - 32項目の回帰は機能上すべて成功。終了時警告なしは24項目、8項目はObjectDB解放警告が残る。ランナーは警告も別欄に記録し、警告付きのstrict PASSをTrueにしない。結果は `evidence/handoff_checks/test-results.json`。
    - 手動実戦、実機スマートフォン、今回変更の公開Webは未検証。

18. 発見・修正した問題

    Counter側の敵種別係数欠落、未使用AIタグ、同じ攻撃への繰り返し抽選、定義切替時の古い観察状態、Cross/Tekiの必殺技Guard迂回と通常Throw Damage流用、旧テストがその実接触分岐を通らないこと、検証Fixtureの残留Effect、人物を覆うAura、Active軌跡とHitBoxの不一致、第9ステージQA終了時の音声/参照残存警告を修正。再描画時にIntel OpenGLのシェーダーキャッシュ読込エラーも検出したため、失敗ログを保管し、新しい検証用APPDATAで描画し直し、エラー・警告0、36描画画像とチェック成功を確認。ゲームデータや既存キャッシュは削除しない。

19. 未解決事項

    - レイ、リオ、レオン等で必殺攻撃/開始/終了が通常P/K等と同じAtlas Frameを参照する。シャドウとクロスにも通常技との共有が検出された。自然な共有か不適切な流用かは原画・実Motionを比較して確定する。専用新原画→1Frameずつ制作→中間Frame→Atlas→ゲーム確認が必要。
    - 技別被Damage/Guardの専用原画・中間Frameが全組み合わせ揃っている状態ではない。既存技別登録は一覧JSONに保存。
    - 方向P/K/Throw・↓Air K・派生Comboの全キャラクター接触経路の照合。Clip名が見つからない項目を未実装と断定せず、固有名/入力接続を追う。
    - Boss既存特殊技の共通ルール統合、必殺掴み同士を含む全技組み合わせの同時接触整合性。
    - 元依頼の全12条件、複数敵、空中/Knockdown対象、Wall/Boss、全Effect局面・全フレーム・手動Balanceを一体の実戦として検証する工程。
    - dev053/dev056/dev064/dev065/dev066/stage3/opening_flow/true_seiyaの8旧検証で終了時ObjectDB警告。機能エラーはないが、解放完了とは報告しない。
    - 新しい専用Spriteを全キャラクターへ追加した状態でも、全体の完成条件を満たした状態でもない。

20. git status --short

    実際の全出力を `evidence/handoff_git_status_before_commit.txt` と `evidence/handoff_git_status_after_commit.txt` へ保存。既存の多数のImport/UID等は保持し、今回のコード・文書・ログだけを選んでコミットする。

21. commit hash

    実コミット後に `evidence/handoff_git_completion.txt` へ記録。Push/公開はこの工程では行っていない。
