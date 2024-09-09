class_name ProjectileMoveStraight
extends Projectile

@export var start_anim : StringName
@export var loop_anim_left : StringName
@export var loop_anim_right : StringName
@export var end_anim : StringName

var velocity : Vector3

enum types {
	STRAIGHT = 0,
	DIAGONAL_DOWN = 1,
	SUPER = 2,
	DIAGONAL_DOWN_SUPER = 3,
}

func _ready():
	match type:
		types.STRAIGHT:
			velocity = Vector3.RIGHT * 0.05
		types.DIAGONAL_DOWN:
			velocity = (Vector3.RIGHT * 0.05) + (Vector3.DOWN * 0.07)
		types.SUPER:
			velocity = Vector3.RIGHT * 0.12
		types.DIAGONAL_DOWN_SUPER:
			velocity = (Vector3.RIGHT * 0.03) + (Vector3.DOWN * 0.03)
	velocity.x *= 1 if right_facing else -1
	match type:
		types.STRAIGHT, types.DIAGONAL_DOWN:
			hitbox.damage_hit = 5
			hitbox.damage_block = 1
			hitbox.stun_hit = 10
			hitbox.stun_block = 5
			hitbox.hitstop_hit = 10
			hitbox.hitstop_block = 2
			hitbox.kback_hit = Vector3(4, 3, 0)
			hitbox.kback_block = Vector3(2, -2, 0)
			hitbox.on_hit = [8]
			hitbox.on_block = [4]
		types.SUPER:
			hitbox.damage_hit = 15
			hitbox.damage_block = 10
			hitbox.stun_hit = 10
			hitbox.stun_block = 5
			hitbox.hitstop_hit = 20
			hitbox.hitstop_block = 3
			hitbox.kback_hit = Vector3(4, 7, 0)
			hitbox.kback_block = Vector3(2, -2, 0)
			hitbox.hitbox_flags += Hitbox.HitboxFlags.SUPER
			hitbox.state_effect = Hitbox.StateEffects.LAUNCHER
			hitbox.hit_priority = 10
			hitbox.on_hit = [0]
			hitbox.on_block = [0]
		types.DIAGONAL_DOWN_SUPER:
			hitbox.damage_hit = 2
			hitbox.damage_block = 1
			hitbox.stun_hit = 10
			hitbox.stun_block = 5
			hitbox.hitstop_hit = 15
			hitbox.hitstop_block = 15
			hitbox.kback_hit = Vector3(-4, 10, 0)
			hitbox.kback_block = Vector3(2, -2, 0)
			hitbox.hitbox_flags += Hitbox.HitboxFlags.SUPER
			hitbox.state_effect = Hitbox.StateEffects.LAUNCHER
			hitbox.hit_priority = 10
			hitbox.on_hit = [0]
			hitbox.on_block = [0]
	$AnimationPlayer.play(start_anim)

func tick(delta : float):
	# hitstop check
	if GameGlobal.global_hitstop:
		return
	global_position += velocity
	if hitbox == null:
		destroy()
	$AnimationPlayer.advance(delta)

func destroy():
	super()
	velocity = Vector3.ZERO
	$AnimationPlayer.play(end_anim)

func _on_animation_player_animation_finished(anim_name):
	match anim_name:
		start_anim:
			$AnimationPlayer.play(loop_anim_right if right_facing else loop_anim_left)
		loop_anim_left:
			$AnimationPlayer.play(loop_anim_left)
		loop_anim_right:
			$AnimationPlayer.play(loop_anim_right)
		end_anim:
			emit_signal(&"projectile_ended", self)
	$AnimationPlayer.advance(0)
