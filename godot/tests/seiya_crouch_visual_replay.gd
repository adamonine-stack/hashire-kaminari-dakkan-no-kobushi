extends SceneTree

## Rendered autoplay preview, not a combat-input or manual-play claim.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var actor: Node2D = load("res://scenes/Player.tscn").instantiate()
	root.add_child(actor)
	actor.set_physics_process(false)
	actor.apply_fighter_definition(load("res://data/fighters/ally_speed.tres"))
	actor.position = Vector2(320,430)
	root.size = Vector2i(640,480)
	var sprite: AnimatedSprite2D = actor.animated_character_sprite
	var scale_before := sprite.scale
	var position_before := sprite.position
	var rows: Array[Dictionary] = []
	var failures: Array[String] = []
	var folder := ProjectSettings.globalize_path("res://../audit_evidence/hero_design_20261010/crouch_replay")
	DirAccess.make_dir_recursive_absolute(folder)
	for facing in [1,-1]:
		actor.facing_direction = facing
		actor._set_visual_facing()
		for repeat in range(3):
			for clip in [&"idle",&"crouch_idle",&"crouch_punch",&"crouch_idle",&"idle"]:
				actor._play_visual_animation(clip,true)
				var seen: Array[int] = []
				for tick in range(40):
					await physics_frame
					if sprite.scale != scale_before or sprite.position != position_before:
						failures.append("transform changed")
					if not sprite.frame in seen:
						seen.append(sprite.frame)
						rows.append({"facing":facing,"repeat":repeat,"clip":clip,"frame":sprite.frame,"scale":str(sprite.scale),"position":str(sprite.position)})
				if clip == &"crouch_punch" and seen != [0,1,2,3,4,5]:
					failures.append("missing continuous punch frames: %s" % str(seen))
	var file := FileAccess.open(folder.path_join("inventory.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows":rows,"failures":failures,"mode":"rendered automatic clip preview, not combat input"},"  "))
	print("SEIYA_CROUCH_VISUAL_REPLAY failures=",failures)
	quit(0 if failures.is_empty() else 1)
