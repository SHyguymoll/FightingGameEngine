class_name State2DMeterFighter
extends Fighter

## A Finite State Machine-based Fighter with features based off of Guilty Gear, Street Fighter, etc.
##
## This is an example of a fighter that someone could make.[br]
## This Fighter implements the following gameplay features:[br]
## [b]Simple Hitboxes[/b]: Hitboxes are preloaded and instantiated on the fly.[br]
## [b]Normal Attacks[/b]: Pressing an attack button with no direction will perform an attack.[br]
## [b]Command Attacks[/b]: Pressing an attack button with a direction will perform a command attack.[br]
## [b]Grounded Dashing and Aerial Dashing[/b]: Double tap left or right for a burst of speed.[br]
## [b]Jump-Cancelling[/b]: During the impact frames of an attack, the fighter can jump.[br]
## [b]The Magic Series[/b]: During the impact frames of an attack,
## a stronger attack can be used for combos and blockstrings. [br]
## Grab Breaks: When grabbed, the grab can be broken by inputting a grab within 5 frames. This will reset
## both fighters to a neutral state.[br]
## [b]Special Cancelling[/b]: During the impact frames of a normal attack, a special attack can be used.[br]
## [b]Super Cancelling[/b]: During the impact frames of a special attack, a super attack can be used.[br]
## [b]Super Meter[/b]: Super Attacks are tied to the fulfillment of a meter on the HUD.[br]
## [b]Infinite Prevention Systems[/b]: Reduction and pushback are used to stop the other Fighter from
## infiniting this Fighter, as well as to stop this Fighter from infinitely looping the other Fighter.[br]
##
## [color=rainbow]IMPORTANT NOTE:[/color] Animations are handled in manual mode when this script runs
## in-game as to stop unintended behavior from happening when the game is paused (spawning way too many
## projectiles, deep-landed jumping attacks failing to come out, etc.), and that is updated in _ready.[br]
##
## State transitions are handled by a FSM. The nodes of this FSM are denoted by this enum. Transitions are handled in the _damage_step and _input_step. Most non-attacking animations are also tied to these nodes.[br]
##
## _input_step and _action_step are left to be implemented by the developer. An example of implementations
## of these functions can be found in Godot Guy.
enum States {
	INTRO, ROUND_WIN, SET_WIN, # round stuff
	IDLE, CRCH, # no movement
	WALK_F, WALK_B, DASH_F, DASH_B, # lateral movement
	JUMP_INIT, JUMP, JUMP_AIR_INIT, DASH_A_F, DASH_A_B, JUMP_NO_ACT, # aerial movement
	ATCK_NRML, ATCK_CMND, ATCK_MOTN, ATCK_GRAB_START, ATCK_GRAB_END, ATCK_JUMP, ATCK_SUPR, # attack
	ATCK_NRML_IMP, ATCK_CMND_IMP, ATCK_MOTN_IMP, ATCK_JUMP_IMP, ATCK_SUPR_IMP, # attack impacts
	BLCK_HGH, BLCK_LOW, BLCK_AIR, GET_UP, # handling getting attacked well
	HURT_HGH, HURT_LOW, HURT_CRCH, HURT_GRB, HURT_GRB_NOBREAK, # not handling getting attacked well
	HURT_FALL, HURT_LIE, HURT_BNCE, # REALLY not handling getting attacked well
	OUTRO_FALL, OUTRO_LIE, OUTRO_BNCE, OUTRO_LOSE, # The final stage of not handling it
}

const JUMP_SQUAT_LENGTH = 4
const DASH_INPUT_LENIENCY : int = 10
const GRABBED_OFFSET_X = 0.46

## Half Circle Back, then Forward. [br]
## The name is a reference to the common Guilty Gear Overdrive input.
const MOTION_GG = [[6,3,2,1,4,6], [6,3,2,1,4,5,6], [6,2,1,4,6],
	[6,2,4,6], [6,2,4,5,6], [6,2,1,4,5,6]]

## Used as a reference for handling blocking attacks.[br]
## block rule arrays: [up, down, away, towards][br]
## 1 means must hold, 0 means ignored, -1 means must not hold.
var block : Dictionary = {away_any = [0, 0, 1, -1],
	away_high = [0, -1, 1, -1],
	away_low = [-1, 1, 1, -1],
	nope = [-1, -1, -1, -1]}

var current_state: States = States.IDLE
var previous_state : States
var ticks_since_state_change : int = 0
var force_airborne := false
var force_collisions := false

## Holds the results of a move_and_slide() call when the Fighter collides with the ground.
var check_true : bool # Used to remember results of move_and_slide()

var animation_ended = true

@export var walk_speed : float = 2
@export var jump_total : float = 2
@export var jump_height : float = 11
@export var gravity : float = -0.5
@export var min_fall_vel : float = -6.5
@export var GROUND_SLIDE_FRICTION : float = 0.97
@export var meter : float = 0
@export var METER_MAX : float = 100
@export var damage_mult : float = 1.0
@export var defense_mult : float = 1.0

var jump_count : float = 0

var ground_vel : Vector3
var aerial_vel : Vector3

@export var hitboxes : Dictionary[String, Resource]
@export var projectiles : Dictionary[String, Resource]
@export var particles : Dictionary[String, Resource]
@export var game_instanced_sounds : Dictionary[String, Resource]

@onready var area3d_intersect_check : Area3D = $Area3DIntersectionCheck

@onready var debug_data : Label3D = $DebugData

var current_attack : String

# Nothing should modify the fighter's state in _process or _ready, _process is purely for
# real-time effects, and _ready for initialization.
func _ready():
	reset_facing()
	debug_data.visible = get_parent().get_parent() is TrainingModeGame


func _do_intro():
	set_state(States.INTRO)


func _skip_intro():
	set_state(States.IDLE)
	previous_state = States.IDLE


func handle_defeated():
	emit_signal(&"defeated")


func handle_damage(attack : Hitbox, hit : bool, next_state : States, combo_count : int):
	print(attack)
	release_grab()
	var reduction : float = float(combo_count) / 5 + 1.0
	if hit:
		health -= (attack.damage_hit * defense_mult) / reduction
		set_stun(attack.stun_hit)
		kback = attack.kback_hit
		kback.y /= reduction
		if health <= 0:
			handle_defeated()
		else:
			set_state(next_state)
	else:
		health = max(health - attack.damage_block * defense_mult, 1)
		set_stun(attack.stun_block)
		kback = attack.kback_block
		set_state(next_state)


func choose_hurting_state(attack : Hitbox):
	if (attack.hitbox_flags & attack.HitboxFlags.HIT_GRAB or
		attack.hitbox_flags & attack.HitboxFlags.CONNECT_GRAB):
		if attack.hitbox_flags & attack.HitboxFlags.UNBLOCK_INESCAP:
			return States.HURT_GRB_NOBREAK
		else:
			return States.HURT_GRB
	if (attack.hitbox_flags & attack.HitboxFlags.END_GRAB or
		attack.hitbox_flags & attack.HitboxFlags.BREAK_GRAB):
		return States.HURT_FALL
	if airborne() or attack.state_effect == attack.StateEffects.LAUNCHER:
		if attack.hitbox_flags & attack.HitboxFlags.BLOCK_HIGH and not attack.hitbox_flags & attack.HitboxFlags.BLOCK_LOW:
			return States.HURT_BNCE
		else:
			return States.HURT_FALL
	elif attack.state_effect == attack.StateEffects.KNOCKDOWN:
		return States.HURT_LIE
	elif attack.state_effect == attack.StateEffects.COLLAPSE:
		return States.HURT_FALL
	elif attack.state_effect == attack.StateEffects.BOUNCE:
		return States.HURT_FALL
	if attack.hitbox_flags & attack.HitboxFlags.BLOCK_HIGH:
		return States.HURT_HGH
	if attack.hitbox_flags & attack.HitboxFlags.BLOCK_LOW:
		return States.HURT_LOW


func choose_blocking_state(attack : Hitbox):
	if airborne():
		return States.BLCK_AIR
	if attack.hitbox_flags & attack.HitboxFlags.BLOCK_LOW:
		return States.BLCK_LOW
	else:
		return States.BLCK_HGH


func counter_hit(attack : Hitbox, combo_count : int):
	handle_damage(attack, true, choose_hurting_state(attack), combo_count)


# Only runs when a hitbox is overlapping
# If attack is blocked or doesn't land, return false
# Otherwise, return true
func _damage_step(attack : Hitbox, combo_count : int) -> bool:
	# handling grabs
	if attack.hitbox_flags & attack.HitboxFlags.CONNECT_GRAB:
		if crouching() and attack.hitbox_flags & attack.HitboxFlags.BLOCK_LOW:
			return false
		if attack.hitbox_flags & attack.HitboxFlags.HIT_GROUND:
			if airborne():
				return false
			else:
				emit_signal(&"grabbed", player)
				handle_damage(attack, true, choose_hurting_state(attack), combo_count)
				return true
		if attack.hitbox_flags & attack.HitboxFlags.HIT_AIR:
			if not airborne():
				return false
			else:
				emit_signal(&"grabbed", player)
				handle_damage(attack, true, choose_hurting_state(attack), combo_count)
				return true
	# handling attacks
	# autofail blocking if in following states:
	# still in hitstun or just can't block or attack is unblockable
	if _in_hurting_state() or dashing():
		handle_damage(attack, true, choose_hurting_state(attack), combo_count)
		return true
	# counter-hits
	if _in_attacking_state() and not current_state == States.ATCK_GRAB_END:
		counter_hit(attack, combo_count)
		return true
	# auto blocking attacks if already blocking
	if blocking():
		if (airborne() or
		attack.hitbox_flags & attack.HitboxFlags.BLOCK_HIGH and current_state == States.BLCK_HGH or
		attack.hitbox_flags & attack.HitboxFlags.BLOCK_LOW and current_state == States.BLCK_LOW):
			handle_damage(attack, false, current_state, combo_count)
			return false
	# manually blocking attacks
	var blocking_rules
	if airborne():
		if attack.hitbox_flags & attack.HitboxFlags.UNBLOCK_INESCAP:
			blocking_rules = block.nope
		else:
			blocking_rules = block.away_any
	else:
		if attack.hitbox_flags & attack.HitboxFlags.UNBLOCK_INESCAP:
			blocking_rules = block.nope
		elif (
				attack.hitbox_flags & attack.HitboxFlags.BLOCK_HIGH and
				attack.hitbox_flags & attack.HitboxFlags.BLOCK_LOW
			):
			blocking_rules = block.away_any
		elif attack.hitbox_flags & attack.HitboxFlags.BLOCK_HIGH:
			blocking_rules = block.away_high
		elif attack.hitbox_flags & attack.HitboxFlags.BLOCK_LOW:
			blocking_rules = block.away_low
	var directions = [
		btn_pressed(GameGlobal.BTN_UP),
		btn_pressed(GameGlobal.BTN_DOWN),
		btn_pressed(GameGlobal.BTN_LEFT),
		btn_pressed(GameGlobal.BTN_RIGHT)
	]
	if not right_facing:
		var temp = directions[2]
		directions[2] = directions[3]
		directions[3] = temp
	for check_input in range(len(directions)):
		if (
				(directions[check_input] == true and blocking_rules[check_input] == -1) or
				(directions[check_input] == false and blocking_rules[check_input] == 1)
		):
			handle_damage(attack, true, choose_hurting_state(attack), combo_count)
			return true
	# attack was blocked successfully
	handle_damage(attack, false, choose_blocking_state(attack), combo_count)
	return false


# This is called when a hitbox makes contact with the other fighter,
# after resolving that the fighter was hit by the attack.
# An Array is passed for maximum customizability.
# For this fighter, the on_hit and on_block arrays stores only a float for meter.
func _on_hit(on_hit_data : Array):
	add_meter(on_hit_data[0])


# Ditto, but for after resolving that the opposing fighter blocked the attack.
func _on_block(on_block_data : Array):
	add_meter(on_block_data[0])


func _post_intro() -> bool:
	return current_state != States.INTRO


func _post_outro() -> bool:
	return (current_state in [States.ROUND_WIN, States.SET_WIN])


func _in_defeated_state() -> bool:
	return current_state in [States.OUTRO_LIE, States.OUTRO_LOSE]


func _in_outro_state() -> bool:
	return current_state in [States.OUTRO_FALL, States.OUTRO_BNCE, States.OUTRO_LIE]


func _in_attacking_state() -> bool:
	return current_state in [
		States.ATCK_NRML,
		States.ATCK_CMND,
		States.ATCK_MOTN,
		States.ATCK_SUPR,
		States.ATCK_GRAB_START,
		States.ATCK_GRAB_END,
		States.ATCK_JUMP,
	]


func _in_hurting_state() -> bool:
	return current_state in [
		States.HURT_HGH, States.HURT_LOW, States.HURT_CRCH, States.HURT_LIE,
		States.HURT_GRB, States.HURT_GRB_NOBREAK, States.HURT_FALL, States.HURT_BNCE,
	]


func _in_grabbed_state() -> bool:
	return current_state == States.HURT_GRB


func _in_neutral_state() -> bool:
	return current_state == States.IDLE


func training_mode_set_meter(val):
	meter = val


func impact_state() -> bool:
	return current_state in [States.ATCK_NRML_IMP, States.ATCK_JUMP_IMP,
		States.ATCK_CMND_IMP, States.ATCK_MOTN_IMP]


func airborne() -> bool:
	return current_state in [States.JUMP, States.JUMP_NO_ACT,
		States.JUMP_AIR_INIT, States.DASH_A_B, States.DASH_A_F,
		States.ATCK_JUMP, States.ATCK_JUMP_IMP, States.BLCK_AIR,
		States.HURT_BNCE, States.HURT_FALL, States.OUTRO_BNCE, States.OUTRO_FALL
	] or force_airborne


func crouching() -> bool:
	return current_state in [States.CRCH, States.HURT_CRCH, States.BLCK_LOW]


func dashing() -> bool:
	return current_state in [States.DASH_B, States.DASH_F,
		States.DASH_A_B, States.DASH_A_F]


func blocking() -> bool:
	return current_state in [States.BLCK_AIR, States.BLCK_HGH, States.BLCK_LOW]


func create_hitbox(pos : Vector3, hitbox_name : String):
	var try_get = hitboxes.get(hitbox_name)
	if try_get == null:
		printerr(hitbox_name + " does not exist")
		return
	var new_hitbox := try_get.instantiate() as Hitbox
	new_hitbox.name = name + "_" + hitbox_name

	if not right_facing:
		pos.x *= -1

	new_hitbox.set_position(pos + global_position)
	new_hitbox.collision_layer += hitbox_layer

	new_hitbox.damage_block *= damage_mult
	new_hitbox.damage_hit *= damage_mult

	emit_signal(&"hitbox_created", new_hitbox)
	if new_hitbox.hitbox_flags & Hitbox.HitboxFlags.END_GRAB:
		emit_signal("grab_released", player)


func create_projectile(pos : Vector3, projectile_name : String, type : int):
	var try_get = projectiles.get(projectile_name)
	if try_get == null:
		printerr(projectile_name + " does not exist")
		return
	var new_projectile := try_get.instantiate() as Projectile
	new_projectile.name = name + "_" + projectile_name

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


func create_particle(par_name : String, origin : GameParticle.Origins, pos_offset : Vector3):
	var try_get = particles.get(par_name)
	if try_get == null:
		printerr(par_name + " does not exist")
		return
	var particle_instance : GameParticle = try_get.instantiate()
	emit_signal(&"particle_created", particle_instance, origin, pos_offset, self)


func create_dramatic_freeze(frz_name : String):
	var try_get = dramatic_freezes.get(frz_name)
	if try_get == null:
		printerr(frz_name + " does not exist")
		return
	var new_freeze := try_get.instantiate() as DramaticFreeze
	emit_signal(&"dramatic_freeze_created", new_freeze, self)


func create_audio(audio_name):
	var try_get = game_instanced_sounds.get(audio_name)
	if try_get == null:
		printerr(audio_name + " does not exist")
		return
	emit_signal(&"audio_created", try_get as AudioStream)


func release_grab():
	emit_signal("grab_released", player)


func add_meter(add_to_meter : float):
	meter = min(meter + add_to_meter, METER_MAX)


func set_airborne():
	force_airborne = true


func set_collisions():
	force_collisions = true


func set_state(new_state: States):
	if current_state != new_state:
		current_state = new_state
		update_character_animation()
		ticks_since_state_change = 0


func update_character_animation():
	pass


func update_attack(new_attack: String) -> void:
	current_attack = new_attack
	animation_ended = false
	attack_connected = false
	attack_hurt = false


func any_atk_just_pressed():
	return (btn_just_pressed("button0") or
			btn_just_pressed("button1") or
			btn_just_pressed("button2"))


func all_atk_just_pressed():
	return (btn_just_pressed("button0") and
			btn_just_pressed("button1") and
			btn_just_pressed("button2"))


func two_atk_just_pressed():
	return (int(btn_just_pressed("button0")) +
			int(btn_just_pressed("button1")) +
			int(btn_just_pressed("button2")) == 2)


func one_atk_just_pressed():
	return (int(btn_just_pressed("button0")) +
			int(btn_just_pressed("button1")) +
			int(btn_just_pressed("button2")) == 1)


func try_super_attack(cur_state: States) -> States:
	match current_state:
		States.IDLE, States.WALK_B, States.WALK_F, States.DASH_F, States.DASH_B:
			if motion_input_check(MOTION_GG) and one_atk_just_pressed() and meter >= 50:
				meter -= 50
				update_attack("attack_super/projectile")
				return States.ATCK_SUPR
		States.JUMP, States.DASH_A_F, States.DASH_A_B:
			if motion_input_check(MOTION_GG) and one_atk_just_pressed() and meter >= 50:
				meter -= 50
				update_attack("attack_super/projectile_air")
				jump_count = 0
				return States.ATCK_SUPR
		States.ATCK_MOTN:
			match current_attack:
				"attack_super/projectile", "attack_motion/uppercut", "attack_motion/spin_approach", "attack_motion/spin_approach_air":
					if motion_input_check(MOTION_GG) and one_atk_just_pressed() and meter >= 50:
						meter -= 50
						update_attack("attack_super/projectile_air")
						jump_count = 0
						return States.ATCK_SUPR
	return cur_state


func try_special_attack(cur_state: States) -> States:
	match current_state:
		States.IDLE, States.WALK_B, States.WALK_F, States.ATCK_NRML, States.DASH_F, States.DASH_B:
			# check z_motion first since there's a lot of overlap with quarter_circle in some cases
			if motion_input_check(MOTION_ZFORWARD) and one_atk_just_pressed():
				update_attack("attack_motion/uppercut")
				jump_count = 0
				return States.ATCK_MOTN
			if motion_input_check(MOTION_QCF) and one_atk_just_pressed():
				update_attack("attack_motion/projectile")
				return States.ATCK_MOTN
			if motion_input_check(MOTION_QCB) and one_atk_just_pressed():
				update_attack("attack_motion/spin_approach")
				return States.ATCK_MOTN
		States.CRCH:
			if motion_input_check(MOTION_ZFORWARD) and one_atk_just_pressed():
				update_attack("attack_motion/uppercut")
				jump_count = 0
				return States.ATCK_MOTN
		States.JUMP, States.DASH_A_F, States.DASH_A_B:
			if (motion_input_check(MOTION_QCF + MOTION_TKF) and
					one_atk_just_pressed()):
				update_attack("attack_motion/projectile_air")
				jump_count = 0
				return States.ATCK_MOTN
			if (motion_input_check(MOTION_QCB + MOTION_TKB) and
					one_atk_just_pressed()):
				update_attack("attack_motion/spin_approach_air")
				return States.ATCK_MOTN
		States.ATCK_NRML:
			match current_attack:
				"attack_normal/c", "attack_command/crouch_c":
					if motion_input_check(MOTION_ZFORWARD) and one_atk_just_pressed():
						update_attack("attack_motion/uppercut")
						jump_count = 0
						return States.ATCK_MOTN
					if motion_input_check(MOTION_QCB) and one_atk_just_pressed():
						update_attack("attack_motion/spin_approach")
						return States.ATCK_MOTN
				"attack_normal/b":
					if motion_input_check(MOTION_QCF) and one_atk_just_pressed():
						update_attack("attack_motion/projectile")
						return States.ATCK_MOTN
	return cur_state


func try_attack(cur_state: States) -> States:
	if (not btn_just_pressed("button0") and not btn_just_pressed("button1") and
		not btn_just_pressed("button2")):
		return cur_state
	previous_state = cur_state
	var super_attack = try_super_attack(cur_state)
	if super_attack != cur_state:
		return super_attack
	var special_attack = try_special_attack(cur_state)
	if special_attack != cur_state:
		return special_attack
	match current_state:
		States.IDLE, States.WALK_F:
			if two_atk_just_pressed():
				update_attack("attack_normal/grab")
				return States.ATCK_GRAB_START
			if btn_just_pressed("button0"):
				update_attack("attack_normal/a")
				return States.ATCK_NRML
			if btn_just_pressed("button1"):
				update_attack("attack_normal/b")
				return States.ATCK_NRML
			if btn_just_pressed("button2"):
				update_attack("attack_normal/c")
				return States.ATCK_NRML
		States.WALK_B:
			if two_atk_just_pressed():
				update_attack("attack_normal/grab_back")
				return States.ATCK_GRAB_START
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
		States.JUMP, States.DASH_A_F, States.DASH_A_B:
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
	return previous_state


func try_magic_series(level: int, cur_state: States) -> States:
	if level == 1 and btn_just_pressed("button1"):
		update_attack("attack_normal/b")
		return States.ATCK_NRML
	elif level == 2 and btn_just_pressed("button2"):
		update_attack("attack_normal/c")
		return States.ATCK_NRML
	else:
		return cur_state

#returns -1 (walk away), 0 (neutral), and 1 (walk towards)
func walk_value() -> Fighter.WalkingX:
	return ((1 * int((btn_pressed(GameGlobal.BTN_RIGHT) and right_facing) or
			(btn_pressed(GameGlobal.BTN_LEFT) and !right_facing))) +
			(-1 * int((btn_pressed(GameGlobal.BTN_LEFT) and right_facing) or
			(btn_pressed(GameGlobal.BTN_RIGHT) and !right_facing)))) as Fighter.WalkingX


func try_walk(exclude, cur_state: States) -> States:
	var walk = walk_value()
	if walk != exclude:
		match walk:
			WalkingX.FORWARD:
				return States.WALK_F
			WalkingX.NEUTRAL:
				return States.IDLE
			WalkingX.BACK:
				if distance < 5:
					return States.WALK_B
	return cur_state


func try_dash(input: String, success_state: States, cur_state: States, cost := false) -> States:
# we only need the last three inputs
	var walks = [btn_pressed_ind(input, -3), btn_pressed_ind(input, -2),
		btn_pressed_ind(input, -1)]
	var count_frames = btn_state(input, -3)[0] + btn_state(input, -2)[0] + btn_state(input, -1)[0]
	if walks == [true, false, true] and count_frames <= DASH_INPUT_LENIENCY and (
			(not cost) or (cost and jump_count >= 0.5)):
		animation_ended = false
		return success_state
	return cur_state


func try_jump(cur_state: States, grounded := true) -> States:
	if btn_pressed(GameGlobal.BTN_UP) and grounded and jump_count >= 1:
		return States.JUMP_INIT
	if btn_just_pressed(GameGlobal.BTN_UP) and not grounded and jump_count >= 1:
		return States.JUMP_AIR_INIT
	return cur_state


func handle_stand_stun():
	if stun_time_current == 0:
		var new_walk = try_walk(null, current_state)
		set_state(new_walk)


func handle_air_stun():
	if stun_time_current > 0:
		return
	if is_on_floor():
		var new_walk = try_walk(null, current_state)
		set_state(new_walk)


func update_character_state():
	if _in_hurting_state() or blocking():
		reduce_stun()

	if _in_hurting_state():
		force_airborne = false
		force_collisions = airborne()

	if current_state not in [States.ATCK_GRAB_END, States.ATCK_GRAB_START]:
		release_grab()

	match current_state:
		States.IDLE, States.CRCH:
			ground_vel = Vector3.ZERO
			jump_count = jump_total
		States.WALK_F:
			jump_count = jump_total
			ground_vel.x = (1 if right_facing else -1) * walk_speed
		States.WALK_B:
			jump_count = jump_total
			ground_vel.x = (-1 if right_facing else 1) * walk_speed
		States.DASH_F:
			jump_count = jump_total
		States.DASH_B:
			jump_count = jump_total
		States.DASH_A_F when ticks_since_state_change == 0:
			jump_count -= 0.5
		States.DASH_A_B when ticks_since_state_change == 0:
			jump_count -= 0.5
		States.JUMP_INIT when ticks_since_state_change == JUMP_SQUAT_LENGTH:
			jump_count -= 1
			aerial_vel.x = walk_value() * walk_speed
			if not right_facing:
				aerial_vel.x *= -1
			@warning_ignore("narrowing_conversion")
			if (btn_pressed_ind_under_time(GameGlobal.BTN_UP, -1, int(JUMP_SQUAT_LENGTH * 1.5)) and
				(btn_pressed_ind_under_time(GameGlobal.BTN_DOWN, -3, JUMP_SQUAT_LENGTH * 2) or
				btn_pressed_ind_under_time(GameGlobal.BTN_DOWN, -4, JUMP_SQUAT_LENGTH * 2))):
				jump_count -= 0.5
				aerial_vel.y = jump_height * 1.333
			else:
				aerial_vel.y = jump_height
		States.JUMP_AIR_INIT when ticks_since_state_change == 0:
			jump_count -= 1
			aerial_vel.x = walk_value() * walk_speed
			if not right_facing:
				aerial_vel.x *= -1
			aerial_vel.y = jump_height
		States.HURT_GRB:
			ground_vel = Vector3.ZERO
			aerial_vel = Vector3.ZERO
		States.HURT_HGH, States.HURT_LOW, States.HURT_CRCH, States.BLCK_HGH, States.BLCK_LOW when (
				stun_time_current == stun_time_start
		):
			ground_vel.x = (-1 if right_facing else 1) * kback.x
		States.HURT_FALL, States.HURT_BNCE, States.BLCK_AIR, States.OUTRO_BNCE, States.OUTRO_FALL when (
				stun_time_current == stun_time_start
		):
			aerial_vel = Vector3((-1 if right_facing else 1) * kback.x, kback.y, kback.z)
		States.HURT_LIE, States.OUTRO_LIE:
			ground_vel.x *= GROUND_SLIDE_FRICTION
		States.ATCK_NRML_IMP, States.ATCK_CMND_IMP:
			if opponent_on_stage_edge:
				ground_vel.x += (-1 if right_facing else 1) * walk_speed / 2

	aerial_vel.y += gravity
	aerial_vel.y = max(min_fall_vel, aerial_vel.y)
	#if aerial_vel.y < 0 and is_on_floor():
		#aerial_vel.y = 0
	velocity = aerial_vel if airborne() else ground_vel
	if force_collisions:
		area3d_intersect_check.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		area3d_intersect_check.process_mode = Node.PROCESS_MODE_DISABLED if airborne() else Node.PROCESS_MODE_INHERIT
	check_true = move_and_slide()


func reset_facing():
	right_facing = distance < 0
	grabbed_offset.x = GRABBED_OFFSET_X * (-1 ^ int(distance < 0))
