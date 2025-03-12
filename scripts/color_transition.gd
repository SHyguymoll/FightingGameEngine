class_name ColorTransition
extends Transition

@export var start_val := 0.0
@export var lerp_val := 0.5

func _ready() -> void:
	$ColorRect.color.a = start_val


func _process(_d):
	if not first_half_done:
		$ColorRect.color.a = lerpf($ColorRect.color.a, 1.0, lerp_val)
		if is_equal_approx($ColorRect.color.a, 1.0):
			first_half_done = true
			emit_signal("first_half_completed")
	elif not second_half_done:
		$ColorRect.color.a = lerpf($ColorRect.color.a, 0.0, lerp_val)
		if is_equal_approx($ColorRect.color.a, 0.0):
			second_half_done = true
			emit_signal("second_half_completed")
