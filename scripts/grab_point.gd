class_name GrabPoint
extends Node3D

var act_on_player := false

func _process(delta):
	($Debug as Node3D).rotate_y(0.5*delta)
