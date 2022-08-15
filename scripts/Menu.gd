extends Node

onready var characters = get_node("/root/CharactersDict").characters
onready var characterIcon = preload("res://scenes/CharacterIcon3D.tscn")
onready var select = preload("res://scenes/PlayerSelect.tscn")
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

func _ready():
	findContent(OS.has_feature("editor"))
	var errorRet = prepareGame()
	if errorRet != "Characters loaded successfully.":
		push_error(errorRet)
		$MenuButtons/Start.hide()
	errorRet = prepareMenu()
	if errorRet != "Menu loaded successfully.":
		push_error(errorRet)
		$MenuButtons/Start.hide()

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
			get_node("/root/CharactersDict").player1 = characters[
				CharactersDict.charMap[player1Cursor.selected.y][player1Cursor.selected.x]
			]
			get_node("/root/CharactersDict").player2 = characters[
				CharactersDict.charMap[player2Cursor.selected.y][player2Cursor.selected.x]
			]
			if get_tree().change_scene("res://scenes/Game.tscn"):
				printerr("game failed to load")

func findContent(debug: bool) -> void:
	contentFolder = "res://Content" if debug else OS.get_executable_path().get_base_dir() + "/Content"

func searchCharacterFolders(start_dir: String) -> Array: #Recursive breadth-first search in /Content/Characters
	var folders = []
	folderManager.open(start_dir)
	folderManager.list_dir_begin(true, true)
	while true:
		var folder = folderManager.get_next()
		if folder == "":
			if len(folders):
				for entry in folders:
					folders.append_array(searchCharacterFolders(entry))
			break
		if folderManager.current_is_dir() and !reservedFolders.has(folder): #Avoid files for recursion loops, and common directories for speed
			folders.append(start_dir + "/" + folder)
	return folders

func searchCharacterPcks(dirs: Array) -> Array:
	var pckNames = []
	for dir in dirs:
		folderManager.open(dir)
		folderManager.list_dir_begin(true, true)
		while true:
			var file = folderManager.get_next()
			if file.get_extension() == "pck" or file.get_extension() == "zip":
				pckNames.append(folderManager.get_current_dir() + "/" + file)
			if file == "":
				break
	folderManager.list_dir_end()
	return pckNames

func prepareGame() -> String:
	if !folderManager.dir_exists(contentFolder): return "Content Folder missing."
	if !folderManager.dir_exists(contentFolder + "/Characters"): return "Character folder missing."
	if !folderManager.dir_exists(contentFolder + "/Game"): return "Game folder missing."
	var characterFolder = searchCharacterFolders(contentFolder + "/Characters")
	var foundPcks = searchCharacterPcks(characterFolder)
	var numberID = 0
	for pck in foundPcks:
		if ProjectSettings.load_resource_pack(pck):
			if !fileManager.file_exists(contentFolder.left(contentFolder.find_last("/Content")) + "/FolderName.gdc"): return "FolderName.gdc missing in pck " + pck
			var folderName = ResourceLoader.load(contentFolder.left(contentFolder.find_last("/Content")) + "/FolderName.gdc").new()
			if !("folder" in folderName):
				folderName.free()
				return "folder variable missing in FolderName.gdc for pck " + pck
			if !ResourceLoader.exists("res://" + folderName.folder + "/MainScript.gd"): return "MainScript missing in pck " + pck
			var mainScript = ResourceLoader.load(
				"res://" + folderName.folder + "/MainScript.gd"
			).new()
			folderName.free()
			characters[numberID] = {
				charName = mainScript.fighterName,
				tscnFile = mainScript.tscnFile,
				charSelectIcon = mainScript.charSelectIcon
			}
			numberID += 1
			mainScript.free()
	return "Characters loaded successfully."

func buildTexture(image: String) -> ImageTexture:
	var iconTexture = ImageTexture.new()
	var iconImage = Image.new()
	iconImage.load(image)
	iconTexture.create_from_image(iconImage)
	return iconTexture

func buildAlbedo(image: String, transparent: bool = false, unshaded: bool = true) -> SpatialMaterial:
	var iconSpatial = SpatialMaterial.new()
	var iconTexture = buildTexture(image)
	iconSpatial.set_texture(SpatialMaterial.TEXTURE_ALBEDO, iconTexture)
	iconSpatial.flags_transparent = transparent
	iconSpatial.flags_unshaded = unshaded
	return iconSpatial

func prepareMenu() -> String:
	var menuFolder = contentFolder + "/Game/Menu"
	if !folderManager.file_exists(menuFolder + "/MenuBackground.png"): return "Menu Background missing."
	if !folderManager.file_exists(menuFolder + "/Font.ttf"): return "Menu Font missing."
	if !folderManager.file_exists(menuFolder + "/Logo/Logo.tscn"): return "Logo missing."
	var charSelFolder = menuFolder + "/CharacterSelect"
	if !folderManager.file_exists(charSelFolder + "/Player1Select.png"): return "Player1Select icon missing."
	if !folderManager.file_exists(charSelFolder + "/Player2Select.png"): return "Player2Select icon missing."
	if !folderManager.file_exists(charSelFolder + "/CharacterSelectBackground.png"): return "Character Select Background missing."
	
	$Background/Background.set_texture(buildTexture(menuFolder + "/MenuBackground.png"))
	menuLogo = load(contentFolder + "/Game/Menu/Logo/Logo.tscn").instance()
	menuLogo.set_translation(menuLogo.menuPos)
	$Logo.add_child(menuLogo)
	var dynamic_font = DynamicFont.new()
	dynamic_font.font_data = load(menuFolder + "/Font.ttf")
	dynamic_font.size = 50
	$MenuButtons/Start.set("custom_fonts/font", dynamic_font)
	return "Menu loaded successfully."

func convertPSArrayToNumberArray(PSArray: PoolStringArray) -> Array:
	var convertedArray = []
	for item in PSArray:
		convertedArray.append(item.to_int())
	return convertedArray

func loadCharSelect():
	$Background/Background.set_texture(buildTexture(contentFolder + "/Game/Menu/CharacterSelect/CharacterSelectBackground.png"))
	CharactersDict.charMap = []
	if folderManager.file_exists(contentFolder + "/Game/Menu/CharacterSelect/Custom.txt"): #custom shape
		fileManager.open(contentFolder + "/Game/Menu/CharacterSelect/Custom.txt", File.READ)
		var currentLine = fileManager.get_csv_line()
		charTopLeft = Vector3(float(currentLine[0]), float(currentLine[1]), float(currentLine[2]))
		currentLine = fileManager.get_csv_line()
		jumpDists = Vector2(float(currentLine[0]), float(currentLine[1]))
		var currentSlice = convertPSArrayToNumberArray(fileManager.get_csv_line())
		var sliceBuilt = []
		var previousSlice = currentSlice.duplicate()
		var currentIndex = 0
		var yIndex = 0
		for character in characters:
			var newIcon = characterIcon.instance()
			newIcon.name = characters[character].charName
			newIcon.characterData = characters[character].tscnFile
			newIcon.set_surface_material(0,buildAlbedo(characters[character].charSelectIcon))
			$CharSelectHolder.add_child(newIcon)
			while currentSlice[currentIndex] == 0:
				sliceBuilt.append(null)
				currentIndex += 1
				if currentIndex == len(currentSlice):
					CharactersDict.charMap.append(sliceBuilt)
					sliceBuilt = []
					if fileManager.get_position() < fileManager.get_len():
						currentSlice = convertPSArrayToNumberArray(fileManager.get_csv_line())
						if !len(currentSlice) == len(previousSlice): return "ERROR: shape must occupy a rectangle of space"
						previousSlice = currentSlice.duplicate()
					else:
						currentSlice = previousSlice.duplicate()
						if !currentSlice.count(0) != len(currentSlice): return "ERROR: shape must not end with empty line"
					currentIndex = 0
					yIndex += 1
			if currentSlice[currentIndex] == 1:
				sliceBuilt.append(character)
				newIcon.translation = Vector3(
					charTopLeft.x + currentIndex*jumpDists.x,
					charTopLeft.y - yIndex*jumpDists.y,
					charTopLeft.z
				)
				currentIndex += 1
				if currentIndex == len(currentSlice):
					CharactersDict.charMap.append(sliceBuilt)
					sliceBuilt = []
					if fileManager.get_position() < fileManager.get_len():
						currentSlice = convertPSArrayToNumberArray(fileManager.get_csv_line())
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
			CharactersDict.charMap.append(sliceBuilt)
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
			currentSlice.append(character)
			if currentRowPos >= WIDTH:
				currentRowPos = 0
				charTopLeft.x = X_LEFT
				charTopLeft.y -= Y_JUMP
				CharactersDict.charMap.append(currentSlice)
				currentSlice = []
		if currentSlice != []:
			while len(currentSlice) != len(CharactersDict.charMap[0]):
				currentSlice.append(null)
			CharactersDict.charMap.append(currentSlice)
			currentSlice = []
	player1Cursor = select.instance()
	player1Cursor.name = "PlayerOne"
	player1Cursor.player = 0
	player1Cursor.selected = Vector2(0,0) #places at lefttopmost spot
	player1Cursor.maxX = len(CharactersDict.charMap[0])
	player1Cursor.maxY = len(CharactersDict.charMap)
	while CharactersDict.charMap[player1Cursor.selected.y][player1Cursor.selected.x] == null:
		player1Cursor.selected.x += 1
		if player1Cursor.selected.x == player1Cursor.maxX:
			player1Cursor.selected.x = 0
			player1Cursor.selected.y += 1
	player1Cursor.set_surface_material(0,buildAlbedo(contentFolder + "/Game/Menu/CharacterSelect/Player1Select.png", true))
	$CharSelectHolder.add_child(player1Cursor)
	player2Cursor = select.instance()
	player2Cursor.name = "PlayerTwo"
	player2Cursor.player = 1
	player2Cursor.selected = Vector2(len(CharactersDict.charMap[0]) - 1,len(CharactersDict.charMap) - 1) #places at rightbottommost spot
	player2Cursor.maxX = len(CharactersDict.charMap[0])
	player2Cursor.maxY = len(CharactersDict.charMap)
	while CharactersDict.charMap[player2Cursor.selected.y][player2Cursor.selected.x] == null:
		player2Cursor.selected.x -= 1
		if player2Cursor.selected.x == -1:
			player2Cursor.selected.x = player2Cursor.maxX
			player2Cursor.selected.y -= 1
	player2Cursor.set_surface_material(0,buildAlbedo(contentFolder + "/Game/Menu/CharacterSelect/Player2Select.png", true))
	$CharSelectHolder.add_child(player2Cursor)
	screen = "CharSelect"
	return "Character Select loaded successfully."

func _on_Start_pressed():
	$MenuButtons/Start.hide()
	menuLogo.queue_free()
	var errorRet = loadCharSelect()
	if errorRet != "Character Select loaded successfully.":
		push_error(errorRet)
