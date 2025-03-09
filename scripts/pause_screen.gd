class_name PauseScreen
extends Control

signal exited

var active := false
var lock := true
var command_list_open := false

var p1_active := false
var p2_active := false
var p1_choice := 0
var p2_choice := 0

@export var p1_choice_positions : Array[Vector2]
@export var p2_choice_positions : Array[Vector2]
@export var p1_select_icon : Node2D
@export var p2_select_icon : Node2D
@export var main_screen : Control
@export var command_list_screen : Control
@export var cmd_list_p1_scroll : ScrollContainer
@export var cmd_list_p2_scroll : ScrollContainer
@export var p1_cmd_list : VBoxContainer
@export var p2_cmd_list : VBoxContainer

@onready var command_item = preload("res://scenes/FighterCommand.tscn")
@onready var input_icons := {
	"8" = preload("res://Content/Art/Menu/ButtonIcons/ArrowU.png"),
	"2" = preload("res://Content/Art/Menu/ButtonIcons/ArrowD.png"),
	"4" = preload("res://Content/Art/Menu/ButtonIcons/ArrowL.png"),
	"6" = preload("res://Content/Art/Menu/ButtonIcons/ArrowR.png"),
	"7" = preload("res://Content/Art/Menu/ButtonIcons/ArrowUL.png"),
	"9" = preload("res://Content/Art/Menu/ButtonIcons/ArrowUR.png"),
	"1" = preload("res://Content/Art/Menu/ButtonIcons/ArrowDL.png"),
	"3" = preload("res://Content/Art/Menu/ButtonIcons/ArrowDR.png"),

	"H8" = preload("res://Content/Art/Menu/ButtonIcons/ArrowHU.png"),
	"H2" = preload("res://Content/Art/Menu/ButtonIcons/ArrowHD.png"),
	"H4" = preload("res://Content/Art/Menu/ButtonIcons/ArrowHL.png"),
	"H6" = preload("res://Content/Art/Menu/ButtonIcons/ArrowHR.png"),
	"H7" = preload("res://Content/Art/Menu/ButtonIcons/ArrowHUL.png"),
	"H9" = preload("res://Content/Art/Menu/ButtonIcons/ArrowHUR.png"),
	"H1" = preload("res://Content/Art/Menu/ButtonIcons/ArrowHDL.png"),
	"H3" = preload("res://Content/Art/Menu/ButtonIcons/ArrowHDR.png"),

	"5" = preload("res://Content/Art/Menu/ButtonIcons/ArrowN.png"),
	"236" = preload("res://Content/Art/Menu/ButtonIcons/MotionQCF.png"),
	"214" = preload("res://Content/Art/Menu/ButtonIcons/MotionQCB.png"),
	"623" = preload("res://Content/Art/Menu/ButtonIcons/MotionDPF.png"),
	"421" = preload("res://Content/Art/Menu/ButtonIcons/MotionDPB.png"),
	"41236" = preload("res://Content/Art/Menu/ButtonIcons/MotionHCDF.png"),
	"63214" = preload("res://Content/Art/Menu/ButtonIcons/MotionHCDB.png"),
	"47896" = preload("res://Content/Art/Menu/ButtonIcons/MotionHCUF.png"),
	"69874" = preload("res://Content/Art/Menu/ButtonIcons/MotionHCUB.png"),

	"B0" = preload("res://Content/Art/Menu/ButtonIcons/Button0.png"),
	"B1" = preload("res://Content/Art/Menu/ButtonIcons/Button1.png"),
	"B2" = preload("res://Content/Art/Menu/ButtonIcons/Button2.png"),
	"B3" = preload("res://Content/Art/Menu/ButtonIcons/Button3.png"),
	"B4" = preload("res://Content/Art/Menu/ButtonIcons/Button4.png"),
	"B5" = preload("res://Content/Art/Menu/ButtonIcons/Button5.png"),
	"BA" = preload("res://Content/Art/Menu/ButtonIcons/ButtonAny.png"),

	"HB0" = preload("res://Content/Art/Menu/ButtonIcons/Button0H.png"),
	"HB1" = preload("res://Content/Art/Menu/ButtonIcons/Button1H.png"),
	"HB2" = preload("res://Content/Art/Menu/ButtonIcons/Button2H.png"),
	"HB3" = preload("res://Content/Art/Menu/ButtonIcons/Button3H.png"),
	"HB4" = preload("res://Content/Art/Menu/ButtonIcons/Button4H.png"),
	"HB5" = preload("res://Content/Art/Menu/ButtonIcons/Button5H.png"),
	"HBA" = preload("res://Content/Art/Menu/ButtonIcons/ButtonAnyH.png"),

	"AIR_OK" = preload("res://Content/Art/Menu/ButtonIcons/ModifierAirOK.png"),
	"AIR_ONLY" = preload("res://Content/Art/Menu/ButtonIcons/ModifierAirOnly.png"),
	"/" = preload("res://Content/Art/Menu/ButtonIcons/Or.png"),

	"?" = preload("res://Content/Art/Menu/ButtonIcons/InvalidInput.png"),
}

func create_input_texture_rect(texture : Texture2D) -> TextureRect:
	var new_input := TextureRect.new()
	new_input.texture = texture
	return new_input


func create_commands(inputs : String) -> Array[TextureRect]:
	var last_was_button := false
	var input_held := false
	var commands_final : Array[TextureRect] = []
	var inputs_patterns : String = ""
	for character in inputs:
		if character == "/":
			inputs_patterns += " /"
			continue
		if not last_was_button:
			match character:
				"[":
					if input_held:
						inputs_patterns += " ?"
					else:
						inputs_patterns += " H_S"
						input_held = true
				"]":
					if not input_held:
						inputs_patterns += " ?"
					else:
						inputs_patterns += " H_E"
						input_held = false
				"B":
					last_was_button = true
				"1", "2", "3", "4", "5", "6", "7", "8", "9":
					inputs_patterns += " " + character
				"J":
					inputs_patterns += " AIR_ONLY"
				"j":
					inputs_patterns += " AIR_OK"
				_:
					inputs_patterns += " ?"
		else:
			match character:
				"0", "1", "2", "3", "4", "5", "A":
					inputs_patterns += " B" + character
				_:
					inputs_patterns += " ?"
			last_was_button = false
	# if input_held is true after iterating through the string, a hold was never escaped,
	# so break them all on purpose to maximize the possibility of the creator seeing it
	if input_held:
		inputs_patterns = inputs_patterns.replace("H_S", "?")
	# replace empty holds with more question marks
	inputs_patterns = inputs_patterns.replace("H_S H_E", "?")
	# split by holds
	var final_input_string := ""
	var hold_starts := inputs_patterns.split("H_S")
	if len(hold_starts) > 1: #if there's more than one item (meaning a split was found)
		for hold_start in hold_starts:
			if hold_start.strip_edges() == "":
				continue
			var hold_ends := hold_start.split("H_E") #then split on the ends too.
			for held in hold_ends[0].split(" "): #for each input in the held section,
				if held.strip_edges() == "":
					continue
				if held == "5":
					final_input_string += "? "
				else:
					final_input_string += "H" + held + " " #append H to it and add it to the final string
			if len(hold_ends) > 1:
				final_input_string += hold_ends[1] #then just add the rest of the string in
	else:
		final_input_string += hold_starts[0]
	# reduce spaces
	final_input_string = final_input_string.strip_edges()
	while final_input_string.contains("  "):
		final_input_string = final_input_string.replace("  ", " ")
	# group certain series of inputs into motions, from most complex to least
	final_input_string = final_input_string.replace("4 1 2 3 6", "41236")
	final_input_string = final_input_string.replace("6 3 2 1 4", "63214")
	final_input_string = final_input_string.replace("4 7 8 9 6", "47896")
	final_input_string = final_input_string.replace("6 9 8 7 4", "69874")
	final_input_string = final_input_string.replace("2 3 6", "236")
	final_input_string = final_input_string.replace("2 1 4", "214")
	final_input_string = final_input_string.replace("6 2 3", "623")
	final_input_string = final_input_string.replace("4 2 1", "421")
	# finally, actually making the command's inputs
	for input in final_input_string.split(" "):
		commands_final.append(create_input_texture_rect(input_icons[input]))
	return commands_final

func make_command_list(p1 : Fighter, p2 : Fighter):
	for command in p1.command_list:
		var command_split := command.split("|", true, 2)
		var new_command : FighterCommand = command_item.instantiate()
		new_command.title = command_split[0]
		new_command.description = command_split[2]
		new_command.inputs = create_commands(command_split[1])
		p1_cmd_list.add_child(new_command)
	for command in p2.command_list:
		var command_split := command.split("|", true, 2)
		var new_command : FighterCommand = command_item.instantiate()
		new_command.title = command_split[0]
		new_command.description = command_split[2]
		new_command.inputs = create_commands(command_split[1])
		p2_cmd_list.add_child(new_command)


func _physics_process(_delta: float) -> void:
	if command_list_open:
		main_screen.visible = false
		command_list_screen.visible = true
	else:
		main_screen.visible = true
		command_list_screen.visible = false

	if not active:
		return
	if lock:
		lock = false
		return
	if Input.is_action_just_pressed("first_up") and p1_active and not command_list_open:
		p1_choice -= 1
		if p1_choice == -1:
			p1_choice = len(p1_choice_positions) - 1
	if Input.is_action_just_pressed("first_down") and p1_active and not command_list_open:
		p1_choice += 1
		if p1_choice == len(p1_choice_positions):
			p1_choice = 0
	if Input.is_action_just_pressed("first_button0") and p1_active and not command_list_open:
		if p1_choice == 0:
			command_list_open = true
			cmd_list_p1_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
			cmd_list_p2_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
		else:
			if get_tree().change_scene_to_file("res://scenes/Menu.tscn"):
				push_error("menu failed to load")
	if Input.is_action_just_pressed("first_pause") and p1_active:
		lock = true
		command_list_open = false
		cmd_list_p1_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cmd_list_p2_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		emit_signal("exited")
	if Input.is_action_just_pressed("second_up") and p2_active and not command_list_open:
		p2_choice -= 1
		if p2_choice == -1:
			p2_choice = len(p2_choice_positions) - 1
	if Input.is_action_just_pressed("second_down") and p2_active and not command_list_open:
		p2_choice += 1
		if p2_choice == len(p2_choice_positions):
			p2_choice = 0
	if Input.is_action_just_pressed("second_button0") and p2_active and not command_list_open:
		if p2_choice == 0:
			command_list_open = true
			cmd_list_p1_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
			cmd_list_p2_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
		else:
			if get_tree().change_scene_to_file("res://scenes/Menu.tscn"):
				push_error("menu failed to load")
	if Input.is_action_just_pressed("second_pause") and p2_active:
		lock = true
		command_list_open = false
		cmd_list_p1_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cmd_list_p2_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		emit_signal("exited")
	p1_select_icon.position = p1_select_icon.position.lerp(p1_choice_positions[p1_choice], 0.2)
	p2_select_icon.position = p2_select_icon.position.lerp(p2_choice_positions[p2_choice], 0.2)
