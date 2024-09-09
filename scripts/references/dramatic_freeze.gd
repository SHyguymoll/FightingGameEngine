class_name DramaticFreeze
extends Node

var source : Fighter
var source_2d_pos : Vector2
var other : Fighter
var other_2d_pos : Vector2

signal end_freeze

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	pass

func complete_freeze() -> void:
	queue_free()
	emit_signal("end_freeze")
