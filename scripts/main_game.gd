extends Node3D

enum Moments {
	FADE_IN,
	INTRO,
	GAME,
	DRAMATIC_FREEZE,
	ROUND_END,
	FADE_OUT,
}

enum RoundChangeTypes {
	ADD,
	REMOVE
}

const MOVEMENTBOUNDX = 4.5

@export var results_screen_file : PackedScene

var p1 : Fighter
var p2 : Fighter
var stage : Stage

var p1_reset_health_on_drop := true
var p2_reset_health_on_drop := true
var p1_health_reset : float
var p2_health_reset : float

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

var player_record_buffer := []
var record_buffer_current := 0
var record := false
var replay := false

var p1_combo := 0
var p2_combo := 0

var game_ended := false
var moment := Moments.FADE_IN
var round_change_behavior : RoundChangeTypes = RoundChangeTypes.ADD

@onready var grab_point = preload("res://scenes/GrabPoint.tscn")
@onready var round_element = preload("res://scenes/RoundElement.tscn")
@onready var clash_particle = preload("res://scenes/Clash.tscn")
@onready var clash_sound = preload("res://sound_effects/clash.wav")
@onready var debug_targetter = preload("res://scenes/DebugTargetter.tscn")

func _ready():
	$SmoothTransitionLayer/ColorRect.color = Color(0, 0, 0, 1)
	reset_hitstop()
	stage = Content.stage_resource.instantiate()
	$FightersAndStage.add_child(stage)
	if stage.mode == Stage.Modes.TWO_D:
		$FighterCamera.set_mode(FighterCamera.Modes.ORTH_BALANCED)
	else:
		$FighterCamera.set_mode(FighterCamera.Modes.PERS_BALANCED)
	p1 = Content.p1_resource.instantiate()
	p1.name = "p1"
	p2 = Content.p2_resource.instantiate()
	p2.name = "p2"
	make_hud()
	init_fighters()
	$FightersAndStage.add_child(p1)
	$FightersAndStage.add_child(p2)
	var p1_dtar = (debug_targetter.instantiate() as DebugTargetter)
	p1_dtar.pointer_texture = load("res://Content/Art/Menu/CharacterSelect/Player1Select.png")
	p1_dtar.pointer_target = p1
	$FightersAndStage.add_child(p1_dtar)
	var p2_dtar = (debug_targetter.instantiate() as DebugTargetter)
	p2_dtar.pointer_texture = load("res://Content/Art/Menu/CharacterSelect/Player2Select.png")
	p2_dtar.pointer_target = p2
	$FightersAndStage.add_child(p2_dtar)



func _physics_process(delta):
	($FighterCamera as FighterCamera).p1_pos = p1.global_position
	($FighterCamera as FighterCamera).p2_pos = p2.global_position
	match moment:
		Moments.FADE_IN:
			move_inputs(true)
			p1._input_step()
			p1._action_step(false)
			p2._input_step()
			p2._action_step(false)
			$SmoothTransitionLayer/ColorRect.color.a = lerpf($SmoothTransitionLayer/ColorRect.color.a, 0.0, 0.25)
			if $SmoothTransitionLayer/ColorRect.color.a < 0.1:
				$SmoothTransitionLayer/ColorRect.color.a = 0.0
				moment = Moments.INTRO
				p1._do_intro()
				p2._do_intro()
		Moments.INTRO:
			move_inputs(true)
			p1._input_step()
			p1._action_step(false)
			p2._input_step()
			p2._action_step(false)
			if p1._post_intro() and p2._post_intro():
				moment = Moments.GAME
				($HUD/BigText as Label).text = "FIGHT"
				$HUD/BigText.visible = true
			check_combos()
			character_positioning(delta)
			update_hud()
		Moments.GAME:
			# handle projectiles
			for proj in ($Projectiles.get_children() as Array[Projectile]):
				proj.tick()
			create_inputs()
			move_inputs(false)
			p1._input_step()
			p1._action_step(false)
			p2._input_step()
			p2._action_step(false)
			check_combos()
			training_mode_settings()
			character_positioning(delta)
			update_hud()
			$HUD/BigText.modulate.a8 -= 10
		Moments.DRAMATIC_FREEZE:
			create_inputs()
			move_inputs(false)
			p1._input_step()
			p1._action_step(true)
			p2._input_step()
			p2._action_step(true)
			character_positioning(delta)
			update_hud()
		Moments.ROUND_END:
			$HUD/BigText.modulate.a8 -= 4
			move_inputs(true)
			p1._input_step()
			p1._action_step(false)
			p2._input_step()
			p2._action_step(false)
			check_combos()
			character_positioning(delta)
			update_hud()
			if game_ended:
				return
			if p1._post_outro() and p2._in_defeated_state():
				GameGlobal.p1_wins += 1
				if GameGlobal.p1_wins < GameGlobal.win_threshold:
					moment = Moments.FADE_OUT
				else:
					print("game ended with a p1 victory, creating results screen")
					make_results_screen(0)
			elif p1._in_defeated_state() and p2._post_outro():
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
		Moments.FADE_OUT:
			$SmoothTransitionLayer/ColorRect.color.a = lerpf($SmoothTransitionLayer/ColorRect.color.a, 1.0, 0.25)
			if is_zero_approx($SmoothTransitionLayer/ColorRect.color.a - 1.0):
				get_tree().reload_current_scene()


func make_results_screen(winner : int):
	game_ended = true
	$HUD.visible = false
	$ResultsScreen.visible = true
	match winner:
		0:
			$ResultsScreen/ResultsScreen.p1_winner_icon.visible = true
			$ResultsScreen/ResultsScreen.winner_quote.text = p1.win_quote
			$ResultsScreen/ResultsScreen.winner_quote.visible = true
		1:
			$ResultsScreen/ResultsScreen.p2_winner_icon.visible = true
			$ResultsScreen/ResultsScreen.winner_quote.text = p2.win_quote
			$ResultsScreen/ResultsScreen.winner_quote.visible = true
		2:
			$ResultsScreen/ResultsScreen.no_winner_icon.visible = true
			$ResultsScreen/ResultsScreen.winner_quote.visible = false
	$ResultsScreen/ResultsScreen.active = true

func results_screen_choices_logic():
	var p1_choice = $ResultsScreen/ResultsScreen.p1_choice
	var p2_choice = $ResultsScreen/ResultsScreen.p2_choice
	if p1_choice == ResultsScreen.Choice.REPLAY and p2_choice == p1_choice:
		GameGlobal.p1_wins = 0
		GameGlobal.p2_wins = 0
		moment = Moments.FADE_OUT
	if p1_choice == ResultsScreen.Choice.CHARACTER_SELECT or p2_choice == ResultsScreen.Choice.CHARACTER_SELECT:
		pass
	if p1_choice == ResultsScreen.Choice.MAIN_MENU or p2_choice == ResultsScreen.Choice.MAIN_MENU:
		if get_tree().change_scene_to_file("res://scenes/Menu.tscn"):
			push_error("menu failed to load")


func make_hud():
	# player 1
	$HUD/HealthAndTime/P1Group/Health.max_value = p1.health
	$HUD/HealthAndTime/P1Group/Health.value = p1.health
	$HUD/HealthAndTime/P1Group/NameAndPosVel/Char.text = p1.char_name
	$HUD/HealthAndTime/P1Group/NameAndPosVel/PosVel.text = (
			str(p1.position) + "\n" + str(p1.velocity))
	$HUD/P1Stats/State.text = p1.States.keys()[p1.current_state]

	# player 2
	$HUD/HealthAndTime/P2Group/Health.max_value = p2.health
	$HUD/HealthAndTime/P2Group/Health.value = p2.health
	$HUD/HealthAndTime/P2Group/NameAndPosVel/Char.text = p2.char_name
	$HUD/HealthAndTime/P2Group/NameAndPosVel/PosVel.text = (
			str(p2.position) + "\n" + str(p2.velocity))
	$HUD/P2Stats/State.text = p2.States.keys()[p2.current_state]

	# set up rounds
	var p1_round_group = $HUD/HealthAndTime/P1Group/Rounds
	var p2_round_group = $HUD/HealthAndTime/P2Group/Rounds
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

	# game itself
	$HUD/BigText.visible = false
	var health_reset_hud = $HUD/TrainingModeControls/P1Controls/HBoxContainer/HealthReset
	health_reset_hud.min_value = 1
	health_reset_hud.max_value = p1.health
	health_reset_hud.value = health_reset_hud.max_value
	$HUD/TrainingModeControls/P1Controls/HBoxContainer/HealthResetSwitch.set_pressed_no_signal(p1_reset_health_on_drop)
	health_reset_hud = $HUD/TrainingModeControls/P2Controls/HBoxContainer/HealthReset
	health_reset_hud.min_value = 1
	health_reset_hud.max_value = p2.health
	health_reset_hud.value = health_reset_hud.max_value
	$HUD/TrainingModeControls/P2Controls/HBoxContainer/HealthResetSwitch.set_pressed_no_signal(p2_reset_health_on_drop)


func update_hud():
	# player 1
	$HUD/HealthAndTime/P1Group/Health.value = p1.health
	$HUD/P1Stats/State.text = p1.States.keys()[p1.current_state]
	if "attack" in $HUD/P1Stats/State.text:
		$HUD/P1Stats/State.text += " : " + p1.current_attack
	$HUD/HealthAndTime/P1Group/NameAndPosVel/PosVel.text = (
			str(p1.position) + "\n" + str(p1.velocity))
	$HUD/P1Stats/Combo.text = str(p1_combo)

	# player 2
	$HUD/HealthAndTime/P2Group/Health.value = p2.health
	$HUD/P2Stats/State.text = p2.States.keys()[p2.current_state]
	if "attack" in $HUD/P2Stats/State.text:
		$HUD/P2Stats/State.text += " : " + p2.current_attack
	$HUD/HealthAndTime/P2Group/NameAndPosVel/PosVel.text = (
			str(p2.position) + "\n" + str(p2.velocity))
	$HUD/P2Stats/Combo.text = str(p2_combo)

	# training
	$HUD/TrainingModeControls/P2Controls/HBoxContainer/RecordStatus.text = (
		"%s/%s %s" % [
			record_buffer_current,
			len(player_record_buffer),
			"PLY" if replay else ("REC" if record else "STP"),
		]
	)


func init_fighters():
	for i in range(p1.BUTTONCOUNT):
		p1_inputs["button" + str(i)] = [[0, false]]
		p1_dummy_buffer["button" + str(i)] = [[0, false]]
	p1.player = true
	p1.position = Vector3(abs(p1.start_x_offset) * -1, 0, 0)
	p1._initialize_boxes()
	p1.hitbox_created.connect(register_hitbox)
	p1.projectile_created.connect(register_projectile)
	p1.dramatic_freeze_created.connect(start_dramatic_freeze)
	p1.audio_created.connect(spawn_audio)
	p1.particle_created.connect(register_particle)
	p1.grabbed.connect(grabbed)
	p1.grab_released.connect(grab_released)
	p1.defeated.connect(player_defeated)
	p1._initialize_hud_elements(true)
	p1._connect_hud_elements(true)
	if p1.ui_under_health:
		$HUD/HealthAndTime/P1Group.add_child(p1.ui_under_health)
	if p1.ui_sidebar:
		$HUD/P1Stats.add_child(p1.ui_sidebar)
	if p1.ui_below:
		$HUD/TrainingModeControlsSpecial/P1Controls.add_child(p1.ui_below)
	if p1.ui_training:
		$HUD/TrainingModeControlsSpecial/P1Controls.add_child(p1.ui_training)
	p1.grabbed_point = grab_point.instantiate()
	$FightersAndStage.add_child(p1.grabbed_point)

	for i in range(p2.BUTTONCOUNT):
		p2_inputs["button" + str(i)] = [[0, false]]
		p2_dummy_buffer["button" + str(i)] = [[0, false]]
	p2.player = false
	p2.position = Vector3(abs(p2.start_x_offset), 0, 0)
	p2._initialize_boxes()
	p2.hitbox_created.connect(register_hitbox)
	p2.projectile_created.connect(register_projectile)
	p2.dramatic_freeze_created.connect(start_dramatic_freeze)
	p2.audio_created.connect(spawn_audio)
	p2.particle_created.connect(register_particle)
	p2.grabbed.connect(grabbed)
	p2.grab_released.connect(grab_released)
	p2.defeated.connect(player_defeated)
	p2._initialize_hud_elements(true)
	p2._connect_hud_elements(true)
	if p2.ui_under_health:
		$HUD/HealthAndTime/P2Group.add_child(p2.ui_under_health)
	if p2.ui_sidebar:
		$HUD/P2Stats.add_child(p2.ui_sidebar)
	if p2.ui_below:
		$HUD/TrainingModeControlsSpecial/P1Controls.add_child(p2.ui_below)
	if p2.ui_training:
		$HUD/TrainingModeControlsSpecial/P2Controls.add_child(p2.ui_training)
	p2.grabbed_point = grab_point.instantiate()
	$FightersAndStage.add_child(p2.grabbed_point)

	p1.position.x = clamp(p1.position.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
	p2.position.x = clamp(p2.position.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)
	p1.distance = p1.position.x - p2.position.x
	p2.distance = p2.position.x - p1.position.x
	p1_health_reset = p1.health
	p2_health_reset = p2.health


func reset_hitstop():
	GameGlobal.global_hitstop = 0

var directionDictionary = {
	"": "x",
	"up": "↑", "down": "↓", "left": "←", "right": "→",
	"upleft": "↖", "downleft": "↙",
	"upright": "↗", "downright": "↘"
}

func slice_input_dictionary(input_dict: Dictionary, from: int, to: int):
	var ret_dict = {
		up=input_dict["up"].slice(from, to),
		down=input_dict["down"].slice(from, to),
		left=input_dict["left"].slice(from, to),
		right=input_dict["right"].slice(from, to),
	}
	var ret_dict_button_count = len(input_dict) - 4
	for i in range(ret_dict_button_count):
		ret_dict["button" + str(i)] = input_dict["button" + str(i)].slice(from, to)
	return ret_dict


func generate_input_hud(buf : Dictionary, input_label : Label):
	var lookup_string := ""
	var dirs := ["up", "down", "left", "right"]

	input_label.text = ""
	for i in range(len(buf.up)):
		lookup_string = ""
		lookup_string += dirs[0] if buf[dirs[0]][i][1] else ""
		lookup_string += dirs[1] if buf[dirs[1]][i][1] else ""
		lookup_string += dirs[2] if buf[dirs[2]][i][1] else ""
		lookup_string += dirs[3] if buf[dirs[3]][i][1] else ""
		input_label.text += directionDictionary[lookup_string]
		input_label.text += "\t"
		for button in buf:
			if button in dirs:
				if buf[button][i][1]:
					input_label.text += (
							"| %s, %s " % [str(buf[button][i][0]), directionDictionary[button]])
				else:
					input_label.text += (
							"| %s, x " % [str(buf[button][i][0])])
			else:
				input_label.text += (
					"| %s, %s " % [buf[button][i][0], ("Ø" if buf[button][i][1] else "0")])
		input_label.text += "\n"


func build_input_tracker(p1_buf : Dictionary, p2_buf : Dictionary) -> void:
	generate_input_hud(p1_buf, $HUD/P1Stats/Inputs)
	generate_input_hud(p2_buf, $HUD/P2Stats/Inputs)

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
			(int(player_inputs.get("up", fail_case)[-1][1]) * 1) +
			(int(player_inputs.get("down", fail_case)[-1][1]) * 2) +
			(int(player_inputs.get("left", fail_case)[-1][1]) * 4) +
			(int(player_inputs.get("right", fail_case)[-1][1]) * 8) +
			(int(player_inputs.get("button0", fail_case)[-1][1]) * 16) +
			(int(player_inputs.get("button1", fail_case)[-1][1]) * 32) +
			(int(player_inputs.get("button2", fail_case)[-1][1]) * 64) +
			(int(player_inputs.get("button3", fail_case)[-1][1]) * 128) +
			(int(player_inputs.get("button4", fail_case)[-1][1]) * 256) +
			(int(player_inputs.get("button5", fail_case)[-1][1]) * 512)
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
		(Input.is_action_pressed(prefix + "_up") and
				not Input.is_action_pressed(prefix + "_down")),
		(Input.is_action_pressed(prefix + "_down") and
				not Input.is_action_pressed(prefix + "_up")),
		(Input.is_action_pressed(prefix + "_left") and
				not Input.is_action_pressed(prefix + "_right")),
		(Input.is_action_pressed(prefix + "_right") and
				not Input.is_action_pressed(prefix + "_left")),
	]


func button_inputs(prefix : String, button_count : int) -> Array:
	var button_input_arr = []
	for button in range(button_count):
		button_input_arr.append(Input.is_action_pressed(prefix + "_button" + str(button)))
	return button_input_arr


func create_inputs():
	p1_buttons = directional_inputs("first") + button_inputs("first", p1.BUTTONCOUNT)
	p2_buttons = directional_inputs("second") + button_inputs("second", p2.BUTTONCOUNT)

	if record:
		player_record_buffer.append(p2_buttons.duplicate())

	if not record and not replay and Input.is_action_just_pressed("training_replay"):
		replay = true

	if generate_prior_input_hash(p1_inputs) != generate_current_input_hash(
				p1_buttons, p1.BUTTONCOUNT):
		create_new_input_set(p1_inputs, p1_buttons)
		p1_input_index += 1
	else:
		increment_inputs(p1_inputs)

	if replay and record_buffer_current == len(player_record_buffer):
		replay = false
		record_buffer_current = 0

	if not replay:
		if (generate_prior_input_hash(p2_inputs) != generate_current_input_hash(
				p2_buttons, p2.BUTTONCOUNT)):
			create_new_input_set(p2_inputs, p2_buttons)
			p2_input_index += 1
		else:
			increment_inputs(p2_inputs)
	else:
		if (generate_prior_input_hash(p2_inputs) !=
					generate_current_input_hash(
							player_record_buffer[record_buffer_current], p2.BUTTONCOUNT)):
			create_new_input_set(p2_inputs, player_record_buffer[record_buffer_current])
			p2_input_index += 1
		else:
			increment_inputs(p2_inputs)
		record_buffer_current += 1


func hitbox_hitbox_collisions():
	for hitbox in ($Hitboxes.get_children() as Array[Hitbox]):
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
				if ($FighterCamera as FighterCamera).mode_is_orth():
					($FighterCamera as FighterCamera).size *= 1.25
				else:
					($FighterCamera as FighterCamera).position.z *= 1.25
				GameGlobal.global_hitstop = 10



func move_inputs(fake_inputs):
	if fake_inputs:
		p1.inputs = p1_dummy_buffer
		p2.inputs = p2_dummy_buffer
		p1._input_step()
		p2._input_step()
		return

	var p1_buf = slice_input_dictionary(
			p1_inputs, max(0, p1_input_index - p1.input_buffer_len),
			p1_input_index + 1
	)
	var p2_buf = slice_input_dictionary(
			p2_inputs, max(0, p2_input_index - p2.input_buffer_len),
			p2_input_index + 1
	)
	build_input_tracker(p1_buf, p2_buf)

	if not fake_inputs:
		hitbox_hitbox_collisions()
		var p1_attackers = (p1._return_attackers() as Array[Hitbox])
		for p1_attacker in p1_attackers:
			if p1_attacker.invalid:
				continue
			var hit = p1._damage_step(p1_attacker, p2_combo)
			if hit:
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

	p1.inputs = p1_buf
	p2.inputs = p2_buf


func check_combos():
	if not p1._in_hurting_state():
		p2_combo = 0
	if not p2._in_hurting_state():
		p1_combo = 0


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
	p2.position.x = clamp(p2.position.x, -MOVEMENTBOUNDX, MOVEMENTBOUNDX)

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
	var new_audio = AudioStreamPlayer.new()
	new_audio.stream = sound
	new_audio.finished.connect(func(): new_audio.queue_free())
	new_audio.autoplay = true
	$Audio.add_child(new_audio)

func register_particle(particle : GameParticle, origin : GameParticle.Origins, position_offset : Vector3, source : Fighter):
	match origin:
		GameParticle.Origins.SOURCE:
			particle.position = source.position + position_offset
			$Particles.add_child(particle)
		GameParticle.Origins.SOURCE_STICKY:
			particle.position = position_offset
			source.add_child(particle)
		GameParticle.Origins.OTHER:
			if source.player:
				particle.position = p2.position + position_offset
				$Particles.add_child(particle)
			else:
				particle.position = p1.position + position_offset
				$Particles.add_child(particle)
		GameParticle.Origins.OTHER_STICKY:
			particle.position = position_offset
			if source.player:
				p2.add_child(particle)
			else:
				p1.add_child(particle)
		GameParticle.Origins.CUSTOM:
			particle.position = position_offset
			$Particles.add_child(particle)


func register_hitbox(hitbox : Hitbox):
	$Hitboxes.add_child(hitbox, true)


func register_projectile(projectile : Projectile):
	projectile.projectile_ended.connect(delete_projectile)
	$Projectiles.add_child(projectile, true)


func start_dramatic_freeze(dramatic_freeze : DramaticFreeze, source : Fighter):
	dramatic_freeze.end_freeze.connect(end_dramatic_freeze)
	dramatic_freeze.source = source
	dramatic_freeze.source_2d_pos = $FighterCamera.unproject_position(source.global_position)
	if source.player:
		dramatic_freeze.other = p2
		dramatic_freeze.other_2d_pos = $FighterCamera.unproject_position(p2.global_position)
	else:
		dramatic_freeze.other = p1
		dramatic_freeze.other_2d_pos = $FighterCamera.unproject_position(p1.global_position)
	$DramaticFreezes.add_child(dramatic_freeze, true)
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


func player_defeated():
	GameGlobal.global_hitstop = 120
	($HUD/BigText as Label).text = "KO"
	$HUD/BigText.modulate.a8 = 255
	moment = Moments.ROUND_END
	p1.game_ended = true
	p2.game_ended = true
	for projectile in ($Projectiles.get_children() as Array[Projectile]):
		projectile.destroy()


func training_mode_settings():
	if p1_reset_health_on_drop and not p2_combo:
		p1.health = p1_health_reset
	if p2_reset_health_on_drop and not p1_combo:
		p2.health = p2_health_reset


func _on_p1_health_reset_switch_toggled(toggled_on):
	p1_reset_health_on_drop = toggled_on


func _on_p1_health_reset_drag_ended(value_changed):
	if value_changed and p1_reset_health_on_drop:
		p1_health_reset = $HUD/TrainingModeControls/P1Controls/HBoxContainer/HealthReset.value


func _on_p2_health_reset_switch_toggled(toggled_on):
	p2_reset_health_on_drop = toggled_on


func _on_p2_health_reset_drag_ended(value_changed):
	if value_changed and p2_reset_health_on_drop:
		p2_health_reset = $HUD/TrainingModeControls/P2Controls/HBoxContainer/HealthReset.value


func _on_record_toggled(toggled_on):
	if toggled_on:
		player_record_buffer.clear()
		record_buffer_current = 0
	record = toggled_on


func _on_reset_button_up():
	get_tree().reload_current_scene()
