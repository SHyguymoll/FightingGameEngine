class_name Fighter
extends CharacterBody3D

var fighterName : String
var tscnFile : String
var charSelectIcon : String

const BUFFERSIZE = 10

@export var health : float
@export var walkSpeed : float

@export var GRAVITY : float
@export var MIN_FALL_VEL : float

var distance : float
var rightFacing : bool
var attackEnded : bool
var damageMultiplier : float
var defenseMultiplier : float
var knockbackHorizontal : float
var knockbackVertical : float

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
var state_current: states = states.idle

func update_state(new_state: states, reset_animation: bool):
	state_current = new_state
	if reset_animation:
		anim_timer = 0

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
# hitbox format:
#"<Name>":
#	{
#		"hitboxes": [<hitbox path>, ...],
#		"hurtboxes": [<hurtbox path>, ...],
#		"mode": either "add" or "set",
#		"extra": ... This one is up to whatever
#	}

var boxes = {}

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

func action():
	pass

func step():
	action()
	anim()
