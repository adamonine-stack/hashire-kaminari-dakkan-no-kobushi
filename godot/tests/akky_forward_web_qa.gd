extends Node

var root: Node:
	get: return get_tree().root

var failures: Array[String] = []
var rows: Array[Dictionary] = []

func _ready() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(600, 360)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var floor_body := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1400, 40)
	floor_shape.shape = rectangle
	floor_body.add_child(floor_shape)
	floor_body.position = Vector2(300, 340)
	viewport.add_child(floor_body)
	var actor: Node = load("res://scenes/Player.tscn").instantiate()
	viewport.add_child(actor)
	actor.apply_character_data(load("res://data/fighters/ally_balance.tres"))
	actor.ai_enabled = false
	actor.input_enabled = true
	actor.is_round_active = true
	actor.set_physics_process(false)
	for clip in ["akky_diagonal_jump", "akky_diagonal_punch", "akky_diagonal_land"]:
		for frame in range(actor.animated_character_sprite.sprite_frames.get_frame_count(clip)):
			var texture: Texture2D = actor.animated_character_sprite.sprite_frames.get_frame_texture(clip, frame)
			check("forward_leap_v1" in String(texture.get_meta("source_texture_path", "")), "dedicated airborne source " + clip)
	var folder := ProjectSettings.globalize_path("user://akky_forward_qa")
	DirAccess.make_dir_recursive_absolute(folder)
	for facing in [1.0, -1.0]:
		actor.reset_character_special_state(true)
		actor.position = Vector2(300, 320)
		actor.velocity = Vector2(0, 80)
		actor.move_and_slide()
		actor.facing_direction = facing
		actor._set_visual_facing()
		actor.set_special_gauge(actor.max_special_gauge)
		actor.current_hp = actor.max_hp
		actor.reversal_cooldown = 0
		var baseline: Vector2 = actor.animated_character_sprite.scale
		var origin: Vector2 = actor.position
		check(actor.request_character_special(false), "start " + str(facing))
		var peak := origin.y
		var descended := false
		var sheet := Image.create(2400, 720, false, Image.FORMAT_RGBA8)
		sheet.fill(Color(0.12, 0.15, 0.19))
		var sample := 0
		for tick in range(90):
			await get_tree().physics_frame
			actor._physics_process(1.0 / 60.0)
			peak = minf(peak, actor.position.y)
			if actor.character_special_state == actor.CharacterSpecialState.ACTIVE:
				descended = descended or actor.velocity.y > 0
				check(is_equal_approx(actor.special_area.position.y, -57 * actor.battle_visual_scale_multiplier), "forward chest-height hitbox")
			check(actor.animated_character_sprite.scale.is_equal_approx(baseline), "constant scale")
			if tick in [0, 3, 8, 12, 16, 22, 34, 56]:
				await get_tree().process_frame
				RenderingServer.force_draw(false)
				if DisplayServer.get_name() != "headless":
					var img := viewport.get_texture().get_image()
					img.convert(Image.FORMAT_RGBA8)
					check(img.get_used_rect().size != Vector2i.ZERO, "rendered pose")
					sheet.blend_rect(img, Rect2i(0,0,600,360), Vector2i(sample % 4 * 600, sample / 4 * 360))
				rows.append({"facing": facing, "tick": tick, "position": str(actor.position), "velocity": str(actor.velocity), "animation": str(actor.animated_character_sprite.animation), "frame": actor.animated_character_sprite.frame})
				sample += 1
		check(origin.y - peak > 25 and origin.y - peak < 65, "low forward leap height")
		check((actor.position.x - origin.x) * facing > 65, "forward diagonal travel")
		check(descended and actor.character_special_data.special_dive_velocity.y <= 0, "natural fall without downward lunge")
		check(actor.is_on_floor() and not actor.is_character_special_busy(), "land and finish")
		check(actor.velocity.x == 0, "stop on recovery")
		if DisplayServer.get_name() != "headless": sheet.save_png(folder.path_join("right.png" if facing > 0 else "left.png"))
		print("AKKY_DIAGONAL facing=", facing, " height=", origin.y-peak, " travel=", actor.position.x-origin.x)
	# An interrupted leap must release the horizontal motion without teleporting.
	actor.set_special_gauge(actor.max_special_gauge)
	actor.reversal_cooldown = 0
	actor.start_character_special()
	actor.interrupt_character_special()
	check(not actor.is_character_special_busy() and actor.velocity.x == 0, "interrupted movement cleared")
	var target: Node = load("res://scenes/Player.tscn").instantiate()
	target.name = "Enemy"
	viewport.add_child(target)
	target.apply_character_data(load("res://data/enemies/enemy_01_standard.tres"))
	target.set_physics_process(false)
	target.ai_enabled = false
	target.input_enabled = false
	for facing in [1.0, -1.0]:
		for guarded in [false, true]:
			for fighter in [actor, target]:
				fighter.reset_character_special_state(true)
				fighter.reset_knockdown_state()
				fighter._cancel_current_action()
				fighter.is_hit = false
				fighter.is_guard_hit = false
				fighter.is_invincible = false
				fighter.hit_stop_timer = 0
				fighter.current_hp = fighter.max_hp
				fighter.is_round_active = true
				fighter._clear_guard_state()
			actor.position = Vector2(300,320)
			target.position = Vector2(300 + 110 * facing,320)
			for fighter in [actor, target]:
				fighter.velocity = Vector2(0,80)
				fighter.move_and_slide()
			actor.facing_direction = facing
			target.facing_direction = -facing
			target.is_guarding = guarded
			target.guard_type = "high" if guarded else ""
			actor.set_special_gauge(actor.max_special_gauge)
			actor.reversal_cooldown = 0
			var hp: int = target.current_hp
			check(actor.request_character_special(false), "contact case starts")
			for tick in range(65):
				await get_tree().physics_frame
				actor._physics_process(1.0 / 60.0)
			check(actor.reversal_connected, "actual hitbox contact " + str(facing) + str(guarded))
			check(target.current_hp == hp if guarded else target.current_hp < hp, "guard/damage result")
			print("AKKY_CONTACT facing=",facing," guard=",guarded," damage=",hp-target.current_hp)
	var file := FileAccess.open(folder.path_join("trajectory.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(rows, "  "))
	print("AKKY_DIAGONAL_SPECIAL_CHECK failures=", failures)
	viewport.queue_free()
	await get_tree().process_frame
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.akkyForwardQAResult = " + JSON.stringify(failures), true)
	else:
		get_tree().quit(0 if failures.is_empty() else 1)
