extends Node
## Holds all of the Fighters and Stages.
##
## This script is a singleton that is used to populate the Character Select Screen,
## and when loading into the game.

## Holds all of the Fighters.
var characters : Array[CharacterId] = [
	CharacterId.new("Godot Guy", "res://Content/Characters/GodotGuy/scenes/GodotGuy.tscn",
		"res://Content/Characters/GodotGuy/IconSmall.png"),
]


## Identifies a fighter to populate the Character Select Screen.
class CharacterId:
	var name : String
	var scene_path : String
	var icon_path : String
	func _init(na : String, sp : String, ip : String):
		name = na
		scene_path = sp
		icon_path = ip


## Holds all of the Stages.
var stages : Array[StageId] = [
	StageId.new("Blank 2D", "res://Content/Stages/BlankStage/BlankStage.tscn", false),
]


## Identifies a stage to be selected on the Character Select Screen.
class StageId:
	var name : String
	var scene_path : String
	var compat_3d : bool
	var icon_path : String
	func _init(na : String, sp : String, c3d : bool, ip : String = ""):
		name = na
		scene_path = sp
		compat_3d = c3d
		icon_path = ip


var char_map : Array = []

var stage_resource : Resource
var p1_resource : Resource
var p2_resource : Resource
