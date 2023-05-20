extends Node3D

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


func build_texture(image: String, needsProcessing: bool = true) -> ImageTexture:
	var finalTexture = ImageTexture.new()
	var processedImage
	if needsProcessing:
		processedImage = Image.new()
		processedImage.load(image)
	else:
		processedImage = ResourceLoader.load(image, "Image")
	finalTexture.create_from_image(processedImage)
	return finalTexture

func build_albedo(image: String, needsProcessing = true, transparent: bool = false, unshaded: bool = true) -> StandardMaterial3D:
	var finalSpatial = StandardMaterial3D.new()
	var intermediateTexture = build_texture(image, needsProcessing)
	finalSpatial.set_texture(StandardMaterial3D.TEXTURE_ALBEDO, intermediateTexture)
	finalSpatial.flags_transparent = transparent
	finalSpatial.flags_unshaded = unshaded
	return finalSpatial

func load_font(font: String, size = 50):
	var newFont = FontFile.new()
	newFont.font_data = load(font)
	newFont.size = size
	return newFont

func make_hud():
	$HUD/P1Health.texture_under = build_texture(Content.contentFolder + "/Game/HUD/Player1Background.png")
	$HUD/P1Health.texture_progress = build_texture(Content.contentFolder + "/Game/HUD/Player1Bar.png")
	$HUD/P1Health.max_value = Content.p1.health
	$HUD/P1Health.value = Content.p1.health
	$HUD/P1Char.set("theme_override_fonts/font", load_font(Content.contentFolder + "/Game/HUD/PlayerFont.ttf", 64))
	$HUD/P1Inputs.set("theme_override_fonts/font", load_font(Content.contentFolder + "/Game/HUD/PlayerFont.ttf", 48))
	$HUD/P1Char.text = Content.p1.char_name
	$HUD/P2Health.texture_under = build_texture(Content.contentFolder + "/Game/HUD/Player2Background.png")
	$HUD/P2Health.texture_progress = build_texture(Content.contentFolder + "/Game/HUD/Player2Bar.png")
	$HUD/P2Health.max_value = Content.p2.health
	$HUD/P2Health.value = Content.p2.health
	$HUD/P2Char.set("theme_override_fonts/font", load_font(Content.contentFolder + "/Game/HUD/PlayerFont.ttf", 64))
	$HUD/P2Inputs.set("theme_override_fonts/font", load_font(Content.contentFolder + "/Game/HUD/PlayerFont.ttf", 48))
	$HUD/P2Char.text = Content.p2.char_name

func init_fighters():
	Content.p1.position = Vector3(Content.p1.STARTXOFFSET * -1,0,0)
	Content.p1.right_facing = true
	Content.p1.update_state(Content.p1.state_start, 0)
	Content.p1.initialize_boxes(true)
	
	Content.p2.position = Vector3(Content.p2.STARTXOFFSET,0,0)
	Content.p2.rightFacing = false
	Content.p2.update_state(Content.p2.state_start, 0)
	Content.p2.initialize_boxes(false)

func _ready():
	add_child(load("res://Content/Game/Stages/BlankStage.tscn").instantiate())
	Content.p1 = load(Content.p1).instantiate()
	Content.p2 = load(Content.p2).instantiate()
	make_hud()
	init_fighters()
	add_child(Content.p1)
	add_child(Content.p2)

const ORTH_DIST = 1.328125

func camera_control(mode: int):
	$Camera3D.projection = 1 if mode < 3 else 0 #0 = Perspective, 1 = Orthagonal
	match mode:
		#2d modes
		0: #default
			$Camera3D.position.x = (Content.p1.position.x + Content.p2.position.x)/2
			$Camera3D.position.y = max(Content.p1.position.y + 1, Content.p2.position.y + 1)
			$Camera3D.position.z = ORTH_DIST
			$Camera3D.size = clamp(abs(Content.p1.position.x - Content.p1.position.x)/2, 3.5, 6)
		1: #focus player1
			$Camera3D.position.x = Content.p1.position.x
			$Camera3D.position.y = Content.p1.position.y + 1
			$Camera3D.position.z = ORTH_DIST
		2: #focus player2
			$Camera3D.position.x = Content.p2.position.x
			$Camera3D.position.y = Content.p2.position.y + 1
			$Camera3D.position.z = ORTH_DIST
		#3d modes
		3: #default
			$Camera3D.position.x = (Content.p1.position.x + Content.p2.position.x)/2
			$Camera3D.position.y = max(Content.p1.position.y + 1, Content.p2.position.y + 1)
			$Camera3D.position.z = clamp(abs(Content.p1.position.x - Content.p2.position.x)/2, 1.5, 1.825) + 0.5
		4: #focus player1
			$Camera3D.position.x = Content.p1.position.x
			$Camera3D.position.y = Content.p1.position.y + 1
			$Camera3D.position.z = 1.5
		5: #focus player2
			$Camera3D.position.x = Content.p2.position.x
			$Camera3D.position.y = Content.p2.position.y + 1
			$Camera3D.position.z = 1.5
	$Camera3D.position.x = clamp($Camera3D.position.x, -CAMERAMAXX, CAMERAMAXX)
	$Camera3D.position.y = clamp($Camera3D.position.y, 0, CAMERAMAXY)

var directionDictionary = { 0: "x", 1: "↑", 2: "↓", 4: "←", 8: "→", 5: "↖", 6: "↙", 9: "↗", 10: "↘" }

func AttackValue(attackHash: int) -> String:
	return (" Ø" if bool(attackHash % 2) else " 0") + ("Ø" if bool((attackHash >> 1) % 2) else "0") + ("Ø" if bool((attackHash >> 2) % 2) else "0") + ("Ø" if bool((attackHash >> 3) % 2) else "0") + ("Ø" if bool((attackHash >> 4) % 2) else "0") + ("Ø " if bool((attackHash >> 5) % 2) else "0 ")

func buildInputsTracked() -> void:
	var latestInputs = InputHandle.p1_inputs.slice(max(0,InputHandle.p1_input_index - Content.p1.input_buffer_len), InputHandle.p1_input_index)
	$HUD/P1Inputs.text = ""
	for input in latestInputs:
		if input[0] < 0:
			return
		$HUD/P1Inputs.text += directionDictionary[input[0] % 16] + AttackValue(input[0] >> 4) + String(input[1]) + "\n"
	
	latestInputs = InputHandle.p2_inputs.slice(max(0,InputHandle.p2_input_index - Content.p2.input_buffer_len), InputHandle.p2_input_index)
	$HUD/P2Inputs.text = ""
	for input in latestInputs:
		if input[0] < 0:
			return
		$HUD/P2Inputs.text += String(input[1]) + AttackValue(input[0] >> 4) + directionDictionary[input[0] % 16] + "\n"

func getInputHashes() -> Array: return [ #convert to hash to send less data (a single int compared to an array)
	(int(InputHandle.p1_buttons[0]) * 1) + \
	(int(InputHandle.p1_buttons[1]) * 2) + \
	(int(InputHandle.p1_buttons[2]) * 4) + \
	(int(InputHandle.p1_buttons[3]) * 8) + \
	max(0, ((int(InputHandle.p1_buttons[4]) - int(Content.p1.BUTTONCOUNT < 1)) * 16)) + \
	max(0, ((int(InputHandle.p1_buttons[5]) - int(Content.p1.BUTTONCOUNT < 2)) * 32)) + \
	max(0, ((int(InputHandle.p1_buttons[6]) - int(Content.p1.BUTTONCOUNT < 3)) * 64)) + \
	max(0, ((int(InputHandle.p1_buttons[7]) - int(Content.p1.BUTTONCOUNT < 4)) * 128)) + \
	max(0, ((int(InputHandle.p1_buttons[8]) - int(Content.p1.BUTTONCOUNT < 5)) * 256)) + \
	max(0, ((int(InputHandle.p1_buttons[9]) - int(Content.p1.BUTTONCOUNT < 6)) * 512)),
	(int(InputHandle.p2_buttons[0]) * 1) + \
	(int(InputHandle.p2_buttons[1]) * 2) + \
	(int(InputHandle.p2_buttons[2]) * 4) + \
	(int(InputHandle.p2_buttons[3]) * 8) + \
	max(0, ((int(InputHandle.p2_buttons[4]) - int(Content.p2.BUTTONCOUNT < 1)) * 16)) + \
	max(0, ((int(InputHandle.p2_buttons[5]) - int(Content.p2.BUTTONCOUNT < 2)) * 32)) + \
	max(0, ((int(InputHandle.p2_buttons[6]) - int(Content.p2.BUTTONCOUNT < 3)) * 64)) + \
	max(0, ((int(InputHandle.p2_buttons[7]) - int(Content.p2.BUTTONCOUNT < 4)) * 128)) + \
	max(0, ((int(InputHandle.p2_buttons[8]) - int(Content.p2.BUTTONCOUNT < 5)) * 256)) + \
	max(0, ((int(InputHandle.p2_buttons[9]) - int(Content.p2.BUTTONCOUNT < 6)) * 512))
]

func handle_inputs():
	InputHandle.p1_buttons[0] = Input.is_action_pressed("first_up")
	InputHandle.p1_buttons[1] = Input.is_action_pressed("first_down")
	if InputHandle.p1_buttons[0] == InputHandle.p1_buttons[1]: #no conflicting directions
		InputHandle.p1_buttons[0] = false
		InputHandle.p1_buttons[1] = false
	InputHandle.p1_buttons[2] = Input.is_action_pressed("first_left")
	InputHandle.p1_buttons[3] = Input.is_action_pressed("first_right")
	if InputHandle.p1_buttons[2] == InputHandle.p1_buttons[3]: #ditto
		InputHandle.p1_buttons[2] = false
		InputHandle.p1_buttons[3] = false
	for button in range(Content.p1.BUTTONCOUNT):
		InputHandle.p1_buttons[button + 4] = Input.is_action_pressed("first_button" + str(button))
	
	InputHandle.p2_buttons[0] = Input.is_action_pressed("second_up")
	InputHandle.p2_buttons[1] = Input.is_action_pressed("second_down")
	if InputHandle.p2_buttons[0] == InputHandle.p2_buttons[1]: #no conflicting directions
		InputHandle.p2_buttons[0] = false
		InputHandle.p2_buttons[1] = false
	InputHandle.p2_buttons[2] = Input.is_action_pressed("second_left")
	InputHandle.p2_buttons[3] = Input.is_action_pressed("second_right")
	if InputHandle.p2_buttons[2] == InputHandle.p2_buttons[3]: #ditto
		InputHandle.p2_buttons[2] = false
		InputHandle.p2_buttons[3] = false
	for button in range(Content.p2.BUTTONCOUNT):
		InputHandle.p2_buttons[button + 4] = Input.is_action_pressed("second_button" + str(button))
	
	var calcHashes = getInputHashes()
	if len(InputHandle.p1_inputs) == 0:
		InputHandle.p1_inputs.append([calcHashes[0], 1])
	elif InputHandle.p1_inputs[InputHandle.p1_input_index][0] != calcHashes[0]:
		InputHandle.p1_inputs.append([calcHashes[0], 1])
		InputHandle.p1_input_index += 1
	else:
		InputHandle.p1_inputs[InputHandle.p1_input_index][1] += 1
	
	if len(InputHandle.p2_inputs) == 0:
		InputHandle.p2_inputs.append([calcHashes[1], 1])
	elif InputHandle.p2_inputs[InputHandle.p2_input_index][0] != calcHashes[1]:
		InputHandle.p2_inputs.append([calcHashes[1], 1])
		InputHandle.p2_input_index += 1
	else:
		InputHandle.p2_inputs[InputHandle.p2_input_index][1] += 1
	
	buildInputsTracked()
	
	var p1_buf = InputHandle.p1_inputs.slice(max(0, InputHandle.p1_input_index - Content.p1.input_buffer_len), InputHandle.p1_input_index)
	var p2_buf = InputHandle.p2_inputs.slice(max(0, InputHandle.p2_input_index - Content.p2.input_buffer_len), InputHandle.p1_input_index)
	
	Content.p1.step(p1_buf)
	Content.p2.step(p2_buf)


const HALFPI = 180
const TURNAROUND_ANIMSTEP = 3

#func characterActBasic():
#	if player1.stateCurrent in statesBase:
#		if player1.position < player2.position:
#			if player1.rightFacing != true:
#				player1.rightFacing = true
#				if player1.stateCurrent == statesBase.Idle:
#					player1.animStep = TURNAROUND_ANIMSTEP
#				if player1.stateCurrent == statesBase.Crouch:
#					player1.animStep = TURNAROUND_ANIMSTEP
#		else:
#			if player1.rightFacing != false:
#				player1.rightFacing = false
#				if player1.stateCurrent == statesBase.Idle:
#					player1.animStep = TURNAROUND_ANIMSTEP
#				if player1.stateCurrent == statesBase.Crouch:
#					player1.animStep = TURNAROUND_ANIMSTEP
#		player1.rotation_degrees.y = HALFPI * int(player1.rightFacing)
#	if player2.stateCurrent in statesBase:
#		if player2.position < player1.position:
#			if player2.rightFacing != true:
#				player2.rightFacing = true
#				if player2.stateCurrent == statesBase.Idle:
#					player2.animStep = TURNAROUND_ANIMSTEP
#				if player2.stateCurrent == statesBase.Crouch:
#					player2.animStep = TURNAROUND_ANIMSTEP
#		else:
#			if player2.rightFacing != false:
#				player2.rightFacing = false
#				if player2.stateCurrent == statesBase.Idle:
#					player2.animStep = TURNAROUND_ANIMSTEP
#				if player2.stateCurrent == statesBase.Crouch:
#					player2.animStep = TURNAROUND_ANIMSTEP
#		player2.rotation_degrees.y = HALFPI * int(player2.rightFacing)
#	player1.position.x = clamp(player1.position.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
#	player2.position.x = clamp(player2.position.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
#	player1.distance = abs(player1.position.x - player2.position.x)
#	player2.distance = abs(player1.position.x - player2.position.x)
	

func _physics_process(_delta):
	camera_control(cameraMode)
	handle_inputs()
#	characterActBasic()
