class_name FighterCamera
extends Camera3D

const ORTH_DIST = 1.328125
const MAXX = 1.6
const MAXY = 10
const DEFAULT_LERP = 0.25
enum Modes {
	BALANCED = 0,
	PLAYER1,
	PLAYER2,
	CUSTOM,
}
var pers_orth : bool
var mode : Modes

var p1_pos : Vector3
var p2_pos : Vector3

var custom_camera : Camera3D
var custom_cam_timer : int

func set_mode(new_mode : Modes):
	mode = new_mode


func _physics_process(_delta: float) -> void:
	projection = PROJECTION_PERSPECTIVE  if pers_orth else PROJECTION_ORTHOGONAL
	rotation = rotation.lerp(custom_camera.rotation if mode == Modes.CUSTOM else Vector3.ZERO, DEFAULT_LERP)
	if not mode == Modes.BALANCED:
		custom_cam_timer = max(custom_cam_timer - 1, 0)
		if not custom_cam_timer:
			set_mode(Modes.BALANCED)
	if GameGlobal.global_hitstop:
		return
	if mode == Modes.CUSTOM:
		position = position.lerp(custom_camera.position, DEFAULT_LERP)
	if pers_orth: # 3d style camera
		match mode:
			Modes.BALANCED:
				position = position.lerp(Vector3(
						(p1_pos.x + p2_pos.x)/2,
						max(p1_pos.y + 1, p2_pos.y + 1),
						clampf(abs(p1_pos.x - p2_pos.x)/2, 1.5, 1.825) + 0.5), DEFAULT_LERP)
			Modes.PLAYER1:
				position = position.lerp(Vector3(
						p1_pos.x,
						p1_pos.y + 1,
						1.5), DEFAULT_LERP)
			Modes.PLAYER2:
				position = position.lerp(Vector3(
						p2_pos.x,
						p2_pos.y + 1,
						1.5), DEFAULT_LERP)
	else: # 2d style camera
		match mode:
			Modes.BALANCED:
				position = position.lerp(Vector3(
						(p1_pos.x + p2_pos.x)/2,
						max(p1_pos.y + 1, p2_pos.y + 1),
						ORTH_DIST), DEFAULT_LERP)
				size = lerpf(size, clampf(abs(p1_pos.x - p2_pos.x)/2, 3.5, 6), DEFAULT_LERP)
			Modes.PLAYER1:
				position = position.lerp(Vector3(p1_pos.x, p1_pos.y, ORTH_DIST), DEFAULT_LERP)
			Modes.PLAYER2:
				position = position.lerp(Vector3(p2_pos.x, p2_pos.y, ORTH_DIST), DEFAULT_LERP)
	position = position.clamp(
		Vector3(-MAXX, 0, position.z),
		Vector3(MAXX, MAXY, position.z)
	)
