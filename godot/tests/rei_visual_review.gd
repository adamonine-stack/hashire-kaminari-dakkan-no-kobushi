extends SceneTree

# Run with a graphical Godot display, from the project root:
# godot --path godot --script res://tests/rei_visual_review.gd
const CLIPS := ["idle", "walk", "dash", "jump_start", "jump_air", "jump_fall",
    "jump_land", "punch_1", "punch_2", "kick_1", "guard", "crouch",
    "crouch_guard", "crouch_punch", "crouch_kick_sweep", "damage_high",
    "knockdown", "stand_up", "ko", "throw"]

func _initialize() -> void:
    call_deferred("review")

func review() -> void:
    if DisplayServer.get_name() == "headless":
        push_error("Rei frame review needs an actual rendering display.")
        quit(1)
        return
    var output := ProjectSettings.globalize_path("res://../audit_evidence/rei_visual_review")
    DirAccess.make_dir_recursive_absolute(output)
    var battle: Node = load("res://scenes/Battle.tscn").instantiate()
    root.add_child(battle)
    await process_frame
    var manager: Node = battle.get_node("BattleManager")
    for entry in manager.player_team:
        manager.select_order_character(String(entry.fighter_id))
    manager.confirm_player_order()
    for i in range(360):
        await physics_frame
        if manager.isRoundActive:
            break
    if not manager.isRoundActive:
        push_error("Could not reach Stage 1 for Rei frame review.")
        quit(1)
        return
    manager.current_enemy_index = 1
    manager.spawn_active_enemy()
    var player: Node = battle.get_node("Player")
    var enemy: Node = battle.get_node("Enemy")
    player.set_physics_process(false)
    enemy.set_physics_process(false)
    battle.set_process(false)
    player.position = Vector2(470, 520)
    enemy.position = Vector2(810, 520)
    battle.get_node("BattleCamera").position = Vector2(640, 360)
    battle.get_node("BattleCamera").zoom = Vector2.ONE
    player._play_visual_animation(&"idle", true)
    player.animated_character_sprite.pause()
    var sprite: AnimatedSprite2D = enemy.animated_character_sprite
    var atlas: FighterMotionAtlas = load("res://assets/characters/enemy04/animations/rei_v1/motion_atlas.tres")
    for clip in atlas.clips:
        if not sprite.sprite_frames.has_animation(clip):
            push_error("Missing Rei animation: " + clip)
            quit(1)
            return
        enemy._play_visual_animation(StringName(clip), true)
        sprite.pause()
        for frame in range(sprite.sprite_frames.get_frame_count(clip)):
            sprite.set_frame_and_progress(frame, 0.0)
            await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png(
                output.path_join("%s_%02d.png" % [clip, frame]))
    # Render the real attack Area2D shape at each phase, on both facings.
    # This overlay exists only in the review script, never in normal gameplay.
    var overlay := Line2D.new()
    overlay.width = 2.0
    overlay.default_color = Color(1, 0.2, 0.2)
    enemy.add_child(overlay)
    for side in [-1, 1]:
        enemy.facing_direction = side
        enemy.character_visual_controller.set_facing(side)
        for action in ["Punch", "Kick"]:
            if action == "Punch":
                enemy.request_punch_attack()
            else:
                enemy.request_kick_attack()
            for phase in ["startup", "active", "recovery"]:
                if phase == "active":
                    enemy.enter_attack_active()
                elif phase == "recovery":
                    enemy.enter_attack_recovery()
                enemy._sync_attack_visual_phase()
                var area: Area2D = enemy.punch_area if action == "Punch" else enemy.kick_area
                var shape: CollisionShape2D = area.get_node("CollisionShape2D")
                var half: Vector2 = shape.shape.size * 0.5
                var center: Vector2 = enemy.to_local(shape.global_position)
                overlay.points = PackedVector2Array([center + Vector2(-half.x, -half.y), center + Vector2(half.x, -half.y), center + half, center + Vector2(-half.x, half.y), center - half])
                overlay.visible = phase == "active"
                await process_frame
                await RenderingServer.frame_post_draw
                root.get_texture().get_image().save_png(output.path_join("hitbox_%s_%s_%d.png" % [action, phase, side]))
            enemy.finish_attack()
    print("REI_VISUAL_REVIEW_OK clips=", atlas.clips.size(), " output=", output)
    manager.cleanup_battle_before_transition()
    battle.queue_free()
    quit()