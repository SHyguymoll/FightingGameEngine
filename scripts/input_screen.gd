extends ColorRect
signal prompt_completed

var current_input : StringName
var event_to_erase : InputEvent
var input_visual : StringName
var is_kb : bool
enum CompletionStates {
	INPUT_UPDATED,
	UPDATE_CANCELLED,
	INCOMPLETE,
}
var completion_state : CompletionStates = CompletionStates.INCOMPLETE

func _ready() -> void:
	$Label.text = "Set new " + "keyboard" if is_kb else "pad" + \
			" input for '" + input_visual + "'"


func event_is_valid(event: InputEvent) -> bool:
	return event is InputEventKey or event is InputEventJoypadButton


func _input(event: InputEvent) -> void:
	if not event_is_valid(event) or event.is_echo():
		return

	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			completion_state = CompletionStates.UPDATE_CANCELLED
			emit_signal("prompt_completed")
			return
		if event.keycode == KEY_DELETE:
			InputMap.action_erase_event(current_input, event_to_erase)
			completion_state = CompletionStates.INPUT_UPDATED
			emit_signal("prompt_completed")
			return
		if not is_kb:
			return
		else:
			InputMap.action_erase_event(current_input, event_to_erase)
			InputMap.action_add_event(current_input, event)
			completion_state = CompletionStates.INPUT_UPDATED
			emit_signal("prompt_completed")
			return

	if event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_START:
			completion_state = CompletionStates.UPDATE_CANCELLED
			emit_signal("prompt_completed")
			return
		if is_kb:
			return
		else:
			InputMap.action_erase_event(current_input, event_to_erase)
			InputMap.action_add_event(current_input, event)
			completion_state = CompletionStates.INPUT_UPDATED
			emit_signal("prompt_completed")
			return

