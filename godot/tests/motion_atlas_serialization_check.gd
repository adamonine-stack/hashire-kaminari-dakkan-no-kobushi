extends SceneTree

var failures: Array[String] = []
const CASES = {
	"body_consistent_air_v1/punch": [4, 0.2857142857142857],
	"body_consistent_ground_v1/ground": [2, 0.2732075471698114],
	"body_consistent_guard_v1/guard": [3, 0.2796137931034483],
	"body_consistent_hit_v1/heavy": [3, 0.349593496],
	"body_consistent_hit_v1/high": [3, 0.28],
	"body_consistent_hit_v1/light": [3, 0.349593496],
	"body_consistent_hit_v1/low": [3, 0.25890166028097067],
	"body_consistent_throw_v1/back": [3, 0.25563682219419925],
	"body_consistent_wall_v1/wall": [2, 0.27357624831309046],
}

func _initialize() -> void:
	for key in CASES:
		var atlas = load("res://assets/characters/player01/animations/%s.tres" % key)
		if atlas.frame_source_scales.size() != CASES[key][0]:
			failures.append("%s source scale count" % key)
			continue
		for scale in atlas.frame_source_scales:
			if not is_equal_approx(scale, CASES[key][1]): failures.append("%s source scale value" % key)
		var target := "user://measured_atlas_serialization.res"
		if ResourceSaver.save(atlas,target) != OK:
			failures.append("%s save" % key)
			continue
		var restored = ResourceLoader.load(target,"Resource",ResourceLoader.CACHE_MODE_IGNORE)
		if restored.frame_source_scales != atlas.frame_source_scales: failures.append("%s binary round trip" % key)
	print("MOTION_ATLAS_SERIALIZATION_CHECK atlases=",CASES.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
