# built-in image_gen production prompts

Reference: existing player Seiya (blond shaggy hair, youthful male face, white long-sleeve collared shirt, dark belt, tan trousers, white sneakers). Preserve exact identity, pixel rendering and anatomical proportions. One isolated full-body pose per call, actual transparent alpha, generous padding, no effects, no shadows, no text, no sheet/panels.

- startup: low athletic crouch facing RIGHT, torso slightly back, fists near torso, preparation for an in-place backward somersault.
- kick: upright torso facing RIGHT, striking leg extended front/upward about55degrees, other leg nearly straight down, arms balancing. Intended to rotate through the backward flip in engine.
- inverted original: upside down, head bottom, hips and shoes above; originally striking leg upper RIGHT. Superseded by selected mirrored edit.
- inverted_approved: exact whole-character horizontal mirror of original upside-down pose. Extended leg UPPER LEFT and bent leg UPPER RIGHT; head/face/hands also mirror. Preserve other details. This is the final image explicitly selected by user's attachment user_approved_inverted.jpg.
- return: late backward somersault, head upper RIGHT, shoes lower LEFT, knees lightly bent and arms out, preparing landing.
- finish: facing RIGHT, both shoes on floor, knees softly bent, torso upright, recovery after flip.

A later leg-only redraw was rejected and is not used. No further image generation or pose change after the final attachment. Packing calibrates each selected pose to the actual size-corrected idle frame2 using opaque anatomical body area; it does not change actor scale.
