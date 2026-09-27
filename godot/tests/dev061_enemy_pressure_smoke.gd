extends SceneTree

const PROFILE_PATHS := [
	"res://data/enemy_ai/enemy_01_standard_ai.tres",
	"res://data/enemy_ai/enemy_02_speed_ai.tres",
	"res://data/enemy_ai/enemy_03_guard_ai.tres",
	"res://data/enemy_ai/enemy_04_throw_ai.tres",
	"res://data/enemy_ai/enemy_05_power_ai.tres",
	"res://data/enemy_ai/enemy_06_combo_ai.tres",
	"res://data/enemy_ai/enemy_07_tricky_ai.tres",
	"res://data/enemy_ai/enemy_08_boss_ai.tres",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for path in PROFILE_PATHS:
		var profile = load(path)
		assert(profile != null)
		assert(profile.aggression_rate >= 0.80)
		assert(profile.pressure_attack_rate >= 0.45)
		assert(profile.post_attack_pressure_rate >= 0.50)
		assert(profile.reaction_time_max <= 0.44)
		assert(profile.idle_time_max <= 0.30)
		assert(profile.attack_cooldown_max <= 0.48)

	var crusher = load("res://data/enemies/enemy_01_standard.tres")
	assert(crusher != null)
	assert(String(crusher.fighter_id) == "enemy_01_crusher")
	assert(String(crusher.fighter_type).to_upper() == "POWER")
	assert(crusher.ai_profile.counter_attack_rate >= 0.75)
	assert(crusher.ai_profile.retreat_rate <= 0.05)

	print("DEV061_ENEMY_PRESSURE_OK profiles=", PROFILE_PATHS.size())
	quit()
