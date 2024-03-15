class_name State2DMeterFighter
extends Fighter

## This script defines a FSM-based Fighter with the following features:
## 2D Movement[br]
## Dashing[br]
## Jump-Cancelling[br]
## The Magic Series (Stronger Attacks Cancel Weaker Attacks)[br]
## Special Cancelling (and Super Cancelling)[br]
## Super Meter[br]

## State transitions are handled by a FSM implemented as match statements in the input_step.
enum States {
	INTRO, ROUND_WIN, SET_WIN, # round stuff
	IDLE, CRCH, # basic basics
	WALK_F, WALK_B, DASH_F, DASH_B, # lateral movement
	JUMP_L_I, JUMP_N_I, JUMP_R_I, # jump from ground initial
	JUMP_L_A_I, JUMP_N_A_I, JUMP_R_A_I, # jump from air initial
	JUMP_L, JUMP_N, JUMP_R, # aerial actionable
	JUMP_L_NO_ACT, JUMP_N_NO_ACT, JUMP_R_NO_ACT, # aerial not actionable
	ATCK_NRML, ATCK_CMND, ATCK_MOTN, ATCK_GRAB, ATCK_JUMP, ATCK_SUPR, # attacking
	BLCK_HGH, BLCK_LOW, BLCK_AIR, GET_UP, # handling getting attacked well
	HURT_HGH, HURT_LOW, HURT_CRCH, HURT_GRB, # not handling getting attacked well
	HURT_FALL, HURT_LIE, HURT_BNCE, # REALLY not handling getting attacked well
	OUTRO_FALL, OUTRO_LIE, OUTRO_BNCE # The final stage of not handling it
}

enum AVEffects {ADD = 0, SET = 1, SET_X = 2, SET_Y = 3, EXPEDIATE = 4}

enum WalkDirections {BACK = -1, NEUTRAL = 0, FORWARD = 1}

const DASH_INPUT_LENIENCY : int = 15
const MOTION_INPUT_LENIENCY : int = 12
# motion inputs, with some leniency
const QUARTER_CIRCLE_FORWARD = [[2,3,6], [2,6]]
const QUARTER_CIRCLE_BACK = [[2,1,4], [2,4]]
# Referencing the Street Fighter 2 input
const TIGER_KNEE_FORWARD = [[2,3,6,9]]
const TIGER_KNEE_BACK = [[2,1,4,7]]
const Z_MOTION_FORWARD = [
	[6,2,3], #canonical
	[6,5,2,3], #forward then down
	[6,2,3,6], #overshot a little
	[6,3,2,3], #rolling method
	[6,3,2,1,2,3], #super rolling method
	[6,5,1,2,3], #forward to two away from a half circle
	[6,5,4,1,2,3], #forward to one away from a half circle
	[6,5,4,1,2,3,6], #forward to a half circle, maximumly lenient
]
const Z_MOTION_BACK = [
	[4,2,1],
	[4,5,2,1],
	[4,1,2,3],
	[4,1,2,3,2,1],
	[4,5,3,2,1],
	[4,5,6,3,2,1],
	[4,5,6,3,2,1,4],
]
# Name is a reference to the common Guilty Gear Overdrive input of a half circle back to forward
const GG_INPUT = [
	[6,3,2,1,4,6],
	[6,3,2,1,4,5,6],
	[6,2,1,4,6],
	[6,2,4,6],
	[6,2,4,5,6],
	[6,2,1,4,5,6],
]

const GRABBED_OFFSET_X = 0.46

@onready var _animate := $AnimationPlayer
var basic_anim_state_dict := {
	States.INTRO : "other/intro",
	States.ROUND_WIN : "other/win",
	States.SET_WIN : "other/win",
	States.IDLE : "basic/idle",
	States.CRCH : "basic/crouch",
	States.JUMP_R_I : "basic/jump", States.JUMP_L_I : "basic/jump",
	States.JUMP_N_I : "basic/jump",
	States.JUMP_R_A_I : "basic/jump", States.JUMP_L_A_I : "basic/jump",
	States.JUMP_N_A_I : "basic/jump",
	States.JUMP_R : "basic/jump", States.JUMP_L : "basic/jump",
	States.JUMP_N : "basic/jump",
	States.JUMP_R_NO_ACT : "basic/jump", States.JUMP_L_NO_ACT : "basic/jump",
	States.JUMP_N_NO_ACT : "basic/jump",
	States.BLCK_HGH : "blocking/high", States.BLCK_LOW : "blocking/low",
	States.BLCK_AIR : "blocking/air",
	States.HURT_HGH : "hurting/high", States.HURT_LOW : "hurting/low",
	States.HURT_CRCH : "hurting/crouch",
	States.HURT_GRB : "hurting/air",
	States.HURT_FALL : "hurting/air", States.HURT_BNCE : "hurting/air",
	States.HURT_LIE : "hurting/lying", States.GET_UP : "hurting/get_up",
	States.OUTRO_FALL : "hurting/air", States.OUTRO_BNCE : "hurting/air",
	States.OUTRO_LIE : "hurting/lying",
}
var animation_ended = true
var move_left_anim : StringName = &"basic/walk_left"
var move_right_anim : StringName = &"basic/walk_right"
var dash_left_anim : StringName = &"basic/dash"
var dash_right_anim : StringName = &"basic/dash"

var walk_speed : float = 2
var jump_total : int = 2
var jump_height : float = 11
var gravity : float = -0.5
var min_fall_vel : float = -6.5
var GROUND_SLIDE_FRICTION : float = 0.97
var meter : float = 0
var METER_MAX : float = 100
var damage_mult : float = 1.0
var defense_mult : float = 1.0
## block rule arrays: [up, down, away, towards]
## 1 means must hold, 0 means ignored, -1 means must not hold
var block : Dictionary = {
	away_any = [0, 0, 1, -1],
	away_high = [0, -1, 1, -1],
	away_low = [-1, 1, 1, -1],
	nope = [-1, -1. -1, -1],
}

var record_y : float
var check_true : bool # Used to remember results of move_and_slide()
var right_facing : bool
var jump_count : int = 0

@onready var hitboxes = {
	"stand_a": preload("scenes/hitboxes/stand/a.tscn"),
	"stand_b": preload("scenes/hitboxes/stand/b.tscn"),
	"stand_c": preload("scenes/hitboxes/stand/c.tscn"),
	"crouch_a": preload("scenes/hitboxes/crouch/a.tscn"),
	"crouch_b": preload("scenes/hitboxes/crouch/b.tscn"),
	"crouch_c": preload("scenes/hitboxes/crouch/c.tscn"),
	"jump_a": preload("scenes/hitboxes/jump/a.tscn"),
	"jump_b": preload("scenes/hitboxes/jump/b.tscn"),
	"jump_c": preload("scenes/hitboxes/jump/c.tscn"),
	"uppercut": preload("scenes/hitboxes/special/uppercut.tscn"),
	"grab": preload("scenes/hitboxes/stand/grab.tscn"),
	"grab_followup": preload("scenes/hitboxes/stand/grab_followup.tscn"),
	"spin_approach": preload("scenes/hitboxes/special/spin_approach.tscn"),
	"spin_approach_final": preload("scenes/hitboxes/special/spin_approach_final.tscn"),
}
@onready var projectiles = {
	"basic": preload("scenes/ProjectileStraight.tscn")
}

var current_state: States = States.INTRO
var previous_state : States

var current_attack : String

var attack_return_state := {
	"attack_normal/a": States.IDLE,
	"attack_normal/b": States.IDLE,
	"attack_normal/c": States.IDLE,
	"attack_command/crouch_a": States.CRCH,
	"attack_command/crouch_b": States.CRCH,
	"attack_command/crouch_c": States.CRCH,
	"attack_motion/projectile": States.IDLE,
	"attack_motion/uppercut": States.JUMP_N_NO_ACT,
	"attack_motion/spin_approach": States.JUMP_N_NO_ACT,
	"attack_motion/spin_approach_air": States.JUMP_N_NO_ACT,
}

var grab_return_states := {
	"attack_normal/grab": {
		true: "attack_normal/grab_followup",
		false: "attack_normal/grab_whiff"
	},
}

# Nothing should modify the fighter's state in _process or _ready, _process is purely for
# real-time effects, and _ready for initialization.
func _ready():
	reset_facing()
	_animate.play(basic_anim_state_dict[current_state] +
			(_animate.anim_right_suf if right_facing else _animate.anim_left_suf))


func _process(_delta):
	$DebugData.text = """Right Facing: %s
State: %s (Prev: %s)
Attack Finished: %s
Stun: %s:%s
Knockback: %s
Current Animation : %s
""" % [
		right_facing,
		States.keys()[current_state],
		States.keys()[previous_state],
		animation_ended,
		stun_time_current,
		stun_time_start,
		kback,
		_animate.current_animation,
	]
	if len(inputs.up) > 0:
		$DebugData.text += str(inputs_as_numpad()[0])


func _input_step(recv_inputs) -> void:
	inputs = recv_inputs

	if GameGlobal.global_hitstop == 0:
		resolve_state_transitions()
	handle_input()
	if GameGlobal.global_hitstop == 0:
		update_character_state()

	_animate.speed_scale = float(GameGlobal.global_hitstop == 0)
	reset_facing()


func _initialize_training_mode_elements():
	if player:
		for scene in ui_elements_packed.player1:
			ui_elements.append(scene.instantiate())
		for scene in ui_elements_training_packed.player1:
			ui_elements_training.append(scene.instantiate())
	else:
		for scene in ui_elements_packed.player2:
			ui_elements.append(scene.instantiate())
		for scene in ui_elements_training_packed.player2:
			ui_elements_training.append(scene.instantiate())

	(ui_elements_training[0] as HSlider).value_changed.connect(training_mode_set_meter)

func _return_attackers():
	return $Hurtbox.get_overlapping_areas() as Array[Hitbox]


# This is called when a hitbox makes contact with the other fighter,
# after resolving that the fighter was hit by the attack.
# An Array is passed for maximum customizability.
func _on_hit(on_hit_data : Array):
# For this fighter, the on_hit and on_block arrays stores only the meter_gain, a float.
	add_meter(on_hit_data[0])

# Ditto, but for after resolving that the opposing fighter blocked the attack.
func _on_block(on_block_data : Array):
	add_meter(on_block_data[0])


func _post_intro() -> bool:
	return current_state != States.INTRO


func _post_outro() -> bool:
	return (current_state in [States.ROUND_WIN, States.SET_WIN] and not _animate.is_playing())


func _in_defeated_state() -> bool:
	return current_state == States.OUTRO_LIE


func _in_outro_state() -> bool:
	return current_state in [States.OUTRO_FALL, States.OUTRO_BNCE, States.OUTRO_LIE]


func _in_attacking_state() -> bool:
	return current_state in [
		States.ATCK_NRML,
		States.ATCK_CMND,
		States.ATCK_MOTN,
		States.ATCK_SUPR,
		States.ATCK_GRAB,
		States.ATCK_JUMP,
	]


func _in_hurting_state() -> bool:
	return current_state in [
		States.HURT_HGH, States.HURT_LOW, States.HURT_CRCH,
		States.HURT_GRB, States.HURT_FALL, States.HURT_BNCE,
	]


func _in_grabbed_state() -> bool:
	return current_state == States.HURT_GRB


func training_mode_set_meter(val):
	meter = val
	(ui_elements[0] as TextureProgressBar).value = meter


func airborne() -> bool:
	return current_state in [
		States.ATCK_JUMP,
		States.JUMP_L, States.JUMP_N, States.JUMP_R,
		States.JUMP_R_NO_ACT, States.JUMP_N_NO_ACT, States.JUMP_L_NO_ACT,
		States.BLCK_AIR, States.HURT_BNCE, States.HURT_FALL,
	]


func crouching() -> bool:
	return current_state in [States.CRCH, States.HURT_CRCH, States.BLCK_LOW]


func dashing() -> bool:
	return current_state in [States.DASH_B, States.DASH_F]

# Functions used by the AnimationPlayer to perform actions within animations
func update_velocity(vel : Vector3, how : AVEffects):
	if not right_facing:
		vel.x *= -1
	match how:
		AVEffects.ADD:
			velocity += vel
		AVEffects.SET:
			velocity = vel
		AVEffects.SET_X:
			velocity.x = vel.x
		AVEffects.SET_Y:
			velocity.y = vel.y
		AVEffects.EXPEDIATE:
			vel.x = abs(vel.x)
			if velocity.x < 0:
				velocity.x -= vel.x
			elif velocity.x > 0:
				velocity.x += vel.x
			else:
				if right_facing:
					velocity.x += vel.x
				else:
					velocity.x -= vel.x
			if velocity.y < 0:
				velocity.y -= vel.y
			else:
				velocity.y += vel.y


func create_hitbox(pos : Vector3, hitbox_name : String):
	var new_hitbox := (hitboxes[hitbox_name].instantiate() as Hitbox)

	if not right_facing:
		pos.x *= -1

	new_hitbox.set_position(pos + global_position)
	new_hitbox.collision_layer += hitbox_layer

	new_hitbox.damage_block *= damage_mult
	new_hitbox.damage_hit *= damage_mult

	emit_signal(&"hitbox_created", new_hitbox)


func create_projectile(pos : Vector3, projectile_name : String, type : int):
	var new_projectile := (projectiles[projectile_name].instantiate() as Projectile)

	if not right_facing:
		pos.x *= -1

	new_projectile.set_position(pos + global_position)
	new_projectile.right_facing = right_facing
	new_projectile.type = type
	new_projectile.source = player

	new_projectile.get_node(^"Hitbox").collision_layer += hitbox_layer
	new_projectile.get_node(^"Hitbox").damage_block *= damage_mult
	new_projectile.get_node(^"Hitbox").damage_hit *= damage_mult

	emit_signal(&"projectile_created", new_projectile)


func release_grab():
	emit_signal("grab_released", player)


func add_meter(add_to_meter : float):
	meter = min(meter + add_to_meter, METER_MAX)
	(ui_elements[0] as TextureProgressBar).value = meter


func set_state(new_state: States):
	if current_state != new_state:
		current_state = new_state
		update_character_animation()


func ground_cancelled_attack_ended() -> bool:
	return is_on_floor()


func update_attack(new_attack: String) -> void:
	current_attack = new_attack
	animation_ended = false
	attack_connected = false
	attack_hurt = false


func any_atk_just_pressed():
	return (
			btn_just_pressed("button0") or
			btn_just_pressed("button1") or
			btn_just_pressed("button2")
	)


func all_atk_just_pressed():
	return (
			btn_just_pressed("button0") and
			btn_just_pressed("button1") and
			btn_just_pressed("button2")
	)


func two_atk_just_pressed():
	return (
			int(btn_just_pressed("button0")) +
			int(btn_just_pressed("button1")) +
			int(btn_just_pressed("button2")) == 2
	)


func one_atk_just_pressed():
	return (
			int(btn_just_pressed("button0")) +
			int(btn_just_pressed("button1")) +
			int(btn_just_pressed("button2")) == 1
	)


func try_super_attack(cur_state: States) -> States:
	match current_state:
		States.IDLE, States.WALK_B, States.WALK_F:
			if motion_input_check(GG_INPUT) and one_atk_just_pressed() and meter >= 50:
				meter -= 50
				update_attack("attack_super/projectile")
				return States.ATCK_SUPR
		States.JUMP_N, States.JUMP_L, States.JUMP_R:
			if motion_input_check(GG_INPUT) and one_atk_just_pressed() and meter >= 50:
				meter -= 50
				update_attack("attack_super/projectile_air")
				jump_count = 0
				return States.ATCK_SUPR
		States.ATCK_MOTN:
			match current_attack:
				"attack_motion/uppercut", "attack_motion/spin_approach", "attack_motion/spin_approach_air":
					if motion_input_check(GG_INPUT) and one_atk_just_pressed() and meter >= 50:
						meter -= 50
						update_attack("attack_super/projectile_air")
						jump_count = 0
						return States.ATCK_SUPR

	return cur_state


func try_special_attack(cur_state: States) -> States:
	match current_state:
		States.IDLE, States.WALK_B, States.WALK_F, States.ATCK_NRML:
			#check z_motion first since there's a lot of overlap with quarter_circle in some cases
			if motion_input_check(Z_MOTION_FORWARD) and one_atk_just_pressed():
				update_attack("attack_motion/uppercut")
				jump_count = 0
				return States.ATCK_MOTN
			if motion_input_check(QUARTER_CIRCLE_FORWARD) and one_atk_just_pressed():
				update_attack("attack_motion/projectile")
				return States.ATCK_MOTN
			if motion_input_check(QUARTER_CIRCLE_BACK) and one_atk_just_pressed():
				update_attack("attack_motion/spin_approach")
				return States.ATCK_MOTN
		States.CRCH:
			if motion_input_check(Z_MOTION_FORWARD) and one_atk_just_pressed():
				update_attack("attack_motion/uppercut")
				jump_count = 0
				return States.ATCK_MOTN
		States.JUMP_N, States.JUMP_L, States.JUMP_R:
			if (motion_input_check(QUARTER_CIRCLE_FORWARD + TIGER_KNEE_FORWARD) and
					one_atk_just_pressed()):
				update_attack("attack_motion/projectile_air")
				jump_count = 0
				return States.ATCK_MOTN
			if motion_input_check(QUARTER_CIRCLE_BACK + TIGER_KNEE_BACK) and one_atk_just_pressed():
				update_attack("attack_motion/spin_approach_air")
				return States.ATCK_MOTN
		States.ATCK_NRML:
			match current_attack:
				"attack_normal/c", "attack_command/crouch_c":
					if motion_input_check(Z_MOTION_FORWARD) and one_atk_just_pressed():
						update_attack("attack_motion/uppercut")
						jump_count = 0
						return States.ATCK_MOTN
					if motion_input_check(QUARTER_CIRCLE_BACK) and one_atk_just_pressed():
						update_attack("attack_motion/spin_approach")
						return States.ATCK_MOTN

	return cur_state


func try_attack(cur_state: States) -> States:
	if (
			!btn_just_pressed("button0") and
			!btn_just_pressed("button1") and
			!btn_just_pressed("button2")
	):
		return cur_state

	previous_state = cur_state

	var super_attack = try_super_attack(cur_state)
	if super_attack != cur_state:
		return super_attack

	var special_attack = try_special_attack(cur_state)
	if special_attack != cur_state:
		return special_attack

	match current_state:
		States.IDLE, States.WALK_B, States.WALK_F:
			if two_atk_just_pressed():
				update_attack("attack_normal/grab")
				return States.ATCK_GRAB
			if btn_just_pressed("button0"):
				update_attack("attack_normal/a")
				return States.ATCK_NRML
			if btn_just_pressed("button1"):
				update_attack("attack_normal/b")
				return States.ATCK_NRML
			if btn_just_pressed("button2"):
				update_attack("attack_normal/c")
				return States.ATCK_NRML
		States.CRCH:
			if btn_just_pressed("button0"):
				update_attack("attack_command/crouch_a")
				return States.ATCK_CMND
			if btn_just_pressed("button1"):
				update_attack("attack_command/crouch_b")
				return States.ATCK_CMND
			if btn_just_pressed("button2"):
				update_attack("attack_command/crouch_c")
				return States.ATCK_CMND
		States.JUMP_N, States.JUMP_L, States.JUMP_R:
			if btn_just_pressed("button0"):
				update_attack("attack_jumping/a")
				return States.ATCK_JUMP
			if btn_just_pressed("button1"):
				update_attack("attack_jumping/b")
				return States.ATCK_JUMP
			if btn_just_pressed("button2"):
				update_attack("attack_jumping/c")
				return States.ATCK_JUMP

	# how did we get here, something has gone terribly wrong
	return States.INTRO


func magic_series(level: int):
	if level == 3:
		return

	if level == 1 and btn_just_pressed("button1"):
		update_attack("attack_normal/b")
		update_character_animation()

	if btn_just_pressed("button2"):
		update_attack("attack_normal/c")
		update_character_animation()

#returns -1 (walk away), 0 (neutral), and 1 (walk towards)
func walk_value() -> int:
	return (
			(1 * int((btn_pressed("right") and right_facing) or
			(btn_pressed("left") and !right_facing))) +
			(-1 * int((btn_pressed("left") and right_facing) or
			(btn_pressed("right") and !right_facing))
			)
	)


func try_walk(exclude, cur_state: States) -> States:
	var walk = walk_value()

	if walk != exclude:
		match walk:
			WalkDirections.FORWARD:
				return States.WALK_F
			WalkDirections.NEUTRAL:
				return States.IDLE
			WalkDirections.BACK:
				if distance < 5:
					return States.WALK_B

	return cur_state


func try_dash(input: String, success_state: States, cur_state: States) -> States:
# we only need the last three inputs
	var walks = [
		btn_pressed_ind(input, -3),
		btn_pressed_ind(input, -2),
		btn_pressed_ind(input, -1),
	]

	var count_frames = btn_state(input, -3)[0] + btn_state(input, -2)[0] + btn_state(input, -1)[0]

	if walks == [true, false, true] and count_frames <= DASH_INPUT_LENIENCY:
		animation_ended = false
		return success_state

	return cur_state


func try_jump(exclude, cur_state: States, grounded := true) -> States:
	if (
			(btn_pressed("up") and grounded) or
			(btn_just_pressed("up") and not grounded) and jump_count > 0
	):
		var dir = walk_value()

		if dir != exclude:
			match dir:
				WalkDirections.FORWARD:
					if right_facing:
						return States.JUMP_R_I if grounded else States.JUMP_R_A_I
					else:
						return States.JUMP_L_I if grounded else States.JUMP_L_A_I
				WalkDirections.BACK:
					if right_facing:
						return States.JUMP_L_I if grounded else States.JUMP_L_A_I
					else:
						return States.JUMP_R_I if grounded else States.JUMP_R_A_I
				WalkDirections.NEUTRAL:
					return States.JUMP_N_I if grounded else States.JUMP_N_A_I

	return cur_state


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


func inputs_as_numpad(timing := true) -> Array:
	var numpad_buffer = []

	for i in range(max(0, len(inputs.up) - 2)):
		numpad_buffer.append(
			directions_as_numpad(
					btn_pressed_ind("up", i),
					btn_pressed_ind("down", i),
					btn_pressed_ind("left", i),
					btn_pressed_ind("right", i)
			)
		)

	if max(0, len(inputs.up) - 2) == 0:
		return [5]

	if timing:
		numpad_buffer.append(
			directions_as_numpad(
					btn_pressed_ind_under_time("up", -2, MOTION_INPUT_LENIENCY),
					btn_pressed_ind_under_time("down", -2, MOTION_INPUT_LENIENCY),
					btn_pressed_ind_under_time("left", -2, MOTION_INPUT_LENIENCY),
					btn_pressed_ind_under_time("right", -2, MOTION_INPUT_LENIENCY)
			)
		)
	else:
		numpad_buffer.append(
			directions_as_numpad(
					btn_pressed_ind("up", -2),
					btn_pressed_ind("down", -2),
					btn_pressed_ind("left", -2),
					btn_pressed_ind("right", -2)
			)
		)

	return numpad_buffer


func motion_input_check(motions_to_check) -> bool:
	var buffer_as_numpad = inputs_as_numpad()

	for motion_to_check in motions_to_check:
		var buffer_sliced = buffer_as_numpad.slice(len(buffer_as_numpad) - len(motion_to_check))
		if buffer_sliced == motion_to_check:
			return true

	return false


func handle_input() -> void:
	var decision : States = current_state
	match current_state:
# Priority order, from least to most:
# Walk, Backdash, Dash, Crouch, Jump, Attack, Block/Hurt (handled elsewhere)
		States.IDLE, States.WALK_B, States.WALK_F:
			match current_state:
				States.IDLE:
					decision = try_walk(WalkDirections.NEUTRAL, decision)
					if len(inputs.up) > 3:
						if right_facing:
							decision = try_dash("left", States.DASH_B, decision)
							decision = try_dash("right", States.DASH_F, decision)
						else:
							decision = try_dash("left", States.DASH_F, decision)
							decision = try_dash("right", States.DASH_B, decision)
				States.WALK_B:
					decision = try_walk(WalkDirections.BACK, decision)
				States.WALK_F:
					decision = try_walk(WalkDirections.FORWARD, decision)
			decision = States.CRCH if btn_pressed("down") else decision
			decision = try_jump(null, decision)
			decision = try_attack(decision)
# Order: release down, attack, b/h
		States.CRCH:
			decision = try_walk(null, decision) if !btn_pressed("down") else decision
			decision = try_attack(decision)
# Order: jump, attack, b/h
		States.JUMP_N, States.JUMP_L, States.JUMP_R:
			decision = try_jump(null, decision, false)
			decision = try_attack(decision)
# Special cases for attack canceling
		States.ATCK_NRML:
			if attack_connected: #if the attack landed at all
				# jump canceling normals
				decision = try_jump(null, decision)
				# magic series
				if decision == States.ATCK_NRML:
					match current_attack:
						"attack_normal/a":
							magic_series(1)
						"attack_normal/b":
							magic_series(2)
						"attack_normal/c":
							magic_series(3)
					# special cancelling
					decision = try_special_attack(decision)
		States.ATCK_MOTN:
			if attack_hurt:
				decision = try_super_attack(decision)
	set_state(decision)


func handle_stand_stun():
	if stun_time_current == 0:
		var new_walk = try_walk(null, current_state)
		set_state(new_walk)


func handle_air_stun():
	if stun_time_current > 0:
		return

	if is_on_floor():
#		handle_stand_stun(buffer)
		var new_walk = try_walk(null, current_state)
		set_state(new_walk)


func update_character_state():
	match current_state:
		States.IDLE:
			velocity.x = 0
			jump_count = jump_total
		States.CRCH:
			velocity.x = 0
			jump_count = jump_total
		States.WALK_F:
			jump_count = jump_total
			if not $StopPlayerIntersection.has_overlapping_areas():
				velocity.x = (1 if right_facing else -1) * walk_speed
			else:
				velocity.x = 0
		States.WALK_B:
			jump_count = jump_total
			velocity.x = (-1 if right_facing else 1) * walk_speed
		States.DASH_F:
			jump_count = jump_total
			if not $StopPlayerIntersection.has_overlapping_areas():
				velocity.x = (1 if right_facing else -1) * walk_speed * 1.5
			else:
				velocity.x = 0
		States.DASH_B:
			jump_count = jump_total
			velocity.x = (-1 if right_facing else 1) * walk_speed * 1.5
		States.JUMP_R_I, States.JUMP_L_I, States.JUMP_N_I, States.JUMP_N_A_I, States.JUMP_L_A_I, States.JUMP_R_A_I:
			jump_count -= 1
			velocity.y = jump_height
		States.JUMP_R, States.JUMP_R_NO_ACT:
			velocity.x = walk_speed
		States.JUMP_L, States.JUMP_L_NO_ACT:
			velocity.x = -1 * walk_speed
		States.JUMP_N, States.JUMP_N_NO_ACT:
			velocity.x = 0
		States.HURT_GRB:
			velocity.x = 0
			velocity.y = -gravity #negative gravity is used here to undo gravity and halt all movement
		States.HURT_HGH, States.HURT_LOW, States.HURT_CRCH, States.BLCK_HGH, States.BLCK_LOW:
			if stun_time_current == stun_time_start:
				velocity.x += (-1 if right_facing else 1) * kback.x
		States.HURT_FALL, States.HURT_BNCE, States.BLCK_AIR, States.OUTRO_BNCE, States.OUTRO_FALL:
			if stun_time_current == stun_time_start:
				velocity.x += (-1 if right_facing else 1) * kback.x
				velocity.y += kback.y
		States.HURT_LIE, States.OUTRO_LIE:
			velocity.x *= GROUND_SLIDE_FRICTION

	velocity.y += gravity
	velocity.y = max(min_fall_vel, velocity.y)
	record_y = velocity.y
	check_true = move_and_slide()
	if velocity.y < 0 and is_on_floor():
		velocity.y = 0


func resolve_state_transitions():
	# complete jump bug fix
	match previous_state:
		States.JUMP_N_I, States.JUMP_N_A_I:
			previous_state = States.JUMP_N
		States.JUMP_R_I, States.JUMP_R_A_I:
			previous_state = States.JUMP_R
		States.JUMP_L_I, States.JUMP_L_A_I:
			previous_state = States.JUMP_L
	match current_state:
		States.IDLE, States.WALK_F, States.WALK_B, States.CRCH when game_ended:
			set_state(States.ROUND_WIN)
			return
		States.INTRO:
			if not _animate.is_playing():
				set_state(States.IDLE)
				previous_state = current_state
		States.ROUND_WIN:
			previous_state = current_state
			set_state(States.ROUND_WIN)
		States.SET_WIN:
			previous_state = current_state
			set_state(States.SET_WIN)
		States.GET_UP:
			if not _animate.is_playing():
				set_state(previous_state)
		States.DASH_B:
			if animation_ended:
				set_state(States.WALK_B)
		States.DASH_F:
			if animation_ended:
				set_state(States.WALK_F)
		States.JUMP_R_I, States.JUMP_R_A_I:
			if not is_on_floor(): set_state(States.JUMP_R)
		States.JUMP_L_I, States.JUMP_L_A_I:
			if not is_on_floor(): set_state(States.JUMP_L)
		States.JUMP_N_I, States.JUMP_N_A_I:
			if not is_on_floor(): set_state(States.JUMP_N)
		States.JUMP_R, States.JUMP_L, States.JUMP_N, States.JUMP_R_NO_ACT, States.JUMP_N_NO_ACT, States.JUMP_L_NO_ACT:
			if is_on_floor():
				var new_walk = try_walk(null, current_state)
				set_state(new_walk)
		States.BLCK_AIR:
			reduce_stun()
			if is_on_floor():
				stun_time_current = 0
			handle_air_stun()
		States.HURT_HGH, States.HURT_LOW, States.HURT_CRCH, States.BLCK_HGH, States.BLCK_LOW:
			reduce_stun()
			handle_stand_stun()
		States.HURT_FALL:
			reduce_stun()
			handle_air_stun()
			if check_true and stun_time_current < stun_time_start:
				set_state(States.HURT_LIE)
		States.HURT_BNCE:
			reduce_stun()
			if check_true:
				set_state(States.HURT_FALL)
				set_stun(stun_time_start)
				kback.y *= -1
		States.OUTRO_BNCE:
			reduce_stun()
			if check_true:
				set_state(States.OUTRO_FALL)
				set_stun(stun_time_start)
				kback.y *= -1
		States.HURT_LIE:
			reduce_stun()
			if stun_time_current == 0:
				set_state(States.GET_UP)
		States.OUTRO_FALL:
			reduce_stun()
			if check_true:
				set_state(States.OUTRO_LIE)
		States.ATCK_NRML, States.ATCK_CMND, States.ATCK_MOTN, States.ATCK_SUPR:
			if animation_ended:
				if attack_return_state.get(current_attack) != null:
					set_state(attack_return_state[current_attack])
				else:
					set_state(previous_state)
		States.ATCK_GRAB:
			if animation_ended:
				update_attack(grab_return_states[current_attack][attack_hurt])
				set_state(States.ATCK_NRML)
		States.ATCK_JUMP:
			if animation_ended:
				if attack_return_state.get(current_attack) != null:
					set_state(attack_return_state[current_attack])
				else:
					set_state(previous_state)
			elif is_on_floor():
				var new_walk = try_walk(null, current_state)
				set_state(new_walk)


func update_character_animation():
	if _in_attacking_state():
		_animate.play(current_attack + (_animate.anim_right_suf if right_facing else _animate.anim_left_suf))
	else:
		match current_state:
			States.WALK_F when right_facing:
				_animate.play(move_right_anim)
			States.WALK_F when !right_facing:
				_animate.play(move_left_anim)
			States.WALK_B when right_facing:
				_animate.play(move_left_anim)
			States.WALK_B when !right_facing:
				_animate.play(move_right_anim)
			States.DASH_F when right_facing:
				_animate.play(dash_right_anim)
			States.DASH_F when !right_facing:
				_animate.play(dash_left_anim)
			States.DASH_B when right_facing:
				_animate.play(dash_left_anim)
			States.DASH_B when !right_facing:
				_animate.play(dash_right_anim)
			_:
				_animate.play(basic_anim_state_dict[current_state] + (_animate.anim_right_suf if right_facing else _animate.anim_left_suf))


func reset_facing():
	if distance < 0:
		right_facing = true
		grabbed_offset.x = -GRABBED_OFFSET_X
	else:
		right_facing = false
		grabbed_offset.x = GRABBED_OFFSET_X


func handle_damage(attack : Hitbox, blocked : bool, next_state : States):
	if not blocked:
		health -= attack.damage_hit * defense_mult
		set_stun(attack.stun_hit)
		kback = attack.kback_hit
		if health <= 0:
			set_state(States.OUTRO_BNCE)
			kback.y += 6.5
			emit_signal(&"defeated")
		else:
			set_state(next_state)
	else:
		health = max(health - attack.damage_block * defense_mult, 1)
		set_stun(attack.stun_block)
		kback = attack.kback_block
		set_state(next_state)

# If attack is blocked, return false
# If attack isn't blocked, return true
func try_block(attack : Hitbox,
			ground_block_rules : Array, air_block_rules : Array,
			fs_stand : States, fs_crouch : States, fs_air : States) -> bool:
	# still in hitstun or just can't block
	if _in_hurting_state() or _in_attacking_state() or dashing():
		if not airborne():
			if crouching():
				handle_damage(attack, false, fs_crouch)
				return true
			else:
				handle_damage(attack, false, fs_stand)
				return true
		else:
			handle_damage(attack, false, fs_air)
			return true
	# Try to block
	var directions = [
		btn_pressed("up"),
		btn_pressed("down"),
		btn_pressed("left"),
		btn_pressed("right")
	]
	if not right_facing:
		var temp = directions[2]
		directions[2] = directions[3]
		directions[3] = temp
	if not airborne():
		for check_input in range(len(directions)):
			if (
					(directions[check_input] == true and ground_block_rules[check_input] == -1) or
					(directions[check_input] == false and ground_block_rules[check_input] == 1)
			):
				if crouching():
					handle_damage(attack, false, fs_crouch)
					return true
				else:
					handle_damage(attack, false, fs_stand)
					return true
		if btn_pressed("down"):
			handle_damage(attack, true, States.BLCK_LOW)
			return false
		else:
			handle_damage(attack, true, States.BLCK_HGH)
			return false
	else:
		for check_input in range(len(directions)):
			if (
					(directions[check_input] == true and air_block_rules[check_input] == -1) or
					(directions[check_input] == false and air_block_rules[check_input] == 1)
			):
				handle_damage(attack, false, fs_air)
				return true
		handle_damage(attack, true, States.BLCK_AIR)
		return false


func try_grab(attack_dmg: float, on_ground : bool) -> bool:
	if crouching():
		return false
	if on_ground and airborne():
		return false

	emit_signal(&"grabbed", player)
	health = max(health - attack_dmg * defense_mult, 1)
	set_stun(-1)
	kback = Vector3.ZERO
	set_state(States.HURT_GRB)
	return true

# Only runs when a hitbox is overlapping, return rules explained above
func _damage_step(attack : Hitbox) -> bool:
	match attack.hit_type:
		"mid":
			return try_block(attack, block.away_any, block.away_any,
					States.HURT_HGH, States.HURT_CRCH, States.HURT_FALL)
		"high":
			return try_block(attack, block.away_high, block.away_any,
					States.HURT_HGH, States.HURT_CRCH, States.HURT_FALL)
		"low":
			return try_block(attack, block.away_low, block.away_any,
					States.HURT_LOW, States.HURT_CRCH, States.HURT_FALL)
		"launch":
			return try_block(attack, block.away_any, block.away_any,
					States.HURT_FALL, States.HURT_FALL, States.HURT_FALL)
		"sweep":
			return try_block(attack, block.away_low, block.away_any,
					States.HURT_LIE, States.HURT_LIE, States.HURT_FALL)
		"slam":
			return try_block(attack, block.away_high, block.away_any,
					States.HURT_BNCE, States.HURT_BNCE, States.HURT_BNCE)
		"grab_ground":
			return try_grab(attack.damage_hit, true)
		"grab_air":
			return try_grab(attack.damage_hit, false)
		_: # this will definitely not be a bug in the future
			return try_block(attack, block.nope, block.nope,
					States.HURT_HGH, States.HURT_CRCH, States.HURT_FALL)
