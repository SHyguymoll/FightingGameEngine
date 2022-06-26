extends Node

var screen = "Menu"

var fileManager = File.new()
var folderManager = Directory.new()

var contentFolder
const reservedFolders = [ #Baseline folders in each Character
	"Scripts",
	"HelperScripts",
	"Sounds",
	"Sprites"
]

onready var characters = get_node("/root/CharactersDict").characters
onready var characterIcon = preload("res://scenes/CharacterIcon3D.tscn")
onready var select = preload("res://scenes/PlayerSelect.tscn")

var menuLogo

var player1Cursor = null
var player2Cursor = null

#onready var screen_size = $Camera.get_viewport_rect().size
var charTopLeft
var jumpDists

const WIDTH = 5

const X_LEFT = -2.5
const Y_TOP = 2
const Z_POSITION = -4
const X_JUMP = 1.25
const Y_JUMP = 1


# Called when the node enters the scene tree for the first time.
func _ready():
	findContent(true)
	var errorRet = prepareGame()
	if errorRet != "Characters loaded successfully.":
		print(errorRet)
		$CanvasLayer/Start.hide()
	errorRet = prepareMenu()
	if errorRet != "Menu loaded successfully.":
		print(errorRet)
		$CanvasLayer/Start.hide()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if screen == "CharSelect":
		player1Cursor.translation = Vector3(
			charTopLeft.x + player1Cursor.selected.x * jumpDists.x,
			charTopLeft.y - player1Cursor.selected.y * jumpDists.y,
			charTopLeft.z
		)
		player2Cursor.translation = Vector3(
			charTopLeft.x + player2Cursor.selected.x * jumpDists.x,
			charTopLeft.y - player2Cursor.selected.y * jumpDists.y,
			charTopLeft.z
		)
		if player1Cursor.choiceMade and player2Cursor.choiceMade:
			get_node("/root/CharactersDict").player1 = characters[player1Cursor.selected]
			get_node("/root/CharactersDict").player2 = characters[player2Cursor.selected]
			if get_tree().change_scene("res://scenes/Game.tscn"):
				printerr("game failed to load")

func acquireContentPath() -> String:
	return OS.get_executable_path().left(OS.get_executable_path().find_last("/")) + "/Content"

func findContent(debug: bool) -> void:
	if debug:
		contentFolder = "res://Content"
	else:
		contentFolder = acquireContentPath()
	pass

func searchCharacters(start_dir: String) -> Array: #Recursive breadth-first search in /Content/Characters
	var folders = []
	folderManager.open(start_dir)
	folderManager.list_dir_begin(true, true)
	while true:
		var folder = folderManager.get_next()
		if folder == "":
			if len(folders):
				for entry in folders:
					folders.append_array(searchCharacters(entry))
			break
		if folderManager.current_is_dir() and !reservedFolders.has(folder): #Avoid files for recursion loops, and common directories for speed
			folders.append(start_dir + "/" + folder)
	folderManager.list_dir_end()
	return folders

func prepareGame() -> String:
	assert(folderManager.dir_exists(contentFolder), "Content Folder missing.")
	assert(folderManager.dir_exists(contentFolder + "/Characters"), "Character folder missing.")
	assert(folderManager.dir_exists(contentFolder + "/Game"), "Game folder missing.")
	var characterFolder = searchCharacters(contentFolder + "/Characters")
	var numberID = 0
	for entry in characterFolder:
		folderManager.open(entry)
		if folderManager.file_exists("MainScript.gd"):
			var mainScript = load(folderManager.get_current_dir() + "/MainScript.gd").new()
			for _a in range(25):
				characters[numberID] = {
					charName = mainScript.fighterName,
					directory = folderManager.get_current_dir(),
					tscnFile = folderManager.get_current_dir() + mainScript.tscnFile,
					charSelectIcon = folderManager.get_current_dir() + mainScript.charSelectIcon
				}
				numberID += 1
			mainScript.free()
	return "Characters loaded successfully."

func prepareMenu() -> String:
	assert(folderManager.dir_exists(contentFolder + "/Game/Menu"), "Menu missing.")
	var menuFolder = contentFolder + "/Game/Menu"
	assert(folderManager.file_exists(menuFolder + "/CharacterSelect/Player1Select.png"), "Player1Select icon missing.")
	assert(folderManager.file_exists(menuFolder + "/CharacterSelect/Player2Select.png"), "Player2Select icon missing.")
	assert(folderManager.file_exists(menuFolder + "/Logo/Logo.tscn"), "Logo missing.")
	
	menuLogo = load(contentFolder + "/Game/Menu/Logo/Logo.tscn").instance()
	menuLogo.set_translation(menuLogo.menuPos)
	add_child(menuLogo)
	return "Menu loaded successfully."

func buildAlbedo(image: String, transparent: bool = false, unshaded: bool = true) -> SpatialMaterial:
	var iconSpatial = SpatialMaterial.new()
	var iconTexture = ImageTexture.new()
	var iconImage = Image.new()
	iconImage.load(image)
	iconTexture.create_from_image(iconImage)
	iconSpatial.set_texture(SpatialMaterial.TEXTURE_ALBEDO, iconTexture)
	iconSpatial.flags_transparent = transparent
	iconSpatial.flags_unshaded = unshaded
	return iconSpatial

func convertPSArrayToNumberArray(PSArray: PoolStringArray) -> Array:
	var convertedArray = []
	for item in PSArray:
		convertedArray.append(item.to_int())
	return convertedArray

func loadCharSelect():
	var charMap = []
	if folderManager.file_exists(contentFolder + "/Game/Menu/CharacterSelect/Custom.txt"): #custom shape
		fileManager.open(contentFolder + "/Game/Menu/CharacterSelect/Custom.txt", File.READ)
		var currentLine = fileManager.get_csv_line()
		charTopLeft = Vector3(float(currentLine[0]), float(currentLine[1]), float(currentLine[2]))
		currentLine = fileManager.get_csv_line()
		jumpDists = Vector2(float(currentLine[0]), float(currentLine[1]))
		var currentSlice = convertPSArrayToNumberArray(fileManager.get_csv_line())
		var previousSlice = currentSlice.duplicate()
		charMap.append(currentSlice)
		var currentIndex = 0
		var yIndex = 0
		for character in characters:
			var newIcon = characterIcon.instance()
			newIcon.name = characters[character].charName
			newIcon.characterData = characters[character].tscnFile
			newIcon.set_surface_material(0,buildAlbedo(characters[character].charSelectIcon))
			$CharSelectHolder.add_child(newIcon)
			while currentSlice[currentIndex] == 0:
				currentIndex += 1
				if currentIndex == len(currentSlice):
					if fileManager.get_position() < fileManager.get_len():
						currentSlice = convertPSArrayToNumberArray(fileManager.get_csv_line())
						assert(len(currentSlice) == len(previousSlice), "ERROR: shape must occupy a rectangle of space")
						previousSlice = currentSlice.duplicate()
					else:
						currentSlice = previousSlice.duplicate()
						assert(currentSlice.count(0) != len(currentSlice), "ERROR: shape must not end with empty line")
					charMap.append(currentSlice)
					currentIndex = 0
					yIndex += 1
			if currentSlice[currentIndex] == 1:
				newIcon.translation = Vector3(
					charTopLeft.x + currentIndex*jumpDists.x,
					charTopLeft.y - yIndex*jumpDists.y,
					charTopLeft.z
				)
				currentIndex += 1
				if currentIndex == len(currentSlice):
					if fileManager.get_position() < fileManager.get_len():
						currentSlice = convertPSArrayToNumberArray(fileManager.get_csv_line())
						assert(len(currentSlice) == len(previousSlice), "ERROR: shape must occupy a rectangle of space")
						previousSlice = currentSlice.duplicate()
					else:
						currentSlice = previousSlice.duplicate()
						assert(currentSlice.count(0) != len(currentSlice), "ERROR: shape must not end with empty line")
					charMap.append(currentSlice)
					currentIndex = 0
					yIndex += 1
		if currentIndex != len(currentSlice) - 1: #set the rest to 0 to stop floating
			while currentIndex != len(currentSlice) - 1:
				charMap[yIndex][currentIndex] = 0
				currentIndex += 1
	else: #fallback shape
		charTopLeft = Vector3(X_LEFT,Y_TOP,Z_POSITION)
		var currentRowPos = 0
		var currentSlice = []
		for character in characters:
			var newIcon = characterIcon.instance()
			newIcon.name = characters[character].charName
			newIcon.characterData = characters[character].tscnFile
			newIcon.set_surface_material(0,buildAlbedo(characters[character].charSelectIcon))
			$CharSelectHolder.add_child(newIcon)
			newIcon.translation = charTopLeft
			charTopLeft.x += X_JUMP
			currentRowPos += 1
			currentSlice.append(1)
			if currentRowPos >= WIDTH:
				currentRowPos = 0
				charTopLeft.x = X_LEFT
				charTopLeft.y -= Y_JUMP
				charMap.append(currentSlice)
				currentSlice = []
		if currentSlice != []:
			while len(currentSlice) != len(charMap[0]):
				currentSlice.append(0)
			charMap.append(currentSlice)
			currentSlice = []
	
	player1Cursor = select.instance()
	player1Cursor.name = "PlayerOne"
	player1Cursor.player = 0
	player1Cursor.selected = Vector2(0,0) #places at lefttopmost spot
	player1Cursor.maxX = len(charMap[0])
	player1Cursor.maxY = len(charMap)
	while charMap[player1Cursor.selected.y][player1Cursor.selected.x] == 0:
		player1Cursor.selected.x += 1
		if player1Cursor.selected.x == player1Cursor.maxX:
			player1Cursor.selected.x = 0
			player1Cursor.selected.y += 1
	player1Cursor.charMap = charMap.duplicate(true)
	player1Cursor.set_surface_material(0,buildAlbedo(contentFolder + "/Game/Menu/CharacterSelect/Player1Select.png", true))
	$CharSelectHolder.add_child(player1Cursor)
	
	player2Cursor = select.instance()
	player2Cursor.name = "PlayerTwo"
	player2Cursor.player = 1
	player2Cursor.selected = Vector2(len(charMap[0]) - 1,len(charMap) - 1) #places at rightbottommost spot
	player2Cursor.maxX = len(charMap[0])
	player2Cursor.maxY = len(charMap)
	while charMap[player2Cursor.selected.y][player2Cursor.selected.x] == 0:
		player2Cursor.selected.x -= 1
		if player2Cursor.selected.x == -1:
			player2Cursor.selected.x = player2Cursor.maxX
			player2Cursor.selected.y -= 1
	player2Cursor.charMap = charMap.duplicate(true)
	player2Cursor.set_surface_material(0,buildAlbedo(contentFolder + "/Game/Menu/CharacterSelect/Player2Select.png", true))
	$CharSelectHolder.add_child(player2Cursor)
	
	screen = "CharSelect"

func _on_Start_pressed():
	$CanvasLayer/Start.hide()
	menuLogo.queue_free()
	loadCharSelect()
	
