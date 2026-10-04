extends SceneTree

const DEFINITIONS := ["fighters/ally_balance", "fighters/ally_power", "fighters/ally_speed",
	"enemies/enemy_01_standard", "enemies/enemy_02_speed", "enemies/enemy_03_guard",
	"enemies/enemy_04_throw", "enemies/enemy_05_power", "enemies/enemy_06_combo",
	"enemies/enemy_07_tricky", "enemies/enemy_08_boss", "enemies/enemy_09_seiya"]
const SLOTS := {
	"P": ["punch_1","punch"], "→P": ["punch_forward"], "←P": ["punch_backward"], "↓P": ["crouch_punch"],
	"K": ["kick_1","kick"], "→K": ["kick_forward"], "←K": ["kick_backward"], "↓K": ["crouch_kick"],
	"Air P": ["jump_punch"], "Air K": ["jump_kick"], "↓Air K": ["jump_kick_down"],
	"Throw": ["throw_start","throw"], "→Throw": ["throw_forward"], "↓Throw": ["throw_down"], "←Throw": ["throw_backward"],
	"Light Hit": ["damage_light"], "Heavy Hit": ["damage_heavy"], "High Hit": ["damage_high"], "Low Hit": ["damage_low"],
	"Launch Hit": ["launch_hit"], "Air Hit": ["air_hit"], "Knockback": ["knockback"], "Ground Bounce": ["ground_bounce"],
	"Knockdown": ["knockdown"], "Throw Front Damage": ["throw_front_damage"], "Throw Down Damage": ["throw_down_damage"],
	"Throw Back Damage": ["throw_back_damage"], "Special Hit": ["special_hit"], "Special Knockback": ["special_knockback"],
	"Special Knockdown": ["special_knockdown"], "Special Guard": ["special_guard"]}

func _initialize() -> void:
	call_deferred("run")

func frame_key(texture: Texture2D) -> String:
	if texture is AtlasTexture:
		return "%s %s" % [texture.atlas.resource_path, texture.region]
	return texture.resource_path

func describe(frames: SpriteFrames, clip: StringName) -> Dictionary:
	if not frames.has_animation(clip): return {"clip":String(clip),"registered":false}
	var keys: Array[String] = []
	for i in range(frames.get_frame_count(clip)):
		keys.append(frame_key(frames.get_frame_texture(clip,i)))
	return {"clip":String(clip),"registered":true,"frames":keys}

func run() -> void:
	var actor: Node = load("res://scenes/Player.tscn").instantiate()
	root.add_child(actor)
	await process_frame
	actor.set_physics_process(false)
	var report: Array[Dictionary] = []
	var markdown := "# 必殺技引き継ぎ・実参照Motion一覧（2026-10-03）\n\n"
	markdown += "実Playerシーンへ12定義を読み込み、統合後のSpriteFramesとMoveDataから出力。登録名の有無は機能の有無を断定しない。固有名による方向Attack/Throwは別途接触経路の照合が必要。専用性は原画比較で確定し、同じFrameの共有を新規Motionとして数えない。\n\n"
	for path in DEFINITIONS:
		actor.apply_character_data(load("res://data/%s.tres" % path))
		var definition: Resource = actor.fighter_definition
		var frames: SpriteFrames = actor.animated_character_sprite.sprite_frames
		var move: Resource = actor.character_special_data
		var packet: Dictionary = actor._get_character_special_attack_dictionary()
		var row := {"id":String(definition.fighter_id),"definition":path,"special_id":move.attack_id,
			"damage_per_hit":packet.damage,"multiplier":move.damage_multiplier,"hitbox_size":str(move.hitbox_size),
			"hitbox_offset":str(move.hitbox_offset),"movement":move.move_distance,"cooldown":move.cooldown,
			"startup_invulnerability":move.startup_invulnerability,"special_phases":{},"requested_slots":{},
			"received_reactions":definition.special_damage_reactions,"normal_attack_shared_frames":[]}
		markdown += "## %s\n\n技: `%s` / 1接触Damage: %d / 倍率: %.2f / Cooldown: %.2fs\n\n" % [definition.display_name,move.attack_id,packet.damage,move.damage_multiplier,move.cooldown]
		if move.somersault_sidekick:
			markdown += "第9ステージ継承仕様: 各段1倍、両段成功で2倍。初段命中後の確定追撃を保持。\n\n"
		var normal_keys: Dictionary = {}
		for normal_clip in [&"punch_1",&"punch_2",&"kick_1",&"kick_2",&"crouch_punch",&"crouch_kick",&"jump_punch",&"jump_kick"]:
			if not frames.has_animation(normal_clip): continue
			for i in range(frames.get_frame_count(normal_clip)):
				normal_keys[frame_key(frames.get_frame_texture(normal_clip,i))] = String(normal_clip)
		var phases := {"Special Startup":move.special_startup_animation,"Special Attack":StringName(move.animation_name),"Special Finish":move.special_finish_animation}
		markdown += "| 必殺技Motion | 実Clip | Frame数 | 通常P/K等との共有 |\n|---|---|---:|---|\n"
		for phase in phases:
			var description := describe(frames,phases[phase])
			row.special_phases[phase] = description
			var shared: Array[String] = []
			for key in description.get("frames",[]):
				if normal_keys.has(key) and not normal_keys[key] in shared: shared.append(normal_keys[key])
			if not shared.is_empty(): row.normal_attack_shared_frames.append({"phase":phase,"shared_with":shared})
			markdown += "| %s | %s | %d | %s |\n" % [phase,phases[phase],description.get("frames",[]).size(),str(shared)]
		markdown += "\n| 要求Motion | 登録名候補 | 現在の参照 |\n|---|---|---|\n"
		for slot in SLOTS:
			var available: Array[Dictionary] = []
			for clip in SLOTS[slot]:
				if frames.has_animation(clip): available.append(describe(frames,clip))
			row.requested_slots[slot] = available
			var summary := "固有名/入力接続を要調査"
			if not available.is_empty(): summary = "%s (%d Frame)" % [available[0].clip,available[0].frames.size()]
			markdown += "| %s | %s | %s |\n" % [slot,str(SLOTS[slot]),summary]
		markdown += "\n技別被Damage登録: `%s`\n\n" % str(definition.special_damage_reactions)
		report.append(row)
	var out := ProjectSettings.globalize_path("res://").path_join("../docs").simplify_path()
	var json_file := FileAccess.open(out.path_join("SPECIAL_HANDOFF_INVENTORY_20261003.json"),FileAccess.WRITE)
	json_file.store_string(JSON.stringify(report,"\t"))
	json_file.close()
	var md_file := FileAccess.open(out.path_join("SPECIAL_HANDOFF_INVENTORY_20261003.md"),FileAccess.WRITE)
	md_file.store_string(markdown.strip_edges() + "\n")
	md_file.close()
	print("SPECIAL_HANDOFF_INVENTORY_OK definitions=%d" % report.size())
	for audio in root.find_children("*", "AudioStreamPlayer", true, false): audio.stop()
	OS.delay_msec(200)
	actor.queue_free()
	await process_frame
	quit()
