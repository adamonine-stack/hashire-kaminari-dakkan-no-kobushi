# 敵専用反応・画面端への高速吹き飛び・サイズ補正

2026-10-02。作業ツリー `.special_reversal_20261002` / `feat/special-reversal-20261002`。

## 今回の仕様

- ゴウのIron Breakerを受ける残り8敵へ被弾・空中・ダウンの原画24枚を追加。クラッシャーを含む9敵すべてで、アッキーの肘打ちとゴウの重打撃を技ID別に選び分ける。服装・体格・既存リソースIDを保持。
- アッキー: 横速度の基準を760から2200へ変更。能力補正後も1800以上。命中時に表示中の画面左右端を壁として記録し、飛ばした側の端に到達→0.16秒の衝突姿勢→重力で落下→ダウン。壁前に地面へ落ちないよう、移動中の高さは約140pxを上限に維持。端数誤差で壁判定が停止しないよう0.5pxの許容を設ける。
- 壁姿勢と落下姿勢は各敵の既存専用原画から選択。新しい壁原画9枚を制作したという意味ではない。壁の閃光・縦の衝撃線・効果音・揺れを追加し、接触と落下を別の実状態として処理する。壁への衝突で追加ダメージは加えない。
- ゴウ: 壁へ運ぶ仕様を使わない。基準力(460,-400)、補正後の上限(420,-400)。中央付近から約310〜320pxで地面へ落ちる。被弾直後から胴体中心で後方へ1回転し、着地直前に回転を完了。飛距離・速度・サイズは維持し、着地時は回転角を戻す。Damage/Gauge/Cooldown/Guard条件を維持。
- サイズ: 飛行開始時のカメラ位置・倍率をダウン/起き上がりの間まで固定し、飛行中にカメラの拡大率が変わらないようにした。専用反応の原画密度も共通で6%縮小。各敵ごとに一度較正した密度を被弾・空中・壁・落下・ダウンで共用し、Sprite Scale/Pivotは変えない。ゴウの攻撃原画と元のIdleは変更していない。
- 全原画が画面端で切れないよう、専用Clipの幅を命中時に計測して停止位置へ反映。壁は固定のステージ座標ではなく、その時表示されていた画面の端。画面揺れ分の余裕も取る。

## ファイル

新原画はart_sources/gou_received_v1に保管し、Godot配布対象外。runtime Atlasはgodot/assets/characters/special_received_gou_v1の9キャラ分。アッキーの共通体格補正はspecial_received_v1の9Atlasへ反映。

build_gou_reversal.pyは基準姿勢を再作成して全9敵を構築。build_akky_enemy_reactions.pyは保管済み原画を優先して構築し、configure_akky_wall_reactions.pyを呼んで壁/落下の対応も復元する。update_special_launch.pyも最新のアッキー・ゴウの基準値を保持。build_special_reaction_reviews.pyで最終描画から一覧とプレビューを作る。

## 確認

akky_wall_launch_checkとgou_reversal_presentation_checkは実Battle.tscnの接触経路で、9敵×左右の技別反応、Sprite Scale/Pivot固定、カメラ倍率固定、画面内への収まり、着地、ガード、KOを確認。アッキーは壁の衝突姿勢・落下姿勢・壁衝突回数1回を、ゴウは200px超360px未満の短い移動、後方1回転と着地時の角度復元、壁衝突0回を独立に確認する。

アッキーはさらに、各敵の近/遠位置×左右の36ケースを受け手のreceive_attack経路で確認。表示画面端への到達、衝突後の落下、追加ダメージなしを検証する。

最新headless結果はevidence/final_body_*.log、非headless結果はevidence/final_wall_render.logとfinal_gou_render.log。描画はevidence/akky_wall_launch_finalとgou_reversal_final。既存25回帰テストはevidence/screen_wall_regressions.log、test-results.json。カメラ・壁・短距離設定後の25/25成功を確認。最終サイズ補正は対象2技の全敵・左右の接触と描画で再確認する。制御された実ゲームの確認であり、手動実戦や公開確認ではない。

最終サイズ補正後のheadless追加4チェックはすべて成功。非headlessもfailures=[]、アッキー138枚・ゴウ131枚（計269枚）。壁の近/遠×左右36ケースも成功し、SCRIPT ERRORや終了警告はない。プレビューは各4物理フレームを約67ms間隔で並べた制御された動作確認用GIF。

## 保存・残りの範囲

今回依頼されたゴウの全敵専用反応、アッキーの画面端への高速壁衝突、サイズ補正、ゴウの短距離化と後方1回転を対象とする。他10攻撃者の専用攻撃原画、他の技×受け手の専用反応、元の方向Attack/Throw/Combo等全体の完成条件は継続作業。

ローカルコミットまで保存。Push/PR/公開は行っていない。既存の生成Import/UID/ログ等は保持し、コミットhashと残存状態をevidence/git_enemy_reactions_wall_completion.txtに記録する。

## 後方1回転の最終確認

ゴウのbackflip_on_launchで命中直後から胴体中心に連続回転。左右それぞれ逆方向にTAUまで進み、着地時に角度0へ復元する。空中時間から回転時間を求め、既存の短距離弾道を維持。通常攻撃とアッキーには適用しない。

gou_backflip_check.logとgou_backflip_render.logはfailures=[]。全9敵×左右で単調な1回転、着地、角度復元を確認し、149枚を描画。アッキー138枚と合わせ287枚。backflip_regressions.logで既存25項目が成功。追加のアッキー壁・共通必殺技・アッキーモーションチェックも成功。実描画のspin画像から確認一覧とGIFを更新した。
