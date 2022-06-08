extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$CanvasLayer/Button.text = OS.get_executable_path()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func constructFolderPath(path: String, slashInd: int) -> String:
	var folderPath = ""
	for i in range(slashInd + 1): #+1 to include slash
		folderPath += path[i]
	return folderPath

func acquireContentPath() -> String:
	var fileManager = File.new()
	var folderPath = constructFolderPath(OS.get_executable_path(), OS.get_executable_path().find_last("/"))
	print(folderPath)
	if fileManager.file_exists(folderPath + "Content/foldercheck"):
		return folderPath + "Content/"
	print("Content Folder is missing.")
	return "FolderMissing"

func prepareGame() -> bool:
	var contentFolder = acquireContentPath()
	if contentFolder == "FolderMissing":
		return false
	return true

func _on_Start_pressed():
	if !prepareGame():
		get_tree().quit()
	
