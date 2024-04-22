class_name FighterCommand
extends Control

var title : String
var inputs : Array[TextureRect]
var description : String

@onready var _title_label := $HBoxContainer/Title
@onready var _inputs_hbox := $HBoxContainer/Inputs
@onready var _description_label := $RichTextLabel

func _ready() -> void:
	_title_label.text = title
	_description_label.text = description
	for input in inputs:
		_inputs_hbox.add_child(input)
