extends KinematicBody

#Update this soon to comply with proposed 

var fighterName = "Ryu - SF2"
var tscnFile = "/SF2Ryu.tscn"
var charSelectIcon = "/Icon.png"
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
var heldButtons = [
	false, #up
	false, #down
	false, #left
	false, #right
	false, #LP
	false, #MP
	false, #HP
	false, #LK
	false, #MK
	false  #HK
]
var tooClose = false

func _ready():
	stateCurrent = "Idle"

func changeState(new_state):
	if states.has(new_state):
		stateCurrent = new_state

func handleInput():
	match stateCurrent:
		"Idle":
			if (heldButtons[3] and rightFacing) or (heldButtons[2] and !rightFacing):
				if !tooClose:
					stateCurrent = "WalkForward"
			if (heldButtons[2] and rightFacing) or (heldButtons[3] and !rightFacing):
				stateCurrent = "WalkBack"
		"WalkForward":
			if (!heldButtons[3] and rightFacing) or (!heldButtons[2] and !rightFacing) or tooClose:
				stateCurrent = "Idle"
		"WalkBack":
			if (!heldButtons[2] and rightFacing) or (!heldButtons[3] and !rightFacing):
				stateCurrent = "Idle"

func doState():
	match stateCurrent:
		"Idle":
			$AnimatedSprite3D.animation = "Idle"
		"WalkForward":
			$AnimatedSprite3D.animation = "Walk_Forward"
			translation += move_and_slide((Vector3.RIGHT if rightFacing else Vector3.LEFT) * walkSpeed, Vector3.UP)
		"WalkBack":
			$AnimatedSprite3D.animation = "Walk_Back"
			translation += move_and_slide((Vector3.LEFT if rightFacing else Vector3.RIGHT) * walkSpeed, Vector3.UP)
			if tooClose:
				translation.x += (-1 if rightFacing else 1) * walkSpeed
		"JumpForward":
			$AnimatedSprite3D.animation = "J_Forward"
			translation += move_and_slide((Vector3.RIGHT if rightFacing else Vector3.LEFT) * jumpSpeed, Vector3.UP)
		"JumpBack":
			$AnimatedSprite3D.animation = "J_Back"
			translation += move_and_slide((Vector3.LEFT if rightFacing else Vector3.RIGHT) * jumpSpeed, Vector3.UP)

func _on_Area_area_entered(_area):
	tooClose = true

func _on_Area_area_exited(_area):
	tooClose = false

func _physics_process(_delta):
	handleInput()
	doState()
