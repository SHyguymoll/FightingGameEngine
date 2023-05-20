extends Node

@onready var character_icon = preload("res://scenes/CharacterIcon3D.tscn")
@onready var select = preload("res://scenes/PlayerSelect.tscn")
var screen = "Menu"
var FileIOManager: FileAccess
var DirIOManager: DirAccess
const reservedFolders = [ #Baseline folders in each Character
	"Scripts",
	"HelperScripts",
	"Sounds",
	"Sprites"
]
var menuLogo
var player1Cursor = null
var player2Cursor = null
var charTopLeft
var jumpDists
const WIDTH = 5
const X_LEFT = -2.5
const Y_TOP = 2
const Z_POSITION = -4
const X_JUMP = 1.25
const Y_JUMP = 1


#TODO: Redo a l l of this

func get_content_folder(debug: bool) -> void:
	Content.contentFolder = "res://Content" if debug else "user://Content"

func check_success(ret: String):
	if ret != "Success":
		push_error(ret)
		$MenuButtons/Start.hide()

func _ready():
	get_content_folder(OS.has_feature("editor"))
	check_success(prepare_game())
	check_success(prepare_menu())

func prepare_game() -> String:
	#Loads all characters into character roster via resource pack loading and ResourceLoader
	DirIOManager = DirAccess.open(Content.contentFolder)
	if !DirIOManager.dir_exists(Content.contentFolder):
		return "Content Folder missing."
	if !DirIOManager.dir_exists(Content.contentFolder + "/Characters"):
		return "Character folder missing."
	if !DirIOManager.dir_exists(Content.contentFolder + "/Game"):
		return "Game folder missing."
	var pcks = search_for_pcks(search_character_folder(Content.contentFolder + "/Characters"))
	var numberID = 0
	var rootFolder = Content.contentFolder.left(Content.contentFolder.rfind("/Content"))
	for pck in pcks:
		#needs reworking
		if ProjectSettings.load_resource_pack(pck):
			if !ResourceLoader.exists("FighterDetails.gd"):
				return "FighterDetails.gd missing in pck " + pck
			var fighter_details = load("FighterDetails.gd").new()
			if !("folder" in fighter_details):
				return "folder variable missing in FighterDetails.gd for pck " + pck
			if !("fighter_name" in fighter_details):
				return "fighter_name variable missing in FighterDetails.gd for pck " + pck
			if !("tscn_file" in fighter_details):
				return "tscn_file variable missing in FighterDetails.gd for pck " + pck
			if !("char_select_icon" in fighter_details):
				return "char_select_icon variable missing in FighterDetails.gd for pck " + pck
			if !ResourceLoader.exists("res://" + fighter_details.folder + "/MainScript.gd"):
				return "MainScript.gd missing in pck " + pck
			Content.characters[numberID] = {
				charName = fighter_details.fighter_name,
				tscnFile = fighter_details.tscn_file,
				charSelectIcon = fighter_details.char_select_icon
			}
			numberID += 1
	return "Success"

func prepare_menu() -> String:
	#Loads all menu elements
	var menuFolder = Content.contentFolder + "/Game/Menu"
	if !FileAccess.file_exists(menuFolder + "/MenuBackground.png"): return "Menu Background missing."
	if !FileAccess.file_exists(menuFolder + "/Font.ttf"): return "Menu Font missing."
	if !FileAccess.file_exists(menuFolder + "/Logo/Logo.tscn"): return "Logo missing."
	var charSelFolder = menuFolder + "/CharacterSelect"
	if !FileAccess.file_exists(charSelFolder + "/Player1Select.png"): return "Player1Select icon missing."
	if !FileAccess.file_exists(charSelFolder + "/Player2Select.png"): return "Player2Select icon missing."
	if !FileAccess.file_exists(charSelFolder + "/CharacterSelectBackground.png"): return "Character Select Background missing."
	
	$Background/Background.set_texture(buildTexture(menuFolder + "/MenuBackground.png", true))
	menuLogo = load(Content.contentFolder + "/Game/Menu/Logo/Logo.tscn").instantiate()
	menuLogo.set_position(menuLogo.menuPos)
	$Logo.add_child(menuLogo)
	$MenuButtons/Start.set("theme_override_fonts/font", loadFont(menuFolder + "/Font.ttf"))
	$MenuButtons/Credits.set("theme_override_fonts/font", loadFont(menuFolder + "/Font.ttf", 32))
	return "Success"

func _process(_delta):
	if screen == "CharSelect":
		player1Cursor.position = Vector3(
			charTopLeft.x + player1Cursor.selected.x * jumpDists.x,
			charTopLeft.y - player1Cursor.selected.y * jumpDists.y,
			charTopLeft.z
		)
		player2Cursor.position = Vector3(
			charTopLeft.x + player2Cursor.selected.x * jumpDists.x,
			charTopLeft.y - player2Cursor.selected.y * jumpDists.y,
			charTopLeft.z
		)
		if player1Cursor.choiceMade and player2Cursor.choiceMade:
			Content.p1 = Content.characters[
				Content.charMap[player1Cursor.selected.y][player1Cursor.selected.x]
			]
			Content.p2 = Content.characters[
				Content.charMap[player2Cursor.selected.y][player2Cursor.selected.x]
			]
			if get_tree().change_scene_to_file("res://scenes/Game.tscn"):
				printerr("game failed to load")

func search_character_folder(start_dir: String) -> Array: #Recursive breadth-first search in /Content/Characters
	var folders = []
	DirIOManager = DirAccess.open(start_dir)
	DirIOManager.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	while true:
		var folder = DirIOManager.get_next()
		if folder == "":
			if len(folders):
				for entry in folders:
					folders.append_array(search_character_folder(entry))
			break
		if DirIOManager.current_is_dir() and !reservedFolders.has(folder): #Avoid files for recursion loops, and common directories for speed
			folders.append(start_dir + "/" + folder)
	return folders

func search_for_pcks(dirs: Array) -> Array:
	var pckNames = []
	for dir in dirs:
		DirIOManager = DirAccess.open(dir)
		DirIOManager.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		while true:
			var file = DirIOManager.get_next()
			if file.get_extension() == "pck" or file.get_extension() == "zip":
				pckNames.append(DirIOManager.get_current_dir() + "/" + file)
			if file == "":
				break
	DirIOManager.list_dir_end()
	return pckNames

func buildTexture(image: String, needsProcessing: bool = true) -> ImageTexture:
	var processedImage
	if needsProcessing:
		processedImage = Image.new()
		processedImage.load(image)
	else:
		processedImage = ResourceLoader.load(image, "Image")
	return ImageTexture.create_from_image(processedImage)

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

func convertPSArrayToNumberArray(PSArray: PackedStringArray) -> Array:
	var convertedArray = []
	for item in PSArray:
		convertedArray.append(item.to_int())
	return convertedArray

func loadCharSelect():
	var characterFolder = Content.contentFolder + "/Game/Menu/CharacterSelect"
	$Background/Background.set_texture(buildTexture(characterFolder + "/CharacterSelectBackground.png"))
	Content.charMap = []
	if FileAccess.file_exists(characterFolder + "/Custom.txt"): #custom shape
		FileIOManager = FileAccess.open(characterFolder + "/Custom.txt", FileAccess.READ)
		var currentLine = FileIOManager.get_csv_line()
		charTopLeft = Vector3(float(currentLine[0]), float(currentLine[1]), float(currentLine[2]))
		currentLine = FileIOManager.get_csv_line()
		jumpDists = Vector2(float(currentLine[0]), float(currentLine[1]))
		var currentSlice = convertPSArrayToNumberArray(FileIOManager.get_csv_line())
		var sliceBuilt = []
		var previousSlice = currentSlice.duplicate()
		var currentIndex = 0
		var yIndex = 0
		for character in Content.characters:
			var icon = character_icon.instantiate()
			icon.name = Content.characters[character].char_name
			icon.characterData = Content.characters[character].tscn_file
			icon.set_surface_override_material(0,buildAlbedo(Content.characters[character].char_select_icon, false))
			$CharSelectHolder.add_child(icon)
			while currentSlice[currentIndex] == 0:
				sliceBuilt.append(null)
				currentIndex += 1
				if currentIndex == len(currentSlice):
					Content.charMap.append(sliceBuilt)
					sliceBuilt = []
					if FileIOManager.get_position() < FileIOManager.get_length():
						currentSlice = convertPSArrayToNumberArray(FileIOManager.get_csv_line())
						if !len(currentSlice) == len(previousSlice): return "ERROR: shape must occupy a rectangle of space"
						previousSlice = currentSlice.duplicate()
					else:
						currentSlice = previousSlice.duplicate()
						if !currentSlice.count(0) != len(currentSlice): return "ERROR: shape must not end with empty line"
					currentIndex = 0
					yIndex += 1
			if currentSlice[currentIndex] == 1:
				sliceBuilt.append(character)
				icon.position = Vector3(
					charTopLeft.x + currentIndex*jumpDists.x,
					charTopLeft.y - yIndex*jumpDists.y,
					charTopLeft.z
				)
				currentIndex += 1
				if currentIndex == len(currentSlice):
					Content.charMap.append(sliceBuilt)
					sliceBuilt = []
					if FileIOManager.get_position() < FileIOManager.get_length():
						currentSlice = convertPSArrayToNumberArray(FileIOManager.get_csv_line())
						if !len(currentSlice) == len(previousSlice): return "ERROR: shape must occupy a rectangle of space"
						previousSlice = currentSlice.duplicate()
					else:
						currentSlice = previousSlice.duplicate()
						if !currentSlice.count(0) != len(currentSlice): return "ERROR: shape must not end with empty line"
					currentIndex = 0
					yIndex += 1
		if currentIndex != len(currentSlice): #set the rest to 0 to stop floating
			while currentIndex != len(currentSlice):
				sliceBuilt.append(null)
				currentIndex += 1
			Content.charMap.append(sliceBuilt)
	else: #fallback shape
		charTopLeft = Vector3(X_LEFT,Y_TOP,Z_POSITION)
		var currentRowPos = 0
		var currentSlice = []
		for character in Content.characters:
			var icon = character_icon.instantiate()
			icon.name = Content.characters[character].char_name
			icon.characterData = Content.characters[character].tscn_file
			icon.set_surface_override_material(0,buildAlbedo(Content.characters[character].char_select_icon, false))
			$CharSelectHolder.add_child(icon)
			icon.position = charTopLeft
			charTopLeft.x += X_JUMP
			currentRowPos += 1
			currentSlice.append(character)
			if currentRowPos >= WIDTH:
				currentRowPos = 0
				charTopLeft.x = X_LEFT
				charTopLeft.y -= Y_JUMP
				Content.charMap.append(currentSlice)
				currentSlice = []
		if currentSlice != []:
			while len(currentSlice) != len(Content.charMap[0]):
				currentSlice.append(null)
			Content.charMap.append(currentSlice)
			currentSlice = []
	player1Cursor = select.instantiate()
	player1Cursor.name = "PlayerOne"
	player1Cursor.player = 0
	player1Cursor.selected = Vector2(0,0) #places at lefttopmost spot
	player1Cursor.maxX = len(Content.charMap[0])
	player1Cursor.maxY = len(Content.charMap)
	while Content.charMap[player1Cursor.selected.y][player1Cursor.selected.x] == null:
		player1Cursor.selected.x += 1
		if player1Cursor.selected.x == player1Cursor.maxX:
			player1Cursor.selected.x = 0
			player1Cursor.selected.y += 1
	player1Cursor.set_surface_override_material(0,buildAlbedo(characterFolder + "/Player1Select.png", true, true))
	$CharSelectHolder.add_child(player1Cursor)
	player2Cursor = select.instantiate()
	player2Cursor.name = "PlayerTwo"
	player2Cursor.player = 1
	player2Cursor.selected = Vector2(len(Content.charMap[0]) - 1,len(Content.charMap) - 1) #places at rightbottommost spot
	player2Cursor.maxX = len(Content.charMap[0])
	player2Cursor.maxY = len(Content.charMap)
	while Content.charMap[player2Cursor.selected.y][player2Cursor.selected.x] == null:
		player2Cursor.selected.x -= 1
		if player2Cursor.selected.x == -1:
			player2Cursor.selected.x = player2Cursor.maxX
			player2Cursor.selected.y -= 1
	player2Cursor.set_surface_override_material(0,buildAlbedo(characterFolder + "/Player2Select.png", true, true))
	$CharSelectHolder.add_child(player2Cursor)
	screen = "CharSelect"
	return "Success"

func _on_Start_pressed():
	$MenuButtons.hide()
	menuLogo.queue_free()
	check_success(loadCharSelect())
