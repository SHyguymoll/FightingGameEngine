class_name State2DAnimationPlayer
extends DupliFlipping2DAnimationPlayer

@export var attached_fighter : State2DMeterFighter
var move_left_anim : StringName = &"basic/walk_left"
var move_right_anim : StringName = &"basic/walk_right"
var dash_left_anim : StringName = &"basic/dash"
var dash_right_anim : StringName = &"basic/dash"

var attack_return_states := {
	"attack_normal/a": State2DMeterFighter.States.IDLE,
	"attack_normal/a_imp": State2DMeterFighter.States.IDLE,
	"attack_normal/b": State2DMeterFighter.States.IDLE,
	"attack_normal/b_imp": State2DMeterFighter.States.IDLE,
	"attack_normal/c": State2DMeterFighter.States.IDLE,
	"attack_normal/c_imp": State2DMeterFighter.States.IDLE,
	"attack_normal/grab_followup": State2DMeterFighter.States.IDLE,
	"attack_normal/grab_whiff": State2DMeterFighter.States.IDLE,
	"attack_normal/grab_back_followup": State2DMeterFighter.States.IDLE,
	"attack_normal/grab_back_whiff": State2DMeterFighter.States.IDLE,
	"attack_command/crouch_a": State2DMeterFighter.States.CRCH,
	"attack_command/crouch_a_imp": State2DMeterFighter.States.CRCH,
	"attack_command/crouch_b": State2DMeterFighter.States.CRCH,
	"attack_command/crouch_b_imp": State2DMeterFighter.States.CRCH,
	"attack_command/crouch_c": State2DMeterFighter.States.CRCH,
	"attack_command/crouch_c_imp": State2DMeterFighter.States.CRCH,
	"attack_jumping/a": State2DMeterFighter.States.JUMP,
	"attack_jumping/a_imp": State2DMeterFighter.States.JUMP,
	"attack_jumping/b": State2DMeterFighter.States.JUMP_NO_ACT,
	"attack_jumping/b_imp": State2DMeterFighter.States.JUMP,
	"attack_jumping/c": State2DMeterFighter.States.JUMP_NO_ACT,
	"attack_jumping/c_imp": State2DMeterFighter.States.JUMP,
	"attack_motion/projectile": State2DMeterFighter.States.IDLE,
	"attack_motion/projectile_air": State2DMeterFighter.States.JUMP_NO_ACT,
	"attack_motion/uppercut": State2DMeterFighter.States.JUMP_NO_ACT,
	"attack_motion/spin_approach": State2DMeterFighter.States.JUMP_NO_ACT,
	"attack_motion/spin_approach_air": State2DMeterFighter.States.JUMP_NO_ACT,
	"attack_super/projectile": State2DMeterFighter.States.IDLE,
	"attack_super/projectile_air": State2DMeterFighter.States.JUMP_NO_ACT,
}

var grab_return_states := {
	"attack_normal/grab": {
		true: "attack_normal/grab_followup",
		false: "attack_normal/grab_whiff",
	},
	"attack_normal/grab_back": {
		true: "attack_normal/grab_back_followup",
		false: "attack_normal/grab_whiff",
	},
}

func update_animation():
	match attached_fighter.current_state:
		State2DMeterFighter.States.WALK_F when attached_fighter.right_facing:
			play(move_right_anim)
		State2DMeterFighter.States.WALK_F when not attached_fighter.right_facing:
			play(move_left_anim)
		State2DMeterFighter.States.WALK_B when attached_fighter.right_facing:
			play(move_left_anim)
		State2DMeterFighter.States.WALK_B when not attached_fighter.right_facing:
			play(move_right_anim)
		State2DMeterFighter.States.DASH_F when attached_fighter.right_facing:
			play(dash_right_anim)
		State2DMeterFighter.States.DASH_F when not attached_fighter.right_facing:
			play(dash_left_anim)
		State2DMeterFighter.States.DASH_B when attached_fighter.right_facing:
			play(dash_left_anim)
		State2DMeterFighter.States.DASH_B when not attached_fighter.right_facing:
			play(dash_right_anim)
		State2DMeterFighter.States.DASH_A_F when attached_fighter.right_facing:
			play(dash_right_anim)
		State2DMeterFighter.States.DASH_A_F when not attached_fighter.right_facing:
			play(dash_left_anim)
		State2DMeterFighter.States.DASH_A_B when attached_fighter.right_facing:
			play(dash_left_anim)
		State2DMeterFighter.States.DASH_A_B when not attached_fighter.right_facing:
			play(dash_right_anim)
		_:
			play(attached_fighter.basic_anim_state_dict[attached_fighter.current_state] + (anim_right_suf if attached_fighter.right_facing else anim_left_suf))


# Functions used by the AnimationPlayer to move the attached fighter within animations
func add_grd_vel(vel : Vector3):
	if not attached_fighter.right_facing:
		vel.x *= -1
	attached_fighter.ground_vel += vel


func add_air_vel(vel : Vector3):
	if not attached_fighter.right_facing:
		vel.x *= -1
	attached_fighter.aerial_vel += vel


func set_grd_vel(vel : Vector3):
	if not attached_fighter.right_facing:
		vel.x *= -1
	attached_fighter.ground_vel = vel


func set_air_vel(vel : Vector3):
	if not attached_fighter.right_facing:
		vel.x *= -1
	attached_fighter.aerial_vel = vel


func set_x_grd_vel(val : float):
	if not attached_fighter.right_facing:
		val *= -1
	attached_fighter.ground_vel.x = val


func set_x_air_vel(val : float):
	if not attached_fighter.right_facing:
		val *= -1
	attached_fighter.aerial_vel.x = val


func set_y_grd_vel(val : float):
	attached_fighter.ground_vel.y = val


func set_y_air_vel(val : float):
	attached_fighter.aerial_vel.y = val


func expediate_grd_vel(vel : Vector3):
	vel.x = abs(vel.x)
	if attached_fighter.ground_vel.x < 0:
		attached_fighter.ground_vel.x -= vel.x
	elif attached_fighter.ground_vel.x > 0:
		attached_fighter.ground_vel.x += vel.x
	else:
		if attached_fighter.right_facing:
			attached_fighter.ground_vel.x += vel.x
		else:
			attached_fighter.ground_vel.x -= vel.x
	if attached_fighter.ground_vel.y < 0:
		attached_fighter.ground_vel.y -= vel.y
	else:
		attached_fighter.ground_vel.y += vel.y


func expediate_air_vel(vel : Vector3):
	vel.x = abs(vel.x)
	if attached_fighter.aerial_vel.x < 0:
		attached_fighter.aerial_vel.x -= vel.x
	elif attached_fighter.aerial_vel.x > 0:
		attached_fighter.aerial_vel.x += vel.x
	else:
		if attached_fighter.right_facing:
			attached_fighter.aerial_vel.x += vel.x
		else:
			attached_fighter.aerial_vel.x -= vel.x
	if attached_fighter.aerial_vel.y < 0:
		attached_fighter.aerial_vel.y -= vel.y
	else:
		attached_fighter.aerial_vel.y += vel.y


func _on_animation_finished(anim_name: StringName) -> void:
	if (anim_name
			.trim_suffix(anim_left_suf)
			.trim_suffix(anim_right_suf)) in (
					attack_return_states.keys() + grab_return_states.keys()):
		attached_fighter.animation_ended = true
