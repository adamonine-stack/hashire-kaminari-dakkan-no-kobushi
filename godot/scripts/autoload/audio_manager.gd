extends Node

const SE_POOL_SIZE := 12

var bgm_volume := 0.80
var se_volume := 0.90
var current_bgm_id := ""
var bgm_player: AudioStreamPlayer
var se_players: Array[AudioStreamPlayer] = []
var se_cursor := 0
var generated_streams: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	add_child(bgm_player)
	for index in range(SE_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SEPlayer%02d" % index
		add_child(player)
		se_players.append(player)
	_load_settings()


func play_bgm(bgm_id: String) -> void:
	if bgm_id.is_empty() or current_bgm_id == bgm_id:
		return
	current_bgm_id = bgm_id
	bgm_player.stream = _stream_for_id(bgm_id, true)
	bgm_player.volume_db = _linear_to_db(bgm_volume * 0.62)
	bgm_player.play()


func stop_bgm() -> void:
	current_bgm_id = ""
	if bgm_player != null:
		bgm_player.stop()


func fade_bgm(bgm_id: String, _duration := 0.35) -> void:
	play_bgm(bgm_id)


func play_se(se_id: String) -> void:
	if se_id.is_empty() or se_players.is_empty():
		return
	var player := se_players[se_cursor]
	se_cursor = (se_cursor + 1) % se_players.size()
	player.stop()
	player.stream = _stream_for_id(se_id, false)
	player.volume_db = _linear_to_db(se_volume)
	player.play()


func play_ui_se(se_id: String) -> void:
	play_se("ui_%s" % se_id)


func set_bgm_volume(value: float) -> void:
	bgm_volume = clampf(value, 0.0, 1.0)
	if bgm_player != null:
		bgm_player.volume_db = _linear_to_db(bgm_volume * 0.62)


func set_se_volume(value: float) -> void:
	se_volume = clampf(value, 0.0, 1.0)


func _load_settings() -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return
	set_bgm_volume(float(settings.get("bgm_volume")))
	set_se_volume(float(settings.get("se_volume")))


func _stream_for_id(sound_id: String, is_bgm: bool) -> AudioStream:
	var key := "%s:%s" % ["bgm" if is_bgm else "se", sound_id]
	if generated_streams.has(key):
		return generated_streams[key]
	var frequency := _frequency_for_id(sound_id)
	var duration := 1.2 if is_bgm else 0.12
	var stream := _make_tone(frequency, duration, is_bgm)
	generated_streams[key] = stream
	return stream


func _frequency_for_id(sound_id: String) -> float:
	var hash_value: int = abs(int(hash(sound_id)))
	return 180.0 + float(hash_value % 620)


func _make_tone(frequency: float, duration: float, is_bgm: bool) -> AudioStreamWAV:
	var sample_rate := 22050
	var frame_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	for i in range(frame_count):
		var t := float(i) / float(sample_rate)
		var envelope := 0.38 if is_bgm else maxf(0.0, 1.0 - (t / duration))
		var sample := sin(TAU * frequency * t) * envelope * 0.22
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	if is_bgm:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = frame_count
	return stream


func _linear_to_db(value: float) -> float:
	if value <= 0.001:
		return -80.0
	return linear_to_db(value)
