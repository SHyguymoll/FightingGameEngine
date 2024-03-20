extends ColorRect
signal input_updated
signal update_cancelled

var active := false
var current_input : StringName
var input_visual : StringName
var is_kb : bool

func _process(delta: float) -> void:
	$Label.text = "Set new " + "keyboard" if is_kb else "pad" + \
			" input for " + input_visual


func event_is_valid(event: InputEvent) -> bool:
	return event is InputEventKey or event is InputEventJoypadButton


func _input(event: InputEvent) -> void:
	if not active or not event_is_valid(event):
		return
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			emit_signal("update_cancelled")
			return
		if not is_kb:
			return
	# wrong type
	if event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_START:
			emit_signal("update_cancelled")
			return
		if is_kb:
			return

