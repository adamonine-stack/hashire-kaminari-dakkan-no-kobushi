extends "res://tests/special_reversal_check.gd"

var captures := 0
var output := ""

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().save_png(output.path_join(label + ".png")) == OK, "capture " + label)
	captures += 1

func check_active_effect(actor: Node, label: String) -> void:
	var seen := false
	for effect in actor.get_children():
		if effect.get_script() == load("res://scripts/combat/reversal_effect.gd") and effect.phase == "active":
			seen = true
			check(effect.to_global(effect.contact_point).distance_to(actor.special_area.global_position) < 0.01,label + " active effect follows real hitbox including facing")
	check(seen,label + " active effect exists")


func reset_pair() -> void:
	super.reset_pair()
	# Controlled poses pause actor clocks; clear previous cases' effects so
	# hitstop from a paused actor cannot stack old auras into the next case.
	for node in root.find_children("*", "Node2D", true, false):
		if node.get_script() == load("res://scripts/combat/reversal_effect.gd"):
			node.queue_free()


func run() -> void:
	output = ProjectSettings.globalize_path("res://").path_join("../evidence/handoff_grapple_guard").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	manager = battle.get_node("BattleManager")
	manager._hide_player_selection()
	manager._set_battle_active(true)
	paused = false
	player = battle.get_node("Player")
	enemy = battle.get_node("Enemy")
	player.apply_character_data(load("res://data/fighters/ally_balance.tres"))
	for i in range(5): await physics_frame
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	for attack_definition in ["enemy_05_power", "enemy_07_tricky"]:
		player.apply_character_data(load("res://data/enemies/%s.tres" % attack_definition))
		for victim_definition in ["ally_balance", "ally_power", "ally_speed"]:
			enemy.apply_character_data(load("res://data/fighters/%s.tres" % victim_definition))
			for direction in [1, -1]:
				reset_pair()
				player.position = Vector2(640 - 65 * direction,520)
				enemy.position = Vector2(640,520)
				player.facing_direction = direction
				enemy.facing_direction = -direction
				player._set_visual_facing()
				enemy._set_visual_facing()
				var label := "%s_%s_%s" % [attack_definition,victim_definition,direction]
				player.start_character_special()
				for i in range(10): await process_frame
				player.enter_character_special_active()
				check_active_effect(player,label)
				player.reversal_elapsed = 0.20
				enemy.is_guarding = true
				enemy.guard_type = "high"
				var packet: Dictionary = player._get_character_special_attack_dictionary()
				var before: int = enemy.current_hp
				player._on_character_special_hitbox_area_entered(enemy.get_node("HurtBox"))
				await process_frame
				check(enemy.current_hp == before - enemy._get_guard_damage_from_attack_data(packet), label + " authored guard chip")
				check(enemy.is_guard_hit and not enemy.is_throw_locked, label + " real contact guards instead of grabbing")
				check(not player._is_throw_busy() and player.reversal_connected, label + " blocked special stays in special recovery path")
				enemy._update_visual_state()
				await capture(label + "_guard")
				player.enter_character_special_recovery()
				check(is_equal_approx(player.character_special_timer,player.character_special_data.recovery_time), label + " guard has full authored recovery")
				reset_pair()
				player.position = Vector2(640 - 65 * direction,520)
				enemy.position = Vector2(640,520)
				player.facing_direction = direction
				enemy.facing_direction = -direction
				player.start_character_special()
				for i in range(10): await process_frame
				player.enter_character_special_active()
				enemy.request_punch_attack()
				player._on_character_special_hitbox_area_entered(enemy.get_node("HurtBox"))
				check(enemy.is_throw_locked and enemy.current_attack_type.is_empty(), label + " hit interrupts current attack into authored grapple")
				check(enemy.pending_throw_damage == packet.damage, label + " special uses 1.5x damage not ordinary throw")
				await capture(label + "_held")
				before = enemy.current_hp
				player._release_throw()
				check(enemy.current_hp == maxi(0,before-int(packet.damage)), label + " release applies special damage once")
				player._release_throw()
				check(enemy.current_hp == maxi(0,before-int(packet.damage)), label + " no duplicate release damage")
				enemy._update_visual_state()
				await capture(label + "_released")
				# A normal throw still ignores guard and uses its own damage value.
				reset_pair()
				player.position.x = 575
				enemy.position.x = 640
				player.facing_direction = 1
				enemy.facing_direction = -1
				enemy.is_guarding = true
				enemy.guard_type = "high"
				player._start_throw()
				player._connect_throw(enemy)
				check(enemy.is_throw_locked and enemy.pending_throw_damage == player.throw_damage,label + " ordinary throw retains guard-breaking damage")
	print("SPECIAL_GRAPPLE_GUARD_CHECK cases=12 captures=%d failures=%s" % [captures,failures])
	for audio in root.find_children("*", "AudioStreamPlayer", true, false): audio.stop()
	for audio in root.find_children("*", "AudioStreamPlayer2D", true, false): audio.stop()
	OS.delay_msec(200)
	battle.queue_free()
	await process_frame
	OS.delay_msec(200)
	quit(0 if failures.is_empty() else 1)
