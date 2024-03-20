extends HBoxContainer
signal input_button_clicked(input_item)

@export var input_to_update : StringName
@export var visible_name : StringName
var kb_assigned := false
var jp_assigned := false

func _ready():
	$ButtonName.text = visible_name
	for event in InputMap.action_get_events(input_to_update):
		if event is InputEventKey and not kb_assigned:
			$KeyboardInput.text = event.as_text()
			kb_assigned = true
		if event is InputEventJoypadButton and not jp_assigned:
			$JoypadInput.text = event.as_text()
			jp_assigned = true


func _on_keyboard_input_pressed() -> void:
	emit_signal("input_button_clicked", self)


func _on_joypad_input_pressed() -> void:
	emit_signal("input_button_clicked", self)
