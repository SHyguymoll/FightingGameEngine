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

func _physics_process(delta: float) -> void:
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
