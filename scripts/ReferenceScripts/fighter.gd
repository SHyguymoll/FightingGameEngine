class_name Fighter
extends CharacterBody3D

signal grabbed
signal grab_released
signal hitbox_created
signal projectile_created
signal audio_created
signal particle_created
signal dramatic_freeze_created
signal defeated

const INFINITE_STUN := -1

## This script holds the main components of a Fighter.[br]
## A Fighter has several variables and methods which are accessed and called by the game.[br]
## input_step() is called with the latest buffer of inputs.[br]
## damage_step() is called per each overlapping hitbox after handling inputs,
## with the details of the attack.[br]
## For safety, nothing should modify the fighter's state in _process, _physics_process,
## or _ready. _process and _physics_process are purely for real-time effects, and _ready for initialization.

@export_category("Gameplay Details")
@export var BUTTONCOUNT : int = 3
@export var JUST_PRESSED_BUFFER : int = 2
@export var start_x_offset : float = 2
@export var grabbed_offset : Vector3 = Vector3(-0.46, -0.87, 0)
@export var grab_point : GrabPoint # When the fighter is the grabber

@export_category("Fighter Details")
@export var char_name : String
@export var health : float

@export var ui_p1_under_health_scene : PackedScene
@export var ui_p1_sidebar_scene : PackedScene
@export var ui_p1_below_scene : PackedScene
@export var ui_p1_training_scene : PackedScene
@export var ui_p2_under_health_scene : PackedScene
@export var ui_p2_sidebar_scene : PackedScene
@export var ui_p2_below_scene : PackedScene
@export var ui_p2_training_scene : PackedScene

# play these to freeze the game for added drama.
@export var dramatic_freezes = {}

# Don't modify any of these, the game will initialize them.
var player : bool # True if player 1, False if player 2.
var distance : float # Ditto
var attack_connected : bool
var attack_hurt : bool
var grabbed_point : GrabPoint
var game_ended := false

# Extremely important, how the character stores the inputs from the game.
# Dictionary with 4 entries for each cardinal directional input, plus the number of buttons (buttonX).
# Each entry holds an array made up of tuples of a boolean and an int, representing how long the
# input was held/not held.
# Saved here as the alternative was moving potentially large blocks of data for many functions.
var inputs
var kback : Vector3 = Vector3.ZERO
var stun_time_start : int = 0
var stun_time_current : int = 0

var hitbox_layer : int
var input_buffer_len : int = 10 # Must be a positive number.
var ui_under_health : Node
var ui_sidebar : Node
var ui_below : Node
var ui_training : Node

func _initialize_hud_elements(training_mode : bool):
	if player:
		if ui_p1_under_health_scene:
			ui_under_health = ui_p1_under_health_scene.instantiate()
		if ui_p1_sidebar_scene:
			ui_sidebar = ui_p1_sidebar_scene.instantiate()
		if ui_p1_below_scene:
			ui_below = ui_p1_below_scene.instantiate()
		if training_mode and ui_p1_training_scene:
			ui_training = ui_p1_training_scene.instantiate()
	else:
		if ui_p2_under_health_scene:
			ui_under_health = ui_p2_under_health_scene.instantiate()
		if ui_p2_sidebar_scene:
			ui_sidebar = ui_p2_sidebar_scene.instantiate()
		if ui_p2_below_scene:
			ui_below = ui_p2_below_scene.instantiate()
		if training_mode and ui_p2_training_scene:
			ui_training = ui_p2_training_scene.instantiate()

func _connect_hud_elements(_training_mode : bool):
	pass

# Functions used by the game, mostly for checks
# the methods seen here are defined "virtually", as in, they are expected to be altered
# by extensions of this class.

func _do_intro() -> void:
	pass

func _post_intro() -> bool:
	return true


func _post_outro() -> bool:
	return true


func _in_defeated_state() -> bool:
	return true


func _in_outro_state() -> bool:
	return true


func _in_attacking_state() -> bool:
	return true


func _in_hurting_state() -> bool:
	return true


func _in_grabbed_state() -> bool:
	return true


func _return_attackers():
	return []


func _input_step() -> void:
	pass

func _action_step(_dramatic_freeze : bool) -> void:
	pass

# This is called when a hitbox makes contact with the other fighter, after resolving that the fighter
# was hit by the attack. An Array is passed for maximum customizability.
func _on_hit(_on_hit_data : Array):
# For this fighter, the on_hit and on_block arrays stores only the meter_gain, a float.
	pass

# Ditto, but for after resolving that the opposing fighter blocked the attack.
func _on_block(_on_block_data : Array):
	pass

# Only runs when a hitbox is overlapping.
# If attack is blocked, return false
# If attack isn't blocked, return true
func _damage_step(_attack : Hitbox, _combo_counter : int) -> bool:
	return true


func _initialize_boxes() -> void:
	if player:
		$Hurtbox.collision_mask = 2
		hitbox_layer = 4
	else:
		$Hurtbox.collision_mask = 4
		hitbox_layer = 2


func set_stun(value):
	stun_time_start = value
	GameGlobal.global_hitstop = int(abs(value)/4)
	stun_time_current = stun_time_start + 1 if stun_time_start != INFINITE_STUN else INFINITE_STUN


func reduce_stun():
	if stun_time_start != INFINITE_STUN:
		stun_time_current = max(0, stun_time_current - 1)

# useful button handling functions
func btn_state(input: String, ind: int):
	return inputs[input][ind]


func btn_pressed_ind(input: String, ind: int):
	return btn_state(input, ind)[1]


func btn_pressed(input: String):
	return btn_pressed_ind(input, -1)


func btn_just_pressed(input: String):
	return btn_pressed_ind_under_time(input, -1, JUST_PRESSED_BUFFER)


func btn_pressed_ind_under_time(input: String, ind: int, duration: int):
	return btn_state(input, ind)[0] < duration and btn_pressed_ind(input, ind)


func btn_held_over_time(input: String, duration: int):
	return btn_state(input, -1)[0] >= duration and btn_pressed(input)
