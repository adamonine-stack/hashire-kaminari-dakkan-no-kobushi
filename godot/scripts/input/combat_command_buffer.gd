extends RefCounted
class_name CombatCommandBuffer

## Facing is sampled when the direction is entered, not after auto-facing.
## Events use simulation time so pause never turns an old command into a new one.
var buffer_seconds := 0.15
var history_seconds := 0.60
var clock := 0.0
var history: Array[Dictionary] = []
var pending: Array[Dictionary] = []
var held: Dictionary = {}
const PRIORITIES := {"special": 100, "throw": 80, "punch": 60, "kick": 60, "jump": 20}

func advance(delta: float) -> void:
	clock += maxf(delta, 0.0)
	while not history.is_empty() and clock - float(history[0].timestamp) > history_seconds:
		history.pop_front()
	for i in range(pending.size() - 1, -1, -1):
		if clock - float(pending[i].timestamp) > buffer_seconds:
			pending.remove_at(i)

func record(kind: String, pressed: bool, facing: float) -> void:
	if bool(held.get(kind, false)) == pressed:
		return
	held[kind] = pressed
	var direction := logical_direction(facing)
	if kind in ["left", "right", "down"] and pressed:
		direction = "down" if kind == "down" else ("forward" if (kind == "right") == (facing > 0.0) else "back")
	var event := {"kind": kind, "timestamp": clock, "direction": direction, "facing": facing, "press": pressed, "release": not pressed}
	history.append(event)
	if pressed and PRIORITIES.has(kind):
		event = event.duplicate()
		event.direction = command_direction(facing)
		event["priority"] = int(PRIORITIES[kind]) + (1 if event.direction != "neutral" else 0)
		pending.append(event)

func logical_direction(facing: float) -> String:
	if bool(held.get("down", false)):
		return "down"
	var axis := int(bool(held.get("right", false))) - int(bool(held.get("left", false)))
	if axis == 0:
		return "neutral"
	return "forward" if float(axis) * facing > 0.0 else "back"

func command_direction(facing: float) -> String:
	var current := logical_direction(facing)
	if current != "neutral":
		return current
	if bool(held.get("left", false)) and bool(held.get("right", false)):
		return "neutral"
	# A short gap between thumb presses retains the direction at entry time.
	for i in range(history.size() - 1, -1, -1):
		var event: Dictionary = history[i]
		if clock - float(event.timestamp) > buffer_seconds:
			break
		if event.kind in ["left", "right", "down"] and bool(event.press):
			return String(event.direction)
	return "neutral"

func peek() -> Dictionary:
	var best: Dictionary = {}
	for event in pending:
		if best.is_empty() or int(event.priority) > int(best.priority):
			best = event
	return best

func consume(event: Dictionary) -> void:
	# Competing buttons from the same sample must not start a second move later.
	for i in range(pending.size() - 1, -1, -1):
		if float(pending[i].timestamp) <= float(event.timestamp):
			pending.remove_at(i)

func clear() -> void:
	history.clear()
	pending.clear()
	held.clear()
