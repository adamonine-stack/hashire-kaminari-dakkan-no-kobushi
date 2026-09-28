# 第4ステージ：クロス・ムラサメ

第3ステージのテキ撃破後にクロスへ進み、撃破すると `STAGE 4 CLEAR` を表示。
既存の `enemy_05_cross_murasame` IDを維持し、シャドウは未公開の第5枠へ移動。
味方の能力値、残HP台帳、交代、回復、セーブの形式は変更しない。

## 通常攻撃と受け側

- パンチ連携：引き手崩し → 背負い崩し → 腕ひねり。
- キック連携：大外崩し → 払腰崩し → 関節崩し。途中でパンチ系へ分岐可能。
- 通常攻撃は従来の打撃判定、ガード、空振り、コンボ補正を使う。拘束や投げ抜けを発生させない。
- 味方3人に引き崩し、肩から投げられる姿勢、足払いによる崩れ、腕関節の4種類を新規追加。
  通常ヒット、コンボ最終段ダウン、実際の投げの保持／放出を区別し、既存の着地・起き上がりにつなぐ。
- 本来の投げは背負い、大外、払腰、内股、袖、回転の6種を順番に使用。
  単発ダメージ、投げ抜け、再掴み防止を維持。無影連投はゲージを消費して回転投げへ接続。

## 素材

組み込みImageGenで新規制作。添付の設定画は外見と動作の参照にのみ使用。
黒い前髪、黒いジャケットと赤い袖タグ、背中の「無影」、黒いジーンズ、チェーン、編上げブーツを保持。
クロス56ポーズ／121クリップ、3072×2016アトラス。全身同一倍率で配置し、アルファの連結成分を分離。
味方は12個の独立した新規反応ポーズと既存着地フレームを補助アトラスに配置。
生成シート末尾の接触している候補2列は採用せず、元の着地素材を維持。
元素材は `.gdignore` 配下に保存し、ゲーム配信への不要な混入を防止。

ビルド：`node tools/build_cross_motion_atlas.cjs` と `node tools/build_cross_reactions.cjs`（Sharp）。
ゲーム素材：`godot/assets/characters/enemy05/animations/cross_v1/`、各味方の `animations/cross_reactions/`。

## 検証

- `stage4_regression.gd`：実際の攻撃判定で4ステージ進行、クリア、リトライ、ID、左右の攻撃位相、通常連携、6投げ、脱出、必殺ゲージ。
- `cross_reactions.gd`：味方3人×左右×6通常技の被弾／ガード／空振り、6投げの保持／放出／復帰。
- `cross_visual_review.gd`：121クリップの全フレームと左右の攻撃判定を描画保存。
- 既存Stage 1～3、味方3人のアトラス、敵空中技、ガード、日本語フォントの回帰。
- 自動描画は手動プレイとは区別。公開版の確認結果はリリース後に追記。

## 生成プロンプト

Tool: built-in ImageGen. Base and additional sheets referenced the supplied 写真1.jpg.

Base: Original 6×6 transparent fighting sprite sheet, Cross Murasame adult Japanese male,
185 cm lean, five-head proportions, heavy black bowl fringe completely covers eyes,
black bomber leather jacket with red sleeve zipper, black shirt, charcoal jeans,
silver hip chain, combat boots, bare hands. Right-facing, isolated full-body poses:
ready/breathing/walk (6); dash/jump/landing (6); punch/chop/elbow (6);
spinning kick/knee/flying knee/sweep (6); guard/crouch/grab/pull/hip/shoulder throw (6);
hurt/airborne/KO/get-up/victory/low throwing ready (6). No text, opponents or page crops.

Additional: 5×4 transparent full-body sheet with the same identity and uniform scale.
Reach, pull, hip pivot with 無影, shoulder throw, outer reap; hip sweep, sleeve lift,
tomoe, side pin, armbar; triangle, ankle lock, rotation, wrist restraint, choke;
special ready, dash grab, spin, aerial grab, breakfall. Invisible opponent; no effects or labels.

Allies: 6×3 reaction sheet, rows reference Akky (tan jacket/black trousers/boots),
Gou (white tank/black trousers/sandals), Seiya (white shirt/khaki trousers/white sneakers).
Columns: pulled forward, upside-down shoulder throw, reaped backward, kneeling wrist pain,
armbar victim, lying landing. Preserve identity, uniform scale, right-facing, transparent,
no attacker. Background extraction pass requested alpha-zero space and unchanged figures.
