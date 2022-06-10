extends Spatial

var loadFrame = true

export var player1 = ""
export var player2 = ""

var stage

var statesBase = [
	"Idle",
	"WalkForward",
	"WalkBack",
	"CrouchStart",
	"CrouchHold",
	"CrouchEnd"
]

const cameraMaxX = 2.6
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
	var debugchar = load("res://Content/Characters/SF2/Ryu/SF2Ryu.tscn")
	player1 = debugchar.instance()
	player2 = debugchar.instance()
	add_child(player1)
	add_child(player2)
	startGame()
	loadFrame = true

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
			#$Camera.translation.z = clamp((player1.translation.x-player2.translation.x)/2, 2, 4)
			#$Camera.translation.z = (player1.translation.x-player2.translation.x)/2

func handleInputs():
	if player1.stateCurrent == "Idle":
		if (Input.is_action_pressed("first_right") and player1.rightFacing) or (Input.is_action_pressed("first_left") and !player1.rightFacing):
			player1.stateCurrent = "WalkForward"
		if (Input.is_action_pressed("first_left") and player1.rightFacing) or (Input.is_action_pressed("first_right") and !player1.rightFacing):
			player1.stateCurrent = "WalkBack"
	if player1.stateCurrent == "WalkForward":
		if (!Input.is_action_pressed("first_right") and player1.rightFacing) or (!Input.is_action_pressed("first_left") and !player1.rightFacing):
			player1.stateCurrent = "Idle"
	if player1.stateCurrent == "WalkBack":
		if (!Input.is_action_pressed("first_left") and player1.rightFacing) or (!Input.is_action_pressed("first_right") and !player1.rightFacing):
			player1.stateCurrent = "Idle"
	
	if player2.stateCurrent == "Idle":
		if (Input.is_action_pressed("second_right") and player2.rightFacing) or (Input.is_action_pressed("second_left") and !player2.rightFacing):
			player2.stateCurrent = "WalkForward"
		if (Input.is_action_pressed("second_left") and player2.rightFacing) or (Input.is_action_pressed("second_right") and !player2.rightFacing):
			player2.stateCurrent = "WalkBack"
	if player2.stateCurrent == "WalkForward":
		if (!Input.is_action_pressed("second_right") and player2.rightFacing) or (!Input.is_action_pressed("second_left") and !player2.rightFacing):
			player2.stateCurrent = "Idle"
	if player2.stateCurrent == "WalkBack":
		if (!Input.is_action_pressed("second_left") and player2.rightFacing) or (!Input.is_action_pressed("second_right") and !player2.rightFacing):
			player2.stateCurrent = "Idle"


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
	$P1.translation = player1.translation
	$P1.translate(Vector3.UP * 2)
	$P2.translation = player2.translation
	$P2.translate(Vector3.UP * 2)
	

func _physics_process(_delta):
	if loadFrame:
		loadFrame = false
	else:
		cameraControl(0)
		handleInputs()
		characterActBasic()
