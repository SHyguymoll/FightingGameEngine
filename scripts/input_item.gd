extends HBoxContainer
signal input_button_clicked(input_item)

@export var input_to_update : StringName
@export var visible_name : StringName
var kb_input = null
var jp_input = null

func _ready():
	$ButtonName.text = visible_name
	for event in InputMap.action_get_events(input_to_update):
		if event is InputEventKey and not kb_input:
			$KeyboardInput.text = event.as_text()
			kb_input = event
		if event is InputEventJoypadButton and not jp_input:
			$JoypadInput.text = event.as_text()
			jp_input = event

func _process(_delta: float) -> void:
	for event in InputMap.action_get_events(input_to_update):
		if event is InputEventKey:
			$KeyboardInput.text = event.as_text()
		if event is InputEventJoypadButton:
			$JoypadInput.text = event.as_text()

func _on_keyboard_input_pressed() -> void:
	emit_signal("input_button_clicked", self, true)


func _on_joypad_input_pressed() -> void:
	emit_signal("input_button_clicked", self, false)
