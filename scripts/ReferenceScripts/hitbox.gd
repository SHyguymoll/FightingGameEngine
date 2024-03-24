class_name Hitbox
extends Area3D

@export_category("Damage")
@export var damage_hit : float
@export var damage_block : float
@export_category("Stun")
@export var stun_hit : int
@export var stun_block : int
@export var hitstop_hit : int
@export var hitstop_block : int
@export_category("Knockback")
@export var kback_hit : Vector3
@export var kback_block : Vector3
@export_category("Audio")
@export var on_hit_sound : AudioStream
@export var on_block_sound : AudioStream
@export_category("Misc")
@export var lifetime : int
@export var is_projectile : bool
@export var hit_priority : int
@export var hit_type : String
@export var on_hit : Array
@export var on_block : Array

var invalid := false

func _physics_process(_d):
	if lifetime > 0:
		lifetime -= 1
	if lifetime == 0:
		queue_free()
