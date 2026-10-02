extends SceneTree

var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	seed(5305)
	# Explicit types keep this regression compatible with Godot 4.7 strict inference.
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame

	var manager: Variant = battle.get_node("BattleManager")
	var enemy: Variant = battle.get_node("Enemy")
	var definition: Resource = load("res://data/enemies/enemy_02_speed.tres")
	var stage: Resource = load("res://data/stages/stage_05_shadow.tres")

	check(definition != null, "Shadow Boxer definition loads")
	check(stage != null, "Stage 5 definition loads")
	check(manager.STAGE_DEFINITIONS.size() == 9, "campaign keeps nine stage definitions")
	check(manager.enemy_team.size() == 8, "published campaign exposes all eight implemented opponents")
	check(manager.enemy_order.size() == 8, "published enemy order exposes eight implemented opponents")
	check(manager.enemy_order[4] == &"enemy_02_shadow_boxer", "fifth published opponent is Shadow Boxer")
	check(manager.STAGE_DEFINITIONS[4].stage_number == 5, "Shadow Boxer remains Stage 5")
	check(manager.STAGE_DEFINITIONS[4].enemy_definition.fighter_id == &"enemy_02_shadow_boxer", "Stage 5 points to Shadow Boxer")
	check(stage.enemy_definition.fighter_id == &"enemy_02_shadow_boxer", "Stage 5 resource points to Shadow Boxer")

	# Regression for the published progression bug: after the first four opponents
	# are defeated, the next opponent must be Stage 5 instead of ending the run.
	for index in range(4):
		manager.enemy_team[index]["is_defeated"] = true
		manager.enemy_team[index]["current_health"] = 0
	manager.current_enemy_index = 3
	check(manager.get_next_enemy_index() == 4, "Stage 4 clear advances to Stage 5")
	check(manager._stage_definition_for_enemy_index(4).stage_number == 5, "Stage 5 definition resolves after Stage 4")

	check(definition.motion_atlas != null and definition.motion_atlas.texture.get_size() == Vector2(2560,2048), "Stage 5 uses the measured complete-pose atlas")
	check(definition.sprite_sheet != null, "existing Shadow Boxer sprite sheet remains assigned")
	check(is_equal_approx(float(definition.character_height_cm), 190.0), "reference height is 190 cm")
	check(float(definition.backstep_speed_multiplier) >= 1.85, "Shadow Boxer has fast evasive backstep")
	check(float(definition.attack_speed_scale) >= 1.20, "Shadow Boxer keeps fast hands")
	check(int(definition.speed_rating) == 5, "speed identity remains maximum")

	enemy.apply_fighter_definition(definition)
	check(enemy.fighter_definition.fighter_id == &"enemy_02_shadow_boxer", "runtime applies Shadow Boxer definition")
	check(enemy.ai_profile == definition.ai_profile, "runtime applies Shadow Boxer AI profile")
	check(enemy.character_visual_controller.get_debug_source() == "motion_atlas", "runtime uses the measured authored atlas")
	check(is_equal_approx(enemy.move_speed, 335.0), "runtime move speed is preserved")
	check(enemy.backstep_speed_multiplier >= 1.85, "runtime backstep speed is strengthened")

	var sprite: AnimatedSprite2D = enemy.animated_character_sprite
	for clip in ["idle", "walk", "dash", "backstep", "jump", "punch", "kick", "guard", "damage", "down", "getup", "ko"]:
		check(sprite.sprite_frames.has_animation(clip), "existing action clip: " + clip)
	check(not sprite.sprite_frames.get_animation_loop("ko"), "KO animation does not loop")

	var profile: Resource = definition.ai_profile
	check(bool(profile.get("can_feint")), "feint is enabled")
	check(bool(profile.get("can_backstep")), "backstep AI is enabled")
	check(bool(profile.get("can_combo")), "combo AI is enabled")
	check(float(profile.get("feint_rate")) >= 0.20, "feint selection rate is meaningful")
	check(float(profile.get("counter_attack_rate")) >= 0.65, "counter focus is strong")
	check(float(profile.get("guard_counter_rate")) >= 0.80, "guard counter is emphasized")
	check(float(profile.get("reactive_backstep_rate")) >= 0.60, "reactive backstep is emphasized")
	check(float(profile.get("combo_rate")) >= 0.55, "rapid combinations are enabled")
	check(float(profile.get("punch_weight")) >= 0.70, "jab and punch selection dominates")
	check(float(profile.get("jump_punch_weight")) > float(profile.get("jump_kick_weight")), "air attack favors boxing action")
	check(float(profile.get("preferred_distance")) > float(profile.get("attack_distance")), "AI maintains outside-boxing distance")
	check(float(profile.get("retreat_speed_multiplier")) > float(profile.get("approach_speed_multiplier")), "retreat movement is sharper than approach")
	check(float(profile.get("reaction_time_max")) <= 0.24, "reaction timing is fast")
	check(float(profile.get("attack_cooldown_max")) <= 0.32, "attack gaps stay short")

	var original_feint_rate := float(profile.get("feint_rate"))
	profile.set("feint_rate", 1.0)
	enemy.ai_feint_cooldown_timer = 0.0
	check(enemy.should_use_feint(), "runtime AI can select feint")
	profile.set("feint_rate", original_feint_rate)

	battle.queue_free()
	await process_frame
	print("STAGE5_SHADOW_BOXER_REGRESSION failures=", failures)
	quit(0 if failures.is_empty() else 1)
