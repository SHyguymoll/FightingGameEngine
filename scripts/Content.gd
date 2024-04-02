extends Node
## Holds all of the Fighters and Stages.
##
## This script is a singleton that is used to populate the Character Select Screen,
## and when loading into the game.

## Holds all of the Fighters.
## Each entry is an array with the following format:[br]
## [Fighter Name (String), Fighter File Path (String), Character Select Icon Path (String)]
var characters : Array = [
	[
		"Godot Guy",
		"res://Content/Characters/GodotGuy/scenes/GodotGuy.tscn",
		"res://Content/Characters/GodotGuy/IconSmall.png",
	],
]
## Holds all of the Stages.
## Each entry is an array with the following format:[br]
## [Stage Name (String), Stage File Path (String), 3D Compatibility (boolean)]
var stages : Array = [
	[
		"Blank 2D Stage",
		"res://Content/Stages/BlankStage/BlankStage.tscn",
		false,
	],
]
var char_map : Array = []

var stage_resource : Resource
var p1_resource : Resource
var p2_resource : Resource
