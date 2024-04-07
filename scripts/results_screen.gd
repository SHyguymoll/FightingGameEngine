class_name ResultsScreen
extends Control

signal choices_made

var active := false

enum Choice {
	REPLAY,
	CHARACTER_SELECT,
	MAIN_MENU,
}

var p1_choice_made := false
var p2_choice_made := false
var p1_choice := 0
var p2_choice := 0

@export var p1_choice_positions : Array[Vector2]
@export var p2_choice_positions : Array[Vector2]
@export var p1_select_icon : Node2D
@export var p2_select_icon : Node2D


func _physics_process(delta: float) -> void:
	if not active:
		return
	if Input.is_action_just_pressed("first_up") and not p1_choice_made:
		p1_choice -= 1
		if p1_choice == -1:
			p1_choice = len(p1_choice_positions) - 1
	if Input.is_action_just_pressed("first_down") and not p1_choice_made:
		p1_choice += 1
		if p1_choice == len(p1_choice_positions):
			p1_choice = 0
	if Input.is_action_just_pressed("first_button0"):
		p1_choice_made = true
	if Input.is_action_just_pressed("second_up") and not p2_choice_made:
		p2_choice -= 1
		if p2_choice == -1:
			p2_choice = len(p2_choice_positions) - 1
	if Input.is_action_just_pressed("second_down") and not p2_choice_made:
		p2_choice += 1
		if p2_choice == len(p2_choice_positions):
			p2_choice = 0
	if Input.is_action_just_pressed("second_button0"):
		p2_choice_made = true
	p1_select_icon.position = p1_select_icon.position.lerp(p1_choice_positions[p1_choice], 0.2)
	p2_select_icon.position = p2_select_icon.position.lerp(p2_choice_positions[p2_choice], 0.2)
	if p1_choice_made and p2_choice_made:
		active = false
		emit_signal("choices_made")
