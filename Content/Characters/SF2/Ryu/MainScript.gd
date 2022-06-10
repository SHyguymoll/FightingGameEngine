extends KinematicBody

#Update this soon to comply with proposed 

var fighterName = "Ryu - SF2"
var health = 10
var walkSpeed = 0.1
var jumpHeight = 10
var jumpSpeed = 1
var jumpCount = 1
var damageMultiplier = 1.0
var defenseMultiplier = 1.0
var startXOffset = 1.5
var rightFacing = true

var states = [
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
	]
var stateCurrent = null

var tooClose = false

func _ready():
	stateCurrent = "Idle"

func changeState(new_state):
	if states.has(new_state):
		stateCurrent = new_state

func doState():
	match stateCurrent:
		"Idle":
			$AnimatedSprite3D.animation = "Idle"
		"WalkForward":
			$AnimatedSprite3D.animation = "Walk_Forward"
			if !tooClose:
				translation += move_and_slide((Vector3.RIGHT if rightFacing else Vector3.LEFT) * walkSpeed, Vector3.UP)
		"WalkBack":
			$AnimatedSprite3D.animation = "Walk_Back"
			translation += move_and_slide((Vector3.LEFT if rightFacing else Vector3.RIGHT) * walkSpeed, Vector3.UP)
		"JumpForward":
			$AnimatedSprite3D.animation = "J_Forward"
			translation += move_and_slide((Vector3.RIGHT if rightFacing else Vector3.LEFT) * jumpSpeed, Vector3.UP)
		"JumpBack":
			$AnimatedSprite3D.animation = "J_Back"
			translation += move_and_slide((Vector3.LEFT if rightFacing else Vector3.RIGHT) * jumpSpeed, Vector3.UP)

func _physics_process(_delta):
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


func _on_Area_area_entered(area):
	tooClose = true


func _on_Area_area_exited(area):
	tooClose = false
