extends Node

const BTN_UP := "up"
const BTN_DOWN := "down"
const BTN_LEFT := "left"
const BTN_RIGHT := "right"
const BTN_0 := "button0"
const BTN_1 := "button1"
const BTN_2 := "button2"
const BTN_3 := "button3"
const BTN_4 := "button4"
const BTN_5 := "button5"

## When referring to multiple buttons use this const and append the required number to the end.
## E.G:
## [codeblock]
## for button in range(button_count):
## 	button_input_arr.append(Input.is_action_pressed(prefix + "_" + GameGlobal.BTN_UNSPEC + str(button)))
## [/codeblock]
const BTN_UNSPEC := "button"

var global_hitstop : int

var win_threshold : int = 2
var p1_wins : int = 0
var p2_wins : int = 0

func _physics_process(_d):
	global_hitstop = max(global_hitstop - 1, 0)
