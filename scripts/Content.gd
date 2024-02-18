extends Node

var content_folder : String
var characters : Dictionary = {}
var stages : Dictionary = {}
var char_map : Array = []

var stage : Stage
var p1_resource : Resource
var p2_resource : Resource
var p1 : Fighter #this is typically an extension of the base Fighter class.
var p2 : Fighter #ditto
