extends Spatial

export var player1 = {
	position = Vector3(),
	rightFacing = true,
	character = null
}
export var player2 = {
	position = Vector3(),
	rightFacing = true,
	character = null
}

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

func startGame():
	player1.position.x = player1.character.data.startXOffset * -1
	player1.position.y = 0
	player1.position.z = 0
	player1.rightFacing = true
	player2.position.x = player2.character.data.startXOffset
	player2.position.y = 0
	player2.position.z = 0
	player2.rightFacing = false

func _ready():
	stage = load("res://Content/Game/Stages/BlankStage.tscn")
	add_child(stage.instance())
	var debugchar = load("res://Content/Characters/SF2/Ryu/SF2Ryu.tscn")
	player1.character = debugchar.instance()
	player2.character = debugchar.instance()
	startGame()

func cameraControl(mode: int):
	match mode:
		0: #default
			$Camera.translation = player1.position+player2.position/2
			$Camera.translation.y += 3
			$Camera.translation.z += 5
			$Camera.translation.x = clamp($Camera.translation.x, -cameraMaxX, cameraMaxX)
			$Camera.translation.y = clamp($Camera.translation.y, 0, cameraMaxY)
			$Camera.translation.z = clamp(player1.position.x+player2.position.x/2, 4.5, 5)

func handleInputs():
	pass

func playerControl():
	if player1.character.stateCurrent in statesBase:
		if player1.position < player2.position:
			player1.rightFacing = true
			player2.rightFacing = false
		else:
			player1.rightFacing = false
			player2.rightFacing = true
		player1.character.rotation_degrees = 180 * player1.rightFacing
		player2.character.rotation_degrees = 180 * player2.rightFacing
	match player1.character.stateCurrent:
		"WalkForward":
			player1.position.x += player1.character.data.walkSpeed * (-1 * (!player1.rightFacing))
		"WalkBack":
			player1.position.x -= player1.character.data.walkSpeed * (-1 * (!player1.rightFacing))
		"JumpForward":
			player1.position.x += player1.character.data.jumpSpeed * (-1 * (!player1.rightFacing))
		"JumpBack":
			player1.position.x -= player1.character.data.jumpSpeed * (-1 * (!player1.rightFacing))
	match player2.character.stateCurrent:
		"WalkForward":
			player2.position.x += player2.character.data.walkSpeed * (-1 * (!player2.rightFacing))
		"WalkBack":
			player2.position.x -= player2.character.data.walkSpeed * (-1 * (!player2.rightFacing))
		"JumpForward":
			player2.position.x += player2.character.data.jumpSpeed * (-1 * (!player2.rightFacing))
		"JumpBack":
			player2.position.x -= player2.character.data.jumpSpeed * (-1 * (!player2.rightFacing))
	player1.position.x = clamp(player1.position.x, -cameraMaxX, cameraMaxX)
	player2.position.x = clamp(player2.position.x, -cameraMaxX, cameraMaxX)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	cameraControl(0)
	handleInputs()
	playerControl()
