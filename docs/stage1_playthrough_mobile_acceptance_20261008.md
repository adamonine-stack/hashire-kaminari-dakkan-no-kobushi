# 第1ステージ通し戦闘・スマホ相当確認

開始branch:codex/stage1-gou-seiya-20261007、HEAD:2183ddb。
新テスト:godot/tests/stage1_release_playthrough.gd。通常Input.action_press/releaseだけを用い、HP/技Damage/HitBox/敵AIを変更せず戦闘。導入完了を明示。第1敵のis_defeatedとHP0を突破条件とし、全編CLEARとは区別する。

## 実描画・通し戦闘
844x390、Intel Iris Xe、Godot native、音声Dummy。AKKY/Gou/Seiya全員でクラッシャーを倒してNEXT_STAGEの選択画面へ進む例を確認。敵が実際に攻撃しプレイヤーが被Damageを受けたこともチェック。画像:audit_evidence/stage1_release_playthrough/各fighter。戦闘画面と次選択画面を目視確認。手動プレイ・実機スマホではなく自動入力のnative実行。

## 入力
844x390のScreenTouch入力を3主人公で実行し各raw_touch=true failures=[]。方向保持/離した履歴/遅延入力/左右/空中攻撃など既存ケース。実機確認とは別。

## 検証用操作の調整と失敗の扱い
初期連打botではSeiyaが敗北。接近入力を保持するとForward Pを多用し、通常コンボへ繋がらないこと、Specialを保持し続ける入力では単押しにならないことを修正。相手の見えるAttack StateからGuard、Lowには下Guard、Gaugeが自然に満タンの場合のみSpecialを単押しする。通常P/Kの入力で戦う。製品バランスは変更しない。
最終native SeiyaはHP28、敵HP0、敵攻撃10で突破。Headlessのclose approach variantでもHP71で突破例がある一方、native用の最終botをheadlessへそのまま適用すると敗北した。自動操作は実行条件・タイミングで勝敗が変わり、常勝・全headlessケース成功とは報告しない。ゲームの勝利/敗北どちらも生じることと、製品不具合を区別する。
初回nativeはfixtureのintro完了待ち不足で戦闘開始せず、intro完了を明示して解消。旧playthroughの全編CLEAR判定は第1ステージ限定判定として不適切だったため新テストへ分離。

## 公開について
第1ステージ突破の実描画証拠は3人分揃った。次は公開対象のclean checkoutでWeb buildとsmoke確認、push/PR/merge、Pages deployment完了、公開先で起動/選択/戦闘/ステージ突破を確認する。現在未公開。自動botの実行条件差、ObjectDB終了cleanup警告、実機スマホ・音声未確認は記録して保持する。既存の未commit変更は混ぜない。
