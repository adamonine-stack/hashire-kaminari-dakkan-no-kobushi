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

var shake_timer := 0.0
var shake_strength := 0.0
var camera_start_position := Vector2.ZERO
var player_combo_hide_timer := 0.0
var enemy_combo_hide_timer := 0.0
var player_combo_tween: Tween
var enemy_combo_tween: Tween

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
		target.connect("screen_shake_requested", Callable(self, "_on_screen_shake_requested"))


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
