# 第4ステージ クロス Motion/必殺技 改修計画

公開e27db58を基準にStage4 enemy_05_power（クロス・ムラサメ）を調査。既存cross_v2には専用無影連投のcharge/reach/grip/pivot/release/recoverがある。安全な原画は保持し、今回新規制作は個別Frameに限定する。

既存Motion一覧はframes.json（全Clip/Frame/Atlas参照）、docs/SPECIAL_HANDOFF_INVENTORY_20261003.md、cross_stage4_20260928.mdを併用。P/方向P/K/方向K/Air/Throw6種/Comboを維持。Startup/Attack/Hold/Release/Finishは固有Motionを維持しphase時間へ合わせる。

重点: damage high/low/light/heavy、down/ko/getup、Akky/Gou/Seiya受け、foot baseline、hair/face/jacket/red sleeve tag/chain/boots、左右反転、重複Sprite、Atlas切れ。原画面積を体格の補助指標とし姿勢の高さとは区別。Idle area14082、Down0.725、Gou/Seiya受けHit0.811/Down0.706。DownとLow Hitを個別に新規制作、姿勢に適したoffline体格補正を実施する。

無影連投はGuard可能な入口を持つ専用回転投げを保持する。主力通常技×1.5、GaugeMAX消費、Cooldown4.2、Startup無敵0.10。接触を同Frame resolverへ送り、互いに同時接触が成立した場合は双方のSpecial Hitへ、片側だけ成立する地上接触は既存の投げ抜け可能なgrip/releaseへ。Guardは専用反応と0.55Recovery、Whiffは0.6875。成功/逃げられた後も専用Recoveryを確保し通常投げへ戻す。

追加必要Motion: New Down / Low Hit、補正Damage/受け各Frame、主人公3人のSpecial Guard（承認済みRei Guardを安全共有、Gouにサングラスなし）、同時Hit時の専用Reaction mapping。新Atlasは512×448、足位置・runtime scale固定。

流れ: 調査→個別原画比較→Atlas/State接続→Stage4描画と3人の受け側・逆方向受け確認→既存回帰→PR/merge/Pages→公開Runtime/配信PCK検証。手操作・ブラウザ・実機の未実施項目を明記する。
