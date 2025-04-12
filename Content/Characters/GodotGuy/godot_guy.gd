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


func handle_defeated():
	set_state(States.OUTRO_BNCE)
	kback.y += 6.5
	emit_signal(&"defeated")


func counter_hit(attack : Hitbox, combo_count : int):
	create_particle("counter_hit", GameParticle.Origins.SOURCE,attack.position)
	attack.hitstop_hit = int(float(attack.hitstop_hit) * 1.5)
	handle_damage(attack, true, choose_hurting_state(attack), combo_count)


func _input_step() -> void:
	resolve_state_transitions()
	handle_input()


func handle_input() -> void:
	var decision : States = current_state
	match current_state:
# Priority order, from least to most:
# Walk, Backdash, Dash, Crouch, Jump, Attack
# Blocking and Hurting is at the top but handled in _damage_step()
		States.IDLE, States.WALK_B, States.WALK_F:
			match current_state:
				States.IDLE:
					decision = try_walk(WalkingX.NEUTRAL, decision)
					if len(inputs.up) > 3:
						if right_facing:
							decision = try_dash(GameGlobal.BTN_LEFT, States.DASH_B, decision)
							decision = try_dash(GameGlobal.BTN_RIGHT, States.DASH_F, decision)
						else:
							decision = try_dash(GameGlobal.BTN_LEFT, States.DASH_F, decision)
							decision = try_dash(GameGlobal.BTN_RIGHT, States.DASH_B, decision)
				States.WALK_B:
					decision = try_walk(WalkingX.BACK, decision)
				States.WALK_F:
					decision = try_walk(WalkingX.FORWARD, decision)
			decision = States.CRCH if btn_pressed(GameGlobal.BTN_DOWN) else decision
			decision = try_jump(decision)
			decision = try_attack(decision)
# Order: release down, attack, b/h
		States.CRCH:
			decision = try_walk(null, decision) if !btn_pressed(GameGlobal.BTN_DOWN) else decision
			decision = try_attack(decision)
# Order: jump, attack, b/h
		States.JUMP:
			if len(inputs.up) > 3:
				if right_facing:
					decision = try_dash(GameGlobal.BTN_LEFT, States.DASH_A_B, decision, true)
					decision = try_dash(GameGlobal.BTN_RIGHT, States.DASH_A_F, decision, true)
				else:
					decision = try_dash(GameGlobal.BTN_LEFT, States.DASH_A_F, decision, true)
					decision = try_dash(GameGlobal.BTN_RIGHT, States.DASH_A_B, decision, true)
			decision = try_jump(decision, false)
			decision = try_attack(decision)
# Cancel ground dashes into specials and supers
		States.DASH_F, States.DASH_B:
			decision = try_super_attack(decision)
			decision = try_special_attack(decision)
# Cancel air dashes into any attack
		States.DASH_A_F, States.DASH_A_B:
			decision = try_attack(decision)
# Special cases for attack canceling
		States.ATCK_NRML_IMP:
			# dash canceling normals
			if len(inputs.up) > 3:
				if right_facing:
					decision = try_dash("left", States.DASH_B, decision)
					decision = try_dash("right", States.DASH_F, decision)
				else:
					decision = try_dash("left", States.DASH_F, decision)
					decision = try_dash("right", States.DASH_B, decision)
			# jump canceling normals
			if decision == States.ATCK_NRML_IMP:
				decision = try_jump(decision)
			# magic series
			if decision == States.ATCK_NRML_IMP:
				match current_attack:
					"attack_normal/a":
						decision = try_magic_series(1, decision)
					"attack_normal/b":
						decision = try_magic_series(2, decision)
					"attack_normal/c":
						decision = try_magic_series(3, decision)
			# special cancelling
			if decision == States.ATCK_NRML_IMP:
				decision = try_special_attack(decision)
		States.ATCK_MOTN:
			if attack_hurt:
				decision = try_super_attack(decision)
# grab breaks
		States.HURT_GRB:
			if ticks_since_state_change < 10 and two_atk_just_pressed():
				set_stun(4)
				kback = Vector3(3, 5, 0)
				create_hitbox(Vector3.ZERO, "grab_break")
				decision = States.HURT_FALL
	set_state(decision)


func try_super_attack(cur_state: States) -> States:
	match current_state:
		States.IDLE, States.WALK_B, States.WALK_F, States.DASH_F, States.DASH_B:
			if motion_input_check(MOTION_GG) and one_atk_just_pressed() and meter >= 50:
				meter -= 50
				update_attack("attack_super/projectile")
				return States.ATCK_SUPR
		States.JUMP, States.DASH_A_F, States.DASH_A_B:
			if motion_input_check(MOTION_GG) and one_atk_just_pressed() and meter >= 50:
				meter -= 50
				update_attack("attack_super/projectile_air")
				jump_count = 0
				return States.ATCK_SUPR
		States.ATCK_MOTN:
			match current_attack:
				"attack_super/projectile", "attack_motion/uppercut", "attack_motion/spin_approach", "attack_motion/spin_approach_air":
					if motion_input_check(MOTION_GG) and one_atk_just_pressed() and meter >= 50:
						meter -= 50
						update_attack("attack_super/projectile_air")
						jump_count = 0
						return States.ATCK_SUPR
	return cur_state


func try_special_attack(cur_state: States) -> States:
	match current_state:
		States.IDLE, States.WALK_B, States.WALK_F, States.ATCK_NRML, States.DASH_F, States.DASH_B:
			# check z_motion first since there's a lot of overlap with quarter_circle in some cases
			if motion_input_check(MOTION_ZFORWARD) and one_atk_just_pressed():
				update_attack("attack_motion/uppercut")
				jump_count = 0
				return States.ATCK_MOTN
			if motion_input_check(MOTION_QCF) and one_atk_just_pressed():
				update_attack("attack_motion/projectile")
				return States.ATCK_MOTN
			if motion_input_check(MOTION_QCB) and one_atk_just_pressed():
				update_attack("attack_motion/spin_approach")
				return States.ATCK_MOTN
		States.CRCH:
			if motion_input_check(MOTION_ZFORWARD) and one_atk_just_pressed():
				update_attack("attack_motion/uppercut")
				jump_count = 0
				return States.ATCK_MOTN
		States.JUMP, States.DASH_A_F, States.DASH_A_B:
			if (motion_input_check(MOTION_QCF + MOTION_TKF) and
					one_atk_just_pressed()):
				update_attack("attack_motion/projectile_air")
				jump_count = 0
				return States.ATCK_MOTN
			if (motion_input_check(MOTION_QCB + MOTION_TKB) and
					one_atk_just_pressed()):
				update_attack("attack_motion/spin_approach_air")
				return States.ATCK_MOTN
		States.ATCK_NRML:
			match current_attack:
				"attack_normal/c", "attack_command/crouch_c":
					if motion_input_check(MOTION_ZFORWARD) and one_atk_just_pressed():
						update_attack("attack_motion/uppercut")
						jump_count = 0
						return States.ATCK_MOTN
					if motion_input_check(MOTION_QCB) and one_atk_just_pressed():
						update_attack("attack_motion/spin_approach")
						return States.ATCK_MOTN
				"attack_normal/b":
					if motion_input_check(MOTION_QCF) and one_atk_just_pressed():
						update_attack("attack_motion/projectile")
						return States.ATCK_MOTN
	return cur_state


func try_attack(cur_state: States) -> States:
	if (not btn_just_pressed("button0") and not btn_just_pressed("button1") and
		not btn_just_pressed("button2")):
		return cur_state
	previous_state = cur_state
	var super_attack = try_super_attack(cur_state)
	if super_attack != cur_state:
		return super_attack
	var special_attack = try_special_attack(cur_state)
	if special_attack != cur_state:
		return special_attack
	match current_state:
		States.IDLE, States.WALK_F:
			if two_atk_just_pressed():
				update_attack("attack_normal/grab")
				return States.ATCK_GRAB_START
			if btn_just_pressed("button0"):
				update_attack("attack_normal/a")
				return States.ATCK_NRML
			if btn_just_pressed("button1"):
				update_attack("attack_normal/b")
				return States.ATCK_NRML
			if btn_just_pressed("button2"):
				update_attack("attack_normal/c")
				return States.ATCK_NRML
		States.WALK_B:
			if two_atk_just_pressed():
				update_attack("attack_normal/grab_back")
				return States.ATCK_GRAB_START
			if btn_just_pressed("button0"):
				update_attack("attack_normal/a")
				return States.ATCK_NRML
			if btn_just_pressed("button1"):
				update_attack("attack_normal/b")
				return States.ATCK_NRML
			if btn_just_pressed("button2"):
				update_attack("attack_normal/c")
				return States.ATCK_NRML
		States.CRCH:
			if btn_just_pressed("button0"):
				update_attack("attack_command/crouch_a")
				return States.ATCK_CMND
			if btn_just_pressed("button1"):
				update_attack("attack_command/crouch_b")
				return States.ATCK_CMND
			if btn_just_pressed("button2"):
				update_attack("attack_command/crouch_c")
				return States.ATCK_CMND
		States.JUMP, States.DASH_A_F, States.DASH_A_B:
			if btn_just_pressed("button0"):
				update_attack("attack_jumping/a")
				return States.ATCK_JUMP
			if btn_just_pressed("button1"):
				update_attack("attack_jumping/b")
				return States.ATCK_JUMP
			if btn_just_pressed("button2"):
				update_attack("attack_jumping/c")
				return States.ATCK_JUMP
	# how did we get here, something has gone terribly wrong
	return previous_state


func try_magic_series(level: int, cur_state: States) -> States:
	if level == 1 and btn_just_pressed("button1"):
		update_attack("attack_normal/b")
		return States.ATCK_NRML
	elif level == 2 and btn_just_pressed("button2"):
		update_attack("attack_normal/c")
		return States.ATCK_NRML
	else:
		return cur_state


func any_atk_just_pressed():
	return (btn_just_pressed("button0") or
			btn_just_pressed("button1") or
			btn_just_pressed("button2"))


func all_atk_just_pressed():
	return (btn_just_pressed("button0") and
			btn_just_pressed("button1") and
			btn_just_pressed("button2"))


func two_atk_just_pressed():
	return (int(btn_just_pressed("button0")) +
			int(btn_just_pressed("button1")) +
			int(btn_just_pressed("button2")) == 2)


func one_atk_just_pressed():
	return (int(btn_just_pressed("button0")) +
			int(btn_just_pressed("button1")) +
			int(btn_just_pressed("button2")) == 1)


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

func _do_switch_facing():
	reset_facing(true)
	if current_state in [
		States.IDLE,
		States.CRCH,
		States.WALK_F,
		States.WALK_B,
	]:
		s_2d_anim_player.update_animation()
