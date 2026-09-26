extends SceneTree

var failures: Array[String] = []
var battle: Node
var manager: Node
var player: Node
var enemy: Node

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame

func _initialize() -> void:
	call_deferred("run")

func defeat_with_punches() -> void:
	enemy.ai_enabled = false
	enemy.set_physics_process(true)
	for attempt in range(35):
		if not manager.isRoundActive:
			return
		player.position = Vector2(560, 520)
		enemy.position = Vector2(660, 520)
		enemy.is_invincible = false
		enemy.hurt_box.monitorable = true
		player.facing_direction = 1
		player.request_attack_input(&"Punch")
		await ticks(70)

func run() -> void:
	seed(26)
	battle = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	manager = battle.get_node("BattleManager")
	player = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	check(manager.enemy_team.size() == 2, "shipped campaign has two stages")
	check(manager.validate_enemy_definitions(), "all eight roster IDs and orders remain valid")
	check(manager.enemy_order[1] == &"enemy_04_rei_kageyama", "Rei occupies stage 2")
	for entry in manager.player_team:
		manager.select_order_character(String(entry.fighter_id))
	manager.confirm_player_order()
	for i in range(480):
		await physics_frame
		if manager.isRoundActive:
			break
	check(manager.isRoundActive, "stage 1 starts")
	await defeat_with_punches()
	for i in range(900):
		await physics_frame
		if manager.current_enemy_index == 1 and manager.isRoundActive:
			break
	check(manager.current_enemy_index == 1 and manager.isRoundActive, "Crusher KO transitions to Rei through real hitboxes")
	check(not manager.isBattleFinished, "stage 1 no longer prematurely clears campaign")
	check(enemy.fighter_definition.fighter_id == &"enemy_04_rei_kageyama", "active fighter is Rei")
	check(enemy.character_visual_controller.get_debug_source() == "motion_atlas", "Rei uses authored atlas")
	check(float(enemy.ai_profile.get("aggression_rate")) >= 0.85, "Rei Stage 2 aggression is raised")
	check(float(enemy.ai_profile.get("sweep_rate")) >= 0.20, "Rei Stage 2 can choose low sweep")
	check(float(enemy.ai_profile.get("attack_cooldown_max")) <= 0.40, "Rei Stage 2 attack cooldown is shortened")
	check(float(enemy.ai_profile.get("idle_time_max")) <= 0.30, "Rei Stage 2 idle gap is shortened")
	var sprite: AnimatedSprite2D = enemy.animated_character_sprite
	for clip in ["idle", "walk", "walk_backward", "dash", "jump_start", "jump_air", "jump_fall", "jump_land", "guard", "crouch_guard", "damage_high", "knockdown", "ko", "getup", "throw", "jump_kick", "jump_punch_down", "special_startup", "special_attack"]:
		check(sprite.sprite_frames.has_animation(clip), "authored clip: " + clip)
	check(not sprite.sprite_frames.get_animation_loop("ko"), "KO does not loop")
	check(sprite.sprite_frames.get_frame_count("walk") == 4, "walk contains four authored phases")
	check(sprite.sprite_frames.get_frame_count("punch_1") == 3, "Rei punch has no extra post-attack idle pose")
	check(sprite.sprite_frames.get_frame_count("kick_1") == 3, "Rei kick has no extra post-attack idle pose")
	check(sprite.sprite_frames.get_frame_count("special_recovery") == 1, "Rei special recovery has no extra idle pose")
	var rei_straight: Resource = load("res://data/attacks/rei_straight.tres")
	var rei_roundhouse: Resource = load("res://data/attacks/rei_roundhouse.tres")
	check(rei_straight != null and rei_straight.hitbox_offset == Vector2(92, -145), "Rei straight hitbox stays aligned to the fist")
	check(rei_roundhouse != null and rei_roundhouse.hitbox_offset == Vector2(105, -135), "Rei roundhouse hitbox stays aligned to the foot")
	enemy.ai_enabled = false
	enemy.set_physics_process(false)
	for side in [-1, 1]:
		enemy.facing_direction = side
		enemy.character_visual_controller.set_facing(side)
		check(sprite.flip_h == (side < 0), "facing mirrors entire atlas")
		for id in ["rei_straight", "rei_uppercut", "rei_roundhouse", "rei_air_kick", "rei_air_punch", "rei_sweep"]:
			enemy.reset_attack_state()
			enemy.start_attack(id)
			check(enemy.current_attack_id == id, "starts authored attack " + id)
			check(not enemy.punch_hitbox_active and not enemy.kick_hitbox_active, "startup has no active collision " + id)
			enemy._sync_attack_visual_phase()
			check(sprite.frame == 0, "startup frame " + id)
			enemy.enter_attack_active()
			enemy._sync_attack_visual_phase()
			check(sprite.frame == 1, "contact frame " + id)
			check(enemy.punch_hitbox_active or enemy.kick_hitbox_active, "contact enables collision " + id)
			enemy.enter_attack_recovery()
			enemy._sync_attack_visual_phase()
			check(sprite.frame == 2, "recovery ends on authored attack recovery frame " + id)
			check(not enemy.punch_hitbox_active and not enemy.kick_hitbox_active, "recovery disables collision " + id)
			enemy.finish_attack()
	enemy.reset_attack_state()
	enemy.ai_enabled = true
	enemy.ai_attack_cooldown_timer = 0.0
	enemy.enter_crouch_sweep()
	check(enemy.current_attack_id == "rei_sweep", "Rei AI can initiate crouch sweep")
	enemy.finish_attack()
	enemy.reset_attack_state()
	enemy.ai_enabled = true
	enemy.set_special_gauge(100)
	check(enemy.request_character_special(true), "Rei can spend gauge on dragon uppercut")
	check(sprite.animation == &"special_startup", "purple charge telegraph")
	enemy.enter_character_special_active()
	check(enemy.character_special_state == enemy.CharacterSpecialState.ACTIVE, "dragon uppercut active")
	enemy.enter_character_special_recovery()
	enemy.finish_character_special()
	check(enemy.special_gauge == 0, "special consumes gauge")
	# A full stage 2 defeat uses the player attack / overlap / HP / KO path too.
	await defeat_with_punches()
	await ticks(240)
	check(manager.flow_state == manager.BattleState.CLEAR, "Rei KO clears campaign")
	check(manager._end_title_label.text == "STAGE 2 CLEAR", "clear presentation reflects both stages")
	check(not manager.battle_hud.result_panel.visible, "no duplicate legacy result")
	manager.restart_current_game()
	for i in range(600):
		await physics_frame
		if manager.isRoundActive and not manager.is_scene_transitioning:
			break
	check(manager.current_enemy_index == 0 and enemy.fighter_definition.fighter_id == &"enemy_01_crusher", "retry restores Crusher")
	check(not enemy.attack_data_by_id.has("rei_straight"), "retry clears Rei-only attack data")
	manager.cleanup_battle_before_transition()
	root.get_node("AudioManager").stop_bgm()
	battle.queue_free()
	await process_frame
	print("STAGE2_REGRESSION failures=", failures)
	quit(0 if failures.is_empty() else 1)