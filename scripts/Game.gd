extends Spatial

onready var player1 = get_node("/root/CharactersDict").player1
onready var player2 = get_node("/root/CharactersDict").player2

var stage

var statesBase = [
	"Idle",
	"WalkForward",
	"WalkBack",
	"CrouchStart",
	"CrouchHold",
	"CrouchEnd"
]

const cameraMaxX = 6
const cameraMaxY = 10
const movementBoundX = 8

func startGame():
	player1.translation = Vector3(player1.startXOffset * -1,0,0)
	player1.rightFacing = true
	player1.stateCurrent = "Idle"
	player2.translation = Vector3(player2.startXOffset,0,0)
	player2.rightFacing = false
	player2.stateCurrent = "Idle"

func _ready():
	stage = load("res://Content/Game/Stages/BlankStage.tscn")
	add_child(stage.instance())
	player1 = load(get_node("/root/CharactersDict").player1.tscnFile).instance()
	player2 = load(get_node("/root/CharactersDict").player2.tscnFile).instance()
	add_child(player1)
	add_child(player2)
	player1.loadExtraData()
	player2.loadExtraData()
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
			$Camera.translation.z = clamp(abs(player1.translation.x-player2.translation.x)/2, 1.5, 1.825)
			$Camera.translation.z += 0.5
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
	player2.heldButtons[0] = Input.is_action_pressed("second_up")
	player2.heldButtons[1] = Input.is_action_pressed("second_down")
	player2.heldButtons[2] = Input.is_action_pressed("second_left")
	player2.heldButtons[3] = Input.is_action_pressed("second_right")
	for button in range(player1.buttonCount):
		player1.heldButtons[button + 4] = Input.is_action_pressed("first_button" + str(button))
	for button in range(player2.buttonCount):
		player2.heldButtons[button + 4] = Input.is_action_pressed("second_button" + str(button))


func characterActBasic():
	if player1.stateCurrent in statesBase:
		if player1.translation < player2.translation:
			player1.rightFacing = true
		else:
			player1.rightFacing = false
		player1.rotation_degrees.y = 180 * int(player1.rightFacing)
	if player2.stateCurrent in statesBase:
		if player2.translation < player1.translation:
			player2.rightFacing = true
		else:
			player2.rightFacing = false
		player2.rotation_degrees.y = 180 * int(player2.rightFacing)
	player1.translation.x = clamp(player1.translation.x, -movementBoundX, movementBoundX)
	player1.translation.y = max(0.0, player1.translation.y)
	player2.translation.x = clamp(player2.translation.x, -movementBoundX, movementBoundX)
	player2.translation.y = max(0.0, player2.translation.y)
	player1.distance = abs(player1.translation.x - player2.translation.x)
	player2.distance = abs(player1.translation.x - player2.translation.x)
	$P1.translation = player1.translation
	$P1.translate(Vector3.UP * 2)
	$P2.translation = player2.translation
	$P2.translate(Vector3.UP * 2)
	

func _physics_process(_delta):
	cameraControl(0)
	handleInputs()
	characterActBasic()
