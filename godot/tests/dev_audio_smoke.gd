extends SceneTree


func _initialize() -> void:
	call_deferred("_run_audio_smoke")


func _run_audio_smoke() -> void:
	var audio := get_root().get_node_or_null("AudioManager")
	assert(audio != null)

	for bgm_id in ["title", "battle", "final_boss", "clear", "game_over"]:
		audio.play_bgm(bgm_id)
		assert(audio.current_bgm_id == bgm_id)
		assert(audio.bgm_player != null)
		assert(audio.bgm_player.stream != null)
		await process_frame

	for se_id in [
		"punch_whiff", "kick_whiff", "jump", "land", "dash",
		"guard", "throw", "throw_escape",
		"hit_weak", "hit_strong", "hit_special", "hit_ko",
		"ui_cursor", "ui_confirm", "ui_cancel"
	]:
		audio.play_se(se_id)
		await process_frame

	assert(audio.generated_streams.size() >= 10)
	audio.stop_bgm()
	print("DEV_AUDIO_OK streams=", audio.generated_streams.size())
	await process_frame
	quit()
