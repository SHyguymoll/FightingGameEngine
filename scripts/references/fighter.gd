class_name Fighter
extends CharacterBody3D

## Common requirements for a valid fighter in OFGE. Please extend off of this class.
##
## This script holds the main components of a Fighter, as well as some extra helpers.[br]
## A Fighter has several variables and methods which are accessed and called by the game.[br]
## _damage_step() is called per each overlapping hitbox before handling inputs,
## with the details of the attack.[br]
## _input_step() is called with the latest buffer of inputs.[br]
## _action_step() is called right after in order to process state changes.
## For safety, nothing should modify the fighter's state in _process, _physics_process,
## or _ready. _process and _physics_process are purely for real-time effects,
## and _ready for initialization.[br]

@warning_ignore_start("unused_signal")
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
## This signal is fired when using the fighter's custom camera for specific moments.[br]
## The int represents how many game ticks the custom camera will be used for.
signal activated_camera(length: int, camera : Camera3D)
## This signal is fired for registering dramatic freezes in the game's scene tree.
## The game will also enter the dramatic freeze moment for the duration of the dramatic freeze.
signal dramatic_freeze_created
## This signal is fired when the Fighter is defeated.
signal defeated
@warning_ignore_restore("unused_signal")

# the motion input stuff is here to make the documentation render correctly.
## Infinite Stun constant, just -1.
## Avoid using infinite stun unless you are ABSOLUTELY SURE that it is applicable.[br]
## --------------------------------------------------------------------------------[br]
## Motion inputs, with some leniency built in, for usage in [method motion_input_check].[br]
## For more specific inputs, I recommend following the naming convention shown here.
const INFINITE_STUN := -1

## Quarter Circle Forward.
const MOTION_QCF = [[2,3,6], [2,6]]

## Quarter Circle Back.
const MOTION_QCB = [[2,1,4], [2,4]]

## Quarter Circle Forward and then Up+Forward.[br]
## The name is a reference to the Street Fighter 2 input [url]https://glossary.infil.net/?t=Tiger%20Knee[/url].
const MOTION_TKF = [[2,3,6,9]]
## Quarter Circle Back and then Up+Back.

const MOTION_TKB = [[2,1,4,7]]

## Forward, then Down, then Down+Forward.[br]
## Due to the nature of this input, multiple cases have been included for brevity and lenience.
const MOTION_ZFORWARD = [[6,2,3], #canonical
	[6,5,2,3], #forward then down
	[6,2,3,6], #overshot a little
	[6,3,2,3], #rolling method
	[6,3,2,1,2,3], #super rolling method
	[6,5,1,2,3], #forward to two away from a half circle
	[6,5,4,1,2,3], #forward to one away from a half circle
	[6,5,4,1,2,3,6], #forward to a half circle, maximumly lenient
]

## Back, then Down, then Down+Back.
const MOTION_ZBACK = [[4,2,1], [4,5,2,1], [4,1,2,3],
	[4,1,2,3,2,1], [4,5,3,2,1], [4,5,6,3,2,1], [4,5,6,3,2,1,4],
]

## Half Circle Forward.
## NOTE: This input may overlay with [member MOTION_ZFORWARD]. Make sure to check between the two.
const MOTION_HCF = [[4,2,6], [4,2,3,6], [4,1,2,6], [4,1,2,3,6]]

## Half Circle Back.
## NOTE: This input may overlay with [member MOTION_ZBACK]. Make sure to check between the two.
const MOTION_HCB = [[6,2,4], [6,3,2,4], [6,2,1,4], [6,3,2,1,4]]

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
## The number of frames in which a direction in a motion input can be held.
@export var mtn_input_lenience : int
## An array of commands that the Fighter has. Use for listing attacks, special details, etc. [br]
## Format: <Command Name>|[Command Input]|[Command Description][br]
## Command Input Details: Directions are rendered with numpad notation. Multiple inputs for the
## same command are separated with a forward slash.[br]
## Certain combinations of inputs can be rendered with one icon (236 as a quarter circle forward,
## [4] as a held back, etc.)
## Button imputs are rendered with BX, where X is a value from 0 to 5, or A for any.[br]
## Certain "tags" can be added to the end of the input (J for airborne, O for attacks that can hurt
## on-the-ground opponents, etc.)[br]
## The Command Description uses a RichTextLabel, so BBCode is supported.
@export var command_list : Array[String]

## Used when the Fighter has a facing direction, can be pinned to a value if not necessary.
var right_facing : bool

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

## The Camera3D node that the fighter uses for specific circumstances. Not meant to be altered
## after being set
@export var custom_camera : Camera3D

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
## This is set to true when the OTHER Fighter is touching the edge of the Stage,
## as handled by the game.
var opponent_on_stage_edge : bool
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
## This is set when the game ends, either through a Fighter signalling that they've been defeated, or through the timer running out.
var game_ended : GameEnds = GameEnds.NO

enum GameEnds {
	NO,
	WIN_TIME,
	LOSE_TIME,
	WIN_KO,
	LOSE_KO,
}
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

## Walking across the screen (referred to as the x direction)
enum WalkingX {BACK = -1, NEUTRAL = 0, FORWARD = 1}

## Walking into/out of the screen (referred to as the z direction)
enum WalkingZ {IN = 1, NEUTRAL = 0, OUT = 1}

## The knockback applied to a Fighter. Typically set by hitboxes through [member Hitbox.kback_hit]
## and [member Hitbox.kback_block] during [method _damage_step],
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

## Do whatever it takes to end the intro early (make _post_intro_true)
func _skip_intro() -> void:
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

## Returns based on if the Fighter is in a "Neutral" state.[br]
## That is, the state that the Fighter rests in when no action is imposed upon it.
func _in_neutral_state() -> bool:
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

## Returns a two element array for the given [param input] and [param ind],
## with the format (int, bool).[br]
## The int represents the length of time that the button has been pressed/unpressed.[br]
## The bool represents if the button was pressed or unpressed.
func btn_state(input: String, ind: int):
	if abs(ind) > len(inputs[GameGlobal.BTN_UP]):
		return [0, false]
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

## Returns the currently held joystick input as a simple number between 1 and 9:[br]
## 7 (up + back) 8 (up) 9 (up + forward)[br]
## 4 (back) 5 (neutral) 6 (forward)[br]
## 1 (down + back) 2 (down) 3 (down + forward)[br]
## Also known as Numpad Notation.
func directions_as_numpad(up, down, back, forward) -> int:
	if up:
		if back and right_facing or forward and not right_facing:
			return 7
		if forward and right_facing or back and not right_facing:
			return 9
		return 8
	if down:
		if back and right_facing or forward and not right_facing:
			return 1
		if forward and right_facing or back and not right_facing:
			return 3
		return 2
	if back and right_facing or forward and not right_facing:
		return 4
	if forward and right_facing or back and not right_facing:
		return 6
	return 5

## Returns the input variable as an array of ints between 1 and 9.[br]
## if timing is true, this also uses mtn_input_lenience to introduce lenience.
func inputs_as_numpad(timing := true) -> Array:
	var numpad_buffer = []
	for i in range(max(0, len(inputs.up) - 2)):
		numpad_buffer.append(directions_as_numpad(btn_pressed_ind("up", i),
			btn_pressed_ind("down", i),
			btn_pressed_ind("left", i),
			btn_pressed_ind("right", i)))
	if max(0, len(inputs.up) - 2) == 0:
		return [5]
	if timing:
		numpad_buffer.append(directions_as_numpad(
			btn_pressed_ind_under_time("up", -2, mtn_input_lenience),
			btn_pressed_ind_under_time("down", -2, mtn_input_lenience),
			btn_pressed_ind_under_time("left", -2, mtn_input_lenience),
			btn_pressed_ind_under_time("right", -2, mtn_input_lenience)))
	else:
		numpad_buffer.append(directions_as_numpad(btn_pressed_ind("up", -2),
			btn_pressed_ind("down", -2),
			btn_pressed_ind("left", -2),
			btn_pressed_ind("right", -2)))
	return numpad_buffer

## Checks if an attempted motion string is valid.[br]
## Relies on the stored joystick values in input.
func motion_input_check(motions_to_check) -> bool:
	var buffer_as_numpad = inputs_as_numpad()
	for motion_to_check in motions_to_check:
		var buffer_sliced = buffer_as_numpad.slice(
			len(buffer_as_numpad) - len(motion_to_check))
		if buffer_sliced == motion_to_check:
			return true
	return false
