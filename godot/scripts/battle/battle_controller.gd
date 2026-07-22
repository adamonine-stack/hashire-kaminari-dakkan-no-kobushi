extends Node2D

@export var shake_duration := 0.12
@export var combo_display_duration := 0.80
@export var show_combo_labels := false
@export var camera_base_zoom := 1.10
@export var camera_min_zoom := 0.86
@export var camera_max_zoom := 1.16
@export var camera_zoom_in_distance := 260.0
@export var camera_zoom_out_distance := 720.0
@export var camera_follow_smoothing := 5.5
@export var camera_zoom_smoothing := 4.5
@export var camera_edge_margin := 64.0
@export var stage_width := 1280.0
@export var enable_damage_numbers := true
@export var damage_number_lifetime := 0.62
@export var damage_number_rise := 34.0
@export var max_damage_number_pool := 14

var shake_timer := 0.0
var shake_strength := 0.0
var camera_start_position := Vector2.ZERO
var player_combo_hide_timer := 0.0
var enemy_combo_hide_timer := 0.0
var player_combo_tween: Tween
var enemy_combo_tween: Tween
var feedback_layer: Node2D
var damage_number_pool: Array[Label] = []
var damage_number_tweens: Dictionary = {}
var damage_number_sequence := 0

@onready var player := $Player
@onready var enemy := $Enemy
@onready var camera := $BattleCamera
@onready var battle_ui_root := $UI/BattleUIRoot
@onready var player_hp_bar := $UI/BattleUIRoot/PlayerHpBar
@onready var enemy_hp_bar := $UI/BattleUIRoot/EnemyHpBar
@onready var player_combo_label := _create_combo_label("PlayerComboLabel", Vector2(330.0, 150.0))
@onready var enemy_combo_label := _create_combo_label("EnemyComboLabel", Vector2(760.0, 150.0))


func _ready() -> void:
	camera.make_current()
	camera_start_position = camera.position
	camera.zoom = Vector2.ONE * camera_base_zoom
	_setup_feedback_layer()
	_connect_player_health(player, true)
	_connect_combo(player, true)

	if enemy != null:
		_connect_player_health(enemy, false)
		_connect_combo(enemy, false)


func _process(delta: float) -> void:
	_update_combo_label_visibility(delta)
	_update_dynamic_camera(delta)

	var shake_offset := Vector2.ZERO
	if shake_timer > 0.0:
		shake_timer = maxf(shake_timer - delta, 0.0)
		shake_offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	camera.offset = shake_offset


func _connect_player_health(target: Node, is_player_bar: bool) -> void:
	if not target.has_signal("hp_changed"):
		return

	if is_player_bar:
		target.connect("hp_changed", Callable(self, "_on_player_hp_changed"))
		_on_player_hp_changed(target.get("current_hp"), target.get("max_hp"))
	else:
		target.connect("hp_changed", Callable(self, "_on_enemy_hp_changed"))
		_on_enemy_hp_changed(target.get("current_hp"), target.get("max_hp"))

	if target.has_signal("screen_shake_requested"):
		var shake_callable := Callable(self, "_on_screen_shake_requested")
		if not target.is_connected("screen_shake_requested", shake_callable):
			target.connect("screen_shake_requested", shake_callable)
	if target.has_signal("damage_feedback_requested"):
		var damage_callable := Callable(self, "_on_damage_feedback_requested")
		if not target.is_connected("damage_feedback_requested", damage_callable):
			target.connect("damage_feedback_requested", damage_callable)


func _connect_combo(target: Node, is_player_combo: bool) -> void:
	if not target.has_signal("combo_changed"):
		return

	target.connect("combo_changed", Callable(self, "_on_combo_changed").bind(is_player_combo))


func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
	_update_hp_bar(player_hp_bar, current_hp, max_hp)


func _on_enemy_hp_changed(current_hp: int, max_hp: int) -> void:
	_update_hp_bar(enemy_hp_bar, current_hp, max_hp)


func _update_hp_bar(bar: ProgressBar, current_hp: int, max_hp: int) -> void:
	bar.max_value = max_hp
	bar.value = current_hp


func _on_screen_shake_requested(strength: float) -> void:
	shake_strength = maxf(shake_strength, strength * _screen_shake_multiplier())
	shake_timer = shake_duration


func _setup_feedback_layer() -> void:
	if feedback_layer != null:
		return
	feedback_layer = Node2D.new()
	feedback_layer.name = "CombatFeedbackLayer"
	feedback_layer.z_index = 80
	add_child(feedback_layer)


func _on_damage_feedback_requested(target: Node, amount: int, guarded: bool, hit_position: Vector2) -> void:
	if not enable_damage_numbers:
		return
	var value := maxi(amount, 0)
	if value <= 0 and not guarded:
		return
	var label := _take_damage_number_label()
	var origin := hit_position
	if origin == Vector2.ZERO and target != null:
		origin = target.global_position + Vector2(0.0, -92.0)
	label.text = "GUARD" if guarded and value <= 0 else ("%d" % value)
	if guarded and value > 0:
		label.text = "GUARD -%d" % value
	label.modulate = Color(0.78, 0.92, 1.0, 1.0) if guarded else Color(1.0, 0.94, 0.56, 1.0)
	label.scale = Vector2(0.92, 0.92) if guarded else Vector2.ONE
	label.global_position = origin + Vector2(-34.0 + float(damage_number_sequence % 3) * 12.0, -110.0 - float(damage_number_sequence % 2) * 10.0)
	label.visible = true
	damage_number_sequence += 1
	var tween := label.create_tween()
	damage_number_tweens[label] = tween
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(label, "global_position", label.global_position + Vector2(0.0, -damage_number_rise), damage_number_lifetime)
	tween.parallel().tween_property(label, "modulate:a", 0.0, damage_number_lifetime)
	tween.tween_callback(_recycle_damage_number_label.bind(label))


func _take_damage_number_label() -> Label:
	for label in damage_number_pool:
		if label != null and is_instance_valid(label) and not label.visible:
			_stop_damage_number_tween(label)
			return label
	if damage_number_pool.size() >= max_damage_number_pool:
		var recycled := damage_number_pool[damage_number_sequence % damage_number_pool.size()]
		if recycled != null and is_instance_valid(recycled):
			_stop_damage_number_tween(recycled)
			recycled.visible = false
			recycled.modulate.a = 1.0
			return recycled
	var label := Label.new()
	label.name = "DamageNumber"
	label.visible = false
	label.size = Vector2(96.0, 36.0)
	label.pivot_offset = Vector2(48.0, 18.0)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_outline_color", Color(0.04, 0.035, 0.03, 0.92))
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_layer.add_child(label)
	damage_number_pool.append(label)
	return label


func _recycle_damage_number_label(label: Label) -> void:
	if label == null or not is_instance_valid(label):
		return
	damage_number_tweens.erase(label)
	label.visible = false
	label.modulate.a = 1.0


func _stop_damage_number_tween(label: Label) -> void:
	if not damage_number_tweens.has(label):
		return
	var tween: Tween = damage_number_tweens[label]
	if tween != null and tween.is_valid():
		tween.kill()
	damage_number_tweens.erase(label)


func _create_combo_label(label_name: String, label_position: Vector2) -> Label:
	var label := Label.new()
	label.name = label_name
	label.visible = false
	label.position = label_position
	label.size = Vector2(240.0, 54.0)
	label.pivot_offset = Vector2(120.0, 27.0)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.2, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	battle_ui_root.add_child(label)
	return label


func _on_combo_changed(combo_count: int, combo_owner: Node, is_player_combo: bool) -> void:
	if not show_combo_labels:
		player_combo_label.visible = false
		enemy_combo_label.visible = false
		return
	var label := player_combo_label if is_player_combo else enemy_combo_label
	if combo_count < 2:
		if label.visible:
			if is_player_combo:
				player_combo_hide_timer = combo_display_duration
			else:
				enemy_combo_hide_timer = combo_display_duration
		return

	label.text = "%d HIT\n%s" % [combo_count, _combo_rank_text(combo_count)]
	label.visible = true
	label.scale = Vector2(1.22, 1.22)
	if is_player_combo:
		player_combo_hide_timer = 0.0
		if player_combo_tween != null:
			player_combo_tween.kill()
		player_combo_tween = create_tween()
		player_combo_tween.tween_property(label, "scale", Vector2.ONE, 0.12)
	else:
		enemy_combo_hide_timer = 0.0
		if enemy_combo_tween != null:
			enemy_combo_tween.kill()
		enemy_combo_tween = create_tween()
		enemy_combo_tween.tween_property(label, "scale", Vector2.ONE, 0.12)


func _update_combo_label_visibility(delta: float) -> void:
	if player_combo_hide_timer > 0.0:
		player_combo_hide_timer = maxf(player_combo_hide_timer - delta, 0.0)
		if player_combo_hide_timer == 0.0:
			player_combo_label.visible = false

	if enemy_combo_hide_timer > 0.0:
		enemy_combo_hide_timer = maxf(enemy_combo_hide_timer - delta, 0.0)
		if enemy_combo_hide_timer == 0.0:
			enemy_combo_label.visible = false


func _combo_rank_text(combo_count: int) -> String:
	if combo_count >= 7:
		return "EXCELLENT"
	if combo_count >= 4:
		return "GREAT"
	return "GOOD"


func _screen_shake_multiplier() -> float:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and settings.has_method("get_screen_shake_multiplier"):
		return float(settings.call("get_screen_shake_multiplier"))
	return 1.0


func _update_dynamic_camera(delta: float) -> void:
	if camera == null or player == null or enemy == null:
		return
	var player_pos: Vector2 = player.global_position
	var enemy_pos: Vector2 = enemy.global_position
	var midpoint := (player_pos + enemy_pos) * 0.5
	var distance := absf(player_pos.x - enemy_pos.x)
	var zoom_t := inverse_lerp(camera_zoom_in_distance, camera_zoom_out_distance, distance)
	zoom_t = clampf(zoom_t, 0.0, 1.0)
	var target_zoom := lerpf(camera_max_zoom, camera_min_zoom, zoom_t)
	target_zoom = clampf(target_zoom, camera_min_zoom, camera_max_zoom)
	var viewport_width := get_viewport_rect().size.x
	var half_width := viewport_width * 0.5 / maxf(target_zoom, 0.01)
	var min_x := half_width - camera_edge_margin
	var max_x := stage_width - half_width + camera_edge_margin
	var target_x := midpoint.x
	if min_x < max_x:
		target_x = clampf(target_x, min_x, max_x)
	var target_position := Vector2(target_x, camera_start_position.y)
	var follow_weight := 1.0 - exp(-camera_follow_smoothing * delta)
	var zoom_weight := 1.0 - exp(-camera_zoom_smoothing * delta)
	camera.position = camera.position.lerp(target_position, follow_weight)
	camera.zoom = camera.zoom.lerp(Vector2.ONE * target_zoom, zoom_weight)
