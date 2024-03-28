class_name FighterCamera
extends Camera3D

const ORTH_DIST = 1.328125
const MAXX = 1.6
const MAXY = 10
const DEFAULT_LERP = 0.25
enum Modes {
	ORTH_BALANCED = 0,
	ORTH_PLAYER1,
	ORTH_PLAYER2,
	ORTH_CUSTOM,
	PERS_BALANCED,
	PERS_PLAYER1,
	PERS_PLAYER2,
	PERS_CUSTOM,
}
var mode : Modes

var p1_pos : Vector3
var p2_pos : Vector3
var custom_pos : Vector3
var custom_rot : Vector3
var custom_lerp : float
var custom_cam_timer : int

func set_mode(new_mode : Modes):
	mode = new_mode

func mode_is_orth() -> bool:
	return mode < Modes.PERS_BALANCED

func mode_is_balanced() -> bool:
	return mode in [Modes.ORTH_BALANCED, Modes.PERS_BALANCED]

func _physics_process(_delta: float) -> void:
	projection = PROJECTION_ORTHOGONAL if mode_is_orth() else PROJECTION_PERSPECTIVE
	rotation = rotation.lerp(custom_rot, custom_lerp) if mode == Modes.PERS_CUSTOM else Vector3.ZERO
	if not mode_is_balanced():
		custom_cam_timer = max(custom_cam_timer - 1, 0)
		if not custom_cam_timer:
			if mode_is_orth():
				set_mode(Modes.ORTH_BALANCED)
			else:
				set_mode(Modes.PERS_BALANCED)
	if GameGlobal.global_hitstop:
		return
	match mode:
		#2d modes
		Modes.ORTH_BALANCED:
			position = position.lerp(Vector3(
					(p1_pos.x + p2_pos.x)/2,
					max(p1_pos.y + 1, p2_pos.y + 1),
					ORTH_DIST), DEFAULT_LERP)
			size = lerpf(size, clampf(abs(p1_pos.x - p2_pos.x)/2, 3.5, 6), DEFAULT_LERP)
		Modes.ORTH_PLAYER1:
			position = position.lerp(Vector3(p1_pos.x, p1_pos.y, ORTH_DIST), DEFAULT_LERP)
		Modes.ORTH_PLAYER2:
			position = position.lerp(Vector3(p2_pos.x, p2_pos.y, ORTH_DIST), DEFAULT_LERP)
		Modes.ORTH_CUSTOM:
			position = position.lerp(Vector3(custom_pos.x, custom_pos.y, custom_pos.z), DEFAULT_LERP)
		#3d modes
		Modes.PERS_BALANCED:
			position = position.lerp(Vector3(
					(p1_pos.x + p2_pos.x)/2,
					max(p1_pos.y + 1, p2_pos.y + 1),
					clampf(abs(p1_pos.x - p2_pos.x)/2, 1.5, 1.825) + 0.5), DEFAULT_LERP)
		Modes.PERS_PLAYER1:
			position = position.lerp(Vector3(
					p1_pos.x,
					p1_pos.y + 1,
					1.5), DEFAULT_LERP)
		Modes.PERS_PLAYER2:
			position = position.lerp(Vector3(
					p2_pos.x,
					p2_pos.y + 1,
					1.5), DEFAULT_LERP)
	position = position.clamp(
		Vector3(-MAXX, 0, position.z),
		Vector3(MAXX, MAXY, position.z)
	)
