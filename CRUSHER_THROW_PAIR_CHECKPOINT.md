# Crusher paired throws: normal and forward checkpoint

Branch: codex/directional-combat-20261003. Parent checkpoint: c4b1e35a885d723eee2b58d16994534cb03f1ed9.

Connected dedicated Crusher grab/hold/release and AKKY held/air receiver art for normal and forward throws. Added optional hold-animation fields with empty defaults to preserve legacy fighter behavior. Kept existing approved AKKY down pose. Forward throw uses the arm correction requested by the user; no per-frame character scale changes.

Selected forward source: exec-10f0bd46-2364-46fe-9865-d0152181cc80.png, produced with built-in imagegen from exec-76c6fd91-8e3f-4cfb-b82c-bb2f06d492a7.png. Prompt: shorten Crusher shoulder-to-fingertip reach approximately 20 percent in both poses, introduce slight elbow bend, preserve anatomy/body/face/costume/AKKY sprites/layout/transparency. Saved to art/dedicated_pair_v1/sources/crusher_throw_forward_strip.png. Normal and grab authoring sources are retained in the same folder outside Godot's exported resources.

Checks: CRUSHER_THROW_MOTION_CHECK failures=[] for both throw directions and facing directions; actual shared physics release/down/get-up/control flow exercised. CRUSHER_THROW_VISUAL_EXPORT_OK; reviewed forward release poses in both facings and the repacked neutral release in rendered 1280x720 game screenshots. Fixed Sprite transform and uncut atlas bounds checked. This is scripted rendering, not hands-on gameplay or physical smartphone testing.

Enemy AI does not yet select the new throw data automatically. Down/back dedicated throw pairs, remaining attack/reaction coverage, and broader scenario validation are still pending; this checkpoint does not complete the two-character motion request. Existing Windows Godot root-certificate warning persists independently of combat scripts.
Regression after connection: THROW_MOTION_SYNC_CHECK failures=[], AIR_COMBO_CHECK failures=[], SPECIAL_REVERSAL_CHECK failures=[]. Full stage/multi-enemy/mobile-device tests were not rerun in this checkpoint.
