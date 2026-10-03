extends SceneTree

var failures: Array[String] = []
var manager: Node
var player: Node
var enemy: Node
var aura: Node
var output: String

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print("DARK_SEIYA_CHECK ",label," ","PASS" if ok else "FAIL")
	if not ok: failures.append(label)
func ticks(n: int) -> void:
	for i in range(n): await physics_frame
func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func reset_pair() -> void:
	aura.cancel()
	aura.cooldown = 0
	manager.reset_active_fighter_state(player,Vector2(360,520),1.0,player.max_hp)
	manager.reset_active_fighter_state(enemy,Vector2(900,520),-1.0,enemy.max_hp)
	manager._set_battle_active(true)
	enemy.ai_profile = null
	enemy.ai_enabled = false
	enemy.input_enabled = false
	await ticks(5)
func wait_phase(phase: int) -> void:
	for i in range(240):
		if aura.phase == phase: return
		await physics_frame
	check(false,"phase timed out %s" % phase)

func run() -> void:
	DisplayServer.window_set_title("Seiya Final Combat QA")
	output = ProjectSettings.globalize_path("res://../evidence/seiya")
	DirAccess.make_dir_recursive_absolute(output)
	change_scene_to_file("res://scenes/TrueBattle.tscn")
	await create_timer(1.5).timeout
	manager = current_scene.get_node("BattleManager")
	player = manager.player
	enemy = manager.enemy
	aura = enemy.aura_controller
	check(aura != null,"registered final boss component")
	check(enemy.max_hp == 180 and enemy.punch_damage == 18 and enemy.kick_damage == 24,"boss direct stats")
	var hero = load("res://data/fighters/ally_speed.tres")
	check(enemy.fighter_definition.visual_scale_adjustment == hero.visual_scale_adjustment and enemy.fighter_definition.head_scale == hero.head_scale and enemy.fighter_definition.body_width_scale == hero.body_width_scale,"identical hero and boss proportions")
	await reset_pair()
	var hp: int = player.current_hp
	var hits_before: int = aura.actual_hits
	check(aura.start_special(),"special begins")
	check(not aura.strike_area.monitoring,"no hitbox during charge")
	await ticks(4)
	await capture("special_1_charge")
	await wait_phase(aura.Phase.SLAM)
	await capture("special_2_slam")
	await wait_phase(aura.Phase.WARNING)
	await capture("special_3_ground_contact_warning")
	check(player.current_hp == hp,"charge and slam do no remote damage")
	check(not aura.strike_area.monitoring,"warning has no hitbox")
	await wait_phase(aura.Phase.ACTIVE)
	await ticks(3)
	await capture("special_4_pillar_hit")
	await wait_phase(aura.Phase.IDLE)
	check(player.current_hp == hp-26,"one pillar deals exactly 26")
	check(aura.actual_hits == hits_before+1,"one pillar contacts once")
	check(not aura.strike_area.monitoring and aura.strike_shape.disabled,"no lingering hitbox")
	check(not aura.start_special(),"cooldown blocks repetition")
	await capture("special_5_recovered")
	# Fixed snapshot and actual input movement avoidance.
	await reset_pair()
	hp = player.current_hp
	aura.start_special()
	var locked: Vector2 = aura.target_position
	Input.action_press("move_right")
	await ticks(40)
	Input.action_release("move_right")
	check(aura.target_position == locked,"target coordinate remains fixed")
	await wait_phase(aura.Phase.IDLE)
	check(player.current_hp == hp,"walk evades pillar")
	# Jump timed off the visible ground marker. Real gravity and HurtBox.
	await reset_pair()
	hp = player.current_hp
	aura.start_special()
	Input.action_press("jump")
	await ticks(1)
	Input.action_release("jump")
	await wait_phase(aura.Phase.ACTIVE)
	await ticks(3)
	await capture("special_6_jump_evade")
	await wait_phase(aura.Phase.IDLE)
	check(player.current_hp == hp,"jump clears matching 96px pillar")
	# Incoming normal hit cancels startup and pending pillar.
	await reset_pair()
	aura.start_special()
	enemy.receive_attack({"damage":1,"knockback_x":0.0,"knockback_y":0.0,"hitstop_time":0.0,"hitstun_time":0.1,"effect_size":1.0,"attack_type":"punch","se_type":"weak","screen_shake":0.0,"hit_stop_frames":0},1,enemy.global_position,player)
	check(not aura.busy() and aura.strike_shape.disabled,"hit interrupts and cleans special")
	# Distance policy uses the production AI readiness contract.
	await reset_pair()
	enemy.ai_profile = enemy.fighter_definition.ai_profile
	enemy.ai_enabled = true
	check(aura.choose_distance_action(0.016) and aura.busy(),"far AI chooses pillar")
	aura.cancel()
	check(not aura.start_special(),"far AI cannot spam pillar")
	aura.cooldown = 2
	player.position.x = 650
	aura.mid_cooldown = 0
	check(aura.choose_distance_action(0.016) and enemy.current_attack_id == "dark_seiya_kick_finish","mid AI chooses advancing aura kick")
	enemy.finish_attack()
	enemy.ai_profile = null
	enemy.ai_enabled = false
	# Aura reach contacts a real opponent outside hero reach.
	await reset_pair()
	player.position.x = 735
	hp = player.current_hp
	enemy.start_attack("dark_seiya_punch_1")
	await ticks(12)
	await capture("normal_aura_punch")
	await ticks(28)
	check(player.current_hp < hp,"visible extended punch contacts at 165px")
	# Render every required motion with shared original body and fixed scale.
	enemy.set_physics_process(false)
	player.set_physics_process(false)
	for clip in ["idle","walk_forward","dash","jump_start","jump_air","jump_fall","punch_1","punch_2","kick_1","guard","damage_high","ko","aura_charge","aura_charge_max","aura_slam","aura_contact","aura_recovery"]:
		enemy._play_visual_animation(StringName(clip),true)
		var sprite: AnimatedSprite2D = enemy.animated_character_sprite
		sprite.pause()
		var scale_before: Vector2 = sprite.scale
		for frame in range(sprite.sprite_frames.get_frame_count(clip)):
			sprite.set_frame_and_progress(frame,0)
			check(sprite.scale == scale_before,clip+" fixed frame scale")
			await capture("boss_%s_%02d" % [clip,frame])
	print("DARK_SEIYA_COMBAT_CHECK failures=",JSON.stringify(failures))
	manager.cleanup_battle_before_transition()
	current_scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
