class_name MainGame
extends Node3D

enum Moments {
	FADE_IN,
	INTRO,
	GAME,
	DRAMATIC_FREEZE,
	PAUSE,
	ROUND_END,
	FADE_OUT,
}

enum RoundChangeTypes {
	ADD,
	REMOVE
}

const MOVEMENTBOUNDX = 4.5

const TICKS_PER_TIME_UNIT = 60
const START_TIME = 99

var p1 : Fighter
var p2 : Fighter
var stage : Stage

var p1_buttons = [false, false, false, false, false, false, false, false, false, false]
var p2_buttons = [false, false, false, false, false, false, false, false, false, false]

var p1_inputs : Dictionary = {
	up=[[0, false]],
	down=[[0, false]],
	left=[[0, false]],
	right=[[0, false]],
}

var p1_dummy_buffer = {
	up=[[0,false]],
	down=[[0,false]],
	left=[[0,false]],
	right=[[0,false]],
}

var p2_inputs : Dictionary = {
	up=[[0, false]],
	down=[[0, false]],
	left=[[0, false]],
	right=[[0, false]],
}

var p2_dummy_buffer = {
	up=[[0,false]],
	down=[[0,false]],
	left=[[0,false]],
	right=[[0,false]],
}

var p1_input_index : int = 0
var p2_input_index : int = 0

var game_tick : int = 0
var game_seconds : int = 0

var p1_combo := 0
var p2_combo := 0

var game_ended := false
var moment := Moments.FADE_IN
var moment_before_pause : Moments
var round_change_behavior : RoundChangeTypes = RoundChangeTypes.ADD

@onready var grab_point = preload("res://scenes/GrabPoint.tscn")
@onready var round_element = preload("res://scenes/RoundElement.tscn")
@onready var clash_particle = preload("res://scenes/Clash.tscn")
@onready var clash_sound = preload("res://sound_effects/clash.wav")
@onready var debug_targetter = preload("res://scenes/DebugTargetter.tscn")

@export var fighter_camera : FighterCamera

@export var game_fighters_and_stage : Node3D
@export var game_projectiles : Node3D
@export var game_hitboxes : Node3D
@export var game_particles : Node3D
@export var game_audio : Node3D

@export var ui_splash_text : Label
@export var ui_p1_health : TextureProgressBar
@export var ui_p2_health : TextureProgressBar
@export var ui_p1_name : Label
@export var ui_p2_name : Label
@export var ui_timer : Label
@export var ui_p1_combo_counter : Label
@export var ui_p2_combo_counter : Label

@export var ui_p1_under_health_section : Control
@export var ui_p2_under_health_section : Control
@export var ui_p1_sidebar_section : Control
@export var ui_p2_sidebar_section : Control
@export var ui_p1_below_section : Control
@export var ui_p2_below_section : Control

@export var layer_hud : CanvasLayer
@export var layer_drama_freeze : CanvasLayer
@export var layer_results_screen : CanvasLayer
@export var layer_pause_screen : CanvasLayer
@export var layer_smooth_transistions : ColorTransition

@export var pause_screen_node : PauseScreen
@export var results_screen_node : ResultsScreen

@export var smooth_transition : ColorRect

func construct_game():
	layer_drama_freeze.visible = true
	layer_hud.visible = true
	layer_results_screen.visible = false
	layer_pause_screen.visible = false
	layer_smooth_transistions.visible = true
	GameGlobal.global_hitstop = 0
	game_seconds = START_TIME
	stage = Content.stage_resource.instantiate()
	game_fighters_and_stage.add_child(stage)
	fighter_camera.set_mode(FighterCamera.Modes.BALANCED)
	fighter_camera.pers_orth = not stage.mode == Stage.Modes.TWO_D
	p1 = Content.p1_resource.instantiate()
	p1.name = "p1"
	p1.player = true
	p2 = Content.p2_resource.instantiate()
	p2.name = "p2"
	p2.player = false
	make_hud()
	pause_screen_node.make_command_list(p1, p2)
	init_fighters()
	game_fighters_and_stage.add_child(p1)
	game_fighters_and_stage.add_child(p2)


func _ready():
	construct_game()


func start_pause_menu(is_p1 : bool):
	p1.update_paused(true)
	p2.update_paused(true)
	for hitbox in (game_hitboxes.get_children() as Array[Hitbox]):
		hitbox.paused = true
	for projectile in (game_projectiles.get_children() as Array[Projectile]):
		projectile.update_paused(true)
	pause_screen_node.p1_active = is_p1
	pause_screen_node.p2_active = not is_p1
	pause_screen_node.p1_choice = 0
	pause_screen_node.p2_choice = 0
	pause_screen_node.p1_select_icon.visible = is_p1
	pause_screen_node.p2_select_icon.visible = not is_p1
	moment_before_pause = moment
	moment = Moments.PAUSE
	pause_screen_node.active = true
	layer_pause_screen.visible = true


func end_pause_menu():
	p1.update_paused(false)
	p2.update_paused(false)
	for hitbox in (game_hitboxes.get_children() as Array[Hitbox]):
		hitbox.paused = false
	for projectile in (game_projectiles.get_children() as Array[Projectile]):
		projectile.update_paused(false)
	moment = moment_before_pause
	pause_screen_node.active = false
	layer_pause_screen.visible = false


func fade_in_function(delta):
	move_inputs(true)
	p1._input_step()
	p1._action_step(false, delta)
	p2._input_step()
	p2._action_step(false, delta)
	character_positioning(delta)
	check_combos()
	layer_smooth_transistions.do_second_half()
	await layer_smooth_transistions.second_half_completed
	moment = Moments.INTRO
	p1._do_intro()
	p2._do_intro()


func intro_function(delta):
	move_inputs(true)
	p1._input_step()
	p1._action_step(false, delta)
	p2._input_step()
	p2._action_step(false, delta)
	if p1._post_intro() and p2._post_intro():
		moment = Moments.GAME
		ui_splash_text.text = "FIGHT"
		ui_splash_text.visible = true
	check_combos()
	character_positioning(delta)
	update_hud()


func game_function(delta):
	# handle projectiles
	for proj in (game_projectiles.get_children() as Array[Projectile]):
		proj.tick(delta)
	# handle players
	create_inputs()
	move_inputs(false)
	p1._input_step()
	p1._action_step(false, delta)
	p2._input_step()
	p2._action_step(false, delta)
	check_combos()
	character_positioning(delta)
	game_tick += 1
	if game_tick % TICKS_PER_TIME_UNIT == 0:
		game_seconds -= 1
		if game_seconds == 0:
			time_over()
	update_hud()
	ui_splash_text.modulate.a8 -= 10
	if Input.is_action_just_pressed("first_pause"):
		start_pause_menu(true)
	if Input.is_action_just_pressed("second_pause"):
		start_pause_menu(false)


func drama_freeze_function(delta):
	create_inputs()
	move_inputs(false)
	p1._input_step()
	p1._action_step(true, delta)
	p2._input_step()
	p2._action_step(true, delta)
	character_positioning(delta)
	update_hud()
	if Input.is_action_just_pressed("first_pause"):
		start_pause_menu(true)
	if Input.is_action_just_pressed("second_pause"):
		start_pause_menu(false)


func pause_function(_delta):
	for audio in game_audio.get_children() as Array[PausingCleaningAudioStreamPlayer]:
		audio.pause(game_tick)
	await pause_screen_node.exited
	for audio in game_audio.get_children() as Array[PausingCleaningAudioStreamPlayer]:
		audio.unpause()
	end_pause_menu()


func _ko_animation_complete() -> bool:
	return ui_splash_text.modulate.a8 == 0


func round_end_function(delta):
	ui_splash_text.modulate.a8 = max(ui_splash_text.modulate.a8 - 4, 0)
	for proj in (game_projectiles.get_children() as Array[Projectile]):
		proj.destroy()
		proj.tick(delta, true)
	move_inputs(true)
	p1._input_step()
	p1._action_step(false, delta)
	p2._input_step()
	p2._action_step(false, delta)
	check_combos()
	character_positioning(delta)
	update_hud()
	if game_ended:
		return
	if not _ko_animation_complete():
		return
	if p1.game_ended in [Fighter.GameEnds.WIN_KO, Fighter.GameEnds.WIN_TIME] and p1._post_outro() and p2._in_defeated_state():
		GameGlobal.p1_wins += 1
		if GameGlobal.p1_wins < GameGlobal.win_threshold:
			moment = Moments.FADE_OUT
		else:
			print("game ended with a p1 victory, creating results screen")
			make_results_screen(0)
	elif p1._in_defeated_state() and p2.game_ended in [Fighter.GameEnds.WIN_KO, Fighter.GameEnds.WIN_TIME] and p2._post_outro():
		GameGlobal.p2_wins += 1
		if GameGlobal.p2_wins < GameGlobal.win_threshold:
			moment = Moments.FADE_OUT
		else:
			print("game ended with a p2 victory, creating results screen")
			make_results_screen(1)
	elif p1._in_defeated_state() and p2._in_defeated_state():
		if (
			GameGlobal.p1_wins == GameGlobal.win_threshold - 1
			and GameGlobal.p2_wins == GameGlobal.win_threshold - 1
		):
			print("game ended on a draw, creating results screen")
			make_results_screen(2)
		else:
			GameGlobal.p1_wins = GameGlobal.win_threshold - 1
			GameGlobal.p2_wins = GameGlobal.win_threshold - 1
			moment = Moments.FADE_OUT


func fade_out_function(_delta):
	layer_smooth_transistions.do_first_half()
	await layer_smooth_transistions.first_half_completed


func _physics_process(delta):
	fighter_camera.p1_pos = p1.global_position
	fighter_camera.p2_pos = p2.global_position
	match moment:
		Moments.FADE_IN:
			fade_in_function(delta)
		Moments.INTRO:
			intro_function(delta)
		Moments.GAME:
			game_function(delta)
		Moments.DRAMATIC_FREEZE:
			drama_freeze_function(delta)
		Moments.PAUSE:
			pause_function(delta)
		Moments.ROUND_END:
			round_end_function(delta)
		Moments.FADE_OUT:
			fade_out_function(delta)
			get_tree().reload_current_scene()


func make_results_screen(winner : int):
	game_ended = true
	layer_hud.visible = false
	layer_results_screen.visible = true
	results_screen_node.start_results_screen(
			winner, p1.win_quote, p2.win_quote)

func results_screen_choices_logic():
	var p1_c = results_screen_node.p1_choice
	var p2_c = results_screen_node.p2_choice
	if p1_c == ResultsScreen.Choice.REPLAY and p2_c == p1_c:
		GameGlobal.p1_wins = 0
		GameGlobal.p2_wins = 0
		moment = Moments.FADE_OUT
	if p1_c == ResultsScreen.Choice.CHARACTER_SELECT or p2_c == ResultsScreen.Choice.CHARACTER_SELECT:
		pass
	if p1_c == ResultsScreen.Choice.MAIN_MENU or p2_c == ResultsScreen.Choice.MAIN_MENU:
		if get_tree().change_scene_to_file("res://scenes/Menu.tscn"):
			push_error("menu failed to load")


func make_hud():
	# player 1
	ui_p1_health.max_value = p1.health
	ui_p1_health.value = p1.health
	ui_p1_name.text = p1.char_name

	p1._initialize_hud_elements(true)
	p1._connect_hud_elements(true)
	if p1.ui_under_health:
		ui_p1_under_health_section.add_child(p1.ui_under_health)
	if p1.ui_sidebar:
		ui_p1_sidebar_section.add_child(p1.ui_sidebar)
	if p1.ui_below:
		ui_p1_below_section.add_child(p1.ui_below)

	# player 2
	ui_p2_health.max_value = p2.health
	ui_p2_health.value = p2.health
	ui_p2_name.text = p2.char_name

	p2._initialize_hud_elements(true)
	p2._connect_hud_elements(true)
	if p2.ui_under_health:
		ui_p2_under_health_section.add_child(p2.ui_under_health)
	if p2.ui_sidebar:
		ui_p2_sidebar_section.add_child(p2.ui_sidebar)
	if p2.ui_below:
		ui_p2_below_section.add_child(p2.ui_below)

	# set up rounds
	var p1_round_group = HBoxContainer.new()
	p1_round_group.alignment = BoxContainer.ALIGNMENT_END
	p1_round_group.name = "Rounds"
	ui_p1_under_health_section.add_child(p1_round_group)
	var p2_round_group = HBoxContainer.new()
	p2_round_group.alignment = BoxContainer.ALIGNMENT_BEGIN
	p2_round_group.name = "Rounds"
	ui_p2_under_health_section.add_child(p2_round_group)
	for n in range(GameGlobal.win_threshold):
		var p1_round = round_element.instantiate()
		p1_round.name = str(n)
		p1_round_group.add_child(p1_round)
		var p2_round = round_element.instantiate()
		p2_round.name = str(n)
		p2_round_group.add_child(p2_round)
	match round_change_behavior:
		RoundChangeTypes.ADD:
			for n in range(GameGlobal.win_threshold):
				(p1_round_group.get_node(str(n)) as RoundElement).unfulfill()
				(p2_round_group.get_node(str(n)) as RoundElement).unfulfill()
			for n in range(GameGlobal.p1_wins):
				(p1_round_group.get_node(str(n)) as RoundElement).fulfill()
			for n in range(GameGlobal.p2_wins):
				(p2_round_group.get_node(str(n)) as RoundElement).fulfill()
		RoundChangeTypes.REMOVE:
			for n in range(GameGlobal.win_threshold):
				(p1_round_group.get_node(str(n)) as RoundElement).fulfill()
				(p2_round_group.get_node(str(n)) as RoundElement).fulfill()
			for n in range(GameGlobal.p1_wins, -1, -1):
				(p2_round_group.get_node(str(n)) as RoundElement).unfulfill()
			for n in range(GameGlobal.p2_wins, -1, -1):
				(p1_round_group.get_node(str(n)) as RoundElement).unfulfill()

	ui_splash_text.visible = false


func update_hud():
	ui_p1_health.value = p1.health
	ui_p1_combo_counter.text = str(p1_combo)
	ui_p1_combo_counter.visible = p1_combo > 1
	ui_p2_health.value = p2.health
	ui_p2_combo_counter.text = str(p2_combo)
	ui_p2_combo_counter.visible = p2_combo > 1
	ui_timer.text = str(game_seconds)


func init_fighters():
	for i in range(p1.BUTTONCOUNT):
		p1_inputs["button" + str(i)] = [[0, false]]
		p1_dummy_buffer["button" + str(i)] = [[0, false]]
	p1.position = Vector3.ZERO
	p1.position.x = clamp(abs(p1.start_x_offset) * -1, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
	p1._initialize_boxes()
	p1.hitbox_created.connect(register_hitbox)
	p1.projectile_created.connect(register_projectile)
	p1.dramatic_freeze_created.connect(start_dramatic_freeze)
	p1.audio_created.connect(spawn_audio)
	p1.particle_created.connect(register_particle)
	p1.grabbed.connect(grabbed)
	p1.grab_released.connect(grab_released)
	p1.defeated.connect(player_defeated)
	p1.activated_camera.connect(custom_camera.bind(p1.custom_camera))
	p1.grabbed_point = grab_point.instantiate()
	game_fighters_and_stage.add_child(p1.grabbed_point)

	for i in range(p2.BUTTONCOUNT):
		p2_inputs["button" + str(i)] = [[0, false]]
		p2_dummy_buffer["button" + str(i)] = [[0, false]]
	p2.position = Vector3.ZERO
	p2.position.x = clamp(abs(p2.start_x_offset), -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
	p2._initialize_boxes()
	p2.hitbox_created.connect(register_hitbox)
	p2.projectile_created.connect(register_projectile)
	p2.dramatic_freeze_created.connect(start_dramatic_freeze)
	p2.audio_created.connect(spawn_audio)
	p2.particle_created.connect(register_particle)
	p2.grabbed.connect(grabbed)
	p2.grab_released.connect(grab_released)
	p2.defeated.connect(player_defeated)
	p2.activated_camera.connect(custom_camera.bind(p2.custom_camera))
	p2.grabbed_point = grab_point.instantiate()
	game_fighters_and_stage.add_child(p2.grabbed_point)

	p1.distance = p1.position.x - p2.position.x
	p2.distance = p2.position.x - p1.position.x


func slice_input_dictionary(input_dict: Dictionary, from: int, to: int):
	var ret_dict = {
		up=input_dict[GameGlobal.BTN_UP].slice(from, to),
		down=input_dict[GameGlobal.BTN_DOWN].slice(from, to),
		left=input_dict[GameGlobal.BTN_LEFT].slice(from, to),
		right=input_dict[GameGlobal.BTN_RIGHT].slice(from, to),
	}
	var ret_dict_button_count = len(input_dict) - 4
	for i in range(ret_dict_button_count):
		ret_dict[GameGlobal.BTN_UNSPEC + str(i)] = input_dict[GameGlobal.BTN_UNSPEC + str(i)].slice(from, to)
	return ret_dict


#convert to hash to simplify comparisons
func generate_current_input_hash(buttons : Array, button_count : int) -> int:
	return (
			(int(buttons[0]) * 1) +
			(int(buttons[1]) * 2) +
			(int(buttons[2]) * 4) +
			(int(buttons[3]) * 8) +
			((int(button_count > 0 and buttons[4])) * 16) +
			((int(button_count > 1 and buttons[5])) * 32) +
			((int(button_count > 2 and buttons[6])) * 64) +
			((int(button_count > 3 and buttons[7])) * 128) +
			((int(button_count > 4 and buttons[8])) * 256) +
			((int(button_count > 5 and buttons[9])) * 512)
	)


#ditto, but for an already completed input
func generate_prior_input_hash(player_inputs: Dictionary):
	var fail_case := [[0,false]]
	return (
			(int(player_inputs.get(GameGlobal.BTN_UP, fail_case)[-1][1]) * 1) +
			(int(player_inputs.get(GameGlobal.BTN_DOWN, fail_case)[-1][1]) * 2) +
			(int(player_inputs.get(GameGlobal.BTN_LEFT, fail_case)[-1][1]) * 4) +
			(int(player_inputs.get(GameGlobal.BTN_RIGHT, fail_case)[-1][1]) * 8) +
			(int(player_inputs.get(GameGlobal.BTN_0, fail_case)[-1][1]) * 16) +
			(int(player_inputs.get(GameGlobal.BTN_1, fail_case)[-1][1]) * 32) +
			(int(player_inputs.get(GameGlobal.BTN_2, fail_case)[-1][1]) * 64) +
			(int(player_inputs.get(GameGlobal.BTN_3, fail_case)[-1][1]) * 128) +
			(int(player_inputs.get(GameGlobal.BTN_4, fail_case)[-1][1]) * 256) +
			(int(player_inputs.get(GameGlobal.BTN_5, fail_case)[-1][1]) * 512)
	)


func increment_inputs(player_inputs: Dictionary):
	for inp in player_inputs:
		player_inputs[inp][-1][0] += 1


func create_new_input_set(player_inputs: Dictionary, new_inputs: Array):
	var ind = 0
	for inp in player_inputs:
		if new_inputs[ind] == player_inputs[inp][-1][1]: #if the same input is the same here
			player_inputs[inp].append(player_inputs[inp][-1].duplicate()) #copy it over
		else: #otherwise, this is a new input, so make a new entry
			player_inputs[inp].append([1, new_inputs[ind]])
		ind += 1


func directional_inputs(prefix: String) -> Array:
	return [
		(Input.is_action_pressed(prefix + "_" + GameGlobal.BTN_UP) and
				not Input.is_action_pressed(prefix + "_" + GameGlobal.BTN_DOWN)),
		(Input.is_action_pressed(prefix + "_" + GameGlobal.BTN_DOWN) and
				not Input.is_action_pressed(prefix + "_" + GameGlobal.BTN_UP)),
		(Input.is_action_pressed(prefix + "_" + GameGlobal.BTN_LEFT) and
				not Input.is_action_pressed(prefix + "_" + GameGlobal.BTN_RIGHT)),
		(Input.is_action_pressed(prefix + "_" + GameGlobal.BTN_RIGHT) and
				not Input.is_action_pressed(prefix + "_" + GameGlobal.BTN_LEFT)),
	]


func button_inputs(prefix : String, button_count : int) -> Array:
	var button_input_arr = []
	for button in range(button_count):
		button_input_arr.append(Input.is_action_pressed(prefix + "_" + GameGlobal.BTN_UNSPEC + str(button)))
	return button_input_arr


func create_inputs():
	p1_buttons = directional_inputs("first") + button_inputs("first", p1.BUTTONCOUNT)
	p2_buttons = directional_inputs("second") + button_inputs("second", p2.BUTTONCOUNT)

	if generate_prior_input_hash(p1_inputs) != generate_current_input_hash(
				p1_buttons, p1.BUTTONCOUNT):
		create_new_input_set(p1_inputs, p1_buttons)
		p1_input_index += 1
	else:
		increment_inputs(p1_inputs)

	if (generate_prior_input_hash(p2_inputs) != generate_current_input_hash(
			p2_buttons, p2.BUTTONCOUNT)):
		create_new_input_set(p2_inputs, p2_buttons)
		p2_input_index += 1
	else:
		increment_inputs(p2_inputs)


func hitbox_hitbox_collisions():
	for hitbox in (game_hitboxes.get_children() as Array[Hitbox]):
		if hitbox.invalid:
			continue
		if (hitbox as Hitbox).hit_priority == -1:
			continue
		for check in hitbox.get_overlapping_areas():
			if hitbox.collision_layer == check.collision_layer:
				continue
			if (check as Hitbox).invalid:
				continue
			if (check as Hitbox).hit_priority == -1:
				continue
			if (hitbox as Hitbox).hit_priority < (check as Hitbox).hit_priority:
				#print("%s collided with %s and is now neutralized" % [hitbox, check])
				hitbox.invalid = true
				break
			elif (hitbox as Hitbox).hit_priority > (check as Hitbox).hit_priority:
				#print("%s collided with %s and is now neutralized" % [check, hitbox])
				(check as Hitbox).invalid = true
			else:

				hitbox.invalid = true
				(check as Hitbox).invalid = true
				register_particle(
						clash_particle.instantiate(),
						GameParticle.Origins.CUSTOM,
						(hitbox.position + (check as Hitbox).position) / 2.0,
						null)
				spawn_audio(clash_sound)
				if not fighter_camera.pers_orth:
					fighter_camera.size *= 1.25
				else:
					fighter_camera.position.z *= 1.25
				GameGlobal.global_hitstop = 10


func move_inputs(fake_inputs : bool):
	if fake_inputs:
		p1.inputs = p1_dummy_buffer
		p2.inputs = p2_dummy_buffer
		return
	else:
		hitbox_hitbox_collisions()
		var p1_attackers = (p1._return_attackers() as Array[Hitbox])
		for p1_attacker in p1_attackers:
			if p1_attacker.invalid:
				continue
			var hit = p1._damage_step(p1_attacker, p2_combo)
			if hit:
				ui_p1_health.tint_progress.g8 = 0
				spawn_audio(p1_attacker.on_hit_sound)
				if not p1_attacker.is_projectile:
					p2.attack_connected = true
					p2.attack_hurt = true
				p2_combo += 1
				p2._on_hit(p1_attacker.on_hit)
				GameGlobal.global_hitstop = int(p1_attacker.hitstop_hit)
			else:
				spawn_audio(p1_attacker.on_block_sound)
				if not p1_attacker.is_projectile:
					p2.attack_connected = true
					p2.attack_hurt = false
				p2._on_block(p1_attacker.on_block)
				GameGlobal.global_hitstop = int(p1_attacker.hitstop_block)
			p1_attacker.queue_free()
		var p2_attackers = (p2._return_attackers() as Array[Hitbox])
		for p2_attacker in p2_attackers:
			if p2_attacker.invalid:
				continue
			var hit = p2._damage_step(p2_attacker, p1_combo)
			if hit:
				ui_p2_health.tint_progress.g8 = 0
				spawn_audio(p2_attacker.on_hit_sound)
				if not p2_attacker.is_projectile:
					p1.attack_connected = true
					p1.attack_hurt = true
				p1_combo += 1
				p1._on_hit(p2_attacker.on_hit)
				GameGlobal.global_hitstop = int(p2_attacker.hitstop_hit)
			else:
				spawn_audio(p2_attacker.on_block_sound)
				if not p2_attacker.is_projectile:
					p1.attack_connected = true
					p1.attack_hurt = false
				p1._on_block(p2_attacker.on_block)
				GameGlobal.global_hitstop = int(p2_attacker.hitstop_block)
			p2_attacker.queue_free()
	if p1.grabbed_point.act_on_player and p2.grabbed_point.act_on_player:
		p1.stun_time_current = 5
		p1.kback = Vector3(5, 5, 0)
		grab_released(true)
		p2.stun_time_current = 5
		p2.kback = Vector3(5, 5, 0)
		grab_released(false)
		pass
	p1.inputs = slice_input_dictionary(
			p1_inputs, max(0, p1_input_index - p1.input_buffer_len),
			p1_input_index + 1)
	p2.inputs = slice_input_dictionary(
			p2_inputs, max(0, p2_input_index - p2.input_buffer_len),
			p2_input_index + 1)


func check_combos():
	if not p1._in_hurting_state():
		p2_combo = 0
		ui_p1_health.tint_progress.g8 += 20
	if not p2._in_hurting_state():
		p1_combo = 0
		ui_p2_health.tint_progress.g8 += 20


func character_positioning(delta):
	if p1.grabbed_point.act_on_player:
		p1.grabbed_point.global_position = p2.grab_point.global_position
		p1.global_position = p1.grabbed_point.global_position + p1.grabbed_offset
	else:
		p1.grabbed_point.global_position = p1.global_position
	if p2.grabbed_point.act_on_player:
		p2.grabbed_point.global_position = p1.grab_point.global_position
		p2.global_position = p2.grabbed_point.global_position + p2.grabbed_offset
	else:
		p2.grabbed_point.global_position = p2.global_position

	p1.position.x = clamp(p1.position.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
	p2.opponent_on_stage_edge = abs(p1.position.x) == MOVEMENTBOUNDX
	p2.position.x = clamp(p2.position.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
	p1.opponent_on_stage_edge = abs(p2.position.x) == MOVEMENTBOUNDX

	p1.distance = p1.position.x - p2.position.x
	p2.distance = p2.position.x - p1.position.x
	# overlap fix
	if (not (p1.grabbed_point.act_on_player or p2.grabbed_point.act_on_player)
			and p1.get_node_or_null("Area3DIntersectionCheck") != null
			and p2.get_node_or_null("Area3DIntersectionCheck") != null):
		if (p1.get_node("Area3DIntersectionCheck") as Area3D).has_overlapping_areas():
			# motion style (faster fighter forces foe forwards)
			var change = abs(p1.velocity.x - p2.velocity.x)*delta
			if abs(p1.velocity.x) > abs(p2.velocity.x):
				if p1.distance >= 0.0:
					if p2.position.x - change >= -MOVEMENTBOUNDX:
						p2.position.x -= change
					else:
						p1.position.x += change
				else:
					if p2.position.x + change <= MOVEMENTBOUNDX:
						p2.position.x += change
					else:
						p1.position.x -= change
			elif abs(p1.velocity.x) < abs(p2.velocity.x):
				if p2.distance >= 0.0:
					if p1.position.x - change >= -MOVEMENTBOUNDX:
						p1.position.x -= change
					else:
						p2.position.x += change
				else:
					if p1.position.x + change <= MOVEMENTBOUNDX:
						p1.position.x += change
					else:
						p2.position.x -= change
			else:
				if p1.distance >= 0.0:
					p1.position.x += change
					p2.position.x -= change
				else:
					p1.position.x -= change
					p2.position.x += change
			var abs_dist = abs(p1.position.x - p2.position.x)
			# standing check (move both of them just enough to stop the overlap)
			var p1_ssx = p1.get_node_or_null("Area3DIntersectionCheck/IntersectionShape").shape.size.x
			var p2_ssx = p1.get_node_or_null("Area3DIntersectionCheck/IntersectionShape").shape.size.x
			if abs_dist < p1_ssx or abs_dist < p2_ssx:
				if p1.distance >= 0.0:
					p1.position.x += abs(p1_ssx - abs_dist)/2
					p2.position.x -= abs(p2_ssx - abs_dist)/2
				else:
					p1.position.x -= abs(p1_ssx - abs_dist)/2
					p2.position.x += abs(p2_ssx - abs_dist)/2
			# finally, recalculate distance
			p1.distance = p1.position.x - p2.position.x
			p2.distance = p2.position.x - p1.position.x


func spawn_audio(sound : AudioStream):
	var new_audio = PausingCleaningAudioStreamPlayer.new()
	new_audio.stream = sound
	game_audio.add_child(new_audio)


func register_particle(particle : GameParticle, origin : GameParticle.Origins, position_offset : Vector3, source : Fighter):
	match origin:
		GameParticle.Origins.SOURCE:
			particle.position = source.position + position_offset
			game_particles.add_child(particle)
		GameParticle.Origins.SOURCE_STICKY:
			particle.position = position_offset
			source.add_child(particle)
		GameParticle.Origins.OTHER:
			if source.player:
				particle.position = p2.position + position_offset
				game_particles.add_child(particle)
			else:
				particle.position = p1.position + position_offset
				game_particles.add_child(particle)
		GameParticle.Origins.OTHER_STICKY:
			particle.position = position_offset
			if source.player:
				p2.add_child(particle)
			else:
				p1.add_child(particle)
		GameParticle.Origins.CUSTOM:
			particle.position = position_offset
			game_particles.add_child(particle)


func register_hitbox(hitbox : Hitbox):
	game_hitboxes.add_child(hitbox, true)


func register_projectile(projectile : Projectile):
	projectile.projectile_ended.connect(delete_projectile)
	game_projectiles.add_child(projectile, true)


func start_dramatic_freeze(dramatic_freeze : DramaticFreeze, source : Fighter):
	dramatic_freeze.end_freeze.connect(end_dramatic_freeze)
	dramatic_freeze.source = source
	dramatic_freeze.source_2d_pos = fighter_camera.unproject_position(source.global_position)
	if source.player:
		dramatic_freeze.other = p2
		dramatic_freeze.other_2d_pos = fighter_camera.unproject_position(p2.global_position)
	else:
		dramatic_freeze.other = p1
		dramatic_freeze.other_2d_pos = fighter_camera.unproject_position(p1.global_position)
	layer_drama_freeze.add_child(dramatic_freeze, true)
	moment = Moments.DRAMATIC_FREEZE


func end_dramatic_freeze():
	moment = Moments.GAME


func delete_projectile(projectile):
	projectile.queue_free()


func grabbed(player):
	if player:
		p1.grabbed_point.act_on_player = true
	else:
		p2.grabbed_point.act_on_player = true


func grab_released(player):
	if player:
		p2.grabbed_point.act_on_player = false
	else:
		p1.grabbed_point.act_on_player = false


func time_over():
	GameGlobal.global_hitstop = 120
	ui_splash_text.text = "TIME"
	ui_splash_text.modulate.a8 = 255
	moment = Moments.ROUND_END
	p1.game_ended = Fighter.GameEnds.WIN_TIME if p1.health > p2.health else Fighter.GameEnds.LOSE_TIME
	p2.game_ended = Fighter.GameEnds.WIN_TIME if p2.health > p1.health else Fighter.GameEnds.LOSE_TIME
	for projectile in (game_projectiles.get_children() as Array[Projectile]):
		projectile.destroy()


func player_defeated():
	GameGlobal.global_hitstop = 120
	ui_splash_text.text = "KO"
	ui_splash_text.modulate.a8 = 255
	moment = Moments.ROUND_END
	p1.game_ended = Fighter.GameEnds.WIN_KO if p1.health > 0 else Fighter.GameEnds.LOSE_KO
	p2.game_ended = Fighter.GameEnds.WIN_KO if p2.health > 0 else Fighter.GameEnds.LOSE_KO
	for projectile in (game_projectiles.get_children() as Array[Projectile]):
		projectile.destroy()


func custom_camera(time : int, new_camera : Camera3D):
	fighter_camera.custom_camera = new_camera
	new_camera.make_current()
	fighter_camera.custom_cam_timer = time
	fighter_camera.set_mode(FighterCamera.Modes.CUSTOM)
