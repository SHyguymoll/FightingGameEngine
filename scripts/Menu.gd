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

var lastCharacterID
onready var characters = get_node("/root/CharactersDict").characters
onready var characterIcon = preload("res://scenes/CharacterIcon3D.tscn")
onready var select = preload("res://scenes/PlayerSelect.tscn")
var player1Cursor = null
var player2Cursor = null


#onready var screen_size = $Camera.get_viewport_rect().size
const WIDTH = 5
const X_LEFT = -2.5
const Y_TOP = 2
const X_JUMP = 1.25
const Y_JUMP = 1
const Z_POSITION = -4

# Called when the node enters the scene tree for the first time.
func _ready():
	var errorRet = prepareGame(true)
	if errorRet != "Characters loaded successfully.":
		print(errorRet)
		$CanvasLayer/Start.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if screen == "CharSelect":
		player1Cursor.translation = Vector3(
			((player1Cursor.selected % WIDTH)*X_JUMP)+X_LEFT,
			-((player1Cursor.selected/WIDTH)*Y_JUMP)+Y_TOP,
			Z_POSITION
		)
		player2Cursor.translation = Vector3(
			((player2Cursor.selected % WIDTH)*X_JUMP)+X_LEFT,
			-((player2Cursor.selected/WIDTH)*Y_JUMP)+Y_TOP,
			Z_POSITION
		)
		if player1Cursor.choiceMade and player2Cursor.choiceMade:
			get_node("/root/CharactersDict").player1 = characters[player1Cursor.selected]
			get_node("/root/CharactersDict").player2 = characters[player2Cursor.selected]
			get_tree().change_scene("res://scenes/Game.tscn")

func acquireContentPath() -> String:
	return OS.get_executable_path().left(OS.get_executable_path().find_last("/")) + "/Content"

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

func prepareGame(debug: bool) -> String:
	if debug:
		contentFolder = "res://Content"
	else:
		contentFolder = acquireContentPath()
	if !folderManager.dir_exists(contentFolder):
		return "Content Folder missing."
	if !folderManager.dir_exists(contentFolder + "/Characters"):
		return "Character folder missing."
	if !folderManager.dir_exists(contentFolder + "/Game"):
		return "Game folder missing."
	var characterFolder = searchCharacters(contentFolder + "/Characters")
	var numberID = 0
	for entry in characterFolder:
		folderManager.open(entry)
		if folderManager.file_exists("MainScript.gd"):
			var mainScript = load(folderManager.get_current_dir() + "/MainScript.gd").new()
			for _a in range(20):
				characters[numberID] = {
					charName = mainScript.fighterName,
					directory = folderManager.get_current_dir(),
					tscnFile = folderManager.get_current_dir() + mainScript.tscnFile,
					charSelectIcon = folderManager.get_current_dir() + mainScript.charSelectIcon
				}
				numberID += 1
			mainScript.free()
	lastCharacterID = numberID - 1
	return "Characters loaded successfully."

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

func loadCharSelect():
	#var characterCount = len(characters)
	var charSpawnPoint = Vector3(X_LEFT,Y_TOP,Z_POSITION)
	var currentRowPos = 0
	for character in characters:
		var newIcon = characterIcon.instance()
		newIcon.name = characters[character].charName
		newIcon.characterData = characters[character].tscnFile
		newIcon.set_surface_material(0,buildAlbedo(characters[character].charSelectIcon))
		#newIcon.connect("")
		$CharSelectHolder.add_child(newIcon)
		newIcon.translation = charSpawnPoint
		charSpawnPoint.x += X_JUMP
		currentRowPos += 1
		if currentRowPos >= WIDTH:
			currentRowPos = 0
			charSpawnPoint.x = X_LEFT
			charSpawnPoint.y -= Y_JUMP
	
	player1Cursor = select.instance()
	player1Cursor.name = "PlayerOne"
	player1Cursor.player = 0
	player1Cursor.selected = 0 #places at lefttopmost spot
	player1Cursor.maxWidth = WIDTH
	player1Cursor.lastID = lastCharacterID
	player1Cursor.set_surface_material(0,buildAlbedo(contentFolder + "/Game/Menu/Player1Select.png", true))
	$CharSelectHolder.add_child(player1Cursor)
	
	player2Cursor = select.instance()
	player2Cursor.name = "PlayerTwo"
	player2Cursor.player = 1
	player2Cursor.selected = (WIDTH - 1) if lastCharacterID > (WIDTH - 1) else lastCharacterID #places at righttopmost spot
	player2Cursor.maxWidth = WIDTH
	player2Cursor.lastID = lastCharacterID
	player2Cursor.set_surface_material(0,buildAlbedo(contentFolder + "/Game/Menu/Player2Select.png", true))
	$CharSelectHolder.add_child(player2Cursor)
	screen = "CharSelect"

func _on_Start_pressed():
	$CanvasLayer/Start.hide()
	loadCharSelect()
	
