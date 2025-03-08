class_name TrainingModeGame
extends MainGame

var p1_reset_health_on_drop := true
var p2_reset_health_on_drop := true
var p1_health_reset : float
var p2_health_reset : float

var player_record_buffer := []
var record_buffer_current := 0
var record := false
var replay := false

@export var ui_p1_position_velocity : Label
@export var ui_p2_position_velocity : Label
@export var ui_p1_reset_health_slider : HSlider
@export var ui_p2_reset_health_slider : HSlider
@export var ui_p1_reset_health_button : CheckButton
@export var ui_p2_reset_health_button : CheckButton
@export var ui_p1_inputs : Label
@export var ui_p2_inputs : Label
@export var ui_input_record_status : Label

@export var ui_p1_training_special_section : PanelContainer
@export var ui_p2_training_special_section : PanelContainer

var dir_dict = {
	"": "x",
	"up": "↑", "down": "↓", "left": "←", "right": "→",
	"upleft": "↖", "downleft": "↙",
	"upright": "↗", "downright": "↘"
}

func init_fighters():
	super()
	p1_health_reset = p1.health
	p2_health_reset = p2.health


func construct_game():
	super()
	var p1_dtar = (debug_targetter.instantiate() as DebugTargetter)
	p1_dtar.pointer_texture = load("res://Content/Art/Menu/CharacterSelect/Player1Select.png")
	p1_dtar.pointer_target = p1
	game_fighters_and_stage.add_child(p1_dtar)
	var p2_dtar = (debug_targetter.instantiate() as DebugTargetter)
	p2_dtar.pointer_texture = load("res://Content/Art/Menu/CharacterSelect/Player2Select.png")
	p2_dtar.pointer_target = p2
	game_fighters_and_stage.add_child(p2_dtar)


func make_hud():
	super()
	ui_p1_position_velocity.text = (
			str(p1.position) + "\n" + str(p1.velocity))
	ui_p2_position_velocity.text = (
			str(p2.position) + "\n" + str(p2.velocity))
	if p1.ui_training:
		ui_p1_training_special_section.add_child(p1.ui_training)
	if p2.ui_training:
		ui_p2_training_special_section.add_child(p2.ui_training)
	ui_p1_reset_health_slider.min_value = 1
	ui_p1_reset_health_slider.max_value = p1.health
	ui_p1_reset_health_slider.value = ui_p1_reset_health_slider.max_value
	ui_p1_reset_health_button.set_pressed_no_signal(p1_reset_health_on_drop)
	ui_p2_reset_health_slider.min_value = 1
	ui_p2_reset_health_slider.max_value = p2.health
	ui_p2_reset_health_slider.value = ui_p2_reset_health_slider.max_value
	ui_p2_reset_health_button.set_pressed_no_signal(p2_reset_health_on_drop)


func update_hud():
	super()
	ui_p1_position_velocity.text = (
			str(p1.position) + "\n" + str(p1.velocity))
	ui_p2_position_velocity.text = (
			str(p2.position) + "\n" + str(p2.velocity))
	ui_input_record_status.text = (
		"%s/%s %s" % [
			record_buffer_current,
			len(player_record_buffer),
			"PLY" if replay else ("REC" if record else "STP"),
		]
	)


func generate_input_hud(buf : Dictionary, input_label : Label):
	var lookup_string := ""
	var dirs := ["up", "down", "left", "right"]

	input_label.text = ""
	for i in range(len(buf.up)):
		lookup_string = ""
		lookup_string += dirs[0] if buf[dirs[0]][i][1] else ""
		lookup_string += dirs[1] if buf[dirs[1]][i][1] else ""
		lookup_string += dirs[2] if buf[dirs[2]][i][1] else ""
		lookup_string += dirs[3] if buf[dirs[3]][i][1] else ""
		input_label.text += dir_dict[lookup_string]
		input_label.text += "\t"
		for button in buf:
			if button in dirs:
				if buf[button][i][1]:
					input_label.text += (
							"| %s, %s " % [str(buf[button][i][0]), dir_dict[button]])
				else:
					input_label.text += (
							"| %s, x " % [str(buf[button][i][0])])
			else:
				input_label.text += (
					"| %s, %s " % [buf[button][i][0], ("Ø" if buf[button][i][1] else "0")])
		input_label.text += "\n"

func build_input_tracker(p1_buf : Dictionary, p2_buf : Dictionary) -> void:
	generate_input_hud(p1_buf, ui_p1_inputs)
	generate_input_hud(p2_buf, ui_p2_inputs)


func move_inputs(fake_inputs : bool):
	super(fake_inputs)
	build_input_tracker(
		slice_input_dictionary(
			p1_inputs, max(0, p1_input_index - p1.input_buffer_len),
			p1_input_index + 1
		), slice_input_dictionary(
			p2_inputs, max(0, p2_input_index - p2.input_buffer_len),
			p2_input_index + 1
		)
	)


func create_inputs():
	p1_buttons = directional_inputs("first") + button_inputs("first", p1.BUTTONCOUNT)
	p2_buttons = directional_inputs("second") + button_inputs("second", p2.BUTTONCOUNT)

	if record:
		player_record_buffer.append(p2_buttons.duplicate())

	if not record and not replay and Input.is_action_just_pressed("training_replay"):
		replay = true

	if generate_prior_input_hash(p1_inputs) != generate_current_input_hash(
				p1_buttons, p1.BUTTONCOUNT):
		create_new_input_set(p1_inputs, p1_buttons)
		p1_input_index += 1
	else:
		increment_inputs(p1_inputs)

	if replay and record_buffer_current == len(player_record_buffer):
		replay = false
		record_buffer_current = 0

	if not replay:
		if (generate_prior_input_hash(p2_inputs) != generate_current_input_hash(
				p2_buttons, p2.BUTTONCOUNT)):
			create_new_input_set(p2_inputs, p2_buttons)
			p2_input_index += 1
		else:
			increment_inputs(p2_inputs)
	else:
		if (generate_prior_input_hash(p2_inputs) !=
					generate_current_input_hash(
							player_record_buffer[record_buffer_current], p2.BUTTONCOUNT)):
			create_new_input_set(p2_inputs, player_record_buffer[record_buffer_current])
			p2_input_index += 1
		else:
			increment_inputs(p2_inputs)
		record_buffer_current += 1


func game_function(delta):
	super(delta)
	if p1_reset_health_on_drop and not p2_combo:
		p1.health = p1_health_reset
	if p2_reset_health_on_drop and not p1_combo:
		p2.health = p2_health_reset


func _on_p1_health_reset_switch_toggled(toggled_on):
	p1_reset_health_on_drop = toggled_on


func _on_p1_health_reset_drag_ended(value_changed):
	if value_changed and p1_reset_health_on_drop:
		p1_health_reset = ui_p1_reset_health_slider.value


func _on_p2_health_reset_switch_toggled(toggled_on):
	p2_reset_health_on_drop = toggled_on


func _on_p2_health_reset_drag_ended(value_changed):
	if value_changed and p2_reset_health_on_drop:
		p2_health_reset = ui_p2_reset_health_slider.value


func _on_record_toggled(toggled_on):
	if toggled_on:
		player_record_buffer.clear()
		record_buffer_current = 0
	record = toggled_on


func _on_reset_button_up():
	get_tree().reload_current_scene()
