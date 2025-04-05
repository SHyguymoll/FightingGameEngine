extends State2DMeterFighter

@onready var s_2d_anim_player : State2DAnimationPlayer = $AnimationPlayer

func _ready():
	reset_facing()
	debug_data.visible = get_parent().get_parent() is TrainingModeGame
	s_2d_anim_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	s_2d_anim_player.play(s_2d_anim_player.basic_anim_state_dict[current_state] +
			(s_2d_anim_player.anim_right_suf if right_facing else s_2d_anim_player.anim_left_suf))


func _process(_delta):
	(ui_under_health as TextureProgressBar).value = meter
	if not get_parent().get_parent() is TrainingModeGame:
		return
	debug_data.text = """State: %s (Prev: %s)
Vels: %s | %s | %s
Stun: %s/%s
Current Animation : %s
Jumps: %s/%s
""" % [States.keys()[current_state], States.keys()[previous_state],
		ground_vel, aerial_vel, kback, stun_time_current, stun_time_start,
		s_2d_anim_player.current_animation, jump_count, jump_total,
	]


func _post_outro() -> bool:
	return (current_state in [States.ROUND_WIN, States.SET_WIN] and not s_2d_anim_player.is_playing())


func _input_step() -> void:
	resolve_state_transitions()
	handle_input()


## NOTE: AnimationPlayer uses a manual mode in order to fix desyncing when pausing.
func _action_step(dramatic_freeze : bool, delta : float):
	if GameGlobal.global_hitstop == 0 and not dramatic_freeze:
		update_character_state()
		reset_facing()
		ticks_since_state_change += 1
		s_2d_anim_player.advance(delta)
	if dramatic_freeze and current_state == States.ATCK_SUPR: #super move exception
		s_2d_anim_player.advance(delta)


func _connect_hud_elements(training_mode : bool):
	if training_mode:
		(ui_training.get_node("HSlider") as HSlider).value_changed.connect(training_mode_set_meter)
		(ui_training.get_node("Label") as Label).text = (States.keys() as Array[String])[current_state]
		if "attack" in (ui_training.get_node("Label") as Label).text:
			(ui_training.get_node("Label") as Label).text += " : " + current_attack


func set_state(new_state: States):
	if current_state != new_state:
		current_state = new_state
		update_character_animation()
		ticks_since_state_change = 0


func resolve_state_transitions():
	# jump bug patch
	if previous_state in [States.JUMP_INIT, States.JUMP_AIR_INIT, States.DASH_A_F, States.DASH_A_B]:
		previous_state = States.JUMP
	# re-intro/outro patch
	if previous_state in [States.INTRO, States.ROUND_WIN, States.SET_WIN,
		States.OUTRO_LOSE, States.OUTRO_FALL, States.OUTRO_LIE, States.OUTRO_BNCE]:
		previous_state = States.IDLE
	match current_state:
		States.IDLE, States.WALK_F, States.WALK_B, States.CRCH when game_ended in [Fighter.GameEnds.WIN_TIME, Fighter.GameEnds.WIN_KO]:
			set_state(States.ROUND_WIN)
			return
		States.IDLE, States.WALK_F, States.WALK_B, States.CRCH when game_ended in [Fighter.GameEnds.LOSE_TIME]:
			set_state(States.OUTRO_LOSE)
			return
		States.INTRO when not s_2d_anim_player.is_playing():
			set_state(States.IDLE)
			previous_state = current_state
		States.ROUND_WIN:
			previous_state = current_state
			set_state(States.ROUND_WIN)
		States.SET_WIN:
			previous_state = current_state
			set_state(States.SET_WIN)
		States.GET_UP:
			if not s_2d_anim_player.is_playing():
				set_state(previous_state)
		States.DASH_B, States.DASH_F when animation_ended:
			set_state(States.IDLE)
		States.DASH_A_F, States.DASH_A_B when ticks_since_state_change >= DASH_INPUT_LENIENCY + 1:
			set_state(States.JUMP)
		States.JUMP_INIT when ticks_since_state_change >= JUMP_SQUAT_LENGTH + 1:
			set_state(States.JUMP)
		States.JUMP_AIR_INIT when ticks_since_state_change >= 1:
			set_state(States.JUMP)
		States.JUMP, States.JUMP_NO_ACT when is_on_floor():
			var new_walk = try_walk(null, current_state)
			set_state(new_walk)
		States.BLCK_AIR:
			if is_on_floor():
				stun_time_current = 0
			handle_air_stun()
			if not stun_time_current:
				set_state(States.JUMP)
		States.HURT_HGH, States.HURT_LOW, States.HURT_CRCH, States.BLCK_HGH, States.BLCK_LOW:
			handle_stand_stun()
		States.HURT_GRB, States.HURT_GRB_NOBREAK:
			if stun_time_current == 0:
				set_state(States.HURT_FALL)
		States.HURT_FALL:
			handle_air_stun()
			if check_true and stun_time_current < stun_time_start:
				set_state(States.HURT_LIE)
		States.HURT_BNCE:
			if check_true:
				set_state(States.HURT_FALL)
				set_stun(stun_time_start)
				kback.y *= -1
		States.OUTRO_BNCE:
			if check_true:
				set_state(States.OUTRO_FALL)
				set_stun(stun_time_start)
				kback.y *= -1
		States.HURT_LIE:
			if stun_time_current == 0:
				set_state(States.GET_UP)
		States.OUTRO_FALL:
			if check_true:
				set_state(States.OUTRO_LIE)
		States.ATCK_NRML when attack_connected:
			set_state(States.ATCK_NRML_IMP)
		States.ATCK_JUMP when attack_connected:
			set_state(States.ATCK_JUMP_IMP)
		States.ATCK_CMND when attack_connected:
			set_state(States.ATCK_CMND_IMP)
		States.ATCK_NRML, States.ATCK_CMND, States.ATCK_MOTN, States.ATCK_SUPR, States.ATCK_JUMP, States.ATCK_NRML_IMP, States.ATCK_JUMP_IMP, States.ATCK_CMND_IMP, States.ATCK_MOTN_IMP, States.ATCK_GRAB_END when animation_ended:
			force_airborne = false
			force_collisions = false
			set_state(s_2d_anim_player.attack_return_states.get(current_attack + ("_imp" if impact_state() else ""), previous_state))
		States.ATCK_GRAB_START when animation_ended:
			force_airborne = false
			force_collisions = false
			update_attack(s_2d_anim_player.grab_return_states[current_attack][attack_hurt])
			set_state(States.ATCK_GRAB_END)
		States.ATCK_JUMP, States.ATCK_JUMP_IMP when is_on_floor():
			var new_walk = try_walk(null, current_state)
			set_state(new_walk)


func update_character_animation():
	if _in_attacking_state():
		s_2d_anim_player.play(
				current_attack + (s_2d_anim_player.anim_right_suf if right_facing
						else s_2d_anim_player.anim_left_suf))
	elif impact_state():
		s_2d_anim_player.play(
				current_attack + "_imp" + (s_2d_anim_player.anim_right_suf if right_facing
						else s_2d_anim_player.anim_left_suf))
	else:
		s_2d_anim_player.update_animation()
	# Update animation immediately for manual processing mode
	s_2d_anim_player.advance(0)
