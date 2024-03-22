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
var p1_cursor : PlayerSelect
var p2_cursor : PlayerSelect
var char_top_left = Vector3(X_LEFT,Y_TOP,Z_POSITION)
var jump_dists = Vector2(X_JUMP, Y_JUMP)


func _ready():
	$Background/Background.set_texture(menu_bckgrd)
	if prepare_game() == ReturnStates.SUCCESS:
		$MenuButtons.show()

func prepare_game() -> ReturnStates:
	#I/O Stuff
	var character_file_folders = directory_traversal(CONT_DIR.path_join("Characters"))
	var stage_file_folders = directory_traversal(CONT_DIR.path_join("Stages"))
	var character_files = search_for_files(character_file_folders, "fighter_details.gd")
	var stage_files = search_for_files(stage_file_folders, "stage_details.gd")

	# Characters
	for c_file in character_files:
		var fighter_details = load(c_file).new()
		if not "folder" in fighter_details:
			push_error("folder variable missing in fighter_details.gd for c_file " + c_file)
			return ReturnStates.INVALID_FIGHTER
		else:
			if not fighter_details.folder is String:
				push_error("folder variable is wrong type, aborting c_file" + c_file)
				return ReturnStates.INVALID_FIGHTER
		if not "fighter_name" in fighter_details:
			push_error(
					"fighter_name variable missing in fighter_details.gd for c_file " + c_file)
			return ReturnStates.INVALID_FIGHTER
		else:
			if not fighter_details.fighter_name is String:
				push_error(
						"fighter_name variable is wrong type, aborting c_file" + c_file)
				return ReturnStates.INVALID_FIGHTER
		if not "fighter_file" in fighter_details:
			push_error(
					"fighter_file variable missing in fighter_details.gd for c_file " + c_file)
			return ReturnStates.INVALID_FIGHTER
		else:
			if not fighter_details.fighter_file is String:
				push_error(
						"fighter_file variable is wrong type, aborting c_file" + c_file)
				return ReturnStates.INVALID_FIGHTER
		if not "char_select_icon" in fighter_details:
			push_error(
					"char_select_icon variable missing in fighter_details.gd for c_file " + c_file)
			return ReturnStates.INVALID_FIGHTER
		else:
			if not fighter_details.char_select_icon is String:
				push_error(
						"char_select_icon variable is wrong type, aborting c_file" + c_file)
				return ReturnStates.INVALID_FIGHTER
		Content.characters.append({
			char_name = fighter_details.fighter_name,
			fighter_file = fighter_details.fighter_file,
			char_select_icon = fighter_details.char_select_icon,
		})

	# Stages
	for s_file in stage_files:
		var stage_details = load(s_file).new()
		if not "folder" in stage_details:
			push_error("folder variable missing in stage_details.gd for s_file " + s_file)
			return ReturnStates.INVALID_STAGE
		else:
			if not stage_details.folder is String:
				push_error("folder variable is wrong type, aborting s_file" + s_file)
				return ReturnStates.INVALID_STAGE
		if not "stage_name" in stage_details:
			push_error(
					"stage_name variable missing in stage_details.gd for s_file " + s_file)
			return ReturnStates.INVALID_STAGE
		else:
			if not stage_details.stage_name is String:
				push_error(
						"stage_name variable is wrong type, aborting s_file" + s_file)
				return ReturnStates.INVALID_STAGE
		if not "stage_file" in stage_details:
			push_error(
					"stage_file variable missing in stage_details.gd for s_file " + s_file)
			return ReturnStates.INVALID_STAGE
		else:
			if not stage_details.stage_file is String:
				push_error(
						"stage_file variable is wrong type, aborting s_file" + s_file)
				return ReturnStates.INVALID_STAGE
		if not "compatible_with_3d" in stage_details:
			push_error(
					"compatible_with_3d variable missing in stage_details.gd for s_file " + s_file)
			return ReturnStates.INVALID_STAGE
		else:
			if not stage_details.compatible_with_3d is bool:
				push_error(
						"compatible_with_3d variable is wrong type, aborting s_file" + s_file)
				return ReturnStates.INVALID_STAGE
		Content.stages.append({
			stage_name = stage_details.stage_name,
			stage_file = stage_details.stage_file,
			compatible_with_3d = stage_details.compatible_with_3d
		})

	return ReturnStates.SUCCESS

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
					Content.char_map[p1_cursor.selected.y][p1_cursor.selected.x].fighter_file)
			Content.p2_resource = load(
					Content.char_map[p2_cursor.selected.y][p2_cursor.selected.x].fighter_file)
			Content.stage_resource = load(Content.stages.pick_random().stage_file)
			for character_icon_instance in $CharSelectHolder.get_children():
				character_icon_instance.queue_free()
			if get_tree().change_scene_to_file("res://scenes/Game.tscn"):
				push_error("game failed to load")

#Recursive depth-first directory traversal
func directory_traversal(current_directory: String) -> Array:
	if not DirAccess.dir_exists_absolute(current_directory):
		push_error(current_directory + " failed to open, aborting search.")
		return []
	var folders = [current_directory]
	var directories = DirAccess.get_directories_at(current_directory)
	for directory in directories:
		folders.append_array(directory_traversal(current_directory + "/" + directory))
	return folders

func search_for_files(dirs: Array, file_name : String) -> Array:
	var pck_names = []
	for dir in dirs:
		if not DirAccess.dir_exists_absolute(dir):
			push_error(dir + " failed to open, aborting this search.")
			continue
		var files = DirAccess.get_files_at(dir)
		for file in files:
			if file == file_name:
				pck_names.append(dir.path_join(file))
	return pck_names

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
			icon.name = character.char_name
			icon.character_data = character.fighter_file
			icon.set_surface_override_material(
					0,build_albedo(character.char_select_icon, false))
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
			icon.name = character.char_name
			icon.character_data = character.fighter_file
			icon.set_surface_override_material(
					0,build_albedo(character.char_select_icon, false))
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
