class_name RoundElement
extends TextureRect

@export var unfulfilled_texture : Texture2D
@export var fulfilled_texture : Texture2D

func fulfill():
	texture = fulfilled_texture

func unfulfill():
	texture = unfulfilled_texture
