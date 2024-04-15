class_name Fighter
extends CharacterBody3D

## The most basic requirements for a valid fighter in OFGE. Please extend off of this class.
##
## This script holds the main components of a Fighter.[br]
## A Fighter has several variables and methods which are accessed and called by the game.[br]
## _damage_step() is called per each overlapping hitbox before handling inputs,
## with the details of the attack.[br]
## _input_step() is called with the latest buffer of inputs.[br]
## _action_step() is called right after in order to process state changes.
## For safety, nothing should modify the fighter's state in _process, _physics_process,
## or _ready. _process and _physics_process are purely for real-time effects,
## and _ready for initialization.

## When the Fighter is grabbed in the damage step, this signal should fire to start the grab logic.
signal grabbed
## When the Fighter finishes a grab, this signal is fired to release the other Fighter.
signal grab_released
## This signal is fired for registering hitboxes in the game's scene tree.
signal hitbox_created
## This signal is fired for registering projectiles in the game's scene tree.
signal projectile_created
## This signal is fired for spawning audio events in the game's scene tree.
signal audio_created
## This signal is fired for registering particles in the game's scene tree.
signal particle_created
## This signal is fired for registering dramatic freezes in the game's scene tree.
## The game will also enter the dramatic freeze moment for the duration of the dramatic freeze.
signal dramatic_freeze_created
## This signal is fired when the Fighter is defeated.
signal defeated

## Infinite Stun constant, just -1.
## Avoid using infinite stun unless you are ABSOLUTELY SURE that it is applicable.
const INFINITE_STUN := -1

@export_category("Gameplay Details")
## The number of buttons that the Fighter uses. Can be any number from 0 to 6.
@export var BUTTONCOUNT : int
## The number of frames under which an input would be considered to be "just" pressed.
## Increase this number for more leniency with immediate inputs.
@export var JUST_PRESSED_BUFFER : int
## The distance from the middle of the stage that the Fighter starts at.
@export var start_x_offset : float
## The offset applied to the Fighter when the Fighter is grabbed.
@export var grabbed_offset : Vector3
## A reference to the Fighter's GrabPoint node, used for when the Fighter grabs the opponent.
@export var grab_point : GrabPoint

@export_category("Fighter Details")
## The name of the Fighter. Supports Unicode.
@export var char_name : String
## The quote that the Fighter says when they win. Supports Unicode.
@export var win_quote : String
## The health of the Fighter. Typically a round number, like 100 or 420.
@export var health : float
## How many inputs are held by the fighter within inputs at once. Must be a positive integer.
@export var input_buffer_len : int

@export_category("UI Details")
# ui stuff, names explain positioning, separated into p1 and p2 for simplicity
## The scene that holds the ui for the Fighter located
## under the health bar on the player 1 side.
@export var ui_p1_under_health_scene : PackedScene
## Ditto,
## on the far side of the screen on the player 1 side.
@export var ui_p1_sidebar_scene : PackedScene
## Ditto,
## at the bottom of the screen on the player 1 side.
@export var ui_p1_below_scene : PackedScene
## Ditto,
## at the bottom of the screen in training mode on the player 1 side.
@export var ui_p1_training_scene : PackedScene
## Ditto,
## under the health bar on the player 2 side.
@export var ui_p2_under_health_scene : PackedScene
## Ditto,
## at the bottom of the scree on the player 2 side.
@export var ui_p2_sidebar_scene : PackedScene
## Ditto,
## on the far side of the screen on the player 2 side.
@export var ui_p2_below_scene : PackedScene
## Ditto,
## at the bottom of the screen in training mode on the player 2 side.
@export var ui_p2_training_scene : PackedScene
## Used with the appropiate scene during [method _initialize_hud_elements] to store the loaded scene.
## Also acts as a helpful reference for updating the ui.
var ui_under_health : Node
## Ditto.
var ui_sidebar : Node
## Ditto.
var ui_below : Node
## Ditto.
var ui_training : Node

# play these to freeze the game for added drama.
## A simple dictionary used for holding Dramatic Freezes. How you index them is up to you.
@export var dramatic_freezes = {}

# Don't modify any of these, the game will initialize them.
## [color=red] DO NOT TOUCH. [/color] a boolean used for differentiating player 1 and player 2.
## True if player 1 and False if player 2.
var player : bool # True if player 1, False if player 2.
## [color=red] DO NOT TOUCH. [/color] The calculated distance between
## this Fighter and the other Fighter.
## This number will be negative if this Fighter is on the left of the other Fighter,
## Positive if this Fighter is on the right of the other Fighter, or 0.
var distance : float # Ditto
## [color=red] DO NOT TOUCH. [/color]
## This is set to true when an attack from this Fighter connects with the other Fighter.
var attack_connected : bool
## [color=red] DO NOT TOUCH. [/color]
## This is set to true when an attack from this Fighter hurts the other Fighter.
var attack_hurt : bool
## [color=red] DO NOT TOUCH. [/color]
## This is set to the other Fighter's GrabPoint for grabbing logic.
var grabbed_point : GrabPoint
## [color=red] DO NOT TOUCH. [/color]
## This is set to true when the game ends, either through a Fighter signalling that they've been defeated, or through the timer running out.
var game_ended := false

## [color=red] DO NOT TOUCH. [/color] Extremely important, how the character stores the inputs from the game.[br]
## Dictionary with 4 entries for each cardinal directional input, plus the number of buttons (buttonX).[br]
## Each entry holds an array made up of tuples of a boolean and an int, representing how long the
## input was held/not held. [br]
## Saved here as the alternative was long reference bouncing for large blocks of data.[br]
## The values here can be accessed by [method btn_state], and can be logically deduced with
## [method btn_pressed_ind], [method btn_pressed], [method btn_just_pressed],
## [method btn_just_pressed_under_time], and [method btn_held_over_time].
var inputs
## [color=red] DO NOT TOUCH. [/color] The hitbox layer used by this Fighter,
## automatically set with [method _initialize_boxes].
var hitbox_layer : int
## [color=red] DO NOT TOUCH. [/color] Set by [method _update_paused] when the game pausees/unpauses.
var paused := false

## The knockback applied to a Fighter. Typically set by hitboxes through [member Hitbox.hitstop_hit]
## and [member Hitbox.hitstop_block] during [method _damage_step],
## but can be modified by the Fighter as deemed appropiate.
var kback : Vector3 = Vector3.ZERO
## The current remaining duration for being stunned. Used for calculating combos. Only set this
## through the [method set_stun] function.
var stun_time_start : int = 0
## The total duration for being stunned. Details are ditto with [member stun_time_start].
var stun_time_current : int = 0

## [color=red] DO NOT TOUCH. [/color] Used to logically initialize the ui depending on the scenes
## stored in the ui variables.
func _initialize_hud_elements(training_mode : bool) -> void:
	if player:
		if ui_p1_under_health_scene:
			ui_under_health = ui_p1_under_health_scene.instantiate()
		if ui_p1_sidebar_scene:
			ui_sidebar = ui_p1_sidebar_scene.instantiate()
		if ui_p1_below_scene:
			ui_below = ui_p1_below_scene.instantiate()
		if ui_p1_training_scene and training_mode:
			ui_training = ui_p1_training_scene.instantiate()
	else:
		if ui_p2_under_health_scene:
			ui_under_health = ui_p2_under_health_scene.instantiate()
		if ui_p2_sidebar_scene:
			ui_sidebar = ui_p2_sidebar_scene.instantiate()
		if ui_p2_below_scene:
			ui_below = ui_p2_below_scene.instantiate()
		if ui_p2_training_scene and training_mode:
			ui_training = ui_p2_training_scene.instantiate()

## Used to connect the hud elements to the Fighter's logic through signals.
func _connect_hud_elements(_training_mode : bool) -> void:
	pass


## Called in the intro moment of the game for running intro animations.
func _do_intro() -> void:
	pass

## Checked until both Fighters have completed their intros.
func _post_intro() -> bool:
	return true

## Checked until both Fighters have completed their outros.
func _post_outro() -> bool:
	return true

## Returns based on if this Fighter has completed its defeat animation.
func _in_defeated_state() -> bool:
	return true

## Returns based on if this Fighter has completed its outro animation.
func _in_outro_state() -> bool:
	return true

## Returns based on if this Fighter is attacking. Used for determining counter-hits, punishes, etc.
func _in_attacking_state() -> bool:
	return true

## Returns based on if the Fighter is "hurting", typically meaning that they have been struck by an
## attack and is still immobilized by it.
func _in_hurting_state() -> bool:
	return true

## Returns based on if the Fighter has been grabbed.
func _in_grabbed_state() -> bool:
	return true

## Returns an array of Hitboxes which are colliding with the Fighter's hurtbox(es).
func _return_attackers() -> Array[Hitbox]:
	return []

## The step taken after the damage step, used for determining what is done with recieved inputs.
## This step is not affected by active Dramatic Freezes.
func _input_step() -> void:
	pass

## The step taken after the input step, used for altering the Fighter's state. This step is affected
## by active Dramatic Freezes, hence the [param _dramatic_freeze] parameter.
func _action_step(_dramatic_freeze : bool, _delta : float) -> void:
	pass

## This is called when a hitbox makes contact with the other fighter, after resolving that the fighter
## was hit by the attack. An Array is passed for maximum customizability.
func _on_hit(_on_hit_data : Array) -> void:
	pass

## Ditto, but for after resolving that the opposing fighter blocked the attack.
func _on_block(_on_block_data : Array) -> void:
	pass

## The first step ran by the Fighter, if [method _return_attackers] returned at least one Hitbox.
## Holds a reference to that Hitbox in [param _attack],
## as well as the current state of the combo counter.
func _damage_step(_attack : Hitbox, _combo_counter : int) -> bool:
	return true

## Used to initialize the Hurtboxes for the Fighter.[br]
## Player 1 ([member player] is True): Hurtbox Collision Masks = 2, [member hitbox_layer] = 4.
## Player 2 ([member player] is False): Hurtbox Collision Masks = 4, [member hitbox_layer] = 2.
func _initialize_boxes() -> void:
	if player:
		$Hurtbox.collision_mask = 2
		hitbox_layer = 4
	else:
		$Hurtbox.collision_mask = 4
		hitbox_layer = 2

## Used to set the stun of the Fighter,
## typically from [member Hitbox.stun_hit] or [member Hitbox.stun_block].
func set_stun(value) -> void:
	stun_time_start = value
	stun_time_current = stun_time_start + 1 if stun_time_start != INFINITE_STUN else INFINITE_STUN

## Used to reduce the stun of the Fighter, typically while the Fighter is hurting or blocking.
func reduce_stun() -> void:
	if stun_time_start != INFINITE_STUN:
		stun_time_current = max(0, stun_time_current - 1)

## Used to update the paused variable. Override as needed.
func update_paused(new_paused : bool):
	paused = new_paused

## Returns a tuple for the given [param input] and [param ind]. with the format (int, bool).[br]
## The int represents the length of time that the button has been pressed/unpressed.[br]
## The bool represents if the button was pressed or unpressed.
func btn_state(input: String, ind: int):
	return inputs[input][ind]

## Returns the boolean from the tuple for the given [param input] and [param ind].
## Akin to [method Input.is_action_pressed] for a specific timeframe.
func btn_pressed_ind(input: String, ind: int) -> bool:
	return btn_state(input, ind)[1]

## Returns the boolean from the tuple for the given [param input] and the latest input.
## Akin to [method Input.is_action_pressed] for the current timeframe.
func btn_pressed(input: String) -> bool:
	return btn_pressed_ind(input, -1)

## Returns the boolean from the tuple for the given [param input] and the latest input.
## Akin to [method Input.is_action_just_pressed], but can be made more lenient through
## [member JUST_PRESSED_BUFFER].
func btn_just_pressed(input: String) -> bool:
	return btn_pressed_ind_under_time(input, -1, JUST_PRESSED_BUFFER)

## Returns the boolean from the tuple for the given [param input] and the latest input, if the
## button was pressed for less frames than under the given [param duration].
## Otherwise, it will always return False.
func btn_pressed_ind_under_time(input: String, ind: int, duration: int) -> bool:
	return btn_state(input, ind)[0] < duration and btn_pressed_ind(input, ind)

## Returns the boolean from the tuple for the given [param input] and the latest input, if the
## button was pressed for more/the same number of frames than the given [param duration].
## Otherwise, it will always return False.
func btn_held_over_time(input: String, duration: int) -> bool:
	return btn_state(input, -1)[0] >= duration and btn_pressed(input)
