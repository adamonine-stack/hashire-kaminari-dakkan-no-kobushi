extends Control

## Autonomous film: all gameplay input is consumed, including pause and touch.
signal beat_started(beat: String)
const CAST_SCALE := preload("res://scripts/ui/ending_cast_scale.gd")
const CREDITS := preload("res://scripts/ui/ending_credits.gd")
const ART := "res://assets/endings/true/"
const PLAYER := preload("res://scenes/Player.tscn")
const HEROES := [preload("res://data/fighters/ally_balance.tres"), preload("res://data/fighters/ally_power.tres"), preload("res://data/fighters/ally_speed.tres")]
const LINES := ["……俺の負けだ。", "ブラックスパロウは……大きくなりすぎた。", "ここで終わらせる。", "行け。", "セイヤ……！", "早く行け。", "あれだ！"]
var stage := ""
var history: Array[String] = []
var spoken: Array[String] = []
var content: Control
var shot: Control
var backdrop: TextureRect
var cast: Node2D
var seiya: Node2D
var akky: Node2D
var dialogue: Panel
var speaker: Label
var words: Label
var veil: ColorRect
var flash: ColorRect
var warning: ColorRect
var title_card: Label
var switch_light: Polygon2D
var switch_lever: Polygon2D
var effects: Node2D
var shot_tween: Tween
var sound_players: Dictionary = {}
var clock := 0.0
var shaking := 0.0
var explosion := false
var alarm := false
var timing_scale := 1.0 # Set before entering tree by QA only; normal playback is real time.
var auto_return := true
var theme_completed := false
const AURA := preload("res://assets/effects/special_v1/aura.png")

func _ready() -> void:
	get_tree().paused = false
	_build()
	_layout()
	get_viewport().size_changed.connect(_layout)
	get_node("/root/AudioManager").music_finished.connect(_on_music_finished)
	get_node("/root/AudioManager").fade_out()
	_run()

func _input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()

func _on_music_finished(music_id: String) -> void:
	if music_id == get_node("/root/AudioManager").THEME_ID:
		theme_completed = true

func _exit_tree() -> void:
	for player in sound_players.values():
		player.stop()
		player.stream = null
	sound_players.clear()

func _process(delta: float) -> void:
	clock += delta
	if alarm: warning.color.a = (sin(clock * 8.0) + 1.0) * 0.07
	if shaking > 0.0:
		shaking = maxf(0.0, shaking - delta)
		var settings := get_node("/root/SettingsManager")
		var strength := 0.0 if settings.screen_shake_mode == "OFF" else (3.0 if settings.screen_shake_mode == "LIGHT" else 8.0)
		shot.position = Vector2(sin(clock * 63.0), cos(clock * 79.0)) * strength * minf(shaking, 1.0)
	else: shot.position = Vector2.ZERO
	if explosion:
		for particle in effects.get_children():
			if particle is GPUParticles2D: continue
			particle.position.y -= delta * float(particle.get_meta("rise", 24.0))
			particle.position.x += sin(clock + particle.get_index()) * delta * 10.0

func _beat(value: String) -> void:
	stage = value
	history.append(value)
	beat_started.emit(value)
	print("[TRUE_ENDING] ", value)

func _wait(seconds: float) -> void:
	await get_tree().create_timer(maxf(0.001, seconds * timing_scale)).timeout

func _fade(alpha: float, seconds := 0.8) -> void:
	var tween := create_tween()
	tween.tween_property(veil, "color:a", alpha, maxf(0.001, seconds * timing_scale))
	await tween.finished

func _say(who: String, text: String, seconds: float) -> void:
	spoken.append(text)
	speaker.text = who
	words.text = text
	dialogue.show()
	words.visible_characters = 0
	var tween := create_tween()
	tween.tween_property(words, "visible_characters", text.length(), maxf(0.001, text.length() / 22.0 * timing_scale))
	await _wait(seconds)
	dialogue.hide()

func _run() -> void:
	_beat("defeat")
	var aura := Sprite2D.new()
	aura.texture = AURA
	aura.position = Vector2(0,-100)
	aura.scale = Vector2(0.27,0.43)
	aura.modulate = Color(0.32,0.16,0.50,0.35)
	seiya.add_child(aura)
	var dissipate := create_tween()
	dissipate.tween_property(aura, "modulate:a", 0.0, 2.1 * timing_scale)
	dissipate.tween_callback(aura.queue_free)
	await _fade(0.0, 1.0)
	await _wait(1.5)
	await _say("セイヤ", LINES[0], 3.2)
	await _wait(0.9)
	await _say("セイヤ", LINES[1], 4.5)
	await _wait(0.9)
	await _say("セイヤ", LINES[2], 3.0)
	await _wait(0.7)
	await _say("セイヤ", LINES[3], 2.0)
	await _wait(0.8)
	_beat("departure")
	seiya.visual_root.scale.x = absf(seiya.visual_root.scale.x)
	seiya.character_visual_controller.play_animation(&"walk_forward", true)
	seiya.animated_character_sprite.play()
	var walk := create_tween()
	walk.tween_property(seiya, "position", Vector2(1120, 430), 6.0 * timing_scale)
	walk.parallel().tween_property(seiya, "scale", Vector2(0.64, 0.64), 6.0 * timing_scale)
	walk.parallel().tween_property(seiya, "modulate", Color(0.04, 0.05, 0.09, 0.0), 6.0 * timing_scale).set_delay(1.0 * timing_scale)
	var step := create_tween()
	step.tween_property(akky, "position:x", akky.position.x + 26, 0.6 * timing_scale)
	alarm = true
	_sound("alarm", -18.0)
	await _say("アッキー", LINES[4], 2.4)
	await _wait(0.6)
	await _say("セイヤ", LINES[5], 2.5)
	# Accelerated QA can finish the walk while dialogue timers are running.
	if walk.is_running():
		await walk.finished
	seiya.hide()
	await _fade(1.0)
	cast.hide()
	_beat("switch")
	backdrop.hide()
	_switch_device()
	await _fade(0.0, 0.6)
	await _wait(1.0)
	_sound("click", -2.0)
	switch_lever.rotation = 0.55
	switch_light.color = Color("ff2525")
	await _wait(0.2)
	_sound("alarm", -5.0)
	_sound("rumble", -12.0)
	await _wait(1.5)
	await _fade(1.0, 0.5)
	effects.hide()
	await _cg("escape", 5.5)
	_sound("alarm", -24.0)
	await _cg("pier", 1.3)
	await _say("アッキー", LINES[6], 2.1)
	await _wait(0.6)
	await _fade(1.0)
	alarm = false
	warning.color.a = 0.0
	_stop_sound("alarm")
	_stop_sound("rumble")
	_sound("waves", -15.0)
	_sound("engine", -22.0)
	await _cg("boat", 7.0)
	_beat("detonation")
	# The untouched boat plate holds before light and sound arrive together.
	flash.color.a = 0.95
	_sound("explosion", 0.0)
	shaking = 3.5
	var flare := create_tween()
	flare.tween_property(flash, "color:a", 0.0, 0.7 * timing_scale)
	backdrop.texture = load(ART + "explosion.png")
	effects.show()
	_explosion_effects()
	explosion = true
	await _wait(1.2)
	for i in range(3):
		_sound("explosion", -10.0 - i * 4.0)
		shaking = 0.6
		await _wait(0.85)
	await _wait(4.0)
	var echo := create_tween()
	if sound_players.has("explosion"): echo.tween_property(sound_players["explosion"], "volume_db", -40.0, 3.0 * timing_scale)
	await _wait(3.0)
	await _fade(1.0, 1.8)
	explosion = false
	effects.hide()
	_stop_sound("explosion")
	_stop_sound("engine")
	get_node("/root/AudioManager").play_ending_theme()
	await _cg("dawn", 8.0, true)
	await _fade(1.0, 2.0)
	_stop_sound("waves")
	await _card("BLACK SPARROW", 3.0)
	await _card("TRUE ENDING", 4.0)
	_record_completion()
	_beat("credits")
	await _credits()
	# Preserve the autonomous film and allow the whole song to finish.
	# QA with auto_return=false keeps the existing short sequence.
	var audio := get_node("/root/AudioManager")
	if auto_return and audio.current_bgm_id == audio.THEME_ID:
		title_card.text = "TRUE ENDING"
		title_card.modulate.a = 1.0
		title_card.show()
		# playing can become false a frame before AudioStreamPlayer.finished.
		# Do not start title playback until the old track's signal is delivered.
		while not theme_completed and audio.current_bgm_id == audio.THEME_ID:
			await get_tree().process_frame
	_beat("complete")
	if auto_return: get_tree().change_scene_to_file("res://scenes/Title.tscn")

func _cg(id: String, hold: float, pull_back := false) -> void:
	if veil.color.a < 0.99: await _fade(1.0, 0.7)
	_beat(id)
	backdrop.show()
	backdrop.texture = load(ART + id + ".png")
	if shot_tween != null: shot_tween.kill()
	backdrop.pivot_offset = Vector2(640, 360)
	backdrop.scale = Vector2(1.07, 1.07) if pull_back else Vector2.ONE
	shot_tween = create_tween()
	shot_tween.tween_property(backdrop, "scale", Vector2.ONE if pull_back else Vector2(1.045, 1.045), (hold + 2.0) * timing_scale)
	await _fade(0.0, 1.0)
	await _wait(hold)

func _card(text: String, hold: float) -> void:
	_beat(text)
	title_card.text = text
	title_card.modulate.a = 0.0
	title_card.show()
	var tween := create_tween()
	tween.tween_property(title_card, "modulate:a", 1.0, 1.0 * timing_scale)
	await tween.finished
	await _wait(hold)
	tween = create_tween()
	tween.tween_property(title_card, "modulate:a", 0.0, 1.0 * timing_scale)
	await tween.finished
	title_card.hide()

func _credits() -> void:
	var roll := CREDITS.make_roll(content)
	var tween := create_tween()
	var roll_duration := 30.0 * timing_scale
	var audio := get_node("/root/AudioManager")
	if auto_return and audio.is_music_playing(audio.THEME_ID):
		# Finish scrolling sooner than the theme, leaving a calm end card
		# while the complete song plays before returning to the title.
		var remaining: float = audio.bgm_player.stream.get_length() - audio.bgm_player.get_playback_position()
		roll_duration = maxf(roll_duration, (remaining - 1.0) * CREDITS.TRUE_SONG_REMAINING_SHARE)
	tween.tween_property(roll, "position:y", CREDITS.offscreen_y(roll), roll_duration)
	await tween.finished
	roll.queue_free()
	await _wait(1.0)

func _record_completion() -> void:
	var cfg := ConfigFile.new()
	if FileAccess.file_exists("user://story_progress.cfg"):
		if cfg.load("user://story_progress.cfg") != OK:
			push_error("Cannot safely update story progress")
			return
	cfg.set_value("story", "true_boss_defeated", true)
	cfg.set_value("story", "true_ending_unlocked", true)
	var result := cfg.save("user://story_progress.cfg")
	if result != OK: push_error("Cannot save true ending: %s" % result)

func _sound(id: String, db: float) -> void:
	var player: AudioStreamPlayer
	if sound_players.has(id): player = sound_players[id]
	else:
		player = AudioStreamPlayer.new()
		player.bus = &"SFX"
		player.stream = load(ART + id + ".wav")
		add_child(player)
		sound_players[id] = player
	player.volume_db = db + linear_to_db(maxf(get_node("/root/AudioManager").se_volume, 0.00001))
	player.play()

func _stop_sound(id: String) -> void:
	if sound_players.has(id): sound_players[id].stop()

func _build() -> void:
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	content = Control.new()
	content.size = Vector2(1280, 720)
	add_child(content)
	shot = Control.new()
	content.add_child(shot)
	backdrop = TextureRect.new()
	backdrop.texture = load("res://assets/backgrounds/stage_08_hideout_boss_room.webp")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.size = Vector2(1280, 720)
	shot.add_child(backdrop)
	cast = Node2D.new()
	shot.add_child(cast)
	for i in range(3):
		var actor = PLAYER.instantiate()
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		actor.collision_layer = 0
		actor.collision_mask = 0
		cast.add_child(actor)
		actor.apply_fighter_definition(HEROES[i])
		actor.input_enabled = false
		actor.ai_enabled = false
		actor.is_round_active = false
		actor.position = [Vector2(390, 530), Vector2(190, 530), Vector2(920, 530)][i]
		actor.character_visual_controller.play_animation(&"damage" if i == 2 else &"idle", true)
		actor.animated_character_sprite.stop()
		if i == 2:
			seiya = actor
			seiya.visual_root.scale.x = -absf(seiya.visual_root.scale.x)
		else:
			if i == 0: akky = actor
	var reference_height := CAST_SCALE.hero_height(akky)
	for item in [["mio", 290.0, CAST_SCALE.MIO_HEIGHT_RATIO], ["ren", 500.0, CAST_SCALE.REN_HEIGHT_RATIO]]:
		var sprite := Sprite2D.new()
		sprite.name = String(item[0])
		sprite.texture = load("res://assets/characters/rescued/" + item[0] + ".png")
		CAST_SCALE.fit_rescued(sprite, reference_height, float(item[2]))
		sprite.position = Vector2(item[1], 530)
		cast.add_child(sprite)
	effects = Node2D.new()
	shot.add_child(effects)
	warning = _rect(Color(1, 0.02, 0.02, 0), 0)
	dialogue = Panel.new()
	dialogue.position = Vector2(55, 570)
	dialogue.size = Vector2(1170, 122)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.01, 0.015, 0.03, 0.94)
	style.border_color = Color("bd9c68")
	style.set_border_width_all(1)
	dialogue.add_theme_stylebox_override("panel", style)
	content.add_child(dialogue)
	speaker = _label("", Vector2(20, 8), Vector2(1100, 36), 24, dialogue)
	speaker.add_theme_color_override("font_color", Color("ebc994"))
	words = _label("", Vector2(20, 51), Vector2(1100, 60), 28, dialogue)
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.hide()
	flash = _rect(Color(1, 0.94, 0.8, 0), 8)
	veil = _rect(Color.BLACK, 10)
	title_card = _label("", Vector2(80, 295), Vector2(1120, 130), 52)
	title_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_card.z_index = 12
	title_card.hide()

func _rect(color: Color, depth: int) -> ColorRect:
	var rect := ColorRect.new()
	rect.size = Vector2(1280, 720)
	rect.color = color
	rect.z_index = depth
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(rect)
	return rect

func _label(text: String, pos: Vector2, extent: Vector2, font_size: int, parent: Node = null) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = extent
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(content if parent == null else parent).add_child(label)
	return label

func _polygon(points: PackedVector2Array, color: Color, parent: Node) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	parent.add_child(polygon)
	return polygon

func _switch_device() -> void:
	_polygon(PackedVector2Array([Vector2(370,180),Vector2(910,180),Vector2(910,540),Vector2(370,540)]), Color("1c242e"), effects)
	_polygon(PackedVector2Array([Vector2(385,195),Vector2(895,195),Vector2(895,525),Vector2(385,525)]), Color("313c47"), effects)
	for y in range(230,500,18):
		_polygon(PackedVector2Array([Vector2(405,y),Vector2(475,y),Vector2(475,y+5),Vector2(405,y+5)]), Color("111820"), effects)
	for x in range(515,705,24):
		_polygon(PackedVector2Array([Vector2(x,480),Vector2(x+12,480),Vector2(x+24,505),Vector2(x+12,505)]), Color("aa843c"), effects)
	for x in [400,880]:
		for y in [210,510]:
			var bolt := Polygon2D.new()
			bolt.polygon = _circle(8)
			bolt.position = Vector2(x,y)
			bolt.color = Color("7a818b")
			effects.add_child(bolt)
	switch_light = _polygon(_circle(22), Color("300d10"), effects)
	switch_light.position = Vector2(775,275)
	_polygon(_circle(72), Color("10131a"), effects).position = Vector2(610,370)
	switch_lever = _polygon(PackedVector2Array([Vector2(-16,-90),Vector2(16,-90),Vector2(16,30),Vector2(-16,30)]), Color("9a2026"), effects)
	switch_lever.position = Vector2(610,370)
	# Face and body stay off-screen; movement of the device plus click implies agency.

func _circle(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(32): points.append(Vector2.from_angle(i * TAU / 32.0) * radius)
	return points

func _explosion_effects() -> void:
	for child in effects.get_children(): child.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = 90817
	# Fire columns animate independently of the CG in the distant base only.
	for i in range(5):
		var flame := Sprite2D.new()
		flame.texture = AURA
		flame.position = Vector2(925 + i * 55, 160)
		flame.modulate = Color(1,0.55,0.16,0.30)
		flame.scale = Vector2(0.13,0.22)
		effects.add_child(flame)
		flame.set_meta("rise", 0.0)
		var flicker := create_tween().set_loops()
		flicker.tween_property(flame, "scale", Vector2(0.11,0.28), 0.23 + i * 0.04)
		flicker.tween_property(flame, "scale", Vector2(0.15,0.19), 0.30)
	var smoke_shader := Shader.new()
	smoke_shader.code = "shader_type canvas_item; void fragment(){ float d=length(UV-vec2(0.5)); float a=1.0-smoothstep(0.06,0.5,d); COLOR=vec4(0.10,0.09,0.12,a*0.11); }"
	for i in range(16):
		var smoke := ColorRect.new()
		smoke.size = Vector2(110,95)
		var smoke_material := ShaderMaterial.new()
		smoke_material.shader = smoke_shader
		smoke.material = smoke_material
		effects.add_child(smoke)
		smoke.position = Vector2(rng.randf_range(890,1160),rng.randf_range(-30,130))
		smoke.set_meta("rise", rng.randf_range(12,30))
	var embers := GPUParticles2D.new()
	embers.position = Vector2(1060,210)
	embers.amount = 130
	embers.lifetime = 4.0
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0,-1,0)
	material.spread = 55
	material.initial_velocity_min = 35
	material.initial_velocity_max = 110
	material.gravity = Vector3(0,-12,0)
	material.color = Color("ffab45")
	embers.process_material = material
	embers.visibility_rect = Rect2(-700,-500,1400,1000)
	effects.add_child(embers)
	embers.emitting = true

func _layout() -> void:
	var size_now := get_viewport_rect().size
	var factor := minf(size_now.x / 1280.0, size_now.y / 720.0)
	content.scale = Vector2.ONE * factor
	content.position = (size_now - Vector2(1280,720) * factor) * 0.5
