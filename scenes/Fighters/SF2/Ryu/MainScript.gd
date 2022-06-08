extends KinematicBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var moveSpeed = 0.1
var data = {
	health = 10,
	walkSpeed = 3,
	jumpHeight = 10,
	jumpSpeed = 3,
	jumpCount = 1,
	damageMultiplier = 1.0,
	states = [
		"Idle",
		"WalkForward",
		"WalkBack",
		"CrouchStart",
		"CrouchHold",
		"CrouchEnd",
		"JumpStart",
		"JumpForward",
		"JumpBack",
		"JumpNeutral"
	],
	
	
	stateCurrent = null,
	contentReferences = ["base"], #airBlock superJump was here, implement ssf2t.gd soon
}

#func _ready():
#	pass # Replace with function body.

func changeState(new_state):
	if data.states.has(new_state):
		data.stateCurrent = new_state

func doState():
	match data.stateCurrent:
		"Idle":
			

func _physics_process(delta):
	doState()
#	if Input.is_action_pressed("first_right"):
#		translation += move_and_slide(Vector3.RIGHT * moveSpeed, Vector3.UP)
#	if Input.is_action_pressed("first_left"):
#		translation += move_and_slide(Vector3.LEFT * moveSpeed, Vector3.UP)
#	if Input.is_action_just_pressed("first_attack_LP"):
#		print("LP")
#	if Input.is_action_just_pressed("first_attack_MP"):
#		print("MP")
#	if Input.is_action_just_pressed("first_attack_LP"):
#		print("HP")
#	if Input.is_action_just_pressed("first_attack_LK"):
#		print("LK")
#	if Input.is_action_just_pressed("first_attack_MK"):
#		print("MK")
#	if Input.is_action_just_pressed("first_attack_HK"):
#		print("HK")
