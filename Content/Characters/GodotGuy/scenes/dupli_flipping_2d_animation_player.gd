class_name DupliFlipping2DAnimationPlayer
extends FlippingAnimationPlayer

func _ready():
	var new_anims = []
	var working_list = get_animation_list()

	for anim_string in working_list:
		if anim_string.ends_with(anim_right_suf) and (
				anim_string.trim_suffix(anim_right_suf) + anim_left_suf) not in working_list:
			new_anims.append(
					[
						create_mirrored_animation(get_animation(anim_string)),
						StringName(anim_string.get_slice("/", 0)) #Animation Library in this case
					]
			)

	for anim in new_anims:
		get_animation_library(anim[1]).add_animation(anim[0].resource_name, anim[0])

func create_mirrored_animation(anim_to_mirror : Animation) -> Animation:
	var new_anim : Animation = anim_to_mirror.duplicate(true)
	new_anim.resource_name = anim_to_mirror.resource_name.trim_suffix(anim_right_suf) + anim_left_suf
	const POSITION_FLIP_X := Vector3(-1,1,1)
	const ROTATION_FLIP := Vector3(1,1,-1)

	for track_ind in range((new_anim as Animation).get_track_count()):
		# only flip the position 3d and rotation 3d tracks
		if (new_anim as Animation).track_get_type(track_ind) == Animation.TYPE_POSITION_3D:
			for key_ind in range((new_anim as Animation).track_get_key_count(track_ind)):
				(new_anim as Animation).track_set_key_value(
						track_ind,
						key_ind,
						(new_anim.track_get_key_value(track_ind, key_ind) as Vector3) * POSITION_FLIP_X)
		if (new_anim as Animation).track_get_type(track_ind) == Animation.TYPE_ROTATION_3D:
			for key_ind in range((new_anim as Animation).track_get_key_count(track_ind)):
				(new_anim as Animation).track_set_key_value(
						track_ind,
						key_ind,
						Quaternion.from_euler(
							(
								new_anim.track_get_key_value(track_ind, key_ind) as Quaternion
							).get_euler() * ROTATION_FLIP
						).normalized()
				)
	return new_anim
