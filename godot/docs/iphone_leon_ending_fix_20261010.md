# Leon defeat / iPhone home-screen restart fix

Reported: iPhone 13 home-screen launch, all three heroes surviving; defeating Leon returned to the opening. A physical iPhone was unavailable, so the precise iOS process termination cause is not confirmed.

The old rescue scene instantiated three complete combat actors and rebuilt their motion textures for a dialogue needing only idle and guard. The extracted unique texture dimensions total 302,194,688 bytes at RGBA8, compared with 2,342,912 bytes for the six authored dialogue poses (99.22% less). These are image size equivalents, not measurements of total browser memory or actual GPU compression. The PNGs are exported verbatim from the existing controller's first idle/guard frames; the original frame scale and position are recorded in `poses.json`.

Leon clear now releases touch input, performs battle transition cleanup, and stores the survivor snapshot as a Stage8Ending checkpoint in the existing run save. Title Continue restores that scene after a browser/PWA restart. Completing a normal/bad ending clears this checkpoint; starting TRUE battle replaces it with the normal TRUE battle save. Consuming the Continue flag prevents accidentally loading the ending checkpoint as a TRUE combat checkpoint.

Validation:

- `STAGE8_ENDING_CHECK failures=[]`: all seven branches, rescued body proportions, TRUE battle/defeat/retry/win.
- `STAGE8_CHECKPOINT_CHECK failures=[]`: all seven restart routes, exact survivor/health/gauge restoration, preservation of a later TRUE battle save.
- `TRUE_ENDING_CHECK failures=[]`: existing cinematic and dialogue contracts.
- `LEON_ENDING_WEB_OK index`: unchanged local release JS/WASM/PCK, private one-HP Leon checkpoint, real attacks, all-survivor rescue, actual IndexedDB persistence, page reload and Continue, TRUE Seiya combat at 844 x 390. Rescue and TRUE combat screenshots reviewed.
- Normal opening path reported `OPENING_FLOW_OK`; its pre-existing shutdown resource warning remains in that isolated smoke test.

Automated Edge touch viewport evidence is not a physical iPhone Safari/home-screen play test. Software WebGL buffer warnings also occur in the existing combat renderer. The public deployed build is verified separately after Pages completes.

Final visual comparison also preserves Seiya's original head shader using recorded pose-local landmarks and multipliers (idle 0.9; authored guard 1.0). The Akky, Gou and Seiya body regions in the final local rescue screenshot each have no pixel differences against the pre-fix public rescue screenshot. All seven ending routes passed again with this correction.
