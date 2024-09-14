extends DupliFlipping2DAnimationPlayer

@export var attached_fighter : State2DMeterFighter

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
