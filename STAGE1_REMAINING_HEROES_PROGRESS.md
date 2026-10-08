# Stage 1 ごう・せいや: 基礎接続 (2026-10-07)

開始 branch: codex/stage1-gou-seiya-20261007
開始 HEAD: 06785831898406ebe71c45233b784339c6c97d1e
開始 git status --short: 空。公開済み AKKY/Crusher を含む HEAD から隔離。

## 実装
両者に Forward P / Forward K / Down K / Air P / Air K を登録。
150ms の既存入力バッファと facing-relative 解析を共用。
通常 P からヒット確認で Forward P / 次 P / K、Forward P から K / Forward K、Air P から Air K。
空振りキャンセルと Air K→Air P のループは禁止。Down K はダウン用途。
ごうは発生・硬直を重め、せいやは発生・硬直を短め、前進 K の移動距離を長め。
Stage 1 HP / 基礎威力 / 固有 Special / 保存形式 / 公開版は変更なし。

## 全対象モーションの棚卸し（両者）
既存流用: 通常P/K, Forward P/K, Down K, Air P/K,
通常Throw/掴み/解放, 軽/重/高/低Hit, Knockback, Knockdown, 起き上がり, KO。
既存専用: ごう Iron Breaker reversal startup/attack/finish,
せいや Somersault startup/attack/finish、Crusher必殺技受け、既存キャラ別Special受け。
新規制作/比較が必要: Back P, Down P launcher, Back K, Down Air K,
方向Throw 3種の攻撃/受け同期, Air Guard/Guard Hit,
Launch/Air Hit, Ground Bounce/Wall Hit, 独立した強Guard反応。
上記新規制作項目は今回未接続。別人のSpriteを代用しない。
各制作は公式立ち姿との頭/体格/衣装/四肢/足元比較から開始する。

## 検証境界
stage1_remaining_heroes_check: 両向き、方向解放後120ms→攻撃、Startup/Recovery HitBox無効、左右HitBox、Sprite倍率不変、Air P→Kのhit-confirm/whiff拒否/逆ループ拒否。
既存ごう Reversal / せいや Somersault 回帰: failures=[]。
Stage 1 実描画の接触ポーズ保存: audit_evidence/stage1_heroes。
スマホ実機・公開Web版での新技操作は未確認。新規専用素材完成/全戦闘確認/公開は後続工程。
初回importのフォントキャッシュ生成前エラーとsafe-saveエラーあり。実行ログの結果と区別する。
