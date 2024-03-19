extends Panel

@export var input_to_update : StringName
var kb_assigned := false
var jp_assigned := false

func _ready():
	for event in InputMap.action_get_events(input_to_update):
		if event is InputEventKey and not kb_assigned:
			$HBox/KeyboardInput.text = event.as_text()
			kb_assigned = true
		if event is InputEventJoypadButton and not jp_assigned:
			$HBox/JoypadInput.text = event.as_text()
			jp_assigned = true
