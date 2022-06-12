extends Node

var fileManager = File.new()
var folderManager = Directory.new()

const reservedFolders = [ #Baseline folders in each Character
	"HelperScripts",
	"Sounds",
	"Sprites"
]

var characters = {}

onready var characterIcon = preload("res://Content/Game/Menu/CharacterIcon3D.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	var errorRet = prepareGame(true)
	if errorRet != "Characters loaded successfully.":
		print(errorRet)
		$CanvasLayer/Start.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

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
		if folderManager.current_is_dir() and !reservedFolders.has(folder): #Avoid not directories to avoid recursion loops, and common directories for speed
			folders.append(start_dir + "/" + folder)
	folderManager.list_dir_end()
	return folders

func prepareGame(debug: bool):
	var contentFolder
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
	for entry in characterFolder:
		folderManager.open(entry)
		if folderManager.file_exists("MainScript.gd"):
			var mainScript = load(folderManager.get_current_dir() + "/MainScript.gd").new()
			characters[mainScript.fighterName] = {
				directory = folderManager.get_current_dir(),
				mainScript = folderManager.get_current_dir() + mainScript.tscnFile,
				charSelectIcon = folderManager.get_current_dir() + mainScript.charSelectIcon
			}
			mainScript.free()
	return "Characters loaded successfully."

func loadCharSelect():
	var characterCount = len(characters)
	var cameraRect = $Camera.get_camera_transform()
	print(cameraRect)
	for character in characters:
		var newIcon = characterIcon.instance()
		newIcon.characterData = characters[character].mainScript
		print(newIcon.characterData)
		var iconSpatial = SpatialMaterial.new()
		var iconTexture = ImageTexture.new()
		var iconImage = Image.new()
		iconImage.load(characters[character].charSelectIcon)
		iconTexture.create_from_image(iconImage)
		iconSpatial.set_texture(SpatialMaterial.TEXTURE_ALBEDO, iconTexture)
		iconSpatial.flags_unshaded = true
		newIcon.get_node("MeshInstance").set_surface_material(0,iconSpatial)
		newIcon.get_node("MeshInstance")
		$CharSelectHolder.add_child(newIcon)
		newIcon.translation.x -= 1
		newIcon.translation.y += 1
		newIcon.translation.z -= 4

func _on_Start_pressed():
	$CanvasLayer/Start.hide()
	loadCharSelect()
	
