# 地面衝突・バウンド採用素材

built-in image_gen使用。生成PNGを変更せず `godot/assets/characters/player01/animations/body_consistent_ground_v1/ground_source.png` へコピーした。採用は2回目の編集結果。正式Idleと既存の地面衝突/バウンド2フレームを入力し、次に候補と正式Idleで部分修正した。

## 初回

Edit two-frame game sprite sheet. Input1 immutable official Akky Idle master anatomy and clothing; Input2 exact two-frame ground impact / ground bounce pose target. Recreate only target's TWO poses in equal horizontal cells, fully transparent background. Frame1 lies/reclines on back with head to LEFT, face looking up/right, arms flexed near chest, both knees folded upward and boots to RIGHT, contacting ground along lower back and trailing boot. Frame2 same body rebounds slightly with knees flexed and boots lifted right, keep natural body rotation. Preserve master small head, face, ponytail, slender shoulders, neck-to-belt torso length, thin jacket sleeves, arm segment lengths and leg lengths, tan short jacket black shirt belt loose black pants and dark boots. Target bulky shoulders/arms/torso should be corrected to official idle build, NOT uniform whole-body shrinking. Anatomical units equal in both frames; body rotates but no head/torso growth. Full figure and enough transparent margin for horizontal limbs, no shadows, backdrop, ground, opponent, debris, glow, labels or extra objects. Keep original motion silhouette and painted pixel sprite aesthetic. Render at source drawing resolution consistent with prior master-referenced sprite strips: a standing figure at these drawing units would be approximately 610 pixels tall; head width about 140pixels. This is two horizontal action poses, not standing sprites.

## 部分修正

Targeted edit of first image TWO ground-impact/bounce poses, official Idle second image anatomy reference. Preserve first image canvas, exact head size/hair/face, torso LENGTH neck-to-belt, all arm and leg segment LENGTHS, hand and boot size, foot and pelvis positions and BOTH poses. Correct only excessive bulk: reduce jacket sleeve/upper-arm thickness by 25 percent in both poses, reduce torso/chest thickness perpendicular to spine by 18 percent. Keep natural loose pants and bend geometry. No uniform full-body scaling, no head resizing, no repositioning, no pose redesign. Match reference slender arms/shoulders/torso. Preserve transparent background, two equal horizontal cells, no shadows, props, ground or detached fragments. Same painted pixel sprite rendering.

上記の数値は画像編集への指示であり、採用画像の実測適合値ではない。身体各部±2%の測定は未確認。
