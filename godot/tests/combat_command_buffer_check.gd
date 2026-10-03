extends SceneTree

const Buffer := preload("res://scripts/input/combat_command_buffer.gd")
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func _initialize() -> void:
	for facing in [1.0, -1.0]:
		var forward := "right" if facing > 0.0 else "left"
		var back := "left" if facing > 0.0 else "right"
		for direction in [forward, back, "down"]:
			var expected := "down" if direction == "down" else ("forward" if direction == forward else "back")
			for delay in [0.0, 0.10, 0.149]:
				var buffer := Buffer.new()
				buffer.record(direction, true, facing)
				buffer.record(direction, false, facing)
				buffer.advance(delay)
				buffer.record("punch", true, -facing)
				check(buffer.peek().direction == expected, "released direction survives %.3f / facing %.0f / %s" % [delay, facing, expected])
				check(buffer.history[0].facing == facing, "entry facing preserved")
				check(buffer.history[1].release, "release event recorded")
		var expired := Buffer.new()
		expired.record(forward, true, facing)
		expired.record(forward, false, facing)
		expired.advance(0.151)
		expired.record("kick", true, facing)
		check(expired.peek().direction == "neutral", "direction expires")
		var held := Buffer.new()
		held.record(back, true, facing)
		held.advance(0.5)
		held.record("kick", true, facing)
		check(held.peek().direction == "back", "held direction outlives history window")
		var priority := Buffer.new()
		priority.record("left", true, facing)
		priority.record("right", true, facing)
		check(priority.command_direction(facing) == "neutral", "opposite directions neutralize")
		priority.clear()
		for action in ["punch", "kick", "throw", "special"]:
			priority.record(action, true, facing)
		check(priority.peek().kind == "special", "special first")
		priority.consume(priority.peek())
		check(priority.pending.is_empty(), "competing buttons consumed once")
		priority.record("special", true, facing)
		check(priority.pending.is_empty(), "held action never repeats")
		priority.record("special", false, facing)
		priority.record("throw", false, facing)
		priority.record("throw", true, facing)
		check(priority.peek().kind == "throw", "new press after release")
		priority.advance(0.151)
		check(priority.peek().is_empty(), "action expiry")
		priority.advance(0.6)
		check(priority.history.is_empty(), "bounded history")
		priority.clear()
		check(priority.held.is_empty(), "reset clears held state")
	print("COMBAT_COMMAND_BUFFER_CHECK failures=%s" % [failures])
	quit(0 if failures.is_empty() else 1)
