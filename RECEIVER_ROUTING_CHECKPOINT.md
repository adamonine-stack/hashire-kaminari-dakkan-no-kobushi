# Receiver routing and dedicated heavy-hit checkpoint

Branch: codex/directional-combat-20261003
Start HEAD: 0ed23f187b984289742b8aab932fb39437e29e94

Resolved prior rendered Seiya-right launch failures: the test awaited two render frames before measuring launch velocity. During slow rendering, several physics ticks could advance the 1800+ wall launch to wall impact, where velocity is correctly zero. The test now holds the victim's physics while deferred real contact resolves, asserts initial impulse, then resumes and verifies the complete flight/wall/fall/down/KO. No Seiya balance or trajectory data changed. Full rendered nine-enemy/both-facing result: SPECIAL_LAUNCH_REACTION_CHECK failures=[] screenshots=139. This is scripted rendered evidence, not hands-on gameplay.

Next phase found a shared routing defect: any attack except low selected damage_high, making middle light/heavy branches unreachable when damage_high existed. Only explicitly high/low attacks now take height-specific clips; middle/unspecified/overhead use existing type/damage/force classification. Explicit move and special receiver mappings retain priority. No damage, hitstun, guard, input, save or stage schema changes.

AKKY and Crusher now have newly authored three-frame damage_heavy sprites: initial torso impact, maximum recoil, return. Key poses were checked against the runtime standing design before strip production. Beige full sleeves/black covered belly/slim AKKY and muscular compact-limbed Crusher retained. Technical packing uses one constant factor per actor and shared foot baseline; no runtime frame scaling. AKKY 320x224 cells/960x224 atlas, Crusher 400x280 cells/1200x280 atlas. Bottom alpha bounds all three frames: AKKY207, Crusher259. Sources live outside Godot under art/dedicated_pair_v1/sources/heavy_hit_key.png and heavy_hit_strip.png. No particles or new effect nodes.

receiver_routing_check tests seven packet cases per actor/facing through actual receive_attack and Sprite selection: light, heavy, high, low, strong knockback, authored launch override, absent override fallback. Heavy clip must have exactly three frames from the dedicated *_heavy_hit.png source. All frames retain Sprite scale and pivot. Rendered captures include every selected frame in both facings.

Existing high/light clips still share source frames in both fighters; AKKY low had shared heavy source until this phase. Strong-hit is now independent; high/low dedicated authoring and remaining full receiver coverage are not declared complete. Phone hardware/manual touch play, public deployment and GPU performance profiling remain untested. Environmental Windows root certificate-store warning persists.

Owned files: player_movement.gd, special_launch_reaction_check.gd, two fighter definitions, PAIR_REACTION_INVENTORY.json; new receiver_routing_check.gd, pack_heavy_hit_pair.gd, two source PNGs and two dedicated atlas PNG/import/tres groups. Inherited unrelated imports/logs/UIDs/user-data are excluded from commit.

Final checks: RECEIVER_ROUTING_CHECK failures=[] in headless and rendered runs; 12 dedicated heavy-hit review frames visually inspected (two actors x three frames x two facings). DEDICATED_SPECIAL_GUARD_CHECK failures=[]; WALL_BOUNCE_CHECK failures=[]; STAGE1_REGRESSION failures=[] after atlas integration. Before atlas integration, directional attacks, air combo and special reversal also passed with the routing fix. No broad tests claimed beyond these logs.
