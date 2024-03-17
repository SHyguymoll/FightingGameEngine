extends DramaticFreeze

func _ready() -> void:
	position_effect()
	$AnimationPlayer.play("super_flash")

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	complete_freeze()

func position_effect():
	$Effects.global_position = source_2d_pos - Vector2(0,200)
