class_name Fighter
extends CharacterBody3D

var fighterName : String
var tscnFile : String
var charSelectIcon : String

var input_buffer_len : int

@export var health : float
@export var walkSpeed : float

@export var gravity : float
@export var min_fall_vel : float

var distance : float
var right_facing : bool
var attack_ended : bool
var damage_mult : float
var defense_mult : float
var kback_hori : float
var kback_vert : float

var start_x_offset : float
const BUTTONCOUNT = 4

#State transitions are handled by a FSM implemented as match statements
enum states {
	intro, round_win, set_win, #round stuff
	idle, crouch, #basic basics
	walk_forward, walk_back, #lateral movement
	jump_forward, jump_neutral, jump_back, #aerial movement
	attack, post_attack, #handling attacks
	block_high, block_low, get_up, #handling getting attacked well
	hurt_high, hurt_low, hurt_crouch, #not handling getting attacked well
	hurt_fall, hurt_lie, hurt_bounce, #REALLY not handling getting attacked well
	}
var state_start: states = states.idle
var state_current: states

func update_state(new_state: states, new_animation_timer: int):
	state_current = new_state
	if new_animation_timer != -1:
		anim_timer = new_animation_timer

# attack format:
#"<Name>":
#	{
#		"damage": <damage>,
#		"type": "<hit location>",
#		"kb_hori": <horizontal knockback value>,
#		"kb_vert": <vertical knockback value>,
#		"hitboxes": "<hitbox set name>",
#		"extra": ... This one is up to whatever
#	}

var attacks = {}

# Animations are handled manually and controlled by the game engine during the physics_process step.
# Therefore, all animations top out at 60 FPS, which is a small constraint for now.
# animation format:
#"<Name>":
#	{
#		"animation_length": <value>,
#		<frame_number>: [<animation frame x>, <animation frame y>], ...,
#		"extra": ... This one is up to whatever
#	}

var animations = {}

var current_animation: String
var anim_timer = 0

func anim():
	pass

# Hitboxes and Hurtboxes are handled through a dictionary for easy reuse.
# box format:
#"<Name>":
#	{
#		"boxes": [<path>, ...],
#		"mode": either "add" or "set",
#		"extra": ... This one is up to whatever
#	}

#TODO: hitboxes
var hitboxes = {}

#TODO: hurtboxes
var hurtboxes = {}

var tooClose = false

enum inputs {Up = 1, Down = 2, Left = 4, Right = 8, A = 16, B = 32, C = 64}

func decodeHash(inputHash: int) -> Array:
	var decodedHash = [false, false, false, false, false, false, false, false]
	var inpVal = inputs.values()
	for i in range(BUTTONCOUNT + 3,-1,-1): #arrays start at 0, so everything is subtracted by 1 (4 directions -> 3)
		if inputHash >= inpVal[i]:
			inputHash -= inpVal[i]
			decodedHash[i] = true
	return decodedHash

func action(inputs):
	pass

func step(inputs):
	action(inputs)
	anim()
