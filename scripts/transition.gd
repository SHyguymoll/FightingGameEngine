class_name Transition
extends Control

@warning_ignore("unused_signal")
signal first_half_completed
@warning_ignore("unused_signal")
signal second_half_completed
var first_half_done := true
var second_half_done := true


func do_first_half():
	first_half_done = false

func do_second_half():
	second_half_done = false
