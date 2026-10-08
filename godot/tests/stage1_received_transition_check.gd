extends SceneTree

var failures: Array[String] = []
var rows: Array[Dictionary] = []

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool, label: String) -> void:
 if not ok:
  failures.append(label)
  push_error(label)

func run() -> void:
 var battle: Node = load("res://scenes/Battle.tscn").instantiate()
 root.add_child(battle)
 current_scene = battle
 await process_frame
 var manager: Node = battle.get_node("BattleManager")
 manager._hide_player_selection()
 manager._set_battle_active(true)
 paused = false
 var actor: Node = battle.get_node("Player")
 var attacker: Node = battle.get_node("Enemy")
 attacker.ai_enabled = false
 attacker.ai_profile = null
 attacker.set_physics_process(false)
 var folder := ProjectSettings.globalize_path("res://../audit_evidence/stage1_received_transitions")
 DirAccess.make_dir_recursive_absolute(folder)
 for entry in [["akky", "fighters/ally_balance"], ["crusher", "enemies/enemy_01_standard"], ["gou", "fighters/ally_power"], ["seiya", "fighters/ally_speed"]]:
  actor.apply_character_data(load("res://data/" + entry[1] + ".tres"))
  for facing in [1.0, -1.0]:
   actor.reset_character_special_state(true)
   actor.reset_knockdown_state()
   actor._cancel_current_action()
   actor.reset_combo()
   actor.reset_attack_state()
   actor.is_hit = false
   actor.is_guard_hit = false
   actor.is_invincible = false
   actor.invincibility_timer = 0.0
   actor.hit_stop_timer = 0.0
   actor.current_hp = actor.max_hp
   actor.is_round_active = true
   actor._clear_guard_state()
   actor.velocity = Vector2.ZERO
   actor.position = Vector2(620, 520)
   attacker.position = Vector2(620 + 400 * facing, 520)
   actor.facing_direction = facing
   actor.input_enabled = true
   actor.set_physics_process(true)
   for tick in range(5): await physics_frame
   var sprite: AnimatedSprite2D = actor.animated_character_sprite
   var scale := sprite.scale
   var origin := sprite.position
   var hp: int = actor.current_hp
   var packet: Dictionary = attacker._get_punch_attack_data().duplicate()
   packet.damage = 1
   packet.hit_reaction = &"damage_heavy"
   packet.causes_knockdown = true
   packet.knockback_x = 160.0
   packet.knockback_y = -180.0
   packet.launch_velocity = Vector2.ZERO
   packet.combo_hit_max = 0
   var label: String = "%s_%s" % [entry[0], "right" if facing > 0 else "left"]
   check(actor.receive_attack(packet, -facing, actor.global_position, attacker), label + " accepts down hit")
   check(actor.current_hp == hp - 1, label + " applies damage once")
   check(sprite.animation == &"knockback", label + " airborne pose selected before hitstop")
   var seen: Dictionary = {}
   var sampled: Dictionary = {}
   var state_ticks: Dictionary = {}
   for tick in range(390):
    await physics_frame
    check(sprite.scale.is_equal_approx(scale), label + " stable scale")
    check(sprite.position.is_equal_approx(origin), label + " stable origin")
    check(sprite.flip_h == (facing < 0), label + " mirrored facing")
    var state := String(actor.knockdown_state)
    if state.is_empty(): state = "RECOVERED"
    seen[state] = true
    state_ticks[state] = int(state_ticks.get(state, 0)) + 1
    var delay := 3 if state == "KNOCKBACK" else (36 if state == "KNOCKDOWN" else 12)
    if int(state_ticks[state]) >= delay and not sampled.has(state):
     sampled[state] = true
     var tex: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
     var file := label + "_" + state + ".png"
     var ground_anchor: Vector2 = actor.get_canvas_transform() * Vector2(actor.global_position.x, 520)
     rows.append({"ground_anchor":[ground_anchor.x, ground_anchor.y], "actor":entry[0], "facing":facing, "state":state, "clip":sprite.animation, "frame":sprite.frame, "source":tex.atlas.resource_path if tex is AtlasTexture else tex.resource_path, "file":file})
     if DisplayServer.get_name() != "headless":
      actor.set_physics_process(false)
      sprite.pause()
      await process_frame
      RenderingServer.force_draw(false)
      check(root.get_texture().get_image().save_png(folder.path_join(file)) == OK, label + " capture")
      actor.set_physics_process(true)
      sprite.play()
   check(seen.has("KNOCKBACK") and seen.has("KNOCKDOWN") and seen.has("GET_UP") and seen.has("RECOVERED"), label + " flight down wakeup recovery")
   check(sampled.size() == 4, label + " sampled all transition poses")
   check(actor.knockdown_state == &"" and actor.hurt_box.monitorable and not actor.is_hit, label + " restores control")
 var inventory_name := "headless_inventory.json" if DisplayServer.get_name() == "headless" else "inventory.json"
 var output := FileAccess.open(folder.path_join(inventory_name), FileAccess.WRITE)
 output.store_string(JSON.stringify(rows, "  "))
 print("STAGE1_RECEIVED_TRANSITION_CHECK cases=8 poses=%d failures=%s" % [rows.size(), failures])
 manager.cleanup_battle_before_transition()
 battle.queue_free()
 await process_frame
 await process_frame
 quit(0 if failures.is_empty() else 1)
