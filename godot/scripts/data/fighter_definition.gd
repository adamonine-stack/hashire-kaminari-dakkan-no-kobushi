extends Resource
class_name FighterDefinition

@export var fighter_id: StringName
@export var display_name: String
@export var hud_name_katakana: String
@export_multiline var description: String

@export var fighter_scene: PackedScene
@export var selection_portrait: Texture2D
@export var selection_icon: Texture2D

@export_group("Official Art Assets")
@export var portrait: Texture2D
@export var battle_texture_path: String = ""
@export var sprite_sheet_path: String = ""
@export var battle_texture: Texture2D:
	get:
		if battle_texture == null and not battle_texture_path.is_empty():
			battle_texture = ResourceLoader.load(
				battle_texture_path,
				"Texture2D",
				ResourceLoader.CACHE_MODE_IGNORE_DEEP
			) as Texture2D
			if battle_texture == null:
				push_warning("Failed to lazy-load battle texture: %s" % battle_texture_path)
		return battle_texture
@export var icon: Texture2D
@export var sprite_sheet: Texture2D:
	get:
		if sprite_sheet == null and not sprite_sheet_path.is_empty():
			sprite_sheet = ResourceLoader.load(
				sprite_sheet_path,
				"Texture2D",
				ResourceLoader.CACHE_MODE_IGNORE_DEEP
			) as Texture2D
			if sprite_sheet == null:
				push_warning("Failed to lazy-load sprite sheet: %s" % sprite_sheet_path)
		return sprite_sheet
## Heavy authored motion atlases can be stored as paths so Web builds do not
## keep every campaign fighter's combat textures resident at battle startup.
## Direct Resource assignments remain supported for backwards compatibility.
@export var motion_atlas_path: String = ""
@export var supplemental_motion_atlas_path: String = ""
@export var motion_atlas: Resource:
	get:
		if motion_atlas == null and not motion_atlas_path.is_empty():
			motion_atlas = ResourceLoader.load(
				motion_atlas_path,
				"Resource",
				ResourceLoader.CACHE_MODE_IGNORE_DEEP
			)
			if motion_atlas == null:
				push_warning("Failed to lazy-load motion atlas: %s" % motion_atlas_path)
		return motion_atlas
@export var supplemental_motion_atlas: Resource:
	get:
		if supplemental_motion_atlas == null and not supplemental_motion_atlas_path.is_empty():
			supplemental_motion_atlas = ResourceLoader.load(
				supplemental_motion_atlas_path,
				"Resource",
				ResourceLoader.CACHE_MODE_IGNORE_DEEP
			)
			if supplemental_motion_atlas == null:
				push_warning("Failed to lazy-load supplemental motion atlas: %s" % supplemental_motion_atlas_path)
		return supplemental_motion_atlas
@export var shadow_texture: Texture2D
@export var idle_pose_texture: Texture2D
@export var prebattle_pose_texture: Texture2D
@export var prebattle_visual_scale := Vector2.ONE
@export var art_folder: String = ""
@export var battle_sprite_height: float = 150.0
@export var battle_sprite_offset: Vector2 = Vector2(0.0, 0.0)
@export var character_height_cm: float = 175.0
@export var visual_scale_adjustment: float = 1.0
## Feet-anchored proportions shared by the visual and combat geometry.
@export var combat_geometry_scale: float = 1.0
@export var body_width_scale: float = 1.0
@export var head_scale: float = 1.0
## Heavy received-special/reversal atlases may be stored as paths so Web builds
## do not keep every campaign fighter's optional motion textures resident at
## battle-scene startup. The existing Resource array remains supported for
## backwards compatibility and is populated on first access when paths exist.
@export var extra_motion_atlas_paths: Array[String] = []
@export var extra_motion_atlases: Array[Resource] = []:
	get:
		if extra_motion_atlases.is_empty() and not extra_motion_atlas_paths.is_empty():
			for atlas_path in extra_motion_atlas_paths:
				if atlas_path.is_empty():
					continue
				var atlas := ResourceLoader.load(
					atlas_path,
					"Resource",
					ResourceLoader.CACHE_MODE_IGNORE_DEEP
				)
				if atlas != null:
					extra_motion_atlases.append(atlas)
				else:
					push_warning("Failed to lazy-load extra motion atlas: %s" % atlas_path)
		return extra_motion_atlases
## attack_id -> {hit, airborne, down}: poses belong to this receiving fighter.
@export var special_damage_reactions: Dictionary = {}
@export var aura_attack: Resource
@export var reversal_attack: Resource
@export var use_direct_combat_stats: bool = false
@export var sprite_body_height_px: float = 0.0
@export var foot_offset: Vector2 = Vector2.ZERO
@export var animation_definitions: Array[FighterAnimationDefinition] = []
@export var sprite_sheet_format: StringName = &"legacy"
@export var sprite_frame_size: Vector2i = Vector2i(96, 96)
@export var sprite_sheet_columns: int = 16
@export var sprite_animation_rows: Dictionary = {}
@export var sprite_animation_frame_counts: Dictionary = {}
@export var sprite_animation_speeds: Dictionary = {}
@export var sprite_animation_clips: Dictionary = {}
@export var sprite_animation_center_offsets: Dictionary = {}
@export var sprite_animation_bottom_offsets: Dictionary = {}
@export_group("Sprite Sheet Layout")
@export var sprite_frame_origin: Vector2 = Vector2(-1.0, -1.0)
@export var sprite_frame_step: Vector2 = Vector2(-1.0, -1.0)
@export var sprite_row_height: float = -1.0
@export var sprite_max_frames_per_animation: int = 8
@export var sprite_cleanup_background: bool = true
@export_range(0.0, 1.0, 0.01) var sprite_background_brightness_limit: float = 0.62
@export_range(0.0, 1.0, 0.01) var sprite_background_color_tolerance: float = 0.24

@export var fighter_type: StringName
@export var team_type: StringName = &"ALLY"
@export var enemy_order: int = 0
@export var ai_profile: Resource
@export var intro_title: String
@export_multiline var intro_description: String
@export var temporary_color: Color = Color.WHITE

@export var max_health: float = 100.0
@export var move_speed: float = 300.0
@export var air_move_speed: float = 300.0
@export var jump_force: float = 500.0
@export_range(1.0, 2.5, 0.05) var backstep_speed_multiplier: float = 1.55

@export_group("Direct Character Stats")
@export var punch_damage: float = 0.0
@export var kick_damage: float = 0.0
@export var punch_startup_multiplier: float = 1.0
@export var kick_startup_multiplier: float = 1.0
@export var punch_recovery_multiplier: float = 1.0
@export var kick_recovery_multiplier: float = 1.0
@export var guard_damage_multiplier: float = 0.25
@export var guard_stamina_multiplier: float = 1.0
@export var attack_knockback_multiplier: float = 1.0
@export var received_knockback_multiplier: float = 1.0
@export var attack_sequence: Array[Resource] = []
@export var air_kick_attack: Resource
@export var air_punch_down_attack: Resource
@export var crouch_kick_sweep_attack: Resource
@export var max_attack_chain_count: int = 0
@export var special_attack_sequence: Array[Resource] = []

@export_group("Character Special")
@export var max_special_gauge: float = 100.0
@export var special_gauge_cost: float = 100.0
@export var special_ai_use_chance: float = 0.35
@export var special_has_armor: bool = false

@export_group("Legacy Scales")
@export var punch_damage_scale: float = 1.0
@export var kick_damage_scale: float = 1.0
@export var throw_damage_scale: float = 1.0

@export var knockback_scale: float = 1.0
@export var attack_speed_scale: float = 1.0

@export var combo_damage_scale: float = 1.0
@export var guard_damage_scale: float = 1.0

@export_range(1, 5) var power_rating: int = 3
@export_range(1, 5) var speed_rating: int = 3
@export_range(1, 5) var health_rating: int = 3
@export_range(1, 5) var throw_rating: int = 3
@export_range(1, 5) var combo_rating: int = 3
