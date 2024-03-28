class_name DebugTargetter
extends Sprite3D

@export var pointer_texture : Texture2D
@export var pointer_target : Node3D

func _ready():
	texture = pointer_texture

func _process(_d):
	position = pointer_target.position + (Vector3.UP * 0.65)
