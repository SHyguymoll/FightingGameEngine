class_name PlayerSelect
extends MeshInstance3D

var player: bool

var selected = Vector2(0, 0)
var max_x: int
var max_y: int

var choice_made = false

var animation = 0

func _process(_delta):
	if !choice_made:
		get_surface_override_material(0).metallic = 0
		if Input.is_action_just_pressed(("first" if player else "second") + "_left"):
			selected.x -= 1
			if selected.x == -1:
				selected.x = max_x - 1
			if Content.char_map[selected.y][selected.x] == null:
				while Content.char_map[selected.y][selected.x] == null:
					selected.x -= 1
					if selected.x == -1:
						selected.x = max_x - 1
		if Input.is_action_just_pressed(("first" if player else "second") + "_right"):
			selected.x += 1
			if selected.x == max_x:
				selected.x = 0
			if Content.char_map[selected.y][selected.x] == null:
				while Content.char_map[selected.y][selected.x] == null:
					selected.x += 1
					if selected.x == max_x:
						selected.x = 0
		if Input.is_action_just_pressed(("first" if player else "second") + "_up"):
			selected.y -= 1
			if selected.y == -1:
				selected.y = max_y - 1
			if Content.char_map[selected.y][selected.x] == null:
				while Content.char_map[selected.y][selected.x] == null:
					selected.y -= 1
					if selected.y == -1:
						selected.y = max_y - 1
		if Input.is_action_just_pressed(("first" if player else "second") + "_down"):
			selected.y += 1
			if selected.y == max_y:
				selected.y = 0
			if Content.char_map[selected.y][selected.x] == null:
				while Content.char_map[selected.y][selected.x] == null:
					selected.y += 1
					if selected.y == max_y:
						selected.y = 0
		choice_made = Input.is_action_just_pressed(("first" if player else "second") + "_button0")
	else:
		get_surface_override_material(0).metallic = abs(animation)
		animation += 0.01
		if animation > 1:
			animation = -1
		if Input.is_action_just_pressed(("first" if player else "second") + "_button1"):
			choice_made = false
			animation = 0
			get_surface_override_material(0).metallic = animation


