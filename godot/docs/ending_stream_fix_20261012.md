# Ending audio memory hardening

Reported again: crash at the ending transition or theme song start. The physical device's termination log is unavailable; this patch addresses an identified memory risk, not a confirmed iOS crash diagnosis.

Music players now explicitly use `AudioServer.PLAYBACK_TYPE_STREAM`. Godot's Web default is Sample playback, which expands compressed music into a browser AudioBuffer. Incremental decoding avoids that whole-song allocation without changing the supplied 215-second song. Cinematic ambience also streams. Ordinary short combat/UI SFX keep their existing playback mode.

Stopped music and unused crossfade slots release their stream references. The true ending replaces the explosion plate with the dawn plate and yields a frame before starting the theme, inside the existing black fade. Normal and true endings use the existing two-frame scene-release transition before entering lightweight credits. Checkpoint writes still precede scene release.

No artwork, character poses, dialogue, credits text, music data, musical position, fade durations, or roll speeds were changed.

Validation uses dedicated APPDATA and browser profiles, never the player's saves. `true_ending_check`, `theme_music_check`, `stage8_ending_check` (all seven routes), and `ending_credits_recovery_check` passed. The browser regression additionally intercepts `BaseAudioContext.createBuffer` and rejects allocations longer than 30 seconds; the 215-second theme must never be expanded that way. Full-song and Web checks are recorded separately in the worktree evidence directory.

Browser touch viewport testing is not physical iPhone Safari/home-screen validation.

Final local validation: `theme_full_ending_check` passed through natural song completion (`elapsed=228.241` wall seconds including runtime scheduling). Fresh Edge contexts at 1280x720 and 844x390 both passed real attacks against a private one-HP True Seiya checkpoint, all 12 film/credits beats, explicit tap back to the title, and IndexedDB `true_ending_unlocked=true`. Both recorded `longAudioBuffers: []`. Dawn and returned-title screenshots were inspected. The legacy harness label `TRUE_ENDING_PUBLIC_WEB_OK index` refers to the local `127.0.0.1` build in these runs; it is not deployed evidence.

The Web harness was updated to recognize the current lightweight credits completion message. One mobile attempt lost the fighter before the boss KO; a fresh retry completed successfully. No physical-phone crash log or deployed verification was obtained. GitHub push was rejected by automatic approval review because external upload was not explicitly authorized; local commits and the Web build remain ready for publication approval.
