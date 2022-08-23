extends Spatial

var player1
var player2
var stage

enum statesBase {
	Idle = 3,
	WalkForward,
	WalkBack,
	Crouch,
}

export var cameraMode = 0
const CAMERAMAXX = 6
const CAMERAMAXY = 10
const MOVEMENTBOUNDX = 8


func buildTexture(image: String, needsProcessing: bool = true) -> ImageTexture:
	var finalTexture = ImageTexture.new()
	var processedImage
	if needsProcessing:
		processedImage = Image.new()
		processedImage.load(image)
	else:
		processedImage = ResourceLoader.load(image, "Image")
	finalTexture.create_from_image(processedImage)
	return finalTexture

func buildAlbedo(image: String, needsProcessing = true, transparent: bool = false, unshaded: bool = true) -> SpatialMaterial:
	var finalSpatial = SpatialMaterial.new()
	var intermediateTexture = buildTexture(image, needsProcessing)
	finalSpatial.set_texture(SpatialMaterial.TEXTURE_ALBEDO, intermediateTexture)
	finalSpatial.flags_transparent = transparent
	finalSpatial.flags_unshaded = unshaded
	return finalSpatial


func startGame():
	$HUD/P1Health.texture_under = buildTexture(CharactersDict.contentFolder + "/Game/HUD/Player1Background.png")
	$HUD/P1Health.texture_progress = buildTexture(CharactersDict.contentFolder + "/Game/HUD/Player1Bar.png")
	$HUD/P1Health.max_value = player1.health
	$HUD/P1Health.value = player1.health
	player1.translation = Vector3(player1.STARTXOFFSET * -1,0,0)
	player1.rightFacing = true
	player1.stateCurrent = statesBase.Idle
	$HUD/P1Char.text = CharactersDict.p1.charName
	$HUD/P2Health.texture_under = buildTexture(CharactersDict.contentFolder + "/Game/HUD/Player2Background.png")
	$HUD/P2Health.texture_progress = buildTexture(CharactersDict.contentFolder + "/Game/HUD/Player2Bar.png")
	$HUD/P2Health.max_value = player2.health
	$HUD/P2Health.value = player2.health
	player2.translation = Vector3(player2.STARTXOFFSET,0,0)
	player2.rightFacing = false
	player2.stateCurrent = statesBase.Idle
	$HUD/P2Char.text = CharactersDict.p2.charName

func _ready():
	stage = load("res://Content/Game/Stages/BlankStage.tscn")
	add_child(stage.instance())
	player1 = load(CharactersDict.p1.tscnFile).instance()
	player2 = load(CharactersDict.p2.tscnFile).instance()
	add_child(player1)
	add_child(player2)
	startGame()

const ORTH_DIST = 1.328125

func cameraControl(mode: int):
	$Camera.projection = 1 if mode < 3 else 0 #0 = Perspective, 1 = Orthagonal
	match mode:
		#2d modes
		0: #default
			$Camera.translation.x = (player1.translation.x+player2.translation.x)/2
			if player1.translation.y >= player2.translation.y:
				$Camera.translation.y = player1.translation.y + 1
			else:
				$Camera.translation.y = player2.translation.y + 1
			$Camera.translation.z = ORTH_DIST
			$Camera.size = clamp(abs(player1.translation.x-player2.translation.x)/2, 3.5, 6)
		1: #focus player1
			$Camera.translation.x = player1.translation.x
			$Camera.translation.y = player1.translation.y + 1
			$Camera.translation.z = ORTH_DIST
		2: #focus player2
			$Camera.translation.x = player2.translation.x
			$Camera.translation.y = player2.translation.y + 1
			$Camera.translation.z = ORTH_DIST
		#3d modes
		3: #default
			$Camera.translation.x = (player1.translation.x+player2.translation.x)/2
			if player1.translation.y >= player2.translation.y:
				$Camera.translation.y = player1.translation.y + 1
			else:
				$Camera.translation.y = player2.translation.y + 1
			$Camera.translation.z = clamp(abs(player1.translation.x-player2.translation.x)/2, 1.5, 1.825) + 0.5
		4: #focus player1
			$Camera.translation.x = player1.translation.x
			$Camera.translation.y = player1.translation.y + 1
			$Camera.translation.z = 1.5
		5: #focus player2
			$Camera.translation.x = player2.translation.x
			$Camera.translation.y = player2.translation.y + 1
			$Camera.translation.z = 1.5
	$Camera.translation.x = clamp($Camera.translation.x, -CAMERAMAXX, CAMERAMAXX)
	$Camera.translation.y = clamp($Camera.translation.y, 0, CAMERAMAXY)

var directionDictionary = { 0: "•", 1: "↑", 2: "↓", 4: "←", 8: "→", 5: "↖", 6: "↙", 9: "↗", 10: "↘" }
var attackDictionary = {}

func buildInputsTracked() -> void:
	var latestInputs = CharactersDict.p1InpHan.slice(max(0,CharactersDict.p1curInpInd - player1.BUFFERSIZE),CharactersDict.p1curInpInd)
	$HUD/P1Inputs.text = ""
	for input in latestInputs:
		if input[0] < 0:
			return
		$HUD/P1Inputs.text += directionDictionary[input[0] % 16] + (" %02d  " % (input[0] >> 4)) + String(input[1]) + "\n"
	
	latestInputs = CharactersDict.p2InpHan.slice(max(0,CharactersDict.p2curInpInd - player2.BUFFERSIZE),CharactersDict.p2curInpInd)
	$HUD/P2Inputs.text = ""
	for input in latestInputs:
		if input[0] < 0:
			return
		$HUD/P2Inputs.text += String(input[1]) + ("  %02d " % (input[0] >> 4)) + directionDictionary[input[0] % 16] + "\n"

func getInputHashes() -> Array: return [ #convert to hash to send less data (a single int compared to an array)
	(int(CharactersDict.p1Btns[0]) * 1) + \
	(int(CharactersDict.p1Btns[1]) * 2) + \
	(int(CharactersDict.p1Btns[2]) * 4) + \
	(int(CharactersDict.p1Btns[3]) * 8) + \
	max(0, ((int(CharactersDict.p1Btns[4]) - int(player1.BUTTONCOUNT < 1)) * 16)) + \
	max(0, ((int(CharactersDict.p1Btns[5]) - int(player1.BUTTONCOUNT < 2)) * 32)) + \
	max(0, ((int(CharactersDict.p1Btns[6]) - int(player1.BUTTONCOUNT < 3)) * 64)) + \
	max(0, ((int(CharactersDict.p1Btns[7]) - int(player1.BUTTONCOUNT < 4)) * 128)) + \
	max(0, ((int(CharactersDict.p1Btns[8]) - int(player1.BUTTONCOUNT < 5)) * 256)) + \
	max(0, ((int(CharactersDict.p1Btns[9]) - int(player1.BUTTONCOUNT < 6)) * 512)),
	(int(CharactersDict.p2Btns[0]) * 1) + \
	(int(CharactersDict.p2Btns[1]) * 2) + \
	(int(CharactersDict.p2Btns[2]) * 4) + \
	(int(CharactersDict.p2Btns[3]) * 8) + \
	max(0, ((int(CharactersDict.p2Btns[4]) - int(player2.BUTTONCOUNT < 1)) * 16)) + \
	max(0, ((int(CharactersDict.p2Btns[5]) - int(player2.BUTTONCOUNT < 2)) * 32)) + \
	max(0, ((int(CharactersDict.p2Btns[6]) - int(player2.BUTTONCOUNT < 3)) * 64)) + \
	max(0, ((int(CharactersDict.p2Btns[7]) - int(player2.BUTTONCOUNT < 4)) * 128)) + \
	max(0, ((int(CharactersDict.p2Btns[8]) - int(player2.BUTTONCOUNT < 5)) * 256)) + \
	max(0, ((int(CharactersDict.p2Btns[9]) - int(player2.BUTTONCOUNT < 6)) * 512))
]

func handleInputs():
	CharactersDict.p1Btns[0] = Input.is_action_pressed("first_up")
	CharactersDict.p1Btns[1] = Input.is_action_pressed("first_down")
	if CharactersDict.p1Btns[0] == CharactersDict.p1Btns[1]: #no conflicting directions
		CharactersDict.p1Btns[0] = false
		CharactersDict.p1Btns[1] = false
	CharactersDict.p1Btns[2] = Input.is_action_pressed("first_left")
	CharactersDict.p1Btns[3] = Input.is_action_pressed("first_right")
	if CharactersDict.p1Btns[2] == CharactersDict.p1Btns[3]: #ditto
		CharactersDict.p1Btns[2] = false
		CharactersDict.p1Btns[3] = false
	for button in range(player1.BUTTONCOUNT):
		CharactersDict.p1Btns[button + 4] = Input.is_action_pressed("first_button" + str(button))
	CharactersDict.p2Btns[0] = Input.is_action_pressed("second_up")
	CharactersDict.p2Btns[1] = Input.is_action_pressed("second_down")
	if CharactersDict.p2Btns[0] == CharactersDict.p2Btns[1]: #no conflicting directions
		CharactersDict.p2Btns[0] = false
		CharactersDict.p2Btns[1] = false
	CharactersDict.p2Btns[2] = Input.is_action_pressed("second_left")
	CharactersDict.p2Btns[3] = Input.is_action_pressed("second_right")
	if CharactersDict.p2Btns[2] == CharactersDict.p2Btns[3]: #ditto
		CharactersDict.p2Btns[2] = false
		CharactersDict.p2Btns[3] = false
	for button in range(player2.BUTTONCOUNT):
		CharactersDict.p2Btns[button + 4] = Input.is_action_pressed("second_button" + str(button))
	
	var calcHashes = getInputHashes()
	if len(CharactersDict.p1InpHan) == 0:
		CharactersDict.p1InpHan.append([calcHashes[0], 1])
	elif CharactersDict.p1InpHan[CharactersDict.p1curInpInd][0] != calcHashes[0]:
		CharactersDict.p1InpHan.append([calcHashes[0], 1])
		CharactersDict.p1curInpInd += 1
	else:
		CharactersDict.p1InpHan[CharactersDict.p1curInpInd][1] += 1
	
	if len(CharactersDict.p2InpHan) == 0:
		CharactersDict.p2InpHan.append([calcHashes[1], 1])
	elif CharactersDict.p2InpHan[CharactersDict.p2curInpInd][0] != calcHashes[1]:
		CharactersDict.p2InpHan.append([calcHashes[1], 1])
		CharactersDict.p2curInpInd += 1
	else:
		CharactersDict.p2InpHan[CharactersDict.p2curInpInd][1] += 1
	
	buildInputsTracked()
	
	player1.handleInput(CharactersDict.p1InpHan.slice(max(0,CharactersDict.p1curInpInd - player1.BUFFERSIZE),CharactersDict.p1curInpInd))
	player2.handleInput(CharactersDict.p2InpHan.slice(max(0,CharactersDict.p2curInpInd - player2.BUFFERSIZE),CharactersDict.p2curInpInd))

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
	player1.translation.x = clamp(player1.translation.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
	player2.translation.x = clamp(player2.translation.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
	player1.distance = abs(player1.translation.x - player2.translation.x)
	player2.distance = abs(player1.translation.x - player2.translation.x)
	

func _physics_process(_delta):
	cameraControl(cameraMode)
	handleInputs()
	characterActBasic()
