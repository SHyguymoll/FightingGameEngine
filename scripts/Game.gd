extends Spatial

onready var player1 = get_node("/root/CharactersDict").player1
onready var player2 = get_node("/root/CharactersDict").player2

var stage

enum statesBase {
	Idle = 3,
	WalkForward,
	WalkBack,
	Crouch,
}

const cameraMaxX = 6
const cameraMaxY = 10
const movementBoundX = 8

func startGame():
	player1.translation = Vector3(player1.STARTXOFFSET * -1,0,0)
	player1.rightFacing = true
	player1.stateCurrent = statesBase.Idle
	player2.translation = Vector3(player2.STARTXOFFSET,0,0)
	player2.rightFacing = false
	player2.stateCurrent = statesBase.Idle

func _ready():
	stage = load("res://Content/Game/Stages/BlankStage.tscn")
	add_child(stage.instance())
	player1 = load(get_node("/root/CharactersDict").player1.tscnFile).instance()
	player2 = load(get_node("/root/CharactersDict").player2.tscnFile).instance()
	add_child(player1)
	add_child(player2)
	startGame()

func cameraControl(mode: int):
	match mode:
		0: #default
			$Camera.translation.x = (player1.translation.x+player2.translation.x)/2
			if player1.translation.y >= player2.translation.y:
				$Camera.translation.y = player1.translation.y
			else:
				$Camera.translation.y = player2.translation.y
			$Camera.translation.y += 1
			$Camera.translation.x = clamp($Camera.translation.x, -cameraMaxX, cameraMaxX)
			$Camera.translation.y = clamp($Camera.translation.y, 0, cameraMaxY)
			#$Camera.translation.z = clamp(abs(player1.translation.x-player2.translation.x)/2, 1.5, 1.825)
			$Camera.translation.z = 1.328125
			$Camera.size = clamp(abs(player1.translation.x-player2.translation.x)/2, 3, 4)
#			$Camera.translation.z = abs(player1.translation.x-player2.translation.x)/2
		1: #focus player1
			$Camera.translation.x = (player1.translation.x+(player2.translation.x * 0.05))/2
			$Camera.translation.y = player1.translation.y
			$Camera.translation.y += 1
			$Camera.translation.x = clamp($Camera.translation.x, -cameraMaxX, cameraMaxX)
			$Camera.translation.y = clamp($Camera.translation.y, 0, cameraMaxY)
			$Camera.translation.z = 2
		2: #focus player2
			$Camera.translation.x = (player2.translation.x+(player1.translation.x * 0.05))/2
			$Camera.translation.y = player2.translation.y
			$Camera.translation.y += 1
			$Camera.translation.x = clamp($Camera.translation.x, -cameraMaxX, cameraMaxX)
			$Camera.translation.y = clamp($Camera.translation.y, 0, cameraMaxY)
			$Camera.translation.z = 2

func handleInputs():
	player1.heldButtons[0] = Input.is_action_pressed("first_up")
	player1.heldButtons[1] = Input.is_action_pressed("first_down")
	player1.heldButtons[2] = Input.is_action_pressed("first_left")
	player1.heldButtons[3] = Input.is_action_pressed("first_right")
	for button in range(player1.BUTTONCOUNT):
		player1.heldButtons[button + 4] = Input.is_action_pressed("first_button" + str(button))
	player2.heldButtons[0] = Input.is_action_pressed("second_up")
	player2.heldButtons[1] = Input.is_action_pressed("second_down")
	player2.heldButtons[2] = Input.is_action_pressed("second_left")
	player2.heldButtons[3] = Input.is_action_pressed("second_right")
	for button in range(player2.BUTTONCOUNT):
		player2.heldButtons[button + 4] = Input.is_action_pressed("second_button" + str(button))
	player1.handleInput()
	player2.handleInput()

const HALFPI = 180
const TURNAROUND_ANIMSTEP = 3

func characterActBasic():
	if player1.stateCurrent in statesBase:
		if player1.translation < player2.translation:
			if player1.rightFacing != true:
				player1.rightFacing = true
				if player1.stateCurrent == statesBase.Idle:
					player1.animStep = TURNAROUND_ANIMSTEP
				if player1.stateCurrent == statesBase.Crouch:
					player1.animStep = TURNAROUND_ANIMSTEP
		else:
			if player1.rightFacing != false:
				player1.rightFacing = false
				if player1.stateCurrent == statesBase.Idle:
					player1.animStep = TURNAROUND_ANIMSTEP
				if player1.stateCurrent == statesBase.Crouch:
					player1.animStep = TURNAROUND_ANIMSTEP
		player1.rotation_degrees.y = HALFPI * int(player1.rightFacing)
	if player2.stateCurrent in statesBase:
		if player2.translation < player1.translation:
			if player2.rightFacing != true:
				player2.rightFacing = true
				if player2.stateCurrent == statesBase.Idle:
					player2.animStep = TURNAROUND_ANIMSTEP
				if player2.stateCurrent == statesBase.Crouch:
					player2.animStep = TURNAROUND_ANIMSTEP
		else:
			if player2.rightFacing != false:
				player2.rightFacing = false
				if player2.stateCurrent == statesBase.Idle:
					player2.animStep = TURNAROUND_ANIMSTEP
				if player2.stateCurrent == statesBase.Crouch:
					player2.animStep = TURNAROUND_ANIMSTEP
		player2.rotation_degrees.y = HALFPI * int(player2.rightFacing)
	player1.translation.x = clamp(player1.translation.x, -movementBoundX, movementBoundX)
	player1.translation.y = max(0.0, player1.translation.y)
	player2.translation.x = clamp(player2.translation.x, -movementBoundX, movementBoundX)
	player2.translation.y = max(0.0, player2.translation.y)
	player1.distance = abs(player1.translation.x - player2.translation.x)
	player2.distance = abs(player1.translation.x - player2.translation.x)
	#debugging meshes
	$P1.translation = player1.translation
	$P1.translate(Vector3.UP * 2)
	$P2.translation = player2.translation
	$P2.translate(Vector3.UP * 2)
	

func _physics_process(_delta):
	cameraControl(0)
	handleInputs()
	characterActBasic()
