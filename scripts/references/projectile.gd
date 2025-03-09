class_name Projectile
extends Node3D

@warning_ignore("unused_signal")
signal projectile_ended(proj)

@export var hitbox : Node3D
var right_facing : bool
var type : int
var source : int
var paused : bool

func _ready():
	pass

func tick(_delta : float, _animate_only : bool = false):
	pass

func update_paused(new_paused : bool):
	paused = new_paused

func destroy():
	if hitbox != null:
		hitbox.queue_free()

func _on_projectile_contact(other):
	if hitbox == null:
		return
	var o_par = other.get_parent()
	if other is Stage or o_par is Stage:
		destroy()
	if o_par is Projectile:
		if o_par.hitbox == null:
			return
		if source != o_par.source and hitbox.hit_priority <= o_par.hitbox.hit_priority:
			destroy()
