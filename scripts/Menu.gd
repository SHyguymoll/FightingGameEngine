extends Node

@onready var character_icon = preload("res://scenes/CharacterIcon3D.tscn")
@onready var select = preload("res://scenes/PlayerSelect.tscn")
var screen = "Menu"
var menuLogo
var p1_cursor : PlayerSelect
var p2_cursor : PlayerSelect
var char_top_left
var jump_dists
const WIDTH = 5
const X_LEFT = -2.5
const Y_TOP = 2
const Z_POSITION = -4
const X_JUMP = 1.25
const Y_JUMP = 1

enum ReturnState {
	SUCCESS,
	NO_CHARACTERS,
	NO_STAGES,
	INVALID_FIGHTER,
	INVALID_STAGE,
	MENU_ELEMENT_MISSING,
	GAME_ELEMENT_MISSING,
	INVALID_SHAPE,
}

func get_content_folders() -> void:
	Content.content_folder = "res://Content" if OS.has_feature("editor") else "user://Content"

func _ready():
	get_content_folders()
	if prepare_game() != ReturnState.SUCCESS or prepare_menu() != ReturnState.SUCCESS:
		$MenuButtons/Start.hide()

func check_folders():
	if not DirAccess.dir_exists_absolute(Content.content_folder):
		DirAccess.make_dir_recursive_absolute(Content.content_folder)
		DirAccess.make_dir_recursive_absolute(Content.content_folder.path_join("Characters"))
		DirAccess.make_dir_recursive_absolute(Content.content_folder.path_join("Game"))
		DirAccess.make_dir_recursive_absolute(Content.content_folder.path_join("Stages"))
		DirAccess.make_dir_recursive_absolute(Content.content_folder.path_join("Art/HUD"))
		DirAccess.make_dir_recursive_absolute(Content.content_folder.path_join("Art/Menu"))
	if not DirAccess.dir_exists_absolute(Content.content_folder.path_join("Characters")):
		DirAccess.make_dir_recursive_absolute(Content.content_folder.path_join("Characters"))
	if not DirAccess.dir_exists_absolute(Content.content_folder.path_join("Art")):
		DirAccess.make_dir_recursive_absolute(Content.content_folder.path_join("Art"))
	if not DirAccess.dir_exists_absolute(Content.content_folder.path_join("Stages")):
		DirAccess.make_dir_recursive_absolute(Content.content_folder.path_join("Stages"))

func prepare_game() -> ReturnState:
	#I/O Stuff
	check_folders()
	var character_file_folders = search_folder_recurs(Content.content_folder.path_join("Characters"))
	var stage_file_folders = search_folder_recurs(Content.content_folder.path_join("Stages"))
	var character_files = search_for_pcks(character_file_folders)
	var stage_files = search_for_pcks(stage_file_folders)

	# Characters
	var number_id = 0
	for c_file in character_files:
		if ProjectSettings.load_resource_pack(c_file):
			if !ResourceLoader.exists("FighterDetails.gd"):
				push_error("FighterDetails.gd missing in c_file " + c_file)
				return ReturnState.INVALID_FIGHTER
			var fighter_details = load("FighterDetails.gd").new()
			if not "folder" in fighter_details:
				push_error("folder variable missing in FighterDetails.gd for c_file " + c_file)
				return ReturnState.INVALID_FIGHTER
			else:
				if not fighter_details.folder is String:
					push_error("folder variable is wrong type, aborting c_file" + c_file)
					return ReturnState.INVALID_FIGHTER
			if not "fighter_name" in fighter_details:
				push_error(
						"fighter_name variable missing in FighterDetails.gd for c_file " + c_file)
				return ReturnState.INVALID_FIGHTER
			else:
				if not fighter_details.fighter_name is String:
					push_error(
							"fighter_name variable is wrong type, aborting c_file" + c_file)
					return ReturnState.INVALID_FIGHTER
			if not "fighter_file" in fighter_details:
				push_error(
						"fighter_file variable missing in FighterDetails.gd for c_file " + c_file)
				return ReturnState.INVALID_FIGHTER
			else:
				if not fighter_details.fighter_file is String:
					push_error(
							"fighter_file variable is wrong type, aborting c_file" + c_file)
					return ReturnState.INVALID_FIGHTER
			if not "char_select_icon" in fighter_details:
				push_error(
						"char_select_icon variable missing in FighterDetails.gd for c_file " + c_file)
				return ReturnState.INVALID_FIGHTER
			else:
				if not fighter_details.char_select_icon is String:
					push_error(
							"char_select_icon variable is wrong type, aborting c_file" + c_file)
					return ReturnState.INVALID_FIGHTER
			Content.characters.append({
				char_name = fighter_details.fighter_name,
				fighter_file = Content.character_folder.path_join(
						(fighter_details.folder.path_join(fighter_details.fighter_file))),
				char_select_icon = Content.character_folder.path_join(
						(fighter_details.folder.path_join(fighter_details.char_select_icon))),
			})
			number_id += 1

	# Stages
	for s_file in stage_files:
		if ProjectSettings.load_resource_pack(s_file):
			if !ResourceLoader.exists("StageDetails.gd"):
				push_error("StageDetails.gd missing in s_file " + s_file)
				return ReturnState.INVALID_STAGE
			var stage_details = load("StageDetails.gd").new()
			if not "folder" in stage_details:
				push_error("folder variable missing in StageDetails.gd for s_file " + s_file)
				return ReturnState.INVALID_STAGE
			else:
				if not stage_details.folder is String:
					push_error("folder variable is wrong type, aborting s_file" + s_file)
					return ReturnState.INVALID_STAGE
			if not "stage_name" in stage_details:
				push_error(
						"stage_name variable missing in StageDetails.gd for s_file " + s_file)
				return ReturnState.INVALID_STAGE
			else:
				if not stage_details.stage_name is String:
					push_error(
							"stage_name variable is wrong type, aborting s_file" + s_file)
					return ReturnState.INVALID_STAGE
			if not "stage_file" in stage_details:
				push_error(
						"stage_file variable missing in StageDetails.gd for s_file " + s_file)
				return ReturnState.INVALID_STAGE
			else:
				if not stage_details.stage_file is String:
					push_error(
							"stage_file variable is wrong type, aborting s_file" + s_file)
					return ReturnState.INVALID_STAGE
			if not "compatible_with_3d" in stage_details:
				push_error(
						"compatible_with_3d variable missing in StageDetails.gd for s_file " + s_file)
				return ReturnState.INVALID_STAGE
			else:
				if not stage_details.compatible_with_3d is bool:
					push_error(
							"compatible_with_3d variable is wrong type, aborting s_file" + s_file)
					return ReturnState.INVALID_STAGE
			Content.stages.append({
				stage_name = stage_details.stage_name,
				stage_file = Content.stage_folder.path_join(
						stage_details.folder.path_join(stage_details.stage_file)),
				compatible_with_3d = stage_details.compatible_with_3d
			})

	return ReturnState.SUCCESS

func prepare_menu() -> ReturnState:
	#Loads all menu elements
	var menu_folder = Content.content_folder.path_join("Art/Menu")
	if !FileAccess.file_exists(menu_folder.path_join("MenuBackground.png")):
		push_error("Menu Background missing.")
		return ReturnState.MENU_ELEMENT_MISSING
	if !FileAccess.file_exists(menu_folder.path_join("Font.ttf")):
		push_error("Menu Font missing.")
		return ReturnState.MENU_ELEMENT_MISSING
	if !FileAccess.file_exists(menu_folder.path_join("Logo/Logo.tscn")):
		push_error("Logo missing.")
		return ReturnState.MENU_ELEMENT_MISSING
	var char_folder = menu_folder.path_join("CharacterSelect")
	if !FileAccess.file_exists(char_folder.path_join("Player1Select.png")):
		push_error("Player1Select icon missing.")
		return ReturnState.MENU_ELEMENT_MISSING
	if !FileAccess.file_exists(char_folder.path_join("Player2Select.png")):
		push_error("Player2Select icon missing.")
		return ReturnState.MENU_ELEMENT_MISSING
	if !FileAccess.file_exists(char_folder.path_join("CharacterSelectBackground.png")):
		push_error("Character Select Background missing.")
		return ReturnState.MENU_ELEMENT_MISSING

	$Background/Background.set_texture(build_texture(menu_folder.path_join("MenuBackground.png"), true))
	menuLogo = load(Content.content_folder.path_join("Game/Menu/Logo/Logo.tscn"))
	$LogoLayer/Logo.add_child(menuLogo.instantiate())
	$MenuButtons/Start.set("theme_override_fonts/font", load_font(menu_folder.path_join("Font.ttf")))
	$MenuButtons/Credits.set("theme_override_fonts/font", load_font(menu_folder.path_join("Font.ttf"), 32))
	return ReturnState.SUCCESS

func _process(_delta):
	if screen == "CharSelect":
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
			Content.p1_resource = load(Content.characters[
				Content.char_map[p1_cursor.selected.y][p1_cursor.selected.x]
			]["fighter_file"])
			Content.p2_resource = load(Content.characters[
				Content.char_map[p2_cursor.selected.y][p2_cursor.selected.x]
			]["fighter_file"])
			for character_icon_instance in $CharSelectHolder.get_children():
				character_icon_instance.queue_free()
			if get_tree().change_scene_to_file("res://scenes/Game.tscn"):
				push_error("game failed to load")

#Recursive depth-first search
func search_folder_recurs(current_directory: String) -> Array:
	if not DirAccess.dir_exists_absolute(current_directory):
		push_error(current_directory + " failed to open, aborting search.")
		return []
	var folders = [current_directory]
	var directories = DirAccess.get_directories_at(current_directory)
	for directory in directories:
		folders.append_array(search_folder_recurs(current_directory + "/" + directory))
	return folders

func search_for_pcks(dirs: Array) -> Array:
	var pck_names = []
	for dir in dirs:
		if not DirAccess.dir_exists_absolute(dir):
			push_error(dir + " failed to open, aborting this search.")
			continue
		var files = DirAccess.get_files_at(dir)
		for file in files:
			if file.get_extension() == "pck" or file.get_extension() == "zip":
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
	var character_select = Content.content_folder.path_join("Game/Menu/CharacterSelect")
	$Background/Background.set_texture(
			build_texture(character_select.path_join("CharacterSelectBackground.png")))
	Content.char_map = []
	if FileAccess.file_exists(character_select.path_join("Custom.txt")): #custom shape
		var file_io = FileAccess.open(character_select.path_join("Custom.txt"), FileAccess.READ)
		var currentLine = file_io.get_csv_line()
		char_top_left = Vector3(float(currentLine[0]), float(currentLine[1]), float(currentLine[2]))
		currentLine = file_io.get_csv_line()
		jump_dists = Vector2(float(currentLine[0]), float(currentLine[1]))
		var cur_slice = Array(file_io.get_csv_line())
		var slice_built = []
		var prev_slice = cur_slice.duplicate()
		var cur_index = 0
		var yIndex = 0
		for character in Content.characters:
			var icon = character_icon.instantiate()
			icon.name = Content.characters[character].char_name
			icon.characterData = Content.characters[character].fighter_file
			icon.set_surface_override_material(
					0,build_albedo(Content.characters[character].char_select_icon, false))
			$CharSelectHolder.add_child(icon)
			while cur_slice[cur_index] == "0":
				slice_built.append(null)
				cur_index += 1
				if cur_index == len(cur_slice):
					Content.char_map.append(slice_built)
					slice_built = []
					if file_io.get_position() < file_io.get_length():
						cur_slice = Array(file_io.get_csv_line())
						if !len(cur_slice) == len(prev_slice):
							push_error("ERROR: shape must occupy a rectangle of space")
							return ReturnState.INVALID_SHAPE
						prev_slice = cur_slice.duplicate()
					else:
						cur_slice = prev_slice.duplicate()
						if !cur_slice.count(0) != len(cur_slice):
							push_error("ERROR: shape must not end with empty line")
							return ReturnState.INVALID_SHAPE
					cur_index = 0
					yIndex += 1
			if cur_slice[cur_index] == "1":
				slice_built.append(character)
				icon.position = Vector3(
					char_top_left.x + cur_index*jump_dists.x,
					char_top_left.y - yIndex*jump_dists.y,
					char_top_left.z
				)
				cur_index += 1
				if cur_index == len(cur_slice):
					Content.char_map.append(slice_built)
					slice_built = []
					if file_io.get_position() < file_io.get_length():
						cur_slice = Array(file_io.get_csv_line())
						if !len(cur_slice) == len(prev_slice):
							push_error("ERROR: shape must occupy a rectangle of space")
							return ReturnState.INVALID_SHAPE
						prev_slice = cur_slice.duplicate()
					else:
						cur_slice = prev_slice.duplicate()
						if !cur_slice.count(0) != len(cur_slice):
							push_error("ERROR: shape must not end with empty line")
							return ReturnState.INVALID_SHAPE
					cur_index = 0
					yIndex += 1
		if cur_index != len(cur_slice): #set the rest to 0 to stop floating
			while cur_index != len(cur_slice):
				slice_built.append(null)
				cur_index += 1
			Content.char_map.append(slice_built)
	else: #fallback shape
		char_top_left = Vector3(X_LEFT,Y_TOP,Z_POSITION)
		var currentRowPos = 0
		var cur_slice = []
		for character in Content.characters:
			var icon = character_icon.instantiate()
			icon.name = Content.characters[character].char_name
			icon.characterData = Content.characters[character].fighter_file
			icon.set_surface_override_material(
					0,build_albedo(Content.characters[character].char_select_icon, false))
			$CharSelectHolder.add_child(icon)
			icon.position = char_top_left
			char_top_left.x += X_JUMP
			currentRowPos += 1
			cur_slice.append(character)
			if currentRowPos >= WIDTH:
				currentRowPos = 0
				char_top_left.x = X_LEFT
				char_top_left.y -= Y_JUMP
				Content.char_map.append(cur_slice)
				cur_slice = []
		if cur_slice != []:
			while len(cur_slice) != len(Content.char_map[0]):
				cur_slice.append(null)
			Content.char_map.append(cur_slice)
			cur_slice = []
	p1_cursor = select.instantiate()
	p1_cursor.name = "PlayerOne"
	p1_cursor.player = 0
	p1_cursor.selected = Vector2(0,0) #places at lefttopmost spot
	p1_cursor.max_x = len(Content.char_map[0])
	p1_cursor.max_y = len(Content.char_map)
	while Content.char_map[p1_cursor.selected.y][p1_cursor.selected.x] == null:
		p1_cursor.selected.x += 1
		if p1_cursor.selected.x == p1_cursor.max_x:
			p1_cursor.selected.x = 0
			p1_cursor.selected.y += 1
	p1_cursor.set_surface_override_material(
			0,build_albedo(character_select.path_join("Player1Select.png"), true, true))
	$CharSelectHolder.add_child(p1_cursor)
	p2_cursor = select.instantiate()
	p2_cursor.name = "PlayerTwo"
	p2_cursor.player = 1
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
	p2_cursor.set_surface_override_material(
			0,build_albedo(character_select.path_join("Player2Select.png"), true, true))
	$CharSelectHolder.add_child(p2_cursor)
	screen = "CharSelect"
	return ReturnState.SUCCESS

func _on_Start_pressed():
	$MenuButtons.hide()
	$LogoLayer/Logo.get_children()[0].queue_free() #this is safe I promise
	load_character_select()
