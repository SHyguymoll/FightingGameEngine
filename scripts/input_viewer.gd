extends ColorRect

const JOYSTICK_CHANGE = 65.5
@export var player : String
@onready var button_on = preload("res://Content/Art/Menu/ControlsScreen/InputPressed.png")
@onready var button_off = preload("res://Content/Art/Menu/ControlsScreen/InputUnpressed.png")


func _process(_delta: float) -> void:
	$VBC/HBC/Joystick/BallTop.position = Vector2(
			lerpf($VBC/HBC/Joystick/BallTop.position.x, 74.5 - (JOYSTICK_CHANGE * int(
					Input.is_action_pressed(player + "_left") and
					not Input.is_action_pressed(player + "_right"))) + (
						JOYSTICK_CHANGE * int(
							Input.is_action_pressed(player + "_right") and
						not Input.is_action_pressed(player + "_left"))), 0.7),
			lerpf($VBC/HBC/Joystick/BallTop.position.y, 74.5 - (JOYSTICK_CHANGE * int(
					Input.is_action_pressed(player + "_up") and
					not Input.is_action_pressed(player + "_down"))) + (
						JOYSTICK_CHANGE * int(
							Input.is_action_pressed(player + "_down") and
						not Input.is_action_pressed(player + "_up"))), 0.7)
	)
	$VBC/HBC/Buttons/VBC/TopRow/Button0.texture = button_on if Input.is_action_pressed(
			player + "_button0") else button_off
	$VBC/HBC/Buttons/VBC/TopRow/Button1.texture = button_on if Input.is_action_pressed(
			player + "_button1") else button_off
	$VBC/HBC/Buttons/VBC/TopRow/Button2.texture = button_on if Input.is_action_pressed(
			player + "_button2") else button_off
	$VBC/HBC/Buttons/VBC/BotRow/Button3.texture = button_on if Input.is_action_pressed(
			player + "_button3") else button_off
	$VBC/HBC/Buttons/VBC/BotRow/Button4.texture = button_on if Input.is_action_pressed(
			player + "_button4") else button_off
	$VBC/HBC/Buttons/VBC/BotRow/Button5.texture = button_on if Input.is_action_pressed(
			player + "_button5") else button_off
