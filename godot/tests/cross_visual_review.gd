extends SceneTree

# Run with a graphical Godot display, from the project root:
# godot --path godot --script res://tests/cross_visual_review.gd
const CLIPS := ["idle", "walk", "dash", "jump_start", "jump_air", "jump_fall",
    "jump_land", "punch_1", "punch_2", "kick_1", "guard", "crouch",
    "crouch_guard", "crouch_punch", "crouch_kick_sweep", "damage_high",
    "knockdown", "stand_up", "ko", "throw"]

func _initialize() -> void:
    call_deferred("review")

func review() -> void:
    if DisplayServer.get_name() == "headless":
        push_error("Cross frame review needs an actual rendering display.")
        quit(1)
        return
    var output := ProjectSettings.globalize_path("res://../audit_evidence/cross_visual_review")
    DirAccess.make_dir_recursive_absolute(output)
    var battle: Node = load("res://scenes/Battle.tscn").instantiate()
    root.add_child(battle)
    current_scene = battle
    await process_frame
    var manager: Node = battle.get_node("BattleManager")
    manager.select_player_by_id(String(manager.player_team[0].fighter_id))
    for i in range(1200):
        await physics_frame
        if manager._enemy_intro_panel != null and manager._enemy_intro_panel.visible:
            manager._advance_enemy_intro()
        if manager.isRoundActive:
            break
    if not manager.isRoundActive:
        push_error("Could not reach Stage 1 for Cross frame review.")
        quit(1)
        return
    manager.current_enemy_index = 3
    manager.spawn_active_enemy()
    manager._apply_current_stage_definition()
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
    var atlas: FighterMotionAtlas = load("res://assets/characters/enemy05/animations/cross_v1/motion_atlas.tres")
    for clip in atlas.clips:
        if "--contacts-only" in OS.get_cmdline_user_args():
            break
        if not sprite.sprite_frames.has_animation(clip):
            push_error("Missing Cross animation: " + clip)
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
        for action in ["cross_punch", "cross_chop", "cross_wrist_finish", "cross_kick", "cross_knee", "cross_joint_finish", "cross_sweep", "cross_air_punch", "cross_air_kick"]:
            enemy.start_attack(action)
            for phase in ["startup", "active", "recovery"]:
                if phase == "active":
                    enemy.enter_attack_active()
                elif phase == "recovery":
                    enemy.enter_attack_recovery()
                enemy._sync_attack_visual_phase()
                var area: Area2D = enemy.punch_area if enemy.current_attack_data.attack_type == "punch" else enemy.kick_area
                var shape: CollisionShape2D = area.get_node("CollisionShape2D")
                var half: Vector2 = shape.shape.size * 0.5
                var center: Vector2 = enemy.to_local(shape.global_position)
                overlay.points = PackedVector2Array([center + Vector2(-half.x, -half.y), center + Vector2(half.x, -half.y), center + half, center + Vector2(-half.x, half.y), center - half])
                overlay.visible = phase == "active"
                await process_frame
                await RenderingServer.frame_post_draw
                root.get_texture().get_image().save_png(output.path_join("hitbox_%s_%s_%d.png" % [action, phase, side]))
            enemy.finish_attack()
    overlay.visible = false
    for variant in range(6):
        manager.reset_active_fighter_state(player, Vector2(745, 520), 1.0)
        manager.reset_active_fighter_state(enemy, Vector2(810, 520), -1.0)
        for fighter in [player, enemy]:
            fighter.is_round_active = true
            fighter.throw_regrab_lock_timer = 0.0
            fighter.velocity = Vector2(0, 1)
            fighter.move_and_slide()
        enemy._start_throw()
        enemy.cross_throw_variant = variant
        enemy._connect_throw(player)
        enemy.animated_character_sprite.pause()
        player.animated_character_sprite.pause()
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(output.path_join("paired_grab_%d.png" % variant))
        enemy._release_throw()
        enemy._finish_throw()
    print("CROSS_VISUAL_REVIEW_OK clips=", atlas.clips.size(), " output=", output)
    manager.cleanup_battle_before_transition()
    battle.queue_free()
    quit()
