extends Node2D

@export var shake_duration := 0.12

var shake_timer := 0.0
var shake_strength := 0.0
var camera_start_position := Vector2.ZERO

@onready var player := $Player
@onready var camera := $BattleCamera
@onready var player_hp_bar := $UI/BattleUIRoot/PlayerHpBar
@onready var enemy_hp_bar := $UI/BattleUIRoot/EnemyHpBar


func _ready() -> void:
	camera.make_current()
	camera_start_position = camera.position
	_connect_player_health(player, true)

	var enemy := get_node_or_null("Enemy")
	if enemy != null:
		_connect_player_health(enemy, false)


func _process(delta: float) -> void:
	if shake_timer <= 0.0:
		camera.position = camera_start_position
		return

	shake_timer = maxf(shake_timer - delta, 0.0)
	camera.position = camera_start_position + Vector2(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength)
	)


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


func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
	_update_hp_bar(player_hp_bar, current_hp, max_hp)


func _on_enemy_hp_changed(current_hp: int, max_hp: int) -> void:
	_update_hp_bar(enemy_hp_bar, current_hp, max_hp)


func _update_hp_bar(bar: ProgressBar, current_hp: int, max_hp: int) -> void:
	bar.max_value = max_hp
	bar.value = current_hp


func _on_screen_shake_requested(strength: float) -> void:
	shake_strength = maxf(shake_strength, strength)
	shake_timer = shake_duration
