extends Node2D

var fileManager = File.new()
var folderManager = Directory.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	$CanvasLayer/Button.text = OS.get_executable_path()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func acquireContentPath() -> String:
	return OS.get_executable_path().left(OS.get_executable_path().find_last("/")) + "Content/"

func prepareGame(debug: bool):
	var contentFolder
	if debug:
		contentFolder = "res://Content"
	else:
		contentFolder = acquireContentPath()
	if !folderManager.dir_exists(contentFolder):
		return false
	var files = []
	folderManager.open(contentFolder)
	folderManager.list_dir_begin(true, true)
	while true:
		var file = folderManager.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)
	print(files)
	return true


func _on_Start_pressed():
	if !prepareGame(true):
		get_tree().quit()
	
