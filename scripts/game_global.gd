extends Node

var global_hitstop : int
var freeze : bool = false

var win_threshold : int = 2
var p1_wins : int = 0
var p2_wins : int = 0

func _physics_process(_d):
	global_hitstop = max(global_hitstop - 1, 0)
