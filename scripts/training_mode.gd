class_name TrainingModeGame
extends MainGame

func construct_game():
	super.construct_game()
	var p1_dtar = (debug_targetter.instantiate() as DebugTargetter)
	p1_dtar.pointer_texture = load("res://Content/Art/Menu/CharacterSelect/Player1Select.png")
	p1_dtar.pointer_target = p1
	$FightersAndStage.add_child(p1_dtar)
	var p2_dtar = (debug_targetter.instantiate() as DebugTargetter)
	p2_dtar.pointer_texture = load("res://Content/Art/Menu/CharacterSelect/Player2Select.png")
	p2_dtar.pointer_target = p2
	$FightersAndStage.add_child(p2_dtar)
