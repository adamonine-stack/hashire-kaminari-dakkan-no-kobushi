extends Node

const SE_POOL_SIZE := 16
const SAMPLE_RATE := 22050
const BGM_GAIN := 0.68

var bgm_volume := 0.80
var se_volume := 0.90
var current_bgm_id := ""
var bgm_player: AudioStreamPlayer
var se_players: Array[AudioStreamPlayer] = []
var se_cursor := 0
var generated_streams: Dictionary = {}
var bgm_duck_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(&"Music")
	_ensure_bus(&"SFX")
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = &"Music"
	add_child(bgm_player)
	for index in range(SE_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SEPlayer%02d" % index
		player.bus = &"SFX"
		add_child(player)
		se_players.append(player)
	_load_settings()


func play_bgm(bgm_id: String) -> void:
	if bgm_id.is_empty() or current_bgm_id == bgm_id:
		return
	current_bgm_id = bgm_id
	bgm_player.stop()
	bgm_player.stream = _stream_for_id(bgm_id, true)
	bgm_player.volume_db = _target_bgm_db()
	bgm_player.play()


func stop_bgm() -> void:
	current_bgm_id = ""
	if bgm_player != null:
		bgm_player.stop()


func fade_bgm(bgm_id: String, duration := 0.35) -> void:
	if bgm_id.is_empty() or current_bgm_id == bgm_id:
		return
	if bgm_player == null or not bgm_player.playing or duration <= 0.05:
		play_bgm(bgm_id)
		return
	var next_id := bgm_id
	var fade_time: float = maxf(duration, 0.10)
	var tween := create_tween()
	tween.tween_property(bgm_player, "volume_db", -36.0, fade_time * 0.45)
	tween.tween_callback(func() -> void:
		current_bgm_id = next_id
		bgm_player.stop()
		bgm_player.stream = _stream_for_id(next_id, true)
		bgm_player.volume_db = -36.0
		bgm_player.play()
	)
	tween.tween_property(bgm_player, "volume_db", _target_bgm_db(), fade_time * 0.55)


func play_se(se_id: String) -> void:
	if se_id.is_empty() or se_players.is_empty():
		return
	var player := se_players[se_cursor]
	se_cursor = (se_cursor + 1) % se_players.size()
	player.stop()
	player.stream = _stream_for_id(se_id, false)
	player.volume_db = _linear_to_db(se_volume) + _se_gain_db(se_id)
	player.play()
	if se_id == "hit_ko":
		_duck_bgm(0.18, 0.34)
	elif se_id == "hit_strong" or se_id == "hit_special":
		_duck_bgm(0.09, 0.58)


func play_ui_se(se_id: String) -> void:
	play_se("ui_%s" % se_id)


func set_bgm_volume(value: float) -> void:
	bgm_volume = clampf(value, 0.0, 1.0)
	if bgm_player != null and (bgm_duck_tween == null or not bgm_duck_tween.is_valid()):
		bgm_player.volume_db = _target_bgm_db()


func set_se_volume(value: float) -> void:
	se_volume = clampf(value, 0.0, 1.0)


func _load_settings() -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return
	set_bgm_volume(float(settings.get("bgm_volume")))
	set_se_volume(float(settings.get("se_volume")))


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(index, bus_name)


func _stream_for_id(sound_id: String, is_bgm: bool) -> AudioStream:
	var key := "%s:%s" % ["bgm" if is_bgm else "se", sound_id]
	if generated_streams.has(key):
		return generated_streams[key]
	var stream: AudioStream = _make_music(sound_id) if is_bgm else _make_sfx(sound_id)
	generated_streams[key] = stream
	return stream


func _make_music(sound_id: String) -> AudioStreamWAV:
	match sound_id:
		"title":
			return _make_music_loop(108.0, 52, [0, 3, 7, 10, 7, 3, 5, 7, 0, 3, 7, 12, 10, 7, 5, 3], 0.74)
		"final_boss":
			return _make_music_loop(142.0, 45, [0, 3, 7, 10, 7, 3, 12, 10, 0, 3, 7, 13, 12, 10, 7, 3], 1.18)
		"clear":
			return _make_music_loop(150.0, 60, [0, 4, 7, 12, 7, 12, 16, 19, 12, 16, 19, 24, 19, 16, 12, 7], 0.88)
		"game_over":
			return _make_music_loop(86.0, 50, [0, -2, -5, -7, -5, -2, 0, -2, -5, -7, -9, -7, -5, -2, -5, -7], 0.64)
		_:
			return _make_music_loop(128.0, 52, [0, 3, 7, 10, 7, 3, 5, 7, 0, 3, 7, 12, 10, 7, 5, 3], 1.0)


func _make_music_loop(bpm: float, root_midi: int, pattern: Array, energy: float) -> AudioStreamWAV:
	var step_duration := 60.0 / bpm / 4.0
	var repeats := 4
	var duration := step_duration * float(pattern.size() * repeats)
	var frame_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var noise_state := 0x12345

	for i in range(frame_count):
		var t := float(i) / float(SAMPLE_RATE)
		var raw_step := int(floor(t / step_duration))
		var step := raw_step % pattern.size()
		var phase := fmod(t, step_duration) / step_duration
		var env := pow(maxf(0.0, 1.0 - phase), 0.55)
		var lead_freq := _midi_to_hz(root_midi + int(pattern[step]))
		var bass_freq := _midi_to_hz(root_midi - 12 + int(pattern[step - (step % 4)]))
		var lead := (1.0 if sin(TAU * lead_freq * t) >= 0.0 else -1.0) * env * 0.075
		var bass := asin(sin(TAU * bass_freq * t)) * (2.0 / PI) * 0.11
		noise_state = int((noise_state * 1103515245 + 12345) & 0x7fffffff)
		var noise := (float(noise_state) / 1073741824.0) - 1.0
		var kick := 0.0
		if step % 8 == 0 or step % 16 == 6:
			var kt := phase * step_duration
			if kt < 0.085:
				kick = sin(TAU * (78.0 - 34.0 * kt / 0.085) * kt) * pow(1.0 - kt / 0.085, 2.2) * 0.17
		var snare := noise * pow(maxf(0.0, 1.0 - phase * 5.0), 2.0) * 0.07 if step % 8 == 4 else 0.0
		var hat := noise * pow(maxf(0.0, 1.0 - phase * 8.0), 3.0) * 0.022 if step % 2 == 0 else 0.0
		var sample := tanh((lead + bass + kick + snare + hat) * energy * 1.25)
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count
	return stream


func _make_sfx(sound_id: String) -> AudioStreamWAV:
	var duration := _sfx_duration(sound_id)
	var frame_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var noise_state := 0x34567

	for i in range(frame_count):
		var t := float(i) / float(SAMPLE_RATE)
		var p := clampf(t / duration, 0.0, 1.0)
		var env := pow(1.0 - p, 2.0)
		noise_state = int((noise_state * 1103515245 + 12345) & 0x7fffffff)
		var noise := (float(noise_state) / 1073741824.0) - 1.0
		var sample := 0.0
		match sound_id:
			"punch_whiff":
				sample = noise * sin(PI * p) * 0.25 + sin(TAU * (430.0 - 180.0 * p) * t) * env * 0.08
			"kick_whiff":
				sample = noise * sin(PI * p) * 0.34 + sin(TAU * (290.0 - 120.0 * p) * t) * env * 0.11
			"jump":
				sample = sin(TAU * (240.0 + 520.0 * p) * t) * env * 0.25
			"land":
				sample = sin(TAU * (95.0 - 40.0 * p) * t) * env * 0.46 + noise * env * 0.09
			"dash":
				sample = noise * sin(PI * p) * 0.31
			"guard":
				sample = sin(TAU * 1180.0 * t) * env * 0.27 + sin(TAU * 1840.0 * t) * env * 0.14 + noise * env * 0.07
			"throw":
				sample = sin(TAU * (120.0 - 55.0 * p) * t) * env * 0.50 + noise * env * 0.10
			"throw_escape":
				sample = sin(TAU * (620.0 + 880.0 * p) * t) * env * 0.28
			"hit_ko":
				sample = sin(TAU * (86.0 - 42.0 * p) * t) * env * 0.62 + noise * env * 0.30 + sin(TAU * 170.0 * t) * env * 0.15
			"hit_strong":
				sample = sin(TAU * (145.0 - 45.0 * p) * t) * env * 0.46 + noise * env * 0.25
			"hit_special":
				sample = sin(TAU * (260.0 + 540.0 * p) * t) * env * 0.29 + sin(TAU * (520.0 - 160.0 * p) * t) * env * 0.20 + noise * env * 0.14
			"hit_weak":
				sample = sin(TAU * (330.0 - 110.0 * p) * t) * env * 0.29 + noise * env * 0.19
			_:
				var frequency := 760.0 if sound_id.begins_with("ui_") else _frequency_for_id(sound_id)
				sample = sin(TAU * frequency * t) * env * 0.22
		data.encode_s16(i * 2, int(clampf(tanh(sample * 1.35), -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


func _sfx_duration(sound_id: String) -> float:
	match sound_id:
		"hit_ko":
			return 0.34
		"hit_strong", "hit_special", "throw":
			return 0.22
		"kick_whiff", "dash":
			return 0.18
		"punch_whiff", "jump", "land", "guard", "throw_escape":
			return 0.14
		_:
			return 0.09


func _midi_to_hz(note: int) -> float:
	return 440.0 * pow(2.0, (float(note) - 69.0) / 12.0)


func _frequency_for_id(sound_id: String) -> float:
	var hash_value: int = abs(int(hash(sound_id)))
	return 240.0 + float(hash_value % 760)


func _duck_bgm(duration: float, ratio: float) -> void:
	if bgm_player == null or not bgm_player.playing:
		return
	if bgm_duck_tween != null and bgm_duck_tween.is_valid():
		bgm_duck_tween.kill()
	var normal_db := _target_bgm_db()
	var duck_db := _linear_to_db(maxf(0.001, bgm_volume * BGM_GAIN * ratio))
	bgm_duck_tween = create_tween()
	bgm_duck_tween.tween_property(bgm_player, "volume_db", duck_db, 0.025)
	bgm_duck_tween.tween_interval(duration)
	bgm_duck_tween.tween_property(bgm_player, "volume_db", normal_db, 0.12)


func _se_gain_db(se_id: String) -> float:
	match se_id:
		"hit_ko":
			return 4.0
		"hit_special":
			return 3.5
		"hit_strong":
			return 3.0
		"throw", "land":
			return 2.0
		"hit_weak", "guard":
			return 1.0
	return 0.0


func _target_bgm_db() -> float:
	return _linear_to_db(bgm_volume * BGM_GAIN)


func _linear_to_db(value: float) -> float:
	if value <= 0.001:
		return -80.0
	return linear_to_db(value)


func _exit_tree() -> void:
	if bgm_duck_tween != null and bgm_duck_tween.is_valid():
		bgm_duck_tween.kill()
	for player in se_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	if is_instance_valid(bgm_player):
		bgm_player.stop()
		bgm_player.stream = null
	generated_streams.clear()
