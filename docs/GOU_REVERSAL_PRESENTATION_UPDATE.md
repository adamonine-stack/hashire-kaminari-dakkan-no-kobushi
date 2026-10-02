# ゴウ Iron Breaker 専用モーション・クラッシャー反応

2026-10-02。作業ツリー `.special_reversal_20261002` / ブランチ `feat/special-reversal-20261002`。

## 今回の更新

ゴウの専用攻撃原画4枚と、Iron Breakerを受けるクラッシャーの専用反応原画3枚を、1枚ずつ制作・確認後にアトラスへまとめた。

- ゴウ: ひねって溜める→踏み込み→重いストレート→硬直。gou_reversal_startup / gou_reversal_breaker / gou_reversal_finishを実STARTUP/ACTIVE/RECOVERYへ接続。
- クラッシャー: 胸腹部を折る初動→膝を引き上げた空中姿勢→腹を押さえた横倒れ。player2_special_iron_breakerへreceived_gou_breaker_hit/air/downを登録。アッキー肘打ちの反応は保持。
- 攻撃者・受け手ごとに一度較正した倍率を全フレームへ共通適用。ゴウは腰アンカーも合わせ、通常SpriteのScale/Pivotを変更しない。
- 原画はart_sources/gou_reversal_v1とart_sources/gou_received_v1/enemy_01_standardへ保存。runtime Atlasはgodot/assets/characters/player02/animations/reversal_v1とgodot/assets/characters/special_received_gou_v1/enemy_01_standardへ配置。build_gou_reversal.pyで再生成可能。
- Damage/Gauge/Cooldown/Guardと吹き飛び値は維持。ユーザーの「面白いからそのくらいでいい」に合わせ、現在の派手な飛距離を維持する。

## 検証

gou_reversal_presentation_checkは実Battle.tscnで攻撃4フレーム×左右、実接触→専用反応→着地、通常被弾との区別、ガード、KO、Scale/Pivot固定、全原画の画面内への収まりを検証。headlessと非headlessともfailures=[]。描画41枚、飛行プレビュー23枚。左右とも水平約447px、上昇約238px。

gou_motion_atlasは旧テストのクリップ名・素材期待値を専用原画へ更新。身体の不透明部分は従来270pxの足基準を守り、薄い透明縁もセル内に収まることを別々に検証。277フレームでfailures=[]。音声を停止・解放して終了時の残存警告も解消。

special_reversal_check / special_launch_reaction_check / akky_reversal_motion_checkもfailures=[]。既存25回帰テストは25/25成功。結果はevidence/gou_presentation_regressions.logとevidence/test-results.json。描画記録は制御された実ゲームであり、手動実戦確認ではない。

## 残作業と保存

ゴウの技を受ける他8敵の専用反応、他10攻撃者の専用Start/Attack/Finish原画、他の技×受け手の専用反応、追加中間フレーム、Boss独自技経路、元の方向Attack/Throw/Combo全体と指定戦闘ケース、手動実戦・公開確認は継続作業。全体完成という報告ではない。

ローカルコミットまで保存し、Push/PR/公開は未実施。既存Import/UID/ログ等の未コミットファイルは保持。hashと残存状態はevidence/git_gou_presentation_completion.txtへ記録する。
