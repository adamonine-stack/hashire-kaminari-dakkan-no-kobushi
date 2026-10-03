# Throw contact key production

Official designs: player01/battle.png, enemy01/portrait.png, enemy01/battle.png.
Built-in imagegen, no CLI/API fallback. Review keys in order:
- exec-652f963d-a0ef-4a27-aa4c-df94ee016820: paired contact design reference, not packed (actors touching).
- exec-b450e8ce-af78-4218-bcb1-0d13217535b5: isolated pose separation, upper bandanna touched canvas edge, not packed.
- exec-9b05a2ce-92d3-4415-a155-6821ee206cad: margin repair, selected source contact_key.png.

Prompt constraints: preserve official faces, hair, lean AKKY torso/leg proportions, full beige sleeves/cuffs, tucked black turtleneck with no bare waist, black loose trousers/boots; Crusher red bandanna/scarred face, muscular arms, black tank and olive cargo trousers. Facing/contact poses isolated on transparent canvas, common foot baseline.

Technical packing: pack_directional_throw_keys.gd. Fixed cell/foot anchors; no per-animation runtime rescale. AKKY scale 172/650 with bent-knee height 161px vs standing 171px; Crusher 228/724. Crusher source faces left, flipped to canonical right for runtime facing mirrors. Separate atlas textures and actors. No extra effects/nodes.

This is ONE contact key per actor, not completed four directional-throw animation sets. Startup/release currently reuse old motion. Further keys must be compared against these official designs before adopting intermediate frames.
