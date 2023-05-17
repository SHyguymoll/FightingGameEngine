extends Node3D

var player1
var player2
var stage

enum statesBase {
	Idle = 3,
	WalkForward,
	WalkBack,
	Crouch,
}

@export var cameraMode = 0
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

func buildAlbedo(image: String, needsProcessing = true, transparent: bool = false, unshaded: bool = true) -> StandardMaterial3D:
	var finalSpatial = StandardMaterial3D.new()
	var intermediateTexture = buildTexture(image, needsProcessing)
	finalSpatial.set_texture(StandardMaterial3D.TEXTURE_ALBEDO, intermediateTexture)
	finalSpatial.flags_transparent = transparent
	finalSpatial.flags_unshaded = unshaded
	return finalSpatial

func loadFont(font: String, size = 50):
	var newFont = FontFile.new()
	newFont.font_data = load(font)
	newFont.size = size
	return newFont

func startGame():
	$HUD/P1Health.texture_under = buildTexture(CharactersDict.contentFolder + "/Game/HUD/Player1Background.png")
	$HUD/P1Health.texture_progress = buildTexture(CharactersDict.contentFolder + "/Game/HUD/Player1Bar.png")
	$HUD/P1Health.max_value = player1.health
	$HUD/P1Health.value = player1.health
	player1.position = Vector3(player1.STARTXOFFSET * -1,0,0)
	player1.rightFacing = true
	player1.stateCurrent = statesBase.Idle
	$HUD/P1Char.set("theme_override_fonts/font", loadFont(CharactersDict.contentFolder + "/Game/HUD/PlayerFont.ttf", 64))
	$HUD/P1Inputs.set("theme_override_fonts/font", loadFont(CharactersDict.contentFolder + "/Game/HUD/PlayerFont.ttf", 48))
	$HUD/P1Char.text = CharactersDict.p1.charName
	$HUD/P2Health.texture_under = buildTexture(CharactersDict.contentFolder + "/Game/HUD/Player2Background.png")
	$HUD/P2Health.texture_progress = buildTexture(CharactersDict.contentFolder + "/Game/HUD/Player2Bar.png")
	$HUD/P2Health.max_value = player2.health
	$HUD/P2Health.value = player2.health
	player2.position = Vector3(player2.STARTXOFFSET,0,0)
	player2.rightFacing = false
	player2.stateCurrent = statesBase.Idle
	$HUD/P2Char.set("theme_override_fonts/font", loadFont(CharactersDict.contentFolder + "/Game/HUD/PlayerFont.ttf", 64))
	$HUD/P2Inputs.set("theme_override_fonts/font", loadFont(CharactersDict.contentFolder + "/Game/HUD/PlayerFont.ttf", 48))
	$HUD/P2Char.text = CharactersDict.p2.charName

func _ready():
	stage = load("res://Content/Game/Stages/BlankStage.tscn")
	add_child(stage.instantiate())
	player1 = load(CharactersDict.p1.tscnFile).instantiate()
	player2 = load(CharactersDict.p2.tscnFile).instantiate()
	add_child(player1)
	add_child(player2)
	startGame()

const ORTH_DIST = 1.328125

func cameraControl(mode: int):
	$Camera3D.projection = 1 if mode < 3 else 0 #0 = Perspective, 1 = Orthagonal
	match mode:
		#2d modes
		0: #default
			$Camera3D.position.x = (player1.position.x+player2.position.x)/2
			if player1.position.y >= player2.position.y:
				$Camera3D.position.y = player1.position.y + 1
			else:
				$Camera3D.position.y = player2.position.y + 1
			$Camera3D.position.z = ORTH_DIST
			$Camera3D.size = clamp(abs(player1.position.x-player2.position.x)/2, 3.5, 6)
		1: #focus player1
			$Camera3D.position.x = player1.position.x
			$Camera3D.position.y = player1.position.y + 1
			$Camera3D.position.z = ORTH_DIST
		2: #focus player2
			$Camera3D.position.x = player2.position.x
			$Camera3D.position.y = player2.position.y + 1
			$Camera3D.position.z = ORTH_DIST
		#3d modes
		3: #default
			$Camera3D.position.x = (player1.position.x+player2.position.x)/2
			if player1.position.y >= player2.position.y:
				$Camera3D.position.y = player1.position.y + 1
			else:
				$Camera3D.position.y = player2.position.y + 1
			$Camera3D.position.z = clamp(abs(player1.position.x-player2.position.x)/2, 1.5, 1.825) + 0.5
		4: #focus player1
			$Camera3D.position.x = player1.position.x
			$Camera3D.position.y = player1.position.y + 1
			$Camera3D.position.z = 1.5
		5: #focus player2
			$Camera3D.position.x = player2.position.x
			$Camera3D.position.y = player2.position.y + 1
			$Camera3D.position.z = 1.5
	$Camera3D.position.x = clamp($Camera3D.position.x, -CAMERAMAXX, CAMERAMAXX)
	$Camera3D.position.y = clamp($Camera3D.position.y, 0, CAMERAMAXY)

var directionDictionary = { 0: "x", 1: "↑", 2: "↓", 4: "←", 8: "→", 5: "↖", 6: "↙", 9: "↗", 10: "↘" }

func AttackValue(attackHash: int) -> String:
	return (" Ø" if bool(attackHash % 2) else " 0") + ("Ø" if bool((attackHash >> 1) % 2) else "0") + ("Ø" if bool((attackHash >> 2) % 2) else "0") + ("Ø" if bool((attackHash >> 3) % 2) else "0") + ("Ø" if bool((attackHash >> 4) % 2) else "0") + ("Ø " if bool((attackHash >> 5) % 2) else "0 ")

func buildInputsTracked() -> void:
	var latestInputs = CharactersDict.p1InpHan.slice(max(0,CharactersDict.p1curInpInd - player1.BUFFERSIZE),CharactersDict.p1curInpInd)
	$HUD/P1Inputs.text = ""
	for input in latestInputs:
		if input[0] < 0:
			return
		$HUD/P1Inputs.text += directionDictionary[input[0] % 16] + AttackValue(input[0] >> 4) + String(input[1]) + "\n"
	
	latestInputs = CharactersDict.p2InpHan.slice(max(0,CharactersDict.p2curInpInd - player2.BUFFERSIZE),CharactersDict.p2curInpInd)
	$HUD/P2Inputs.text = ""
	for input in latestInputs:
		if input[0] < 0:
			return
		$HUD/P2Inputs.text += String(input[1]) + AttackValue(input[0] >> 4) + directionDictionary[input[0] % 16] + "\n"

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
		if player1.position < player2.position:
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
		if player2.position < player1.position:
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
	player1.position.x = clamp(player1.position.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
	player2.position.x = clamp(player2.position.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
	player1.distance = abs(player1.position.x - player2.position.x)
	player2.distance = abs(player1.position.x - player2.position.x)
	

func _physics_process(_delta):
	cameraControl(cameraMode)
	handleInputs()
	characterActBasic()
