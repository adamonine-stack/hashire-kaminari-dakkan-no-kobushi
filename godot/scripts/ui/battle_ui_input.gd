extends Control

const BUTTON_ACTIONS := {
	"MoveLeftButton": "move_left",
	"MoveRightButton": "move_right",
	"CrouchButton": "crouch",
	"PunchButton": "attack",
	"JumpButton": "jump",
}

var _held_actions: Array[String] = []


func _ready() -> void:
	for button_name in BUTTON_ACTIONS:
		var button := get_node_or_null(button_name) as Button
		if button == null:
			continue

		var action_name := BUTTON_ACTIONS[button_name] as String
		button.focus_mode = Control.FOCUS_NONE
		button.button_down.connect(_on_action_button_down.bind(action_name))
		button.button_up.connect(_on_action_button_up.bind(action_name))


func _exit_tree() -> void:
	for action_name in _held_actions:
		Input.action_release(action_name)
	_held_actions.clear()


func _on_action_button_down(action_name: String) -> void:
	if not _held_actions.has(action_name):
		_held_actions.append(action_name)
	Input.action_press(action_name)


func _on_action_button_up(action_name: String) -> void:
	Input.action_release(action_name)
	_held_actions.erase(action_name)
