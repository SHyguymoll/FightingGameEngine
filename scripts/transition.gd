class_name Transition
extends Control

signal first_half_completed
signal second_half_completed
var first_half_done := true
var second_half_done := true


func do_first_half():
	first_half_done = false

func do_second_half():
	second_half_done = false
