extends Node

@onready var character_icon = preload("res://scenes/CharacterIcon3D.tscn")
@onready var select = preload("res://scenes/PlayerSelect.tscn")
var screen = "Menu"
var file_manager: FileAccess
var dir_manager: DirAccess
const RESERVED_FOLDERS = [ #Baseline folders in each Character
	"Scripts",
	"HelperScripts",
	"Sounds",
	"Sprites"
]
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
	CONTENT_MISSING,
	CHARACTERS_MISSING,
	GAME_MISSING,
	INVALID_FIGHTER,
	MENU_ELEMENT_MISSING,
	GAME_ELEMENT_MISSING,
}

func get_content_folder() -> void:
	Content.content_folder = "res://Content" if OS.has_feature("editor") else "user://Content"

func _ready():
	get_content_folder()
	if prepare_game() != ReturnState.SUCCESS or prepare_menu() != ReturnState.SUCCESS:
		$MenuButtons/Start.hide()

func prepare_game() -> ReturnState:
	# Loads all characters into character roster via resource pack loading and ResourceLoader
	dir_manager = DirAccess.open(Content.content_folder)
	if !dir_manager.dir_exists(Content.content_folder):
		return ReturnState.CONTENT_MISSING
	if !dir_manager.dir_exists(Content.content_folder.path_join("Characters")):
		return ReturnState.CHARACTERS_MISSING
	if !dir_manager.dir_exists(Content.content_folder.path_join("Game")):
		return ReturnState.GAME_MISSING
	var pcks = search_for_pcks(
			search_character_folder(Content.content_folder.path_join("Characters")))
	var number_id = 0
	var root_folder = Content.content_folder.left(Content.content_folder.rfind("/Content"))
	for pck in pcks:
		if ProjectSettings.load_resource_pack(pck):
			if !ResourceLoader.exists("FighterDetails.gd"):
				push_error("FighterDetails.gd missing in pck " + pck)
				return ReturnState.INVALID_FIGHTER
			var fighter_details = load("FighterDetails.gd").new()
			if !("folder" in fighter_details):
				push_error("folder variable missing in FighterDetails.gd for pck " + pck)
				return ReturnState.INVALID_FIGHTER
			if !("fighter_name" in fighter_details):
				push_error("fighter_name variable missing in FighterDetails.gd for pck " + pck)
				return ReturnState.INVALID_FIGHTER
			if !("tscn_file" in fighter_details):
				push_error("tscn_file variable missing in FighterDetails.gd for pck " + pck)
				return ReturnState.INVALID_FIGHTER
			if !("char_select_icon" in fighter_details):
				push_error("char_select_icon variable missing in FighterDetails.gd for pck " + pck)
				return ReturnState.INVALID_FIGHTER
			Content.characters[number_id] = {
				char_name = fighter_details.fighter_name,
				tscn_file = fighter_details.tscn_file,
				char_select_icon = fighter_details.char_select_icon
			}
			number_id += 1
	return ReturnState.SUCCESS

func prepare_menu() -> ReturnState:
	#Loads all menu elements
	var menu_folder = Content.content_folder + "/Game/Menu"
	if !FileAccess.file_exists(menu_folder + "/MenuBackground.png"):
		push_error("Menu Background missing.")
		return ReturnState.MENU_ELEMENT_MISSING
	if !FileAccess.file_exists(menu_folder + "/Font.ttf"):
		push_error("Menu Font missing.")
		return ReturnState.MENU_ELEMENT_MISSING
	if !FileAccess.file_exists(menu_folder + "/Logo/Logo.tscn"):
		push_error("Logo missing.")
		return ReturnState.MENU_ELEMENT_MISSING
	var char_folder = menu_folder + "/CharacterSelect"
	if !FileAccess.file_exists(char_folder + "/Player1Select.png"):
		push_error("Player1Select icon missing.")
		return ReturnState.MENU_ELEMENT_MISSING
	if !FileAccess.file_exists(char_folder + "/Player2Select.png"):
		push_error("Player2Select icon missing.")
		return ReturnState.MENU_ELEMENT_MISSING
	if !FileAccess.file_exists(char_folder + "/CharacterSelectBackground.png"):
		push_error("Character Select Background missing.")
		return ReturnState.MENU_ELEMENT_MISSING

	$Background/Background.set_texture(build_texture(menu_folder + "/MenuBackground.png", true))
	menuLogo = load(Content.content_folder + "/Game/Menu/Logo/Logo.tscn")
	$LogoLayer/Logo.add_child(menuLogo.instantiate())
	$MenuButtons/Start.set("theme_override_fonts/font", load_font(menu_folder + "/Font.ttf"))
	$MenuButtons/Credits.set("theme_override_fonts/font", load_font(menu_folder + "/Font.ttf", 32))
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
			]["tscn_file"])
			Content.p2_resource = load(Content.characters[
				Content.char_map[p2_cursor.selected.y][p2_cursor.selected.x]
			]["tscn_file"])
			for character_icon_instance in $CharSelectHolder.get_children():
				character_icon_instance.queue_free()
			if get_tree().change_scene_to_file("res://scenes/Game.tscn"):
				printerr("game failed to load")

func search_character_folder(start_dir: String) -> Array: #Recursive breadth-first search in /Content/Characters
	var folders = []
	dir_manager = DirAccess.open(start_dir)
	dir_manager.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	while true:
		var folder = dir_manager.get_next()
		if folder == "":
			if len(folders):
				for entry in folders:
					folders.append_array(search_character_folder(entry))
			break
		if dir_manager.current_is_dir() and !RESERVED_FOLDERS.has(folder): #Avoid files for recursion loops, and common directories for speed
			folders.append(start_dir + "/" + folder)
	return folders

func search_for_pcks(dirs: Array) -> Array:
	var pck_names = []
	for dir in dirs:
		dir_manager = DirAccess.open(dir)
		dir_manager.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		while true:
			var file = dir_manager.get_next()
			if file.get_extension() == "pck" or file.get_extension() == "zip":
				pck_names.append(dir_manager.get_current_dir() + "/" + file)
			if file == "":
				break
	dir_manager.list_dir_end()
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

func loadCharSelect():
	var character_folder = Content.content_folder + "/Game/Menu/CharacterSelect"
	$Background/Background.set_texture(build_texture(character_folder + "/CharacterSelectBackground.png"))
	Content.char_map = []
	if FileAccess.file_exists(character_folder + "/Custom.txt"): #custom shape
		file_manager = FileAccess.open(character_folder + "/Custom.txt", FileAccess.READ)
		var currentLine = file_manager.get_csv_line()
		char_top_left = Vector3(float(currentLine[0]), float(currentLine[1]), float(currentLine[2]))
		currentLine = file_manager.get_csv_line()
		jump_dists = Vector2(float(currentLine[0]), float(currentLine[1]))
		var cur_slice = Array(file_manager.get_csv_line())
		var slice_built = []
		var prev_slice = cur_slice.duplicate()
		var cur_index = 0
		var yIndex = 0
		for character in Content.characters:
			var icon = character_icon.instantiate()
			icon.name = Content.characters[character].char_name
			icon.characterData = Content.characters[character].tscn_file
			icon.set_surface_override_material(0,build_albedo(Content.characters[character].char_select_icon, false))
			$CharSelectHolder.add_child(icon)
			while cur_slice[cur_index] == "0":
				slice_built.append(null)
				cur_index += 1
				if cur_index == len(cur_slice):
					Content.char_map.append(slice_built)
					slice_built = []
					if file_manager.get_position() < file_manager.get_length():
						cur_slice = Array(file_manager.get_csv_line())
						if !len(cur_slice) == len(prev_slice): return "ERROR: shape must occupy a rectangle of space"
						prev_slice = cur_slice.duplicate()
					else:
						cur_slice = prev_slice.duplicate()
						if !cur_slice.count(0) != len(cur_slice): return "ERROR: shape must not end with empty line"
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
					if file_manager.get_position() < file_manager.get_length():
						cur_slice = Array(file_manager.get_csv_line())
						if !len(cur_slice) == len(prev_slice): return "ERROR: shape must occupy a rectangle of space"
						prev_slice = cur_slice.duplicate()
					else:
						cur_slice = prev_slice.duplicate()
						if !cur_slice.count(0) != len(cur_slice): return "ERROR: shape must not end with empty line"
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
			icon.characterData = Content.characters[character].tscn_file
			icon.set_surface_override_material(0,build_albedo(Content.characters[character].char_select_icon, false))
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
	p1_cursor.set_surface_override_material(0,build_albedo(character_folder + "/Player1Select.png", true, true))
	$CharSelectHolder.add_child(p1_cursor)
	p2_cursor = select.instantiate()
	p2_cursor.name = "PlayerTwo"
	p2_cursor.player = 1
	p2_cursor.selected = Vector2(len(Content.char_map[0]) - 1,len(Content.char_map) - 1) #places at rightbottommost spot
	p2_cursor.max_x = len(Content.char_map[0])
	p2_cursor.max_y = len(Content.char_map)
	while Content.char_map[p2_cursor.selected.y][p2_cursor.selected.x] == null:
		p2_cursor.selected.x -= 1
		if p2_cursor.selected.x == -1:
			p2_cursor.selected.x = p2_cursor.max_x
			p2_cursor.selected.y -= 1
	p2_cursor.set_surface_override_material(0,build_albedo(character_folder + "/Player2Select.png", true, true))
	$CharSelectHolder.add_child(p2_cursor)
	screen = "CharSelect"
	return "Success"

func _on_Start_pressed():
	$MenuButtons.hide()
	$LogoLayer/Logo.get_children()[0].queue_free() #this is safe I promise
	loadCharSelect()
