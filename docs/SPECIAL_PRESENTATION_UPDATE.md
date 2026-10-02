# 必殺技の豪華演出・大きな吹き飛び 更新報告

2026-10-02。作業ツリー `.special_reversal_20261002`、ブランチ `feat/special-reversal-20261002`。

今回の対象は登録済み切り返し必殺技12種の演出と吹き飛び、およびアッキーの肘打ちを受ける敵9種類の専用反応。被弾素材は「受け手の見た目」と「攻撃した技ID」の組み合わせで選ぶ。全必殺技×全受け手の専用素材が完成したという報告ではない。

## 1–3. 調査・変更・新規ファイル

PlayerAttackData → character specialの攻撃Dictionary → SpecialContactResolver → 受け手のreceive_attack → KNOCKBACK → KNOCKDOWNを確認。Guardはこの経路より先に判定される。KOも既存HP0とラウンド終了通知を維持しながら物理的に飛ばす。

変更した処理: fighter_definition.gd、player_movement.gd、player_knockdown_movement.gd、player_fighter_definition_movement.gd、reversal_effect.gd。必殺技Resource12個のknockback/camera_shake、enemy_01_standard〜enemy_09_seiyaの9定義に専用反応Resourceと技ID対応表を登録。

新規: special_flight_trail.gd、special_launch_reaction_check.gd、tools/prepare_special_reaction_refs.py、build_akky_enemy_reactions.py、update_special_launch.py、pack_special_vfx.py、build_special_launch_review.py。各敵のruntime Atlas/設定/packing_manifestをgodot/assets/characters/special_received_v1へ追加。原画27枚はart_sources/special_received_v1へ保管し、ゲーム配布対象に含めない。オーラ/衝撃原画2枚はart_sources/special_vfx、実行時512×512素材はgodot/assets/effects/special_v1。

## 4–7. Input / Attack / Throw / Combo

今回の新規Input、通常Attack、Throw、Comboはなし。既存必殺技の挙動を更新した。従来の方向Attack/Throw/Comboの不足を全て完成させたという意味ではない。

## 8–9. 必殺技・Damage・軌道

通常P/Kの最大Damage×1.5を保持。下記Damageはテスト時の初期定義値であり、能力補正で変化する。ベクトルはMoveDataの基準値。攻撃側と受け側の補正後も必殺技限定で水平速度600以上・上昇速度400以上を確保する。Guard成功時には適用しない。

| 攻撃者 / 技ID | Damage | 基準吹き飛び(x,y) |
|---|---:|---|
| アッキー / player1_special_thunder_drive | 23 | (760,-460) |
| ゴウ / player2_special_iron_breaker | 38 | (820,-500) |
| セイヤ / player3_special_clear_counter | 20 | (720,-440) |
| Crusher / crusher_fault_break | 12 | (820,-520) |
| Shadow / shadow_slip_counter | 11 | (700,-430) |
| Masato / masato_palm_reversal | 9 | (740,-450) |
| Rei / rei_dragon_uppercut | 14 | (560,-700) |
| Cross / cross_muei | 11 | (730,-480) |
| Rio / rio_cross_counter | 12 | (750,-450) |
| Teki / teki_deadly_hand | 11 | (680,-500) |
| Leon / leon_crow_reversal | 15 | (840,-560) |
| 敵Seiya / seiya_dark_reversal | 36 | (780,-520) |

## 10–11. Combo Break / Guard

既存の短い開始保護、被弾中切り返し、攻撃中断、Gauge/Cooldown/空振り硬直、同時Special処理を保持。非GuardのSpecial命中は吹き飛びとダウンへ遷移。ガード可能で、Guard成功時にはダウンや飛び軌跡を出さない。既存6技の削り0.15、新規6技の削り0.0を独立した期待値で検証。

## 12–13. 攻撃・被弾Motion

アッキーの開始2枚→専用肘打ち→終了のAttackを保持。専用被弾原画はアッキーを受け手として作るのではなく、肘打ちを受けるCrusher/Shadow/Masato/Rei/Cross/Rio/Teki/Leon/敵Seiyaを各3枚ずつ制作した。胸の衝撃でのけぞるHit、空中へ飛ぶAir、仰向けまたは横向きに着地するDownを登録。

受け手のspecial_damage_reactions[attack_id]がhit/airborne/down Clipを指定する。received_akky_elbow_hitは1枚、airは初動と空中の2枚、downは1枚。特殊反応が未登録の技は従来反応へ戻る。1枚ずつ制作・確認し、クロスとレオンの逆向きのけぞりを修正。各敵につき初動原画で一度だけ倍率を較正し、その倍率を空中・ダウンでも固定。横幅が必要な姿勢はセルを広げて収め、Sprite Scale/Pivotを変更しない。足基準は既存Idleに合わせる。

## 14–16. Effect / AI / HitBox

炎状の全身オーラ、稲妻、足元リング、前方軌跡、攻撃部の輝き、白い閃光と拡大衝撃波、飛行中の光の軌跡、着地のエネルギーBurstを接続。色は青/金/紫/赤、Camera Shakeは6。Effectの時間はHitStopに合わせて止まり、終了後に消える。

必殺技の接触位置が通常PunchAreaから取得されていた問題を発見し、SpecialArea中心を受け手HurtBox内へ収めた座標に修正した。HitBox/HurtBox寸法は今回変更していない。横向きの専用原画が画面端で切れるため、実際の全Frame幅を命中時に一度計測して停止位置へ反映。通常時の衝突形状は維持。Enemy AIの候補判定・使用率は今回変更していない。

## 17–18. 実Game確認・修正

既存25回帰テスト成功。special_reversal_checkで12技のDamage、独立Guard削り値、非Guardダウン、補正後の大きな力、Combo Break/入力/同時接触/AI反応を確認。akky_reversal_motion_checkも成功。

special_launch_reaction_checkは実Battle.tscnのArea2D接触経路で敵9種類×左右2方向を確認。専用Clip選択、全遷移のScale/Pivot固定、空中と着地の原画が描画Viewportに収まること、飛距離200px超、高さ55px超、Guardで飛ばないことを確認。KO時の飛行・着地・起き上がらない状態も確認。

非headlessで開始/Impact/Air/Downを72枚、飛行の連続確認を16枚、合計88枚保存。最終テストのfailures=[]。描画・共通チェックにSCRIPT ERRORや終了警告はない。アッキーから敵への実測は水平約427〜483px、上昇約112〜174px（初期位置640、画面端で停止）。これは制御された実ゲーム描画であり、手動Play Testではない。

修正した問題: 通常パンチ由来のEffect座標、逆向きのけぞり2枚、ダウン姿勢の画面端切れ、専用技IDが非発動中に空になるDictionary、立ち被弾を前提にした旧テスト、固定FPS終了時の音声オブジェクト残存。

## 19. 未完了

他の必殺技を受ける各プレイヤー/敵の技別専用反応、他11攻撃者の専用Start/Attack/Finish原画の不足、追加中間Frame、Boss独自Special/Ultimateとの全経路統合、元の指定12戦闘ケースと方向Attack/Throw/Comboの全体確認、手動実戦Balance確認は継続作業。今回の更新を全体完成や公開済みとは扱わない。

## 20–21. Git

検証済みの素材・処理・テスト・本報告をローカルコミットする。実際のhashとgit status --shortはevidence/git_special_presentation_completion.txtへ記録。既存の生成Import/UID/ログ等の未コミットファイルは保持。Push/PR/公開は行わない。
