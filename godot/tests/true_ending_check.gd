extends SceneTree

var failures: Array[String] = []
var rendered := false
var ending
var realtime := false
var evidence_dir := "res://../evidence/true_ending/"

func _initialize() -> void:
	rendered = "--render-ending" in OS.get_cmdline_user_args()
	realtime = "--real-time" in OS.get_cmdline_user_args()
	if "--mobile" in OS.get_cmdline_user_args():
		root.size = Vector2i(844,390)
		evidence_dir = "res://../evidence/true_ending_mobile/"
	if realtime: evidence_dir = "res://../evidence/true_ending_realtime/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence_dir))
	call_deferred("run_check")

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func inspect_beat(beat: String) -> void:
	if beat == "escape":
		for actor in [ending.akky, ending.seiya]:
			check(actor.poses.is_empty(), "cast resources released before CG")
	if beat == "credits":
		check(ending.backdrop.texture == null, "CG released before credits")
		check(ending.effects.get_child_count() == 0, "explosion nodes released before credits")
		for player in ending.sound_players.values():
			check(player.stream == null, "film SFX released before credits")
	if beat == "escape":
		check(not ending.seiya.visible, "Seiya gone before escape")
		check(ending.switch_light.color == Color("ff2525") and ending.switch_lever.rotation > 0.5, "switch actuated and red lamp on")
	if beat == "boat":
		check(not ending.sound_players["alarm"].playing, "alarm ends at sea")
		check(get_root().get_node("AudioManager").current_bgm_id.is_empty(), "sea has no BGM")
		check(ending.sound_players["waves"].playing and ending.sound_players["engine"].playing, "wave and boat ambience at sea")

func capture(beat: String) -> void:
	if not rendered: return
	var delay := 0.38 if beat == "defeat" else (1.6 if beat == "credits" else 0.17)
	if realtime: delay = 3.5 if beat == "defeat" else (4.0 if beat == "credits" else 1.2)
	await create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if not img.is_empty(): img.save_png(evidence_dir + "%s.png" % beat.replace(" ", "_"))

func run_check() -> void:
	if "--mobile" in OS.get_cmdline_user_args():
		root.size = Vector2i(844,390)
		await process_frame
		await process_frame
		check(root.size == Vector2i(844,390), "mobile viewport is 844x390")
	var cfg := ConfigFile.new()
	cfg.set_value("story", "normal_ending_unlocked", true)
	cfg.set_value("story", "last_stage8_route", "G")
	cfg.set_value("custom", "preserve", 73)
	cfg.save("user://story_progress.cfg")
	for asset in ["escape","pier","boat","explosion","dawn"]:
		check(ResourceLoader.exists("res://assets/endings/true/%s.png" % asset), "CG present: " + asset)
	ending = load("res://scenes/TrueEnding.tscn").instantiate()
	ending.timing_scale = 1.0 if realtime else (0.14 if rendered else 0.015)
	ending.auto_return = false
	ending.beat_started.connect(capture)
	ending.beat_started.connect(inspect_beat)
	root.add_child(ending)
	current_scene = ending
	await process_frame
	check(ending.cast.get_child_count() == 5, "four survivors plus Seiya")
	check(not ResourceLoader.has_cached("res://scenes/Player.tscn"), "film does not load combat scene")
	var cast_bytes := 0
	for actor in [ending.akky, ending.cast.get_child(1), ending.seiya]:
		check(not actor is CharacterBody2D, "cast has no combat physics")
		var frames: SpriteFrames = actor.animated_character_sprite.sprite_frames
		for clip in frames.get_animation_names():
			for index in range(frames.get_frame_count(clip)):
				var texture := frames.get_frame_texture(clip, index)
				cast_bytes += texture.get_width() * texture.get_height() * 4
	check(cast_bytes < 4 * 1024 * 1024, "hero cast stays under 4 MiB RGBA")
	check(ending.seiya.animated_character_sprite.sprite_frames.get_frame_count("walk_forward") == 6, "Seiya keeps six authored walking frames")
	for pose in ending.seiya.poses.walk_forward.frames:
		check(pose.has("head"), "walking preserves head transform")
	print("TRUE_ENDING_CAST_RGBA_BYTES ", cast_bytes)
	var hero_height: float = ending.CAST_SCALE.hero_height(ending.akky)
	for item in [["mio", 0.97], ["ren", 1.0]]:
		var rescued: Sprite2D = ending.cast.get_node(String(item[0]))
		var height := rescued.region_rect.size.y * absf(rescued.scale.y)
		check(absf(height / hero_height - float(item[1])) < 0.01, "matching body scale " + String(item[0]))
		check(is_equal_approx(rescued.position.y, ending.akky.position.y), "matching ground " + String(item[0]))

	check(not ending.akky.input_enabled and not ending.seiya.ai_enabled, "cast cannot fight")
	var start: Vector2 = ending.akky.position
	Input.action_press("move_right")
	Input.action_press("pause")
	for i in range(3): await physics_frame
	Input.action_release("move_right")
	Input.action_release("pause")
	check(ending.akky.position == start and not paused, "gameplay and pause input blocked")
	var timeout := Time.get_ticks_msec() + (180000 if realtime else 60000)
	while ending.stage != "complete" and Time.get_ticks_msec() < timeout:
		await process_frame
	check(ending.stage == "complete", "sequence reaches credits completion")
	check(ending.spoken == Array(ending.LINES), "exact seven lines only")
	check(ending.history == ["defeat","departure","switch","escape","pier","boat","detonation","dawn","BLACK SPARROW","TRUE ENDING","credits","complete"], "film beat order")
	check(not ending.seiya.visible, "Seiya disappears before CG")
	cfg.load("user://story_progress.cfg")
	check(cfg.get_value("story", "true_ending_unlocked", false), "true ending saved")
	check(cfg.get_value("story", "normal_ending_unlocked", false) and cfg.get_value("custom", "preserve", 0) == 73, "existing save entries retained")
	ending.queue_free()
	await process_frame
	change_scene_to_file("res://scenes/Title.tscn")
	for i in range(5): await process_frame
	check(current_scene.title_menu.get_child(0).text.contains("TRUE ENDING CLEAR"), "title reflects completion")
	if rendered: await capture("title_complete")
	print("TRUE_ENDING_CHECK failures=%s" % JSON.stringify(failures))
	current_scene.queue_free()
	await process_frame
	await process_frame
	var audio := get_root().get_node("AudioManager")
	audio.stop_bgm()
	audio.bgm_player.stream = null
	for sound in audio.se_players:
		sound.stop()
		sound.stream = null
	await create_timer(0.3).timeout
	# --fixed-fps can finish simulated cleanup before the audio mixer runs.
	OS.delay_msec(250)
	quit(0 if failures.is_empty() else 1)
