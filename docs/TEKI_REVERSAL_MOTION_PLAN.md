# Stage 3 Teki motion plan (before implementation)

対象: enemy_07_tricky、テキ・ファイター。最新公開ab0264cを基準。
185 Motion FrameをGodotで抽出。damage High/Low/Lightは同じFrame30、Heavy/Knockbackは30/31、Downは32、Getupは32/33/22/0、KOは31/32。Specialはface_grab_hold 37/38流用。

重点調査: 通常hit/air/down/getup/KO/grabbed/thrown、Akky/Gou/Seiya各Special反応、左右反転、足位置、当たり判定と見た目、KO/着地のState接続。
Before evidence: evidence/teki_audit/metrics.json とaudit_page_01〜03.jpg。Idle body area13825。通常Hit0.832、Down0.632、Gou/Seiya Hit0.780、Down0.663。姿勢差による高さ変化とキャラクター縮小は別に扱う。

新規Special設計: デッドリーハンドをGuard可能な掌打と爪状の短いTrailにする。掴み拘束演出にせず、接触で相手攻撃を止め、Horizontal Knockbackへ移行。
Anticipation(重心を下げ、後ろの手を開く) → Coil(掌を腰へ引く) → Startup(踏み込み) → Palm strike → Claw follow-through → Retract → Recovery → Ready。
8個別Frame。攻撃判定を掌と接触位置へ合わせ、顔・衣装をEffectで隠さない。
Damage通常主力×1.5=11。既存MAX Gauge消費・Cooldown4.2・短いStartup無敵0.10・HitStun受付を維持。Guard Chipは既存15%=2、Recovery0.55、Whiff0.6875。

被ダメージ修正: 新しいDown原画を最初にIdleと比較。既存の被弾／Special受けFrameはデザインが保たれるものだけ体格補正し、安全な共有を継続。通常HighとLowの同一表現、Getupへのサイズ接続も確認。新規Canvasは512×448、runtime scale/pivot固定。
Specialを受ける主人公3人は、既存の専用Special Reaction/Guardが掌打のHorizontal Knockbackに適合するか実画面で確認し、安全に共有できる場合だけ使用する。

Motion inventory: docs/SPECIAL_HANDOFF_INVENTORY_20261003.md のTekiと主人公項目、および今回Godot抽出のframes.jsonを併用。P/方向P/K/方向K/Air/Throw/方向Throw/Comboは既存実装を維持。
完成まで: 主要Key Pose → 個別制作 → 原画比較 → Atlas → Godot描画検証 → 回帰 → commit/PR/merge → Pages公開確認。
