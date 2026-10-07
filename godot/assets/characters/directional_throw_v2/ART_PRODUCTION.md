# Directional throw release / victim art

AKKY and Crusher only. Official standing designs and the previously reviewed directional_throw_v1 contact keys were references. AKKY retains the beige full-length sleeved jacket, tucked black shirt, black trousers and boots. Crusher retains his red bandanna, black sleeveless shirt and green trousers. No runtime per-frame scale multiplier was introduced.

Each throw was designed and reviewed individually: key pose -> comparison against reference -> proportion correction -> three actor / three victim poses -> full-row comparison -> atlas extraction -> Godot rendered comparison. Contact during HOLD remains the previously reviewed paired contact art; release art starts on the same damage/release event for both actors. These are deliberately short authored clips, not a claim of completed high-frame-count animation.

| Throw | Reviewed key / correction | Selected generated source |
| --- | --- | --- |
| neutral | isolated release keys exec-9030e588-af00-4693-bc3e-728184516c4c | exec-9f09b613-2994-41f5-9345-c64649e3c7c9 |
| forward | first extended rear leg rejected; compact rear leg exec-e7227fe1-2705-41ab-b692-e4d3213fcddb | exec-bd6a0d8c-459d-4d76-a4ec-918795175476 |
| down | half-kneel / braced fall exec-3f93dd10-f95e-4303-af4a-7fb349eb923f; overlapping source row rejected | exec-173bcd04-1560-4df5-afe7-7e3f59325512 |
| back | turned torso key exec-cf7120b8-bd96-4bda-b2fc-4eb26b6a2b44; row overlap and enlarged head corrected | exec-3faf9d3c-0f68-4e1c-94a6-e94c8790b4dc |

Selected sources are preserved in sources/*.png. Generation used imagegen with reference editing, not programmatic drawing or anatomical image warping. Background transparency was checked through alpha values, rather than the preview's hidden RGB background.

packing.json records source row cuts, physical root/ground marks and one uniform source-to-atlas scale for each character's entire three-pose row. It does not fit each pose by its bounding-box height. pack_directional_throw_motion.gd performs rectangular extraction, retains four pixels of antialias padding, uniformly resizes and mirrors Crusher into the canonical facing. It refuses cell overflow instead of shrinking an individual pose.

AKKY cells: 320x224, ground/root (160,208), atlas 960x896. Crusher cells: 400x280, ground/root (200,260), atlas 1200x1120. Four rows: neutral, forward, down, back. Runtime Sprite scale and position stay fixed through all frames. Down/back landing uses the dedicated prone cell; normal/forward keep the existing landing/down art.

Godot review exported startup, contact, all victim release frames and down poses for both facings into throw_motion_evidence. This is controlled rendered review, not manual smartphone play. The combined runtime atlas area is 2,204,160 pixels (approximately 8.8 MB uncompressed RGBA); no new particles or effect nodes. GPU/mobile performance has not been benchmarked.
