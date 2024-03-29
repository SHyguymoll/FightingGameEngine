class_name GameParticle
extends GPUParticles3D

enum Origins {
	SOURCE,
	SOURCE_STICKY,
	OTHER,
	OTHER_STICKY,
	CUSTOM,
}

func _ready() -> void:
	emitting = true

func _on_finished() -> void:
	queue_free()
