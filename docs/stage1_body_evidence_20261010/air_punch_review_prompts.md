# 空中パンチ修正の採用プロンプト

実行: built-in image_gen。正式Idleを身体寸法・デザインの基準とした。元の空中パンチを姿勢参照にした最初の候補は胴体が圧縮されたため不採用。

## 採用候補の作成

Pose edit from ONE immutable official Akky Idle input. Create 4 equal horizontal sprite cells showing air punch. Preserve exact original slender anatomical proportions and style. CRITICAL geometric ratio: neck-to-belt torso length must be about 1.5 TIMES top-of-hair-to-chin head length, as in master. Do not compress torso into chibi while tucking legs. Keep small head, narrow shoulders, long slim torso, full-length upper/lower arms and thighs/shins. Tan open jacket with zips, black high-neck shirt belt baggy black pants boots, black hair and face identical to master. Frame 1 airborne, knees flexed and drawn up below belt, fists guard. Frame 2 partial straight right punch, left fist guards. Frame 3 fully extended straight right punch. Frame 4 retract to same guard as frame 1. Body upright to slightly leaning forward; knees can tuck but pelvis remains below belt, body never enlarged. Each head and torso exactly same physical length and drawing scale in all frames. Transparent RGBA, exactly4 cells horizontal, plenty of margins for punch reach, all full figures, no reference idle extra, no shadows, no fragments, no text.

## 胴体長の修正

Targeted anatomy edit of first image only, the four airborne punch frames. Second is official idle master. Preserve every head and hair EXACT same size, facial identity, shoulder width, pose ordering, straight punch arms, leg segment lengths and clothing. Increase neck-to-belt torso length by 15 percent in ALL FOUR frames: lengthen the black shirt and jacket between chest and belt, move pelvis/tucked legs down accordingly, keep neck/head and shoulders at same locations. This corrects compressed torso versus official idle. Do NOT rescale entire figure, do NOT grow head, do NOT widen body, do NOT lengthen arms/legs. Maintain transparent four equal horizontal cells, full bodies and sufficient margins, no labels or fragments.

最終素材: godot/assets/characters/player01/animations/body_consistent_air_v1/punch_source.png。生成出力を加工せずコピーし、Godotで切り出し・透明余白・素材単位換算を設定した。
