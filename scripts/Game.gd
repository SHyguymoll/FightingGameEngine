extends Node3D

var p1: Fighter
var p2: Fighter
var stage : Stage

@export var camera_mode = 0
const CAMERA_MAX = Vector2(6, 10)
const MOVEMENT_BOUNDS_X = 8


func build_texture(image: String, needsProcessing: bool = true) -> ImageTexture:
	var finalTexture = ImageTexture.new()
	var processedImage
	if needsProcessing:
		processedImage = Image.new()
		processedImage.load(image)
	else:
		processedImage = ResourceLoader.load(image, "Image")
	return ImageTexture.create_from_image(processedImage)

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
	newFont.fixed_size = size
	return newFont

func make_hud():
	$HUD/P1Health.texture_under = build_texture(
			Content.content_folder.path_join("/Game/HUD/Player1Background.png"))
	$HUD/P1Health.texture_progress = build_texture(
			Content.content_folder.path_join("/Game/HUD/Player1Bar.png"))
	$HUD/P1Health.max_value = p1.health
	$HUD/P1Health.value = p1.health
	$HUD/P1Char.set(
			"theme_override_fonts/font",
			load_font(Content.content_folder.path_join("/Game/HUD/PlayerFont.ttf"), 64))
	$HUD/P1Inputs.set(
			"theme_override_fonts/font",
			load_font(Content.content_folder.path_join("/Game/HUD/PlayerFont.ttf"), 48))
	$HUD/P1Char.text = p1.char_name
	$HUD/P2Health.texture_under = build_texture(
			Content.content_folder.path_join("/Game/HUD/Player2Background.png"))
	$HUD/P2Health.texture_progress = build_texture(
			Content.content_folder.path_join("/Game/HUD/Player2Bar.png"))
	$HUD/P2Health.max_value = p2.health
	$HUD/P2Health.value = p2.health
	$HUD/P2Char.set(
			"theme_override_fonts/font",
			load_font(Content.content_folder.path_join("/Game/HUD/PlayerFont.ttf"), 64))
	$HUD/P2Inputs.set(
			"theme_override_fonts/font",
			load_font(Content.content_folder.path_join("/Game/HUD/PlayerFont.ttf"), 48))
	$HUD/P2Char.text = p2.char_name

func init_fighters():
	p1.position = Vector3(abs(p1.start_x_offset) * -1,0,0)
	p1.right_facing = true
	p1.update_state(p1.state_start, 0)
	p1.initialize_boxes(true)

	p2.position = Vector3(abs(p2.start_x_offset),0,0)
	p2.right_facing = false
	p2.update_state(p2.state_start, 0)
	p2.initialize_boxes(false)

func _ready():
	add_child(load("res://Content/Game/Stages/BlankStage.tscn").instantiate())
	stage = Content.stage_resource.instantiate()
	p1 = Content.p1_resource.instantiate()
	p2 = Content.p2_resource.instantiate()
	make_hud()
	init_fighters()
	add_child(p1)
	add_child(p2)

const ORTH_DIST = 1.328125

func camera_control(mode: int):
	$Camera3D.projection = 1 if mode < 3 else 0 #0 = Perspective, 1 = Orthagonal
	match mode:
		#2d modes
		0: #default
			$Camera3D.position.x = (p1.position.x + p2.position.x)/2
			$Camera3D.position.y = max(p1.position.y + 1, p2.position.y + 1)
			$Camera3D.position.z = ORTH_DIST
			$Camera3D.size = clampf(abs(p1.position.x - p2.position.x)/2, 3.5, 6)
		1: #focus player1
			$Camera3D.position.x = p1.position.x
			$Camera3D.position.y = p1.position.y + 1
			$Camera3D.position.z = ORTH_DIST
		2: #focus player2
			$Camera3D.position.x = p2.position.x
			$Camera3D.position.y = p2.position.y + 1
			$Camera3D.position.z = ORTH_DIST
		#3d modes
		3: #default
			$Camera3D.position.x = (p1.position.x + p2.position.x)/2
			$Camera3D.position.y = max(p1.position.y + 1, p2.position.y + 1)
			$Camera3D.position.z = clampf(
					abs(p1.position.x - p2.position.x)/2, 1.5, 1.825) + 0.5
		4: #focus player1
			$Camera3D.position.x = p1.position.x
			$Camera3D.position.y = p1.position.y + 1
			$Camera3D.position.z = 1.5
		5: #focus player2
			$Camera3D.position.x = p2.position.x
			$Camera3D.position.y = p2.position.y + 1
			$Camera3D.position.z = 1.5
	$Camera3D.position.clamp(
		Vector3(-CAMERA_MAX.x, 0, $Camera3D.position.z),
		Vector3(CAMERA_MAX.x, CAMERA_MAX.y, $Camera3D.position.z)
	)

var directionDictionary = {
	0: "x",
	1: "↑",
	2: "↓",
	4: "←",
	8: "→",
	5: "↖",
	6: "↙",
	9: "↗",
	10: "↘",
}

func attack_value(attackHash: int) -> String:
	return (" Ø" if bool(attackHash % 2) else " 0") + \
	("Ø" if bool((attackHash >> 1) % 2) else "0") + \
	("Ø" if bool((attackHash >> 2) % 2) else "0") + \
	("Ø" if bool((attackHash >> 3) % 2) else "0") + \
	("Ø" if bool((attackHash >> 4) % 2) else "0") + \
	("Ø " if bool((attackHash >> 5) % 2) else "0 ")

func slice_input_dictionary(input_dict: Dictionary, from: int, to: int):
	var ret_dict = {
		up=input_dict["up"].slice(from, to),
		down=input_dict["down"].slice(from, to),
		left=input_dict["left"].slice(from, to),
		right=input_dict["right"].slice(from, to),
	}
	var ret_dict_button_count = len(input_dict) - 4
	for i in range(ret_dict_button_count):
		ret_dict["button" + str(i)] = input_dict["button" + str(i)].slice(from, to)
	return ret_dict

func build_inputs_tracked() -> void:
	var latest_input_set = slice_input_dictionary(
		GameGlobal.p1_inputs,
		max(0, GameGlobal.p1_input_index - GameGlobal.p1.input_buffer_len),
		GameGlobal.p1_input_index + 1
	)
	$HUD/P1Inputs.text = ""
	for i in range(len(latest_input_set.up)):
		for button in latest_input_set:
			$HUD/P1Inputs.text += str(latest_input_set[button][i])
		$HUD/P1Inputs.text += "\n"

	latest_input_set = slice_input_dictionary(
		GameGlobal.p2_inputs,
		max(0, GameGlobal.p2_input_index - GameGlobal.p2.input_buffer_len),
		GameGlobal.p2_input_index + 1
	)
	$HUD/P2Inputs.text = ""
	for i in range(len(latest_input_set.up)):
		for button in latest_input_set:
			$HUD/P2Inputs.text += str(latest_input_set[button][i])
		$HUD/P2Inputs.text += "\n"

#convert to hash to simplify comparisons
func get_current_input_hashes() -> Array: return [
	(int(GameGlobal.p1_buttons[0]) * 1) + \
	(int(GameGlobal.p1_buttons[1]) * 2) + \
	(int(GameGlobal.p1_buttons[2]) * 4) + \
	(int(GameGlobal.p1_buttons[3]) * 8) + \
	max(0, ((int(GameGlobal.p1_buttons[4]) - int(p1.BUTTONCOUNT < 1)) * 16)) + \
	max(0, ((int(GameGlobal.p1_buttons[5]) - int(p1.BUTTONCOUNT < 2)) * 32)) + \
	max(0, ((int(GameGlobal.p1_buttons[6]) - int(p1.BUTTONCOUNT < 3)) * 64)) + \
	max(0, ((int(GameGlobal.p1_buttons[7]) - int(p1.BUTTONCOUNT < 4)) * 128)) + \
	max(0, ((int(GameGlobal.p1_buttons[8]) - int(p1.BUTTONCOUNT < 5)) * 256)) + \
	max(0, ((int(GameGlobal.p1_buttons[9]) - int(p1.BUTTONCOUNT < 6)) * 512)),
	(int(GameGlobal.p2_buttons[0]) * 1) + \
	(int(GameGlobal.p2_buttons[1]) * 2) + \
	(int(GameGlobal.p2_buttons[2]) * 4) + \
	(int(GameGlobal.p2_buttons[3]) * 8) + \
	max(0, ((int(GameGlobal.p2_buttons[4]) - int(p2.BUTTONCOUNT < 1)) * 16)) + \
	max(0, ((int(GameGlobal.p2_buttons[5]) - int(p2.BUTTONCOUNT < 2)) * 32)) + \
	max(0, ((int(GameGlobal.p2_buttons[6]) - int(p2.BUTTONCOUNT < 3)) * 64)) + \
	max(0, ((int(GameGlobal.p2_buttons[7]) - int(p2.BUTTONCOUNT < 4)) * 128)) + \
	max(0, ((int(GameGlobal.p2_buttons[8]) - int(p2.BUTTONCOUNT < 5)) * 256)) + \
	max(0, ((int(GameGlobal.p2_buttons[9]) - int(p2.BUTTONCOUNT < 6)) * 512))
]

func generate_prior_input_hash(player_inputs: Dictionary):
	var val = 0
	var multiplier = 1
	for inp in player_inputs:
		if player_inputs[inp][-1][1]:
			val += multiplier
		multiplier *= 2
	return val

func increment_inputs(player_inputs: Dictionary):
	for inp in player_inputs:
		player_inputs[inp][-1][0] += 1

func create_new_input_set(player_inputs: Dictionary, new_inputs: Array):
	var ind = 0
	for inp in player_inputs:
		if new_inputs[ind] == player_inputs[inp][-1][1]: #if the same input is the same here
			player_inputs[inp].append(player_inputs[inp][-1].duplicate()) #copy it over
		else: #otherwise, this is a new input, so make a new entry
			player_inputs[inp].append([1, new_inputs[ind]])
		ind += 1

func handle_inputs():
	GameGlobal.p1_buttons[0] = Input.is_action_pressed("first_up")
	GameGlobal.p1_buttons[1] = Input.is_action_pressed("first_down")
	if GameGlobal.p1_buttons[0] == GameGlobal.p1_buttons[1]: #no conflicting directions
		GameGlobal.p1_buttons[0] = false
		GameGlobal.p1_buttons[1] = false
	GameGlobal.p1_buttons[2] = Input.is_action_pressed("first_left")
	GameGlobal.p1_buttons[3] = Input.is_action_pressed("first_right")
	if GameGlobal.p1_buttons[2] == GameGlobal.p1_buttons[3]: #ditto
		GameGlobal.p1_buttons[2] = false
		GameGlobal.p1_buttons[3] = false
	for button in range(p1.BUTTONCOUNT):
		GameGlobal.p1_buttons[button + 4] = Input.is_action_pressed("first_button" + str(button))

	GameGlobal.p2_buttons[0] = Input.is_action_pressed("second_up")
	GameGlobal.p2_buttons[1] = Input.is_action_pressed("second_down")
	if GameGlobal.p2_buttons[0] == GameGlobal.p2_buttons[1]: #no conflicting directions
		GameGlobal.p2_buttons[0] = false
		GameGlobal.p2_buttons[1] = false
	GameGlobal.p2_buttons[2] = Input.is_action_pressed("second_left")
	GameGlobal.p2_buttons[3] = Input.is_action_pressed("second_right")
	if GameGlobal.p2_buttons[2] == GameGlobal.p2_buttons[3]: #ditto
		GameGlobal.p2_buttons[2] = false
		GameGlobal.p2_buttons[3] = false
	for button in range(p2.BUTTONCOUNT):
		GameGlobal.p2_buttons[button + 4] = Input.is_action_pressed("second_button" + str(button))

	var calcHashes = get_current_input_hashes()

	if generate_prior_input_hash(GameGlobal.p1_inputs) != calcHashes[0]:
		create_new_input_set(GameGlobal.p1_inputs, GameGlobal.p1_buttons)
		GameGlobal.p1_input_index += 1
	else:
		increment_inputs(GameGlobal.p1_inputs)

	if generate_prior_input_hash(GameGlobal.p2_inputs) != calcHashes[1]:
		create_new_input_set(GameGlobal.p2_inputs, GameGlobal.p2_buttons)
		GameGlobal.p2_input_index += 1
	else:
		increment_inputs(GameGlobal.p2_inputs)

	build_inputs_tracked()
	var p1_buf = slice_input_dictionary(
		GameGlobal.p1_inputs,
		max(0, GameGlobal.p1_input_index - GameGlobal.p1.input_buffer_len),
		GameGlobal.p1_input_index + 1
	)
	var p2_buf = slice_input_dictionary(
		GameGlobal.p2_inputs,
		max(0, GameGlobal.p2_input_index - GameGlobal.p2.input_buffer_len),
		GameGlobal.p2_input_index + 1
	)

	p1.step(p1_buf, GameGlobal.p1_input_index)
	p2.step(p2_buf, GameGlobal.p2_input_index)

func character_positioning():
	p1.position.x = clamp(p1.position.x, -MOVEMENT_BOUNDS_X, MOVEMENT_BOUNDS_X)
	p2.position.x = clamp(p2.position.x, -MOVEMENT_BOUNDS_X, MOVEMENT_BOUNDS_X)
	p1.distance = p1.position.x - p2.position.x
	p2.distance = p2.position.x - p1.position.x
	p1.reset_facing()
	p2.reset_facing()

func _physics_process(_delta):
	camera_control(camera_mode)
	handle_inputs()
	character_positioning()
