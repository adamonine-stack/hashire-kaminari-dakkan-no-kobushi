from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
BATTLE = ROOT / "godot/scripts/battle/battle_manager.gd"
STAGE1 = ROOT / "godot/scripts/battle/stage1_battle_manager.gd"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly 1 match, found {count}")
    return text.replace(old, new, 1)


def regex_once(text: str, pattern: str, replacement: str, label: str) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly 1 regex match, found {count}")
    return updated


battle = BATTLE.read_text(encoding="utf-8")

battle = regex_once(
    battle,
    r'const ENEMY_DEFINITIONS: Array\[Resource\] = \[.*?\]\nconst STAGE_DEFINITIONS: Array\[Resource\] = \[.*?\]\n',
    '''const ENEMY_MANIFESTS: Array[Dictionary] = [
\t{"fighter_id": &"enemy_01_crusher", "display_name": "クラッシャー", "fighter_type": "POWER", "max_health": 125, "definition_path": "res://data/enemies/enemy_01_standard.tres"},
\t{"fighter_id": &"enemy_04_rei_kageyama", "display_name": "レイ・カゲヤマ", "fighter_type": "KARATE", "max_health": 112, "definition_path": "res://data/enemies/enemy_04_throw.tres"},
\t{"fighter_id": &"enemy_07_teki_fighter", "display_name": "テキ・ファイター", "fighter_type": "TECHNICAL_GRAPPLER", "max_health": 118, "definition_path": "res://data/enemies/enemy_07_tricky.tres"},
\t{"fighter_id": &"enemy_05_cross_murasame", "display_name": "クロス・ムラサメ", "fighter_type": "JUJUTSU", "max_health": 108, "definition_path": "res://data/enemies/enemy_05_power.tres"},
\t{"fighter_id": &"enemy_02_shadow_boxer", "display_name": "シャドウボクサー", "fighter_type": "BOXER", "max_health": 88, "definition_path": "res://data/enemies/enemy_02_speed.tres"},
\t{"fighter_id": &"enemy_06_rio_flick_garcia", "display_name": "リオ・“フリック”・ガルシア", "fighter_type": "GRAPPLE_SPEED", "max_health": 102, "definition_path": "res://data/enemies/enemy_06_combo.tres"},
\t{"fighter_id": &"enemy_03_masato_takahashi", "display_name": "マサト・タカハシ", "fighter_type": "JUDO", "max_health": 96, "definition_path": "res://data/enemies/enemy_03_guard.tres"},
\t{"fighter_id": &"enemy_08_leon_crow", "display_name": "レオン・クロウ", "fighter_type": "BOSS", "max_health": 170, "definition_path": "res://data/enemies/enemy_08_boss.tres"},
]
const STAGE_DEFINITION_PATHS: Array[String] = [
\t"res://data/stages/stage_01_crusher.tres",
\t"res://data/stages/stage_02_rei.tres",
\t"res://data/stages/stage_03_teki.tres",
\t"res://data/stages/stage_04_cross.tres",
\t"res://data/stages/stage_05_shadow.tres",
\t"res://data/stages/stage_06_rio.tres",
\t"res://data/stages/stage_07_masato.tres",
\t"res://data/stages/stage_08_leon.tres",
\t"res://data/stages/stage_09_secret_boss.tres",
]
''',
    "replace resident enemy/stage resource constants",
)

battle = replace_once(
    battle,
    'var battle_statistics: Array[Dictionary] = []\n',
    '''var battle_statistics: Array[Dictionary] = []
var _current_enemy_definition: Resource = null
var _current_enemy_definition_index := -1
var _current_stage_definition: Resource = null
var _current_stage_definition_index := -1
''',
    "add current-only resource caches",
)

battle = replace_once(
    battle,
    '\tbattle_statistics.clear()\n\tselected_player_ids.clear()\n',
    '\tbattle_statistics.clear()\n\t_release_enemy_definition_cache()\n\t_release_stage_definition_cache()\n\tselected_player_ids.clear()\n',
    "release caches on run initialization",
)

battle = regex_once(
    battle,
    r'func initialize_enemy_team\(\) -> void:\n.*?\n\nfunc reset_player_roster\(\) -> void:',
    '''func initialize_enemy_team() -> void:
\tenemy_team.clear()
\tenemy_order.clear()
\tvar active_enemy_count := _active_enemy_definition_count()
\tif not validate_enemy_definitions(active_enemy_count):
\t\tfor index in range(active_enemy_count):
\t\t\tvar fallback_id := StringName("enemy_%02d" % (index + 1))
\t\t\tenemy_order.append(fallback_id)
\t\t\tenemy_team.append(_create_progress_entry(
\t\t\t\tfallback_id,
\t\t\t\t"Enemy %d" % (index + 1),
\t\t\t\tindex,
\t\t\t\tenemy.max_hp
\t\t\t))
\t\treturn

\tfor index in range(active_enemy_count):
\t\tvar manifest: Dictionary = ENEMY_MANIFESTS[index]
\t\tvar fighter_id := StringName(manifest["fighter_id"])
\t\tenemy_order.append(fighter_id)
\t\tenemy_team.append(_create_enemy_progress_entry_from_manifest(manifest, index))


func _active_enemy_definition_count() -> int:
\tif active_enemy_count_limit <= 0:
\t\treturn ENEMY_MANIFESTS.size()
\treturn clampi(active_enemy_count_limit, 1, ENEMY_MANIFESTS.size())


func _create_enemy_progress_entry_from_manifest(manifest: Dictionary, battle_order: int) -> Dictionary:
\tvar fighter_id := StringName(manifest["fighter_id"])
\tvar max_health := _enemy_progress_max_health(fighter_id, int(manifest["max_health"]))
\treturn {
\t\t"definition": null,
\t\t"definition_path": String(manifest["definition_path"]),
\t\t"character_id": fighter_id,
\t\t"fighter_id": fighter_id,
\t\t"display_name": String(manifest["display_name"]),
\t\t"fighter_type": String(manifest["fighter_type"]),
\t\t"scene_path": "",
\t\t"max_health": max_health,
\t\t"current_health": max_health,
\t\t"special_gauge": 0.0,
\t\t"is_defeated": false,
\t\t"is_available": true,
\t\t"battle_order": battle_order,
\t\t"has_been_selected": false,
\t}


func _enemy_progress_max_health(_fighter_id: StringName, authored_max_health: int) -> int:
\treturn authored_max_health


func _prepare_loaded_enemy_definition(definition: Resource) -> Resource:
\treturn definition


func _release_enemy_definition_cache() -> void:
\t_current_enemy_definition = null
\t_current_enemy_definition_index = -1


func _release_stage_definition_cache() -> void:
\t_current_stage_definition = null
\t_current_stage_definition_index = -1


func _ensure_current_enemy_definition() -> Resource:
\tif current_enemy_index < 0 or current_enemy_index >= enemy_team.size():
\t\treturn null
\tif _current_enemy_definition != null and _current_enemy_definition_index == current_enemy_index:
\t\treturn _current_enemy_definition

\t_release_enemy_definition_cache()
\tvar data := enemy_team[current_enemy_index]
\tvar definition_path := String(data.get("definition_path", ""))
\tif definition_path.is_empty() or not ResourceLoader.exists(definition_path):
\t\tpush_warning("Enemy definition path is missing: %s" % definition_path)
\t\treturn null
\tvar definition := ResourceLoader.load(definition_path)
\tif definition == null:
\t\tpush_warning("Failed to load enemy definition: %s" % definition_path)
\t\treturn null
\tdefinition = _prepare_loaded_enemy_definition(definition)
\tif definition == null or StringName(definition.fighter_id) != StringName(data["fighter_id"]):
\t\tpush_warning("Enemy definition ID mismatch at stage %d" % (current_enemy_index + 1))
\t\treturn null
\tif int(definition.enemy_order) != current_enemy_index + 1:
\t\tpush_warning("Enemy order mismatch: %s" % definition.fighter_id)
\t\treturn null
\tif definition.fighter_scene == null or definition.ai_profile == null or int(round(definition.max_health)) <= 0:
\t\tpush_warning("Enemy definition is incomplete: %s" % definition.fighter_id)
\t\treturn null

\t_current_enemy_definition = definition
\t_current_enemy_definition_index = current_enemy_index
\tvar resolved_max := _enemy_progress_max_health(StringName(data["fighter_id"]), int(round(definition.max_health)))
\tdata["max_health"] = resolved_max
\tif not bool(data["is_defeated"]):
\t\tdata["current_health"] = clampi(int(data["current_health"]), 1, resolved_max)
\treturn _current_enemy_definition


func _enemy_view_data(enemy_index: int) -> Dictionary:
\tif enemy_index < 0 or enemy_index >= enemy_team.size():
\t\treturn {}
\tvar view := enemy_team[enemy_index].duplicate(true)
\tif enemy_index == current_enemy_index:
\t\tview["definition"] = _ensure_current_enemy_definition()
\treturn view


func reset_player_roster() -> void:''',
    "replace enemy initialization with lightweight manifests",
)

battle = regex_once(
    battle,
    r'func validate_enemy_definitions\(required_count: int = -1\) -> bool:\n.*?\n\treturn true\n\n\nfunc start_initial_player_selection',
    '''func validate_enemy_definitions(required_count: int = -1) -> bool:
\tvar count := ENEMY_MANIFESTS.size() if required_count < 0 else clampi(required_count, 0, ENEMY_MANIFESTS.size())
\tif count <= 0:
\t\tpush_warning("No enemy definitions are enabled for this battle.")
\t\treturn false

\tvar seen_ids := {}
\tfor index in range(count):
\t\tvar manifest: Dictionary = ENEMY_MANIFESTS[index]
\t\tvar fighter_id := StringName(manifest.get("fighter_id", &""))
\t\tvar definition_path := String(manifest.get("definition_path", ""))
\t\tif fighter_id == &"" or seen_ids.has(fighter_id):
\t\t\tpush_warning("Enemy manifest has an empty or duplicated fighter_id.")
\t\t\treturn false
\t\tseen_ids[fighter_id] = true
\t\tif int(manifest.get("max_health", 0)) <= 0:
\t\t\tpush_warning("Enemy manifest max health is invalid: %s" % fighter_id)
\t\t\treturn false
\t\tif definition_path.is_empty() or not ResourceLoader.exists(definition_path):
\t\t\tpush_warning("Enemy definition path is missing: %s" % definition_path)
\t\t\treturn false
\treturn true


func start_initial_player_selection''',
    "replace eager enemy validation",
)

battle = replace_once(
    battle,
    '''\tvar data := enemy_team[current_enemy_index]
\t# Applying a definition emits HP signals from the reused Enemy. Preserve the
\t# checkpoint before those signals update its progress dictionary.
\tvar current_health := int(clampi(data["current_health"], 1, data["max_health"]))
\tvar definition: Resource = data.get("definition", null)
''',
    '''\tvar data := enemy_team[current_enemy_index]
\tvar definition := _ensure_current_enemy_definition()
\tif definition == null:
\t\treturn
\t# Applying a definition emits HP signals from the reused Enemy. Preserve the
\t# checkpoint before those signals update its progress dictionary.
\tvar current_health := int(clampi(data["current_health"], 1, data["max_health"]))
''',
    "load only current enemy during spawn",
)

battle = replace_once(
    battle,
    '''func prepare_battle() -> void:
\tif _should_finish_game():
\t\treturn

\t_apply_current_stage_definition()
''',
    '''func prepare_battle() -> void:
\tif _should_finish_game():
\t\treturn
\tif _ensure_current_enemy_definition() == null:
\t\treturn

\t_apply_current_stage_definition()
''',
    "ensure current enemy before battle",
)

battle = replace_once(
    battle,
    '''\tif _should_show_enemy_intro():
\t\t_notify_hud_enemy_intro(enemy_team[current_enemy_index], current_enemy_index)
\t\tawait start_enemy_intro(enemy_team[current_enemy_index])
''',
    '''\tif _should_show_enemy_intro():
\t\tvar enemy_view := _enemy_view_data(current_enemy_index)
\t\t_notify_hud_enemy_intro(enemy_view, current_enemy_index)
\t\tawait start_enemy_intro(enemy_view)
''',
    "use current enemy view for intro",
)

battle = replace_once(
    battle,
    '\thud_enemy_spawned.emit(enemy, current_enemy_index, data.duplicate(true))\n',
    '\thud_enemy_spawned.emit(enemy, current_enemy_index, _enemy_view_data(current_enemy_index))\n',
    "emit current enemy definition only to HUD",
)

battle = replace_once(
    battle,
    '''func transition_to_next_enemy() -> void:
\t_set_battle_active(false)
\t_clear_active_fighter_actions(player)
\t_clear_active_fighter_actions(enemy)
\tplayer.visible = false
\tenemy.visible = false
''',
    '''func transition_to_next_enemy() -> void:
\t_set_battle_active(false)
\t_clear_active_fighter_actions(player)
\t_clear_active_fighter_actions(enemy)
\tplayer.visible = false
\tenemy.visible = false
\t_release_enemy_definition_cache()
\t_release_stage_definition_cache()
''',
    "release prior stage resources on transition",
)

battle = replace_once(
    battle,
    '''\tif enemy.has_method("reset_special_attack_state"):
\t\tenemy.reset_special_attack_state(false)
\tif battle_hud != null:
''',
    '''\tif enemy.has_method("reset_special_attack_state"):
\t\tenemy.reset_special_attack_state(false)
\t_release_enemy_definition_cache()
\t_release_stage_definition_cache()
\tif battle_hud != null:
''',
    "release caches during cleanup",
)

battle = replace_once(
    battle,
    '''\tif battle_hud.has_method("update_enemy_information") and current_enemy_index >= 0 and current_enemy_index < enemy_team.size():
\t\tbattle_hud.update_enemy_information(enemy_team[current_enemy_index], current_enemy_index)
''',
    '''\tif battle_hud.has_method("update_enemy_information") and current_enemy_index >= 0 and current_enemy_index < enemy_team.size():
\t\tbattle_hud.update_enemy_information(_enemy_view_data(current_enemy_index), current_enemy_index)
''',
    "provide HUD current-only definition",
)

battle = regex_once(
    battle,
    r'func _active_enemy_type\(\) -> String:\n.*?\n\treturn String\(definition\.fighter_type\)\n',
    '''func _active_enemy_type() -> String:
\tif current_enemy_index < 0 or current_enemy_index >= enemy_team.size():
\t\treturn ""
\treturn String(enemy_team[current_enemy_index].get("fighter_type", ""))
''',
    "read enemy type from manifest",
)

battle = regex_once(
    battle,
    r'func _stage_definition_for_enemy_index\(enemy_index: int\) -> Resource:\n.*?\n\treturn STAGE_DEFINITIONS\[enemy_index\]\n',
    '''func _stage_definition_for_enemy_index(enemy_index: int) -> Resource:
\tif enemy_index < 0 or enemy_index >= STAGE_DEFINITION_PATHS.size():
\t\treturn null
\tif _current_stage_definition != null and _current_stage_definition_index == enemy_index:
\t\treturn _current_stage_definition
\t_release_stage_definition_cache()
\tvar stage_path := STAGE_DEFINITION_PATHS[enemy_index]
\tif not ResourceLoader.exists(stage_path):
\t\tpush_warning("Stage definition path is missing: %s" % stage_path)
\t\treturn null
\t_current_stage_definition = ResourceLoader.load(stage_path)
\t_current_stage_definition_index = enemy_index if _current_stage_definition != null else -1
\treturn _current_stage_definition
''',
    "lazy-load current stage definition",
)

BATTLE.write_text(battle, encoding="utf-8")

stage1 = STAGE1.read_text(encoding="utf-8")
stage1 = replace_once(
    stage1,
    '''func _create_progress_entry_from_definition(definition: Resource, battle_order: int) -> Dictionary:
\t_apply_battle_hp_target_once(definition)
\t_apply_battle_attack_target_once(definition)
\treturn super._create_progress_entry_from_definition(definition, battle_order)
''',
    '''func _create_progress_entry_from_definition(definition: Resource, battle_order: int) -> Dictionary:
\t_apply_battle_hp_target_once(definition)
\t_apply_battle_attack_target_once(definition)
\treturn super._create_progress_entry_from_definition(definition, battle_order)


func _enemy_progress_max_health(fighter_id: StringName, authored_max_health: int) -> int:
\tif BATTLE_HP_RESOURCE_TARGETS.has(fighter_id):
\t\treturn int(round(float(BATTLE_HP_RESOURCE_TARGETS[fighter_id])))
\treturn authored_max_health


func _prepare_loaded_enemy_definition(definition: Resource) -> Resource:
\t_apply_battle_hp_target_once(definition)
\t_apply_battle_attack_target_once(definition)
\treturn definition
''',
    "preserve Stage1 enemy HP/damage targets after lazy load",
)
STAGE1.write_text(stage1, encoding="utf-8")

print("STEP1 lazy resource patch applied")
