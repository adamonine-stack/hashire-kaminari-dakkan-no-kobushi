extends SceneTree

const REQUIRED := {
	"P": "punch_1", "Forward P": "forward_punch", "Back P": "anti_air_punch", "Down P": "launcher_punch",
	"K": "kick_1", "Forward K": "forward_kick", "Back K": "evade_kick", "Down K": "crouch_kick_sweep",
	"Air P": "air_punch", "Air K": "jump_kick", "Down Air K": "dive_kick",
	"Throw": "throw_release", "Forward Throw": "throw_forward", "Down Throw": "throw_slam", "Back Throw": "throw_back",
	"Special Startup": "special_startup", "Special Attack": "special_attack", "Special Finish": "special_recovery",
	"Light Hit": "damage_high", "Heavy Hit": "damage_heavy", "High Hit": "damage_high", "Low Hit": "damage_low",
	"Launch Hit": "launch_hit", "Air Hit": "air_hit", "Knockback": "knockback", "Knockdown": "knockdown_high",
	"Ground Bounce": "ground_bounce", "Wall Hit": "wall_hit", "Throw Front Hit": "throw_front_hit",
	"Throw Down Hit": "throw_down_hit", "Throw Back Hit": "throw_back_hit", "Special Hit": "special_hit",
	"Special Knockback": "special_knockback", "Special Knockdown": "special_knockdown", "Special Guard": "special_guard"
}

func _initialize() -> void:
	var files: Array[String] = []
	for folder in ["res://data/fighters", "res://data/enemies"]:
		for name in DirAccess.get_files_at(folder):
			if name.ends_with(".tres"):
				files.append(folder.path_join(name))
	var lines: Array[String] = ["# Combat motion inventory", "", "Resource inventory only. Existing names are reuse candidates, not visual approval. Missing names require pose review before deciding modification versus new art.", ""]
	for path in files:
		var fighter: Resource = load(path)
		if fighter == null or fighter.get("fighter_id") == null:
			continue
		var clips: Dictionary = {}
		for key in ["motion_atlas", "supplemental_motion_atlas"]:
			var atlas: Resource = fighter.get(key)
			if atlas != null:
				clips.merge(atlas.clips, true)
		for atlas in fighter.extra_motion_atlases:
			if atlas != null:
				clips.merge(atlas.clips, true)
		for definition in fighter.animation_definitions:
			if definition != null:
				clips[String(definition.animation_name)] = {}
		for clip in fighter.sprite_animation_clips:
			clips[String(clip)] = {}
		lines.append("## %s (%s)" % [fighter.display_name, fighter.fighter_id])
		lines.append("")
		lines.append("Source: `%s`" % path)
		lines.append("")
		lines.append("Existing clips: %s" % ", ".join(clips.keys()))
		lines.append("")
		lines.append("| Required motion | Expected clip | Inventory decision |")
		lines.append("|---|---|---|")
		for label in REQUIRED:
			var clip: String = REQUIRED[label]
			lines.append("| %s | %s | %s |" % [label, clip, "Reuse candidate; visual check pending" if clips.has(clip) else "Missing exact clip; pose review / new production needed"])
		lines.append("")
	var output := FileAccess.open("res://../combat_motion_inventory.md", FileAccess.WRITE)
	if output == null:
		push_error("Cannot write inventory")
		quit(1)
		return
	output.store_string("\n".join(lines) + "\n")
	output.close()
	print("COMBAT_MOTION_INVENTORY fighters=%d" % files.size())
	quit()
