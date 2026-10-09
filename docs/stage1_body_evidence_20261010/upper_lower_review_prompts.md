# 上段・下段被弾の採用素材プロンプト

実行: built-in image_gen。両画像とも正式Idleを唯一のデザイン参照兼編集元とした。元の太い被弾素材を参照する候補は不採用。出力PNGは加工せずゲームフォルダへコピーし、Godotが共通キャンバスへ配置する。

## 上段

Identity-preserve sprite pose edit. Input is immutable official Akky idle master. Derive exactly three UPPER HIT REACTION frames of THIS same slender small-headed figure. Frame 1 slight backward lean, chin tilts upward, hands recoil loosely raised near chest. Frame 2 stronger backward lean, same anatomical proportions, feet planted and knees flexed. Frame 3 recovering toward frame 1. Match official master hair silhouette, face, narrow shoulders, neck-to-belt torso length, limb lengths, head size, tan open jacket black shirt belt loose black pants dark boots, painted game sprite style. Do not use bulky cartoon anatomy. All frames same physical drawing scale; leaning lowers projected height naturally. Transparent RGBA horizontal row of exactly three equal cells, feet aligned on common baseline, ample margins, no extra idle, no text, FX, shadows or fragments. Preserve design faithfully, change only pose.

保存: godot/assets/characters/player01/animations/body_consistent_hit_v1/high_source.png

## 下段

Identity-preserve sprite pose edit. The single input is official Akky master. Derive a three frame LOW HIT REACTION sprite sheet from THIS exact small-headed slender figure. Preserve original identity, hair, tan open jacket, black high neck shirt, belt, loose black pants, dark boots, painted game sprite style and anatomy. Do not make head, shoulders or torso larger. Frame 1: mild forward bend after abdomen impact, right hand guarding lower abdomen, left hand beside thigh, knees partly bent. Frame 2: slightly deeper bend, same hand positions. Frame 3: recovering toward frame 1 pose. Faces point right/down. Keep identical head size, neck-to-belt torso length and limb lengths across all 3; body bend should lower projected height, do not compensate by enlarging. One horizontal row with 3 equal cells on transparent RGBA, feet at common baseline, no additional figure, no FX, no labels. The idle master anatomical dimensions are mandatory. Thin shoulders, slim torso, small head. Preserve full body and natural lower hit reaction.

保存: godot/assets/characters/player01/animations/body_consistent_hit_v1/low_source.png
