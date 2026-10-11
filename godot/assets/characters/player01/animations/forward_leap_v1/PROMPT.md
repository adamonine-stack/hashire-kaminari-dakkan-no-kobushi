# Akky low forward jumping punch

Built-in image generation, using the existing body_consistent_air_v1 character reference. Preserve Akky's face, black hair, tan jacket, black turtleneck, black trousers and boots.

Motion: low forward leap with both boots airborne, shoulder and hip rotation, horizontal straight punch, front knee tucked and rear leg trailing. Eight poses: neutral, loaded takeoff, airborne windup, punch extension, full commitment, follow-through, landing, recovery. No overhead windup or downward punch, and no grounded standing punch during airborne frames.

The transparent generated source is kept unchanged. Alpha-connected silhouettes are measured instead of assuming equal source cells. The runtime packs all poses into 320 by 224 cells with one uniform source scale based on neutral body height; no per-pose fitting or scaling.
