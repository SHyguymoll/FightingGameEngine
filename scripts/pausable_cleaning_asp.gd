class_name PausingCleaningAudioStreamPlayer
extends AudioStreamPlayer

var time_paused : float
var game_tick_started : int

func _ready() -> void:
	finished.connect(func(): queue_free())
	play()

func pause(current_game_tick : int):
	var p_ticks = float(ProjectSettings.get_setting(
		"physics/common/physics_ticks_per_second"))
	time_paused = float(current_game_tick - game_tick_started)/p_ticks
	stop()

func unpause():
	play(time_paused)
