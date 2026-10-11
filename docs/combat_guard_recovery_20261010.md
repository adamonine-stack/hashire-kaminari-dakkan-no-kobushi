# ガード後に攻撃入力が止まる不具合

## 原因と修正

`apply_guard_recoil()` はガードされた攻撃を `reset_attack_state(false)` で終了し、パンチとキックの cooldown に硬直時間を設定する。
一方、共有コンボ処理では cooldown の減算が `_update_current_attack()` 内にしかなく、攻撃終了後はこの関数が呼ばれない。
硬直表示が終わっても cooldown が正のまま残り、プレイヤーと敵の通常・方向攻撃の開始条件を満たせなくなる。

攻撃していないフレームでも両 cooldown を減算する。攻撃中の既存タイマー処理と被弾停止の扱いは維持する。

## 再現と検証

`guard_recoil_recovery_check.gd` は戦闘シーンを起動し、双方のパンチ・キックについてガード応答を実行する。
硬直中の入力拒否、硬直終了後の cooldown 解除、状態リセットなしでの攻撃再開を確認する。
その後、プレイヤーはタッチイベント、敵は AI 用の入力経路からパンチ・キックを出し、実際の Area2D 接触による相手 HP の減少を確認する。

- 修正前: cooldown 解除と攻撃再開など10件が失敗。
- 修正後: `GUARD_RECOIL_RECOVERY_CHECK failures=[]`。
- `duel_mobile_repeat_check`, `duel_mobile_input_check`, `stage1_regression`, `dev062_guard_counterplay_smoke`, `st_action_fix_regression` は成功。
- `stage2_regression`, `stage3_regression`, `stage4_regression`, `stage5_shadow_boxer_regression`, `special_reversal_check` も成功。
- `combat_command_integration_check` は6件失敗。HEAD の修正前コードに戻して同じ条件で実行しても同じ6件が失敗する。今回の変更による新規失敗ではない。

検証はローカルの headless 自動実行。実機の手動操作と公開 Web ビルドの更新・確認は含まない。
