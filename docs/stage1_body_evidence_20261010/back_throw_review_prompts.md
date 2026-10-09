# 後方投げ採用素材のプロンプト

実行: built-in image_gen。正式Idleを唯一の基本デザイン・身体比率の基準として編集した。

## 3姿勢の作成

Pose edit of official Akky sprite. The SINGLE input is immutable official Idle master: preserve face/hair, small head, slender shoulders, neck-to-belt torso length, upper/lower arm and leg lengths, tan jacket black shirt belt loose black pants dark boots and painted game style. Produce exactly THREE equal horizontal cells on transparent RGBA, same physical anatomy drawing units in all frames. BACK THROW sequence: frame 1 facing RIGHT, knees flexed with moderately wide stable stance, two fists up near chest/face preparing grapple. Frame 2 torso turns LEFT/back, face looking LEFT, both hands extend together toward LEFT in a backward throw release, weight rotates across bent legs, no opponent drawn. Frame 3 facing LEFT, retract to guard with both fists raised and stable spread stance. Preserve natural body twist and stance but do NOT increase shoulders/torso/head width. Neck-to-belt length about 1.5 times top-of-hair-to-chin head length as master. No muscle bulk, no caricature head. Feet on common baseline, full figures with enough room for leftward arms, no cropped hands, shadows, FX, text, labels, no extra idle or fragments. Same drawing scale in every cell. This is correction to master anatomy, not a redesign.

## 胴体長の修正と放出時の顔向き保持

Targeted anatomical correction to the first three-frame back-throw sheet, using second official idle as immutable reference. Preserve every head/hair/face size exactly, shoulder width, arm/leg segment lengths, original 3 poses and leftward throwing arms, clothing and transparent cells. In ALL THREE frames lengthen neck-to-belt torso by 22 percent to match master: extend black shirt/jacket vertically through middle torso, move pelvis and legs down accordingly, leave neck and shoulders fixed. Do not scale whole figure, do not widen torso, do not enlarge head or limbs. Frame2 head looking right over shoulder while arms throw LEFT must stay as currently drawn; frame3 face LEFT. Keep feet on common baseline and full bodies within transparent margins. Exactly three equal cells, no extra objects or text.

最終素材: godot/assets/characters/player01/animations/body_consistent_throw_v1/back_source.png。生成出力を加工せずコピーし、Godotで切り出し・透明余白・素材単位換算を設定した。
