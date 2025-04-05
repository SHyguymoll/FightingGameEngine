extends Node

const WIDTH = 5
const X_LEFT = -2.5
const Y_TOP = 2
const Z_POSITION = -4
const X_JUMP = 1.25
const Y_JUMP = 1
const CONT_DIR := "res://Content"
enum ReturnStates {
	SUCCESS,
	NO_CHARACTERS,
	NO_STAGES,
	INVALID_FIGHTER,
	INVALID_STAGE,
	MENU_ELEMENT_MISSING,
	GAME_ELEMENT_MISSING,
	INVALID_SHAPE,
}
enum Screens {
	MAIN_MENU,
	OPTIONS_CONTROLS,
	OPTIONS_OTHER,
	FIGHTER_SELECT,
}
@onready var transitions : Array[Transition] = [
	$TransitionScreens/Black,
	$TransitionScreens/Purple,
]
@export var menu_bckgrd : Texture2D
@export var player_select_bckgrd : Texture2D
@onready var input_prompt = preload("res://scenes/NewControlPrompt.tscn")
@onready var custom_layout = preload("res://Content/Art/Menu/CharacterSelect/custom_layout.gd").new()
@onready var character_icon = preload("res://scenes/CharacterIcon3D.tscn")
@onready var p1_select = preload("res://scenes/Player1Select.tscn")
@onready var p2_select = preload("res://scenes/Player2Select.tscn")
var screen := Screens.MAIN_MENU
var training_mode := false
var p1_cursor : PlayerSelect
var p2_cursor : PlayerSelect
var char_top_left = Vector3(X_LEFT,Y_TOP,Z_POSITION)
var jump_dists = Vector2(X_JUMP, Y_JUMP)


func _ready():
	$Background/Background.set_texture(menu_bckgrd)
	$MenuButtons.show()


func _process(_delta):
	if screen == Screens.FIGHTER_SELECT:
		p1_cursor.position = Vector3(
			char_top_left.x + p1_cursor.selected.x * jump_dists.x,
			char_top_left.y - p1_cursor.selected.y * jump_dists.y,
			char_top_left.z
		)
		p2_cursor.position = Vector3(
			char_top_left.x + p2_cursor.selected.x * jump_dists.x,
			char_top_left.y - p2_cursor.selected.y * jump_dists.y,
			char_top_left.z
		)
		if p1_cursor.choice_made and p2_cursor.choice_made:
			Content.p1_resource = load(
					Content.char_map[p1_cursor.selected.y][p1_cursor.selected.x].scene_path)
			Content.p2_resource = load(
					Content.char_map[p2_cursor.selected.y][p2_cursor.selected.x].scene_path)
			Content.stage_resource = load((Content.stages.pick_random() as Content.StageId).scene_path)
			for character_icon_instance in $CharSelectHolder.get_children():
				character_icon_instance.queue_free()
			if training_mode:
				if get_tree().change_scene_to_file("res://scenes/TrainingGame.tscn"):
					push_error("game failed to load")
			else:
				if get_tree().change_scene_to_file("res://scenes/VersusGame.tscn"):
					push_error("game failed to load")


func build_texture(image: String, needsProcessing: bool = true) -> ImageTexture:
	var processedImage
	if needsProcessing:
		processedImage = Image.new()
		processedImage.load(image)
	else:
		processedImage = ResourceLoader.load(image, "Image")
	return ImageTexture.create_from_image(processedImage)

func build_albedo(image: String, needsProcessing = true, transparent: bool = false, unshaded: bool = true) -> StandardMaterial3D:
	var finalSpatial = StandardMaterial3D.new()
	var intermediateTexture = build_texture(image, needsProcessing)
	finalSpatial.set_texture(StandardMaterial3D.TEXTURE_ALBEDO, intermediateTexture)
	finalSpatial.flags_transparent = transparent
	finalSpatial.flags_unshaded = unshaded
	return finalSpatial

func load_font(font: String, size = 50):
	var new_font : FontFile = FontFile.new()
	new_font.font_data = load(font)
	new_font.fixed_size = size
	return new_font

func load_character_select():
	$Background/Background.set_texture(player_select_bckgrd)
	Content.char_map = []
	if custom_layout != null: #custom shape
		char_top_left = custom_layout.char_top_left
		jump_dists = custom_layout.jump_dists
		var cur_index = 0
		var slice_built = []
		var y_index = 0
		var cur_slice = custom_layout.definition[y_index]
		var prev_slice = custom_layout.definition[max(y_index - 1, 0)]
		for character in Content.characters:
			var icon = character_icon.instantiate()
			icon.name = character.name
			icon.character_data = character.scene_path
			icon.set_surface_override_material(
					0,build_albedo(character.icon_path, false))
			$CharSelectHolder.add_child(icon)
			while cur_slice[cur_index] == 0:
				slice_built.append(null)
				cur_index += 1
				if cur_index == len(cur_slice):
					Content.char_map.append(slice_built)
					slice_built = []
					cur_index = 0
					y_index += 1
					if y_index < len(custom_layout.definition):
						cur_slice = custom_layout.definition[y_index]
						prev_slice = custom_layout.definition[max(y_index - 1, 0)]
						if not len(cur_slice) == len(prev_slice):
							push_error("ERROR: shape must occupy a rectangle of space")
							return ReturnStates.INVALID_SHAPE
					else:
						if cur_slice.count(0) == len(cur_slice) - 1:
							push_error("ERROR: shape must not end with empty line")
							return ReturnStates.INVALID_SHAPE

			if cur_slice[cur_index] == 1:
				slice_built.append(character)
				icon.position = Vector3(
					char_top_left.x + cur_index * jump_dists.x,
					char_top_left.y - y_index * jump_dists.y,
					char_top_left.z
				)
				cur_index += 1
				if cur_index == len(cur_slice):
					Content.char_map.append(slice_built)
					slice_built = []
					cur_index = 0
					y_index += 1
					if y_index < len(custom_layout.definition):
						cur_slice = custom_layout.definition[y_index]
						prev_slice = custom_layout.definition[max(y_index - 1, 0)]
						if not len(cur_slice) == len(prev_slice):
							push_error("ERROR: shape must occupy a rectangle of space")
							return ReturnStates.INVALID_SHAPE
					else:
						if cur_slice.count(0) == len(cur_slice) - 1:
							push_error("ERROR: shape must not end with empty line")
							return ReturnStates.INVALID_SHAPE
		if cur_index != len(cur_slice): #set the rest to 0 to stop floating
			while cur_index != len(cur_slice):
				slice_built.append(null)
				cur_index += 1
			Content.char_map.append(slice_built)
		custom_layout = null # finally, free the custom_shape
	else: #fallback shape
		var cur_row_pos = 0
		var cur_slice = []
		var char_position_working = char_top_left
		for character in Content.characters:
			var icon = character_icon.instantiate()
			icon.name = character.name
			icon.character_data = character.scene_path
			icon.set_surface_override_material(
					0,build_albedo(character.icon_path, false))
			$CharSelectHolder.add_child(icon)
			icon.position = char_position_working
			char_position_working.x += X_JUMP
			cur_row_pos += 1
			cur_slice.append(character)
			if cur_row_pos == WIDTH:
				cur_row_pos = 0
				char_position_working.x = X_LEFT
				char_position_working.y -= Y_JUMP
				Content.char_map.append(cur_slice)
				cur_slice = []
		if cur_slice != []:
			while len(cur_slice) < WIDTH:
				cur_slice.append(null)
			Content.char_map.append(cur_slice)
	p1_cursor = p1_select.instantiate()
	p1_cursor.selected = Vector2(0,0) #places at lefttopmost spot
	p1_cursor.max_x = len(Content.char_map[0])
	p1_cursor.max_y = len(Content.char_map)
	while Content.char_map[p1_cursor.selected.y][p1_cursor.selected.x] == null:
		p1_cursor.selected.x += 1
		if p1_cursor.selected.x == p1_cursor.max_x:
			p1_cursor.selected.x = 0
			p1_cursor.selected.y += 1
	$CharSelectHolder.add_child(p1_cursor)
	p2_cursor = p2_select.instantiate()
	p2_cursor.selected = Vector2(
			len(Content.char_map[0]) - 1,
			len(Content.char_map) - 1) #places at rightbottommost spot
	p2_cursor.max_x = len(Content.char_map[0])
	p2_cursor.max_y = len(Content.char_map)
	while Content.char_map[p2_cursor.selected.y][p2_cursor.selected.x] == null:
		p2_cursor.selected.x -= 1
		if p2_cursor.selected.x == -1:
			p2_cursor.selected.x = p2_cursor.max_x
			p2_cursor.selected.y -= 1
	$CharSelectHolder.add_child(p2_cursor)
	return ReturnStates.SUCCESS


func failure_cleanup():
	for char_icon in $CharSelectHolder.get_children():
		char_icon.queue_free()


func transition_and_call(transition : Transition, in_between_funcs : Array[Callable]):
	transition.do_first_half()
	await transition.first_half_completed
	for function in in_between_funcs:
		function.call()
	transition.do_second_half()
	await transition.second_half_completed


func try_load_c_select():
	var try_load = load_character_select()
	if try_load == ReturnStates.SUCCESS:
		screen = Screens.FIGHTER_SELECT
	else:
		failure_cleanup()
		push_error(ReturnStates.keys()[try_load])


func _on_PlayerVsPlayer_pressed() -> void:
	training_mode = false
	await transition_and_call(transitions[1], [$MenuButtons.hide, $Logo.hide, try_load_c_select])


func _on_training_mode_pressed() -> void:
	training_mode = true
	await transition_and_call(transitions[1], [$MenuButtons.hide, $Logo.hide, try_load_c_select])


func _on_controls_pressed() -> void:
	await transition_and_call(transitions[0], [$MenuButtons.hide, $ControlButtons.show])


func _on_controls_back_pressed() -> void:
	await transition_and_call(transitions[0], [$ControlButtons.hide, $MenuButtons.show])


func _on_input_button_clicked(input_item: Variant, is_kb: bool) -> void:
	$ControlPrompt.show()
	var new_prompt = input_prompt.instantiate()
	new_prompt.current_input = input_item.input_to_update
	new_prompt.event_to_erase = input_item.kb_input if is_kb else input_item.jp_input
	new_prompt.input_visual = input_item.visible_name
	new_prompt.is_kb = is_kb
	$ControlPrompt.add_child(new_prompt)
	await new_prompt.prompt_completed
	new_prompt.queue_free()
	$ControlPrompt.hide()
