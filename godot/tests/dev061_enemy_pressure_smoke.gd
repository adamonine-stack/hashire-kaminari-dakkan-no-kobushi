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

	# Stage 5 Shadow Boxer keeps the existing art/motion pipeline but gains
	# a distinct out-boxer decision profile: long range, feints, reactive
	# backsteps, guard counters and punch-heavy rapid combinations.
	var shadow = load("res://data/enemies/enemy_02_speed.tres")
	assert(shadow != null)
	assert(String(shadow.fighter_id) == "enemy_02_shadow_boxer")
	assert(is_equal_approx(float(shadow.character_height_cm), 190.0))
	assert(shadow.motion_atlas == null)
	assert(shadow.sprite_sheet != null)
	assert(shadow.backstep_speed_multiplier >= 1.85)
	assert(shadow.attack_speed_scale >= 1.20)
	assert(shadow.ai_profile.can_feint)
	assert(shadow.ai_profile.can_backstep)
	assert(shadow.ai_profile.can_combo)
	assert(shadow.ai_profile.feint_rate >= 0.20)
	assert(shadow.ai_profile.counter_attack_rate >= 0.65)
	assert(shadow.ai_profile.guard_counter_rate >= 0.80)
	assert(shadow.ai_profile.reactive_backstep_rate >= 0.60)
	assert(shadow.ai_profile.combo_rate >= 0.55)
	assert(shadow.ai_profile.punch_weight >= 0.70)
	assert(shadow.ai_profile.jump_punch_weight > shadow.ai_profile.jump_kick_weight)
	assert(shadow.ai_profile.preferred_distance > shadow.ai_profile.attack_distance)
	assert(shadow.ai_profile.retreat_speed_multiplier > shadow.ai_profile.approach_speed_multiplier)

	print("DEV061_ENEMY_PRESSURE_OK profiles=", PROFILE_PATHS.size())
	quit()
