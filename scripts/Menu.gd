extends Node2D

var fileManager = File.new()
var folderManager = Directory.new()

const reservedFolders = [
	"HelperScripts",
	"Sounds",
	"Sprites"
]

var characters = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	$CanvasLayer/Button.text = OS.get_executable_path()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func acquireContentPath() -> String:
	return OS.get_executable_path().left(OS.get_executable_path().find_last("/")) + "Content/"

func bfSearch(start_dir: String) -> Array:
	var folders = []
	folderManager.open(start_dir)
	folderManager.list_dir_begin(true, true)
	while true:
		var folder = folderManager.get_next()
		if folder == "":
			if len(folders):
				for entry in folders:
					folders.append_array(bfSearch(entry))
			break
		if folderManager.current_is_dir() and !reservedFolders.has(folder):
			folders.append(start_dir + "/" + folder)
	return folders

#func dfSearch(start_dir: String) -> Array:
#	if !start_dir:
#		return []
#	var folders = []
#	folderManager.open(start_dir)
#	folderManager.list_dir_begin(true, true)
#	print(folderManager)
#	while true:
#		var check = folderManager.get_next()
#		if check:
#			folders.append_array(dfSearch(start_dir + "/" + check))
#		else:
#			break
#	return folders

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
	var characterFolder = bfSearch(contentFolder + "/Characters")
	for entry in characterFolder:
		folderManager.open(entry)
		if folderManager.file_exists("MainScript.gd"):
			print(folderManager.get_current_dir() + "/MainScript.gd")
			var mainScript = load(folderManager.get_current_dir() + "/MainScript.gd").new()
			characters[mainScript.fighterName] = [mainScript.tscnFile, mainScript.charSelectIcon]
			mainScript.free()
			return "Characters loaded successfully."


func _on_Start_pressed():
	var errorRet = prepareGame(true)
	print(errorRet)
	match errorRet:
		"Characters loaded successfully.":
			pass
		_:
			get_tree().quit()
	
